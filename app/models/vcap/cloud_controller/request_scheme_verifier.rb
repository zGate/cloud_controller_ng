module VCAP::CloudController
  class RequestSchemeVerifier
    def initialize(config)
      @config = config
    end

    def verify(request, identity_context)
      return if !identity_context.user && !identity_context.admin?

      if @config[:https_required] && request.scheme != "https"
        raise Errors::NotAuthorized
      end

      if identity_context.admin?
        if @config[:https_required_for_admins] && request.scheme != "https"
          raise Errors::NotAuthorized
        end
      end
    end
  end
end
