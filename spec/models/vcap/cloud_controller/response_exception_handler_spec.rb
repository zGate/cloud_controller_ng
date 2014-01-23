require "spec_helper"

describe VCAP::CloudController::ResponseExceptionHandler do
  describe "#handler" do
    subject { described_class.new(logger) }
    let(:logger) { Logger.new("/dev/null") }

    let(:response) { Rack::Response.new }
    let(:exception) { Exception.new }

    context "when exception does not have error_code" do
      it "re-raises an exception" do
        expect {
          subject.handle(response, exception)
        }.to raise_error(exception)
      end
    end

    context "when exception has error_code" do
      before { exception.stub(:error_code).and_return(555) }

      def self.it_sets_http_status(expected_status)
        it "set HTTP response status to #{expected_status}" do
          subject.handle(response, exception)
          expect(response.status).to eq(expected_status)
        end
      end

      def self.it_sets_http_body(expected_body)
        it "set HTTP response body to error payload" do
          subject.handle(response, exception)
          expect(response.body).to eq(expected_body)
        end
      end

      def self.it_logs(level)
        it "logs exception at #{level} level" do
          logger.should_receive(level).with(/Request failed:/)
          subject.handle(response, exception)
        end
      end

      context "when exception has response_code within 400..499" do
        before { exception.stub(:response_code).and_return(499) }
        it_sets_http_status 499
        it_sets_http_body %|{"code":555,"description":"Exception","error_code":"CF-Exception","types":[],"backtrace":null}\n|
        it_logs :info
      end

      context "when exception does not response_code" do
        before { exception.stub(:response_code).and_return(999) }
        it_sets_http_status 999
        it_sets_http_body %|{"code":555,"description":"Exception","error_code":"CF-Exception","types":[],"backtrace":null}\n|
        it_logs :error
      end
    end
  end
end
