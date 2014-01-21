CloudController::Application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # Unfortunetly currently classes have to be cached in development
  # because Rails/Sinatra/EM gets stuck on the second requests reloading them.
  config.cache_classes = true

  # Do not eager load code on boot.
  config.eager_load = false

  # Show full error reports and disable caching.
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log
end
