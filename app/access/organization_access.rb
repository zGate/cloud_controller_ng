module VCAP::CloudController
  class OrganizationAccess < BaseAccess
    def update?(org)
      return super unless super.nil?
      org.managers.include?(context.user) && org.active?
    end
  end
end
