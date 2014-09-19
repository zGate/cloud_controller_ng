module VCAP::CloudController
  class ProcessTypeAccess < BaseAccess
    include Allowy::AccessControl

    def read?(object)
      true
    end
  end
end

