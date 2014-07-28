module VCAP::CloudController
  class OrganizationAccess < BaseAccess
    def create?(org)
      return true if admin_user?
      FeatureFlag.some_method_that_we_can_test_in_isolation_and_not_have_to_test_everywhere_we_use_it("user_org_creation")
    end

    def update?(org)
      return true if admin_user?
      org.managers.include?(context.user) && org.active?
    end
  end
end
