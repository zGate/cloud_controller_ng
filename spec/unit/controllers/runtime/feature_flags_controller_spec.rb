require "spec_helper"

module VCAP::CloudController
  describe FeatureFlagsController, type: :controller do
    it_behaves_like "an admin only endpoint", path: "/v2/config/feature_flags"

    describe "setting a feature flag" do
      context "when the user is an admin" do
        context "and the flag is in the default feature flags" do
          before do
            TestConfig.config[:feature_flag_defaults] = {
              user_org_creation: false
            }
          end

          it "should set the feature flag to the specified value" do
            put "/v2/config/feature_flags/user_org_creation", MultiJson.dump({enabled: true}), admin_headers
            expect(last_response.status).to eq(200)
            expect(decoded_response["entity"]["name"]).to eq("user_org_creation")
            expect(decoded_response["entity"]["enabled"]).to be true
          end
        end

        context "and the flag is not a default feature flag" do
          it "should return a 404 when the feature flag does not exist" do
            put "/v2/config/feature_flags/bogus", {}, admin_headers
            expect(last_response.status).to eq(404)
            expect(decoded_response['description']).to match(/feature flag could not be found/)
            expect(decoded_response['error_code']).to match(/FeatureFlagNotFound/)
          end
        end
      end

      context "when the user is not an admin" do
        it "should return a 403" do
          feature_flag = FeatureFlag.make(enabled: false, name: "foobar")
          put "/v2/config/feature_flags/#{feature_flag.name}", MultiJson.dump({enabled: true}), headers_for(User.make)

          expect(last_response.status).to eq(403)
          expect(decoded_response['description']).to match(/not authorized/)
          expect(decoded_response['error_code']).to match(/NotAuthorized/)
        end
      end
    end

    describe "get /v2/config/feature_flags" do
      before do
        TestConfig.config[:feature_flag_defaults] = {
          flag_one: false,
          flag_two: true,
          flag_three: false,
        }
      end
      context "when there are no overrides" do
        it "returns all the things" do
          FeatureFlag.make(name: "foobar")
          get "/v2/config/feature_flags", {}, admin_headers

          expect(last_response.status).to eq(200)
          expect(decoded_response.length).to eq(3)
          expect(decoded_response["flag_one"]).to eq(false)
          expect(decoded_response["flag_two"]).to eq(true)
          expect(decoded_response["flag_three"]).to eq(false)
        end
      end

      context "when there are overrides" do
        it "returns the defaults, overidden where needed" do
          FeatureFlag.make(name: "flag_two", enabled: false)

          get "/v2/config/feature_flags", {}, admin_headers
          puts last_response.body
          expect(last_response.status).to eq(200)
          expect(decoded_response.length).to eq(3)
          expect(decoded_response["flag_one"]).to eq(false)
          expect(decoded_response["flag_two"]).to eq(false)
          expect(decoded_response["flag_three"]).to eq(false)
        end
      end
    end
  end
end
