CloudController::Application.routes.draw do
  get "rails", to: "rails#index"

  get "/v2/apps/:guid/summary", to: "vcap/cloud_controller/app_summaries#summary"

  if app = Rails.application.sinatra_cc_app
    match "(*path)", to: app, via: :all
  end
end
