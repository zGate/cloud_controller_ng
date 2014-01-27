module VCAP::CloudController::IdentityContext
  class IdentityContext
    attr_reader :user, :roles

    def initialize(user, token)
      @user = user
      @token = token
      @roles = VCAP::CloudController::Roles.new(token)
    end

    def admin?
      roles.admin?
    end

    def require_identity!
      # The logic here is a bit oddly ordered, but it supports the
      # legacy calls setting a user, but not providing a token.
      return if user
      return if admin?

      if @token
        # Ideally this should be NotAuthenticated instead of NotAuthorized
        # since from current point of view we do not know who the token belongs.
        # We need to keep this NotAuthorized to be compatible with v2 api.
        raise VCAP::Errors::NotAuthorized
      else
        raise VCAP::Errors::InvalidAuthToken
      end
    end
  end
end
