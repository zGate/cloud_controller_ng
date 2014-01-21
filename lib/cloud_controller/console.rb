module VCAP::CloudController
  class Console < Rails::Railtie
    console do
      @config_file = File.expand_path("../../../config/cloud_controller.yml", __FILE__)
      unless File.exists?(@config_file)
        warn "#{@config_file} not found. Try running bin/console <PATH_TO_CONFIG_FILE>."
        exit 1
      end

      @config = VCAP::CloudController::Config.from_file(@config_file)
      logger = Logger.new(STDOUT)
      db_config = @config.fetch(:db).merge(log_level: :debug)

      VCAP::CloudController::DB.load_models(db_config, logger)
      VCAP::CloudController::Config.configure_components(@config)

      if Rails.env.development?
        $:.unshift(File.expand_path("../../../spec/support", __FILE__))
        require "machinist/sequel"
        require "machinist/object"
        require "fakes/blueprints"
      end
    end
  end
end
