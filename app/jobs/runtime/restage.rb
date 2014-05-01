module VCAP::CloudController
  module Jobs
    module Runtime
      class Restage < Struct.new(:app_guid)
        def perform
          app = App.find(app_guid)
          app.stop!
          app.mark_for_restaging
          app.start!
        end

        def job_name_in_configuration
          :restage
        end

        def max_attempts
          1
        end
      end
    end
  end
end
