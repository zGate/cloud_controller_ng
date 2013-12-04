require 'spec_helper'

describe 'Service Broker API integration', type: :controller do
  describe 'v2.0' do
    # Given ...
    let!(:service_broker) { VCAP::CloudController::ServiceBroker.make(broker_url: the_broker_url) }
    let!(:service) { VCAP::CloudController::Service.make(service_broker: service_broker, url: nil) }
    let!(:plan) { VCAP::CloudController::ServicePlan.make(service: service) }
    let!(:org) { VCAP::CloudController::Organization.make }
    let!(:space) { VCAP::CloudController::Space.make(organization: org) }

    let(:the_broker_url) { "http://#{the_broker_domain}" }
    let(:the_broker_domain) { 'the.broker.com' }
    let(:the_service_id) { service.broker_provided_id }
    let(:the_plan_guid) { plan.guid }
    let(:the_plan_id) { plan.broker_provided_id }
    let(:the_space_guid) { space.guid }
    let(:the_org_guid) { org.guid }
    let(:guid_pattern) { '[[:alnum:]-]+' }

    describe 'a provision request' do

      context "Something" do
        let(:request_to_cc) do
          {
            name: 'test-service',
            space_guid: the_space_guid,
            service_plan_guid: the_plan_guid
          }
        end

        let(:request_from_cc_to_broker) do
          {
            service_id:        the_service_id,
            plan_id:           the_plan_id,
            organization_guid: the_org_guid,
            space_guid:        the_space_guid,
          }
        end

        it 'sends all required fields' do
          the_request = stub_request(:put, %r(#{the_broker_domain}/v2/service_instances/#{guid_pattern})).
            with(body: hash_including(request_from_cc_to_broker)).
            to_return(status: 201, body: '{}')

          post('/v2/service_instances',
               request_to_cc.to_json,
               json_headers(admin_headers)
          )

          last_response.status.should == 201

          expect(the_request).to have_been_made
        end

      end

      context 'when the dashboard_url is given' do
        it 'returns a 201 to the user' do
          the_request = stub_request(:put, %r(#{the_broker_domain}/v2/service_instances/#{guid_pattern})).
            to_return(status: 201, body: '{"dashboard_url": "http://something.com"}')

          post('/v2/service_instances',
               {name: 'test-service', space_guid: the_space_guid, service_plan_guid: the_plan_guid}.to_json,
               json_headers(admin_headers)
          )

          last_response.status.should == 201

          expect(the_request).to have_been_made
        end
      end

      context 'when the dashboard_url is not given' do
        it 'returns a 201 to the user' do
          the_request = stub_request(:put, %r(#{the_broker_domain}/v2/service_instances/#{guid_pattern})).
            to_return(status: 201, body: '{}')

          post('/v2/service_instances',
               {name: 'test-service', space_guid: the_space_guid, service_plan_guid: the_plan_guid}.to_json,
               json_headers(admin_headers)
          )

          last_response.status.should == 201

          expect(the_request).to have_been_made
        end
      end
    end
  end
end
