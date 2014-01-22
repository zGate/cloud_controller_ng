require "spec_helper"
require "tempfile"
require "thread"

describe "Cloud controller", type: :integration, monitoring: true do
  context "when configured to use development mode" do
    port = 8181
    fixture_cc_config_path = "spec/fixtures/config/port_8181_config.yml"
    fixture_newrelic_config_path = "spec/fixtures/config/newrelic.yml"

    before do
      start_nats(debug: false)
      start_cc(
        debug: true,
        config: fixture_cc_config_path,
        env: {
          "NRCONFIG" => newrelic_config_file.path,
          "RACK_ENV" => "development",
        }
      )
    end

    after do
      stop_cc
      stop_nats
      newrelic_config_file.unlink
    end

    context "when developer mode is enabled" do
      let(:newrelic_config_file) do
        newrelic_config = YAML.load_file(fixture_newrelic_config_path)
        newrelic_config['development']['developer_mode'] = true
        file = Tempfile.new("newrelic.yml")
        file.write(YAML.dump(newrelic_config))
        file.close
        file
      end

      it "reports the transaction information in /newrelic about Rails and Sinatra endpoints" do
        info_response = make_get_request("/info", {}, port)
        expect(info_response.code).to eq("200")

        rails_response = make_get_request("/rails", {}, port)
        expect(rails_response.code).to eq("200")

        newrelic_response = make_get_request("/newrelic", {}, port)
        expect(newrelic_response.code).to eq("200")
        expect(newrelic_response.body).to include("/info")
        expect(newrelic_response.body).to include("/rails")
      end
    end

    context "when developer mode is not enabled" do
      let(:newrelic_config_file) do
        newrelic_config = YAML.load_file(fixture_newrelic_config_path)
        newrelic_config['development']['developer_mode'] = false
        file = Tempfile.new("newrelic.yml")
        file.write(YAML.dump(newrelic_config))
        file.close
        file
      end

      it "does not report transaction infromation in /newrelic" do
        newrelic_response = make_get_request("/newrelic", {}, port)
        expect(newrelic_response.code).to eq("404")
      end
    end
  end
end

