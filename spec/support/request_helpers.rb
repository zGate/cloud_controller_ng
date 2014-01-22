module RequestHelpers
  def app
    Rails.application.tap do |app|
      app.cc_config = config
      app.reset_sinatra_cc_app
    end
  end
end
