require "spec_helper"
require "rspec_api_documentation/dsl"

resource "Feature Flags (experimental)", :type => :api do
  let(:admin_auth_header) { admin_headers["HTTP_AUTHORIZATION"] }

  authenticated_request

  supported_flags = { 'user_org_creation' => false, 'app_bits_upload' => true }

  shared_context "name_parameter" do
    parameter :name, "The name of the Feature Flag", valid_values: supported_flags.keys
  end

  shared_context "updatable_fields" do
    field :enabled, "The state of the feature flag.", required: true, valid_values: [true, false]
  end

  get "/v2/config/feature_flags" do
    example "Get all feature flags" do
      client.get "/v2/config/feature_flags", {}, headers

      expect(status).to eq(200)
      expect(parsed_response.length).to eq(supported_flags.length)
      supported_flags.each do |name, enabled|
        expect(parsed_response).to include(
          {
            'name'          => name,
            'default_value' => enabled,
            'enabled'       => enabled,
            'url'           => "/v2/config/feature_flags/#{name}"
          })
      end
    end
  end

  get "/v2/config/feature_flags/:name" do
    include_context "name_parameter"

    example "Get a feature flag" do
      client.get "/v2/config/feature_flags/user_org_creation", {}, headers

      expect(status).to eq(200)
      expect(parsed_response).to eq(
        {
          'name'          => 'user_org_creation',
          'default_value' => false,
          'enabled'       => false,
          'url'           => '/v2/config/feature_flags/user_org_creation'
        })
    end
  end

  describe "Specific Feature Flags" do
    describe "Enabling User Organization Creation" do
      include_context "updatable_fields"

      put "/v2/config/feature_flags/user_org_creation" do
        example "Allow users to create organizations" do
          client.put "/v2/config/feature_flags/user_org_creation", fields_json, headers

          expect(status).to eq(200)
          expect(parsed_response).to eq(
            {
              'name'          => 'user_org_creation',
              'default_value' => false,
              'enabled'       => true,
              'url'           => '/v2/config/feature_flags/user_org_creation'
            })
        end
      end
    end

    describe "Disable App Bits Upload" do
      include_context "updatable_fields"

      put "/v2/config/feature_flags/app_bits_upload" do
        example "Disable app bits uploading" do
          client.put "/v2/config/feature_flags/app_bits_upload", fields_json(enabled: false), headers

          expect(status).to eq(200)
          expect(parsed_response).to eq(
            {
              'name'          => 'app_bits_upload',
              'default_value' => true,
              'enabled'       => false,
              'url'           => '/v2/config/feature_flags/app_bits_upload'
            })
        end
      end
    end
  end
end
