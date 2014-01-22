module VCAP::CloudController
  class AppSummariesController < ActionController::Base
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
        logger.info("allowy.access-denied", op: op, obj: obj, user: user, roles: roles)
        raise Errors::NotAuthorized
      end
    end

    before_filter do
      @config = Rails.application.cc_config
      @token_decoder = Rails.application.cc_token_decoder
    end

    before_filter do
      VCAP::CloudController::SecurityContext.clear
      auth_token = env["HTTP_AUTHORIZATION"]

      token_information = decode_token(auth_token)

      if token_information
        token_information['user_id'] ||= token_information['client_id']
        uaa_id = token_information['user_id']
      end

      if uaa_id
        user = User.find(:guid => uaa_id.to_s)
        user ||= User.create(guid: token_information['user_id'], admin: current_user_admin?(token_information), active: true)
      end

      VCAP::CloudController::SecurityContext.set(user, token_information)

      validate_scheme(user, VCAP::CloudController::SecurityContext.admin?)
    end

    def decode_token(auth_token)
      token_information = @token_decoder.decode_token(auth_token)
      logger.info("Token received from the UAA #{token_information.inspect}")
      token_information
    rescue CF::UAA::TokenExpired
      logger.info('Token expired')
    rescue CF::UAA::DecodeError, CF::UAA::AuthError => e
      logger.warn("Invalid bearer token: #{e.inspect} #{e.backtrace}")
    end

    def validate_scheme(user, admin)
      return unless user || admin

      if @config[:https_required]
        raise Errors::NotAuthorized unless request.scheme == "https"
      end

      if @config[:https_required_for_admins] && admin
        raise Errors::NotAuthorized unless request.scheme == "https"
      end
    end

    def current_user_admin?(token_information)
      if User.count.zero?
        admin_email = config[:bootstrap_admin_email]
        admin_email && (admin_email == token_information['email'])
      else
        VCAP::CloudController::Roles.new(token_information).admin?
      end
    end
  end
end
