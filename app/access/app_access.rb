module VCAP::CloudController
  class AppAccess < BaseAccess
    def create?(app)
      return true if admin_user?
      return false if app.in_suspended_org?
      app.space.developers.include?(context.user)
    end

    def update?(app)
      create?(app)
    end

    def delete?(app)
      create?(app)
    end

    def upload?(app)
      return true if admin_user?
      return false unless FeatureFlag.enabled? 'app_bits_upload'
      update?(app)
    end

    def upload_with_token?(app)
      update_with_token?(app)
    end

    def read_env?(app)
     return true if admin_user?
     app.space.developers.include?(context.user)
    end

    def read_env_with_token?(app)
      read_with_token?(app)
    end
  end
end
