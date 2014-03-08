require 'spec_helper'

describe 'Service Broker' do
  before do
    VCAP::CloudController::Controller.any_instance.stub(:in_test_mode?).and_return(false)
  end

  before(:all) { setup_cc }
  after(:all) { $spec_env.reset_database_with_seeds }

  describe 'adding a service broker' do
    context 'when a service has no plans' do
      before do
        stub_catalog_fetch(200, {
          services: [{
            id:          '12345',
            name:        'MySQL',
            description: 'A MySQL service, duh!',
            bindable:    true,
            plans:       []
          }]
        })
      end

      it 'notifies the operator of the problem' do
        post('/v2/service_brokers', {
          name: 'some-guid',
          broker_url: 'http://broker-url',
          auth_username: 'username',
          auth_password: 'password'
        }.to_json, json_headers(admin_headers))

        expect(last_response.status).to eql(502)
        expect(decoded_response['code']).to eql(270012)
        expect(decoded_response['description']).to eql("Service broker catalog is invalid: \nService MySQL\n  At least one plan is required\n")
      end
    end

    context 'when there are multiple validation problems in the catalog' do
      before do
        stub_catalog_fetch(200, {
          services: [{
            id:          12345,
            name:        "service-1",
            description: "A service, duh!",
            bindable:    true,
            plans:       [{
              id:          "plan-1",
              name:        "small",
              description: "A small shared database with 100mb storage quota and 10 connections"
            }, {
              id:          "plan-2",
              name:        "large",
              description: "A large dedicated database with 10GB storage quota, 512MB of RAM, and 100 connections"
            }]
          },
            {
              id:          '67890',
              name:        "service-2",
              description: "Another service, duh!",
              bindable:    true,
              plans:       [{
                id:          "plan-b",
                name:        "small",
                description: "A small shared database with 100mb storage quota and 10 connections"
              }, {
                id:          "plan-b",
                name:        "large",
                description: ""
              }]
            },
            {
              id:          '67890',
              name:        "service-3",
              description: "Yet another service, duh!",
              bindable:    true,
              dashboard_client: {
                id: 'client-1'
              },
              plans:       [{
                id:          123,
                name:        "tiny",
                description: "A small shared database with 100mb storage quota and 10 connections"
              }, {
                id:          '456',
                name:        "tiny",
                description: "A large dedicated database with 10GB storage quota, 512MB of RAM, and 100 connections"
              }]
            },
            {
              id:          '987654',
              name:        "service-4",
              description: "Yet another service, duh!",
              bindable:    true,
              dashboard_client: {
                id: 'client-1',
                secret: 'no-one-knows',
                redirect_uri: 'http://example.com/client-1'
              },
              plans:       []
            }
          ]
        })
      end

      it 'notifies the operator of the problem' do
        post('/v2/service_brokers', {
          name: 'some-guid',
          broker_url: 'http://broker-url',
          auth_username: 'username',
          auth_password: 'password'
        }.to_json, json_headers(admin_headers))

        expect(last_response.status).to eql(502)
        expect(decoded_response['code']).to eql(270012)
        expect(decoded_response['description']).to eql(
          "Service broker catalog is invalid: \n" +
          "Service ids must be unique\n" +
          "Service dashboard_client ids must be unique\n" +
          "Service service-1\n" +
          "  Service id must be a string, but has value 12345\n" +
          "Service service-2\n" +
          "  Plan ids must be unique\n" +
          "  Plan large\n" +
          "    Plan description is required\n" +
          "Service service-3\n" +
          "  Service dashboard client secret is required\n" +
          "  Service dashboard client redirect_uri is required\n" +
          "  Plan names must be unique within a service\n" +
          "  Plan tiny\n" +
          "    Plan id must be a string, but has value 123\n" +
          "Service service-4\n" +
          "  At least one plan is required\n"
        )
      end
    end
  end

  describe 'updating a service broker' do
    context 'when the dashboard_client values for a service have changed' do

      def build_service(attrs={})
        @index ||= 0
        @index += 1
        {
          id:          SecureRandom.uuid,
          name:        "service-#{@index}",
          description: "A service, duh!",
          bindable:    true,
          plans:       [{
            id:          "plan-#{@index}",
            name:        "plan-#{@index}",
            description: "A plan, duh!"
          }]
        }.merge(attrs)
      end

      before do
        service_1 = build_service(dashboard_client: {id: 'client-1', secret: 'shhhhh', redirect_uri: 'http://example.com/client-1'})
        service_2 = build_service(dashboard_client: {id: 'client-2', secret: 'sekret', redirect_uri: 'http://example.com/client-2'})
        service_3 = build_service(dashboard_client: {id: 'client-3', secret: 'unguessable', redirect_uri: 'http://example.com/client-3'})
        service_4 = build_service

        # set up a fake broker catalog that includes dashboard_client for services
        stub_catalog_fetch(200, services: [service_1, service_2, service_3, service_4])
        setup_uaa_stubs_to_add_new_client
        stub_request(:get, %r{http://localhost:8080/uaa/oauth/clients/.*}).to_return(status: 404)

        # add that broker to the CC
        post('/v2/service_brokers',
          {
            name: 'broker_name',
            broker_url: stubbed_broker_url,
            auth_username: stubbed_broker_username,
            auth_password: stubbed_broker_password
          }.to_json,
          json_headers(admin_headers)
        )
        expect(last_response).to have_status_code(201)
        @service_broker_guid = decoded_response.fetch('metadata').fetch('guid')

        service_1.delete(:dashboard_client)
        service_2[:dashboard_client][:id] = 'different-client'
        service_3[:dashboard_client][:secret] = 'SUPERsecret'
        service_4[:dashboard_client] = { id: 'client-4', secret: '1337', redirect_uri: 'http://example.com/client-4'}
        stub_catalog_fetch(200, services: [service_1, service_2, service_3, service_4])
      end

      it "updates the clients in UAA" do
        put("/v2/service_brokers/#{@service_broker_guid}", '{}', json_headers(admin_headers))
        expect(last_response).to have_status_code(200)

        expect(a_request(:delete, 'http://localhost:8080/uaa/oauth/clients/client-1')).to have_been_made

        expect(a_request(:delete, 'http://localhost:8080/uaa/oauth/clients/client-2')).to have_been_made
        expect(
          a_request(:post, 'http://localhost:8080/uaa/oauth/clients').with(
            body: hash_including('client_id' => 'different-client', 'client_secret' => 'sekret')
          )
        ).to have_been_made

        expect(
          a_request(:put, 'http://localhost:8080/uaa/oauth/clients/client-3').with(
            body: hash_including('client_id' => 'client-3', 'client_secret' => 'SUPERsecret')
          )
        ).to have_been_made

        expect(
          a_request(:post, 'http://localhost:8080/uaa/oauth/clients').with(
            body: hash_including('client_id' => 'client-4', 'client_secret' => '1337')
          )
        ).to have_been_made
      end
    end
  end
end
