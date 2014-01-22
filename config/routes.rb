CloudController::Application.routes.draw do
  get "rails", to: "rails#index"

  unless app = Rails.application.sinatra_cc_app
    raise ArgumentError, "sinatra_cc_app must not be nil"
  end

  # controller and action are for rake routes and rails c
  match "(*path)", {
    to: app,
    via: :all,
    controller: 'sinatra_cc',
    action: 'sinatra_cc',
  }
end
