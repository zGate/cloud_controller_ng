require "repositories/services/service_usage_event_repository"

module VCAP::CloudController
  module Jobs
    module Runtime
      class UsageEventsCleanup < Struct.new(:cutoff_age_in_days)
        def perform
          logger = Steno.logger("cc.background")
          cleanup_events(logger, Repositories::Services::ServiceUsageEventRepository.new, "ServiceUsageEvent")
          cleanup_events(logger, Repositories::Runtime::AppUsageEventRepository.new, "AppUsageEvent")
        end

        def job_name_in_configuration
          :usage_events_cleanup
        end

        def max_attempts
          1
        end

        private

        def cleanup_events(logger, repository, event_name)
          logger.info("Cleaning up old #{event_name} rows")

          deleted_count = repository.delete_events_older_than(cutoff_age_in_days)

          logger.info("Cleaned up #{deleted_count} #{event_name} rows")
        end
      end
    end
  end
end
