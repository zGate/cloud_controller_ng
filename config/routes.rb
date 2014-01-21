CloudController::Application.routes.draw do
  get "rails", to: proc { |env| [200, {}, ['From Rails!']] }

  # controller and action are for rake routes and rails c
  match "(*path)", {
    to: Rails.application.sinatra_cc_app,
    via: [:get, :post, :delete, :put, :patch],
    controller: 'sinatra_cc',
    action: 'sinatra_cc',
  }
end
