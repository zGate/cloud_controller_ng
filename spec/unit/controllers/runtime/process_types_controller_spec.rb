require "spec_helper"

module VCAP::CloudController
  describe VCAP::CloudController::ProcessTypesController do
    describe "Associations" do
      it do
        expect(described_class).to have_nested_routes({
          app: [:get]
        })
      end
    end

    context "when the number of instances is updated on the overall app object" do
      it "reflects the overall app instances in the 'web' process type" do
        process_type = ProcessType.make
        app = process_type.app
        app.instances = 3
        app.save

        get "/v2/process_types/#{ProcessType.first.guid}", {}, json_headers(admin_headers)
        expect(decoded_entity).to include({ "instances" => 3 })
      end

      it "does not affect the non-web process types" do
        process_type = ProcessType.make(name: 'worker')
        app = process_type.app
        app.instances = 3
        app.save

        get "/v2/process_types/#{ProcessType.first.guid}", {}, json_headers(admin_headers)
        expect(decoded_entity).to include({ "instances" => 0 })
      end
    end

    context "when the number of instances is updated on the process type" do
      it "updates the containing app when the process type is web" do
        process_type = ProcessType.make(name: 'web')
        app = process_type.app
        process_type.instances = 3
        app.save

        get "/v2/apps/#{app.guid}", {}, json_headers(admin_headers)
        expect(decoded_entity).to include({ "instances" => 3 })
      end

      it "does not update the containing app when the process type is not web" do
        process_type = ProcessType.make(name: 'worker')
        app = process_type.app
        process_type.instances = 3
        app.save

        get "/v2/apps/#{app.guid}", {}, json_headers(admin_headers)
        expect(decoded_entity).to include({ "instances" => 1 })
      end
    end

    let(:decoded_entity) { MultiJson.load(last_response.body)["entity"] }
  end

end
