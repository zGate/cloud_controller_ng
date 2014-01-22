require File.expand_path('../boot', __FILE__)

require "action_controller/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(:default, Rails.env)

module CloudController
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.

    # Set by runner when Rails.application instance is loaded
    attr_accessor :cc_config

    def cc_token_decoder
      return unless cc_config
      @token_decoder ||= VCAP::UaaTokenDecoder.new(cc_config[:uaa])
    end

    def sinatra_cc_app
      return unless cc_config
      @sinatra_cc_app ||= build_sinatra_cc_app
    end

    def reset_sinatra_cc_app
      @token_decoder = nil
      @sinatra_cc_app = nil
    end

    private

    def build_sinatra_cc_app
      cont_cc_config = cc_config.dup
      cont_cc_token_decoder = cc_token_decoder
      Rack::Builder.new do
        use Rack::CommonLogger
        map("/") { run VCAP::CloudController::Controller.new(cont_cc_config, cont_cc_token_decoder) }
      end
    end
  end
end

$:.unshift(File.expand_path("../../lib", __FILE__))
require "cloud_controller/console"

$:.unshift(File.expand_path("../../app", __FILE__))
require "cloud_controller"

# Bypass activesupport autoloader since all classes are not properly namespaced.
Vcap = VCAP
