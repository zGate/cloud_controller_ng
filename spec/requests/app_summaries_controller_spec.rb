require "spec_helper"

module VCAP::CloudController
  describe AppSummariesController do
    describe "GET /v2/apps/:id/summary" do
      let(:locator) { CloudController::DependencyLocator.instance }
      let(:app1) { App.make }

      describe "user from token" do
        it "security context is set to user obtained from the token" do
          token_to_user_finder = instance_double("VCAP::CloudController::TokenToUserFinder")
          locator.stub(:token_to_user_finder).with(no_args).and_return(token_to_user_finder)

          user = instance_double("VCAP::CloudController::User")
          token = double('token')
          expect(token_to_user_finder).to receive(:find).
            with("fake-token").
            and_return([user, token])

          expect(SecurityContext).to receive(:set).with(user, token)
          get "/v2/apps/#{app1.guid}/summary", {}, admin_headers.merge("HTTP_AUTHORIZATION" => "fake-token") rescue nil
        end
      end

      describe "request sheme verification" do
        it "handles the invalid request scheme" do
          request_scheme_verifier = instance_double("VCAP::CloudController::RequestSchemeVerifier")
          locator.stub(:request_scheme_verifier).with(no_args).and_return(request_scheme_verifier)

          exception = Exception.new
          request_scheme_verifier.should_receive(:verify).
            with(kind_of(Rack::Request), kind_of(IdentityContext)).
            and_raise(exception)

          response_exception_handler = instance_double("VCAP::CloudController::ResponseExceptionHandler")
          locator.stub(:response_exception_handler).with(no_args).and_return(response_exception_handler)

          response_exception_handler.should_receive(:handle).
            with(kind_of(ActionDispatch::Response), exception)

          get "/v2/apps/#{app1.guid}/summary", {}, admin_headers
        end
      end

      context "when app does not exist" do
        it "returns 404" do
          get "/v2/apps/fake-not-found-guid/summary", {}, admin_headers
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
        before { locator.stub(:authorization_provider).with(no_args).and_return(test_auth_provider) }
        let(:test_auth_provider) { Authorization::SingleOpProvider.new }

        context "when can access the app" do
          before { test_auth_provider.allow_access(:read, app1) }

          it "present full object" do
            get "/v2/apps/#{app1.guid}/summary", {}, admin_headers
            expect(last_response.status).to eq(200)
            expect(decoded_response["guid"]).to eq(app1.guid)
          end
        end

        context "when cannot access the app" do
          it "has an error response" do
            get "/v2/apps/#{app1.guid}/summary", {}, admin_headers
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
