require "spec_helper"

module VCAP::CloudController
  describe VCAP::CloudController::ResourceMatchesController do
    include_context "resource pool"

    before do
      @resource_pool.add_directory(@tmpdir)
    end

    def resource_match_request(verb, path, matches, non_matches)
      user = User.make(:admin => true, :active => true)
      req = MultiJson.dump(matches + non_matches)
      send(verb, path, req, json_headers(headers_for(user)))
      expect(last_response.status).to eq(200)
      resp = MultiJson.load(last_response.body)
      expect(resp).to eq(matches)
    end

    describe "PUT /v2/resource_match" do
      it "should return an empty list when no resources match" do
        resource_match_request(:put, "/v2/resource_match", [], [@dummy_descriptor])
      end

      it "should return a resource that matches" do
        resource_match_request(:put, "/v2/resource_match", [@descriptors.first], [@dummy_descriptor])
      end

      it "should return many resources that match" do
        resource_match_request(:put, "/v2/resource_match", @descriptors, [@dummy_descriptor])
      end

      context "when app_bits_upload is disabled" do
        before { FeatureFlag.make(name: 'app_bits_upload', enabled: false).save }

        context "and the user is an admin" do
          it "should still allow resource match" do
            user = User.make(:admin => true, :active => true)
            send(:put, "/v2/resource_match", '{}', json_headers(headers_for(user)))
            expect(last_response.status).to eq(200)
          end
        end

        context "and the user is not an admin" do
          it "returns a 403" do
            user = User.make(:admin => false, :active => true)
            send(:put, "/v2/resource_match", '{}', json_headers(headers_for(user)))
            expect(last_response.status).to eq(403)
          end
        end
      end
    end
  end
end
