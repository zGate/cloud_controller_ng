module VCAP::CloudController
  module Jobs
    module Runtime
      class PendingPackagesCleanup < Struct.new(:expiration)

        def perform
        end

        def job_name_in_configuration
          :pending_packages
        end

        def max_attempts
          1
        end
      end
    end
  end
end
