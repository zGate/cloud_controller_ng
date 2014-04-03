module VCAP::CloudController
  class BaseAccess
    include Allowy::AccessControl

    def create?(object)
      return true if admin_user?
      return false unless has_write_scope?
    end

    def read?(object)
      return @ok_read if instance_variable_defined?(:@ok_read)
      return false unless has_read_scope?
      @ok_read = (admin_user? || object_is_visible_to_user?(object, context.user))
    end

    def update?(object)
      return true if admin_user?
      return false unless has_write_scope?
    end

    def delete?(object)
      return true if admin_user?
      return false unless has_write_scope?
    end

    def index?(object_class)
      true
    end

    def logged_in?
      !context.user.nil? || context.roles.present?
    end

    private

    def has_write_scope?
      VCAP::CloudController::SecurityContext.token['scopes'] =~ /cloud_controller\.write/
    end

    def has_read_scope?
      VCAP::CloudController::SecurityContext.token['scopes'] =~ /cloud_controller\.read/
    end

    def object_is_visible_to_user?(object, user)
      object.class.user_visible(user, false).where(:guid => object.guid).count > 0
    end

    def admin_user?
      return @admin_user if instance_variable_defined?(:@admin_user)
      @admin_user = context.roles.admin?
    end
  end
end
