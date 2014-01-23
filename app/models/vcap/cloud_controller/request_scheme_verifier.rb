module VCAP::CloudController
  class RequestSchemeVerifier
    def initialize(config)
      @config = config
    end

    def verify(request, security_context)
      return if !security_context.current_user && !security_context.admin?

      if @config[:https_required] && request.scheme != "https"
        raise Errors::NotAuthorized
      end

      if security_context.admin?
        if @config[:https_required_for_admins] && request.scheme != "https"
          raise Errors::NotAuthorized
        end
      end
    end
  end
end
