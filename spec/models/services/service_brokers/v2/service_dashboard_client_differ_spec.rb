require 'spec_helper'
require 'models/services/service_brokers/v2/service_dashboard_client_differ'

module VCAP::CloudController::ServiceBrokers::V2
  describe ServiceDashboardClientDiffer do
    describe '.create_changeset' do
      let(:uaa_client) { double(:uaa_client) }
      let(:service_broker) { double(:service_broker) }
      let(:catalog_service_1) do
        CatalogService.new(service_broker, 'dashboard_client' => {
          'id' => 'client-id-1',
          'secret' => 'sekret',
          'redirect_uri' => 'https://foo.com'
        })
      end
      let(:catalog_service_2) do
        CatalogService.new(service_broker, 'dashboard_client' => {
          'id' => 'client-id-2',
          'secret' => 'sekret2',
          'redirect_uri' => 'https://foo2.com'
        })
      end
      let(:differ) { ServiceDashboardClientDiffer.new(service_broker, uaa_client) }

      subject(:changeset) { differ.create_changeset(services_requesting_clients, existing_clients) }

      context 'when there is a non-existing client requested' do
        let(:services_requesting_clients) { [catalog_service_1] }
        let(:existing_clients) { [] }
        it 'returns a create command' do
          expect(changeset).to have(1).items
          expect(changeset.first).to be_a CreateClientCommand
          expect(changeset.first.client_attrs).to eq(catalog_service_1.dashboard_client)
          expect(changeset.first.service_broker).to eq(service_broker)
        end
      end

      context 'when a requested client exists' do
        let(:services_requesting_clients) { [catalog_service_1] }
        let(:existing_clients) do
          [
            double(:client,
              service_id_on_broker: catalog_service_1.broker_provided_id,
              uaa_id: catalog_service_1.dashboard_client['id']
            )
          ]
        end

        it 'returns update commands for the existing clients' do
          expect(changeset).to have(1).items
          expect(changeset.first).to be_a UpdateClientCommand
          expect(changeset.first.client_attrs).to eq(catalog_service_1.dashboard_client)
        end
      end
    end
  end
end
