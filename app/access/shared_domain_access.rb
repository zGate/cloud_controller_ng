module VCAP::CloudController
  class SharedDomainAccess < BaseAccess
    def read?(_)
      has_read_scope? && logged_in?
    end
  end
end
