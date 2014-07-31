require "cloud_controller/multi_response_message_bus_request"
require "models/runtime/droplet_uploader"
require "cloud_controller/dea/app_stopper"

module VCAP::CloudController
  class Backend
    def initialize(message_bus, diego_client)
      @message_bus = message_bus
      @diego_client = diego_client
    end

    def for(app)
      if @diego_client.running_enabled(app)
        Diego.new(app, @diego_client)
      else
        Dea.new(app, @message_bus)
      end
    end

    class Dea
      include VCAP::CloudController::Dea # TODO: Stop including once this backed is moved into the Dea namespace

      def initialize(app, message_bus)
        @app = app
        @message_bus = message_bus
      end

      def scale
        changes = @app.previous_changes
        delta = changes[:instances][1] - changes[:instances][0]

        Client.change_running_instances(@app, delta)
        broadcast_app_updated
      end

      def start#(staging_result={})
        started_instances = staging_result[:started_instances] || 0
        Dea::Client.start(@app, :instances_to_start => @app.instances - started_instances)
        broadcast_app_updated
      end

      def stop
        Client.stop(@app)
        broadcast_app_updated
      end

      def delete
        stopper = AppStopper.new(@message_bus)
        stopper.stop(@app)
      end

      def broadcast_app_updated # TODO: Make private when all usages have been moved into this class
        @message_bus.publish("droplet.updated", droplet: @app.guid)
      end
    end

    class Diego
      def initialize(app, diego_client)
        @app = app
        @diego_client = diego_client
      end

      def scale
        @diego_client.send_desire_request(@app)
      end

      def start#(_={})
        @diego_client.send_desire_request(@app)
      end

      def stop
        @diego_client.send_desire_request(@app)
      end

      def delete
        @diego_client.send_desire_request(@app)
      end
    end
  end

  module AppObserver
    class << self
      extend Forwardable

      def configure(config, message_bus, dea_pool, stager_pool, diego_client)
        @config = config
        @message_bus = message_bus # TODO: Always use @backend instead
        @dea_pool = dea_pool # TODO: Always use @backend instead
        @stager_pool = stager_pool # TODO: Always use @backend instead
        @diego_client = diego_client # TODO: Always use @backend instead
        @backend = Backend.new(@message_bus, @diego_client)
      end

      def deleted(app)
        @backend.for(app).delete

        delete_package(app) if app.package_hash
        delete_buildpack_cache(app)
      end

      def updated(app)
        changes = app.previous_changes
        return unless changes

        if changes.has_key?(:state)
          react_to_state_change(app)
        elsif changes.has_key?(:instances)
          react_to_instances_change(app)
        end
      end

      def run
        @stager_pool.register_subscriptions
      end

      private

      def delete_buildpack_cache(app)
        delete_job = Jobs::Runtime::BlobstoreDelete.new(app.guid, :buildpack_cache_blobstore)
        Jobs::Enqueuer.new(delete_job, queue: "cc-generic").enqueue()
      end

      def delete_package(app)
        delete_job = Jobs::Runtime::BlobstoreDelete.new(app.guid, :package_blobstore)
        Jobs::Enqueuer.new(delete_job, queue: "cc-generic").enqueue()
      end

      def dependency_locator
        CloudController::DependencyLocator.instance
      end

      def validate_app_for_staging(app)
        if app.package_hash.nil? || app.package_hash.empty?
          raise Errors::ApiError.new_from_details("AppPackageInvalid", "The app package hash is empty")
        end

        if app.buildpack.custom? && !app.custom_buildpacks_enabled?
          raise Errors::ApiError.new_from_details("CustomBuildpacksDisabled")
        end
      end

      def stage_app_on_diego(app)
        # TODO: encapsulate in Diego::ClientStrategy included in CompositeClientStrategy
        validate_app_for_staging(app)
        @diego_client.send_stage_request(app, VCAP.secure_uuid)
      end

      def react_to_state_change(app)
        # TODO: client_strategy.react_to_state_change(app) and move all logic into *::ClientStrategy included in CompositeClientStrategy
        # or decompose logic further?
        if !app.started? # needs to be stopped...
          @backend.for(app).stop
        elsif app.needs_staging?
          if @diego_client.staging_needed(app)
            stage_app_on_diego(app)
          else
            validate_app_for_staging(app)
            task = Dea::AppStagerTask.new(@config, @message_bus, app, @dea_pool, @stager_pool, dependency_locator.blobstore_url_generator)
            app.last_stager_response = task.stage do |staging_result|
              @backend.for(app).start(staging_result)
            end
          end
        else
          @backend.for(app).start
        end
      end

      def foo_bar(app, staging_result={:started_instances => 0})
        started_instances = staging_result[:started_instances]
        Dea::Client.start(app, :instances_to_start => app.instances - started_instances)
        @backend.for(app).broadcast_app_updated
      end

      def react_to_instances_change(app)
        @backend.for(app).scale if app.started?
      end
    end
  end
end
