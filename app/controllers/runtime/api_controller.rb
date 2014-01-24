require "models/vcap/cloud_controller/identity_context"

module VCAP::CloudController
  class ApiController < ActionController::Base
    before_filter { inject_dependencies(::CloudController::DependencyLocator.instance) }

    rescue_from Exception do |exception|
      @response_exception_handler.handle(response, exception)
    end

    # Make sure security context is cleared first
    # since it's still used by Sinatra CC app.
    before_filter { SecurityContext.clear }

    attr_reader :identity_context
    before_filter { @identity_context = @identity_context_provider.for_auth_header(env["HTTP_AUTHORIZATION"]) }

    before_filter { @request_scheme_verifier.verify(request, identity_context) }

    attr_reader :authorization
    before_filter { @authorization = @authorization_provider.for_identity_context(identity_context) }

    private

    def inject_dependencies(dependency_locator)
      @identity_context_provider = dependency_locator.identity_context_provider
      @request_scheme_verifier = dependency_locator.request_scheme_verifier
      @response_exception_handler = dependency_locator.response_exception_handler
      @authorization_provider = dependency_locator.authorization_provider
    end
  end
end
