require 'models/services/service_brokers/v2/create_client_command'
require 'models/services/service_brokers/v2/update_client_command'

module VCAP::CloudController::ServiceBrokers::V2
  class ServiceDashboardClientDiffer
    def initialize(broker, client_manager)
      @broker = broker
      @client_manager = client_manager
    end

    def create_changeset(catalog_services, existing_clients)
      catalog_services.map do |service|
        existing_client = existing_clients.detect {|client|
          client.uaa_id == service.dashboard_client.fetch('id')
        }
        if existing_client
          UpdateClientCommand.new(
            client_attrs: service.dashboard_client,
            client_manager: client_manager,
          )
        else
          CreateClientCommand.new(
            client_attrs: service.dashboard_client,
            client_manager: client_manager,
            service_broker: broker,
          )
        end
      end
    end

    private

    attr_reader :broker, :client_manager
  end
end
