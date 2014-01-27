require "spec_helper"

module VCAP::CloudController
  describe AppSummariesController do
    describe "GET /v2/apps/:id/summary" do
      with_dependency_locator
      with_preset_identity_context

      let(:app1) { App.make }

      describe "Sinatra CC app security context" do
        it "clears security context set by sinatra requests" do
          SecurityContext.should_receive(:clear).with(no_args)
          get "/v2/apps/#{app1.guid}/summary", {}, preset_headers
        end
      end

      describe "request sheme verification" do
        it "handles the invalid request scheme" do
          request_scheme_verifier = instance_double("VCAP::CloudController::RequestSchemeVerifier")
          dependency_locator.stub(:request_scheme_verifier).with(no_args).and_return(request_scheme_verifier)

          exception = Exception.new
          request_scheme_verifier.should_receive(:verify).
            with(kind_of(Rack::Request), preset_identity_context).
            and_raise(exception)

          response_exception_handler = instance_double("VCAP::CloudController::ResponseExceptionHandler")
          dependency_locator.stub(:response_exception_handler).with(no_args).and_return(response_exception_handler)

          response_exception_handler.should_receive(:handle).
            with(kind_of(ActionDispatch::Response), exception)

          get "/v2/apps/#{app1.guid}/summary", {}, preset_headers
        end
      end

      describe "authentication" do
        before { preset_identity_context.remove_identity }

        it "requires that requester has identity (option A)" do
          error = Exception.new
          preset_identity_context.
            should_receive(:require_identity!).
            with(no_args).
            and_raise(error)

          response_exception_handler = instance_double("VCAP::CloudController::ResponseExceptionHandler")
          dependency_locator.
            stub(:response_exception_handler).
            with(no_args).
            and_return(response_exception_handler)

          response_exception_handler.should_receive(:handle).
            with(kind_of(ActionDispatch::Response), error)

          get "/v2/apps/#{app1.guid}/summary", {}, preset_headers
        end

        it "requires that requester has identity (option B)" do
          preset_identity_context.
            should_receive(:require_identity!).
            with(no_args).
            and_raise(TestAuthError)

          get "/v2/apps/#{app1.guid}/summary", {}, preset_headers
          expect(last_response).to be_an_api_error(
            code: 99999,
            response_code: 999,
            description: "Preset identity context requires identity",
            error_code: "CF-TestAuthError",
            types: ["TestAuthError"],
          )
        end

        class TestAuthError < Exception
          def error_code;    99999; end
          def response_code; 999; end
          def message;       "Preset identity context requires identity"; end
        end
      end

      context "when app does not exist" do
        it "returns 404" do
          get "/v2/apps/fake-not-found-guid/summary", {}, preset_headers
          expect(last_response).to be_an_api_error(
            code: 100004,
            response_code: 404,
            description: "The app name could not be found: fake-not-found-guid",
            error_code: "CF-AppNotFound",
            types: ["AppNotFound", "Error"],
          )
        end
      end

      context "when app exists" do
        with_single_op_authorization

        context "when can access the app" do
          before { single_op_authorization.allow_access(:read, app1) }

          it "presents full object" do
            get "/v2/apps/#{app1.guid}/summary", {}, preset_headers
            expect(last_response.status).to eq(200)
            expect(decoded_response["guid"]).to eq(app1.guid)
          end
        end

        context "when cannot access the app" do
          it "has an error response" do
            get "/v2/apps/#{app1.guid}/summary", {}, preset_headers
            expect(last_response).to be_an_api_error(
              code: 10003,
              response_code: 403,
              description: "You are not authorized to perform the requested action",
              error_code: "CF-NotAuthorized",
              types: ["NotAuthorized", "Error"],
            )
          end
        end
      end
    end
  end
end
