module VCAP::CloudController
  class ApiController < ActionController::Base
    before_filter { inject_dependencies(::CloudController::DependencyLocator.instance) }

    before_filter do
      SecurityContext.clear
      SecurityContext.set(*@token_to_user_finder.find(env["HTTP_AUTHORIZATION"]))
    end

    before_filter { @request_scheme_verifier.verify(request, SecurityContext) }

    rescue_from Exception do |exception|
      @response_exception_handler.handle(response, exception)
    end

    attr_reader :authorization
    before_filter { @authorization = @authorization_provider.for_security_context(SecurityContext) }

    private

    def inject_dependencies(dependency_locator)
      @token_to_user_finder = dependency_locator.token_to_user_finder
      @request_scheme_verifier = dependency_locator.request_scheme_verifier
      @response_exception_handler = dependency_locator.response_exception_handler
      @authorization_provider = dependency_locator.authorization_provider
    end
  end
end
