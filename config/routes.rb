CloudController::Application.routes.draw do
  get "rails", to: "rails#index"

  if app = Rails.application.sinatra_cc_app
    match "(*path)", to: app, via: :all
  end
end
