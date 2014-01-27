module VCAP::CloudController::IdentityContext
  class PresetIdentityContext
    attr_reader :user, :roles

    def initialize
      @user = user
      @roles = VCAP::CloudController::Roles.new(nil)
    end

    def admin?
      false
    end

    def remove_identity
      @remove_identity = true
    end

    def require_identity!
      raise VCAP::Errors::NotAuthorized if @remove_identity
    end
  end
end
