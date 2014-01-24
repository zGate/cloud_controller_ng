module VCAP::CloudController::IdentityContext
  class IdentityContext
    attr_reader :user, :roles

    def initialize(user, token)
      @user = user
      @roles = VCAP::CloudController::Roles.new(token)
    end

    def admin?
      roles.admin?
    end
  end
end

