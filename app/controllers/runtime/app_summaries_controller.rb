module VCAP::CloudController
  class AppSummariesController < ApiController
    before_filter { @config = Rails.application.cc_config }

    before_filter do
      SecurityContext.clear
      SecurityContext.set(*@token_to_user_finder.find(env["HTTP_AUTHORIZATION"]))
    end

    before_filter { @request_scheme_verifier.verify(request, SecurityContext) }

    rescue_from Exception do |exception|
      @response_exception_handler.handle(response, exception)
    end

    def summary
      app = find_guid_and_validate_access(:read, params[:guid])
      app_info = {
        guid: app.guid,
        name: app.name,
        routes: app.routes.map(&:as_summary_json),
        running_instances: app.running_instances,
        services: app.service_bindings.map { |service_binding| service_binding.service_instance.as_summary_json },
        available_domains: (app.space.organization.private_domains + SharedDomain.all).map(&:as_summary_json)
      }.merge(app.to_hash)
      render json: app_info
    end

    # from Base
    def user
      VCAP::CloudController::SecurityContext.current_user
    end

    # from Base
    def roles
      VCAP::CloudController::SecurityContext.roles
    end

    private

    def inject_dependencies(dependency_locator)
      @token_to_user_finder = dependency_locator.token_to_user_finder
      @request_scheme_verifier = dependency_locator.request_scheme_verifier
      @response_exception_handler = dependency_locator.response_exception_handler
      @logger = Steno.logger("cc.app-summaries-controller")
    end

    # from ModelController
    def find_guid_and_validate_access(op, guid, find_model = App)
      obj = find_model.find(guid: guid)
      raise self.class.not_found_exception.new(guid) if obj.nil?
      validate_access(op, obj, user, roles)
      obj
    end

    # from ModelController
    def validate_access(op, obj, user, roles)
      if cannot? op, obj
        raise Errors::NotAuthenticated if user.nil? && roles.none?
        @logger.info("allowy.access-denied", op: op, obj: obj, user: user, roles: roles)
        raise Errors::NotAuthorized
      end
    end
  end
end
