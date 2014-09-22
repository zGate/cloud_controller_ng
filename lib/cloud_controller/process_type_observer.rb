require "cloud_controller/multi_response_message_bus_request"
require "models/runtime/droplet_uploader"
require "cloud_controller/dea/app_stopper"
require "cloud_controller/backends"

module VCAP::CloudController
  module ProcessTypeObserver
    class << self
      extend Forwardable

      def configure(backends)
        @backends = backends
      end

      def updated(process_type)
        p process_type.previous_changes
        changes = process_type.previous_changes
        return unless changes

        if changes.has_key?(:instances)
          react_to_instances_change(process_type)
        end
      end

      private

      def react_to_instances_change(process_type)
        @backends.find_one_to_run(process_type.app, process_type).scale if process_type.app.started?
      end
    end
  end
end
