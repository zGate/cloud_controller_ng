module VCAP::CloudController
  module Dea
    class Backend
      def initialize(app, process_type, config, message_bus, dea_pool, stager_pool)
        @logger ||= Steno.logger("cc.dea.backend")
        @app = app
        @process_type = process_type
        @config = config
        @message_bus = message_bus
        @dea_pool = dea_pool
        @stager_pool = stager_pool
      end

      def requires_restage?
        false
      end

      def stage
        blobstore_url_generator = CloudController::DependencyLocator.instance.blobstore_url_generator
        task = AppStagerTask.new(@config, @message_bus, @process_type, @dea_pool, @stager_pool, blobstore_url_generator)
        @process_type.last_stager_response = task.stage { |staging_result| start(staging_result) }
      end

      def scale
        changes = @process_type.previous_changes
        delta = changes[:instances][1] - changes[:instances][0]

        Client.change_running_instances(@process_type, delta)
      end

      def start(staging_result={})
        started_instances = staging_result[:started_instances] || 0
        Client.start(@process_type, instances_to_start: @app.instances - started_instances)
      end

      def stop
        app_stopper = AppStopper.new(@message_bus)
        app_stopper.publish_stop(droplet: @app.guid)
      end
    end
  end
end
