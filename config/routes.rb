CloudController::Application.routes.draw do
  get   "rails",   to: proc { |env| [200, {}, ['From Rails!']] }
  match "(*path)", to: Rails.application.sinatra_cc_app, via: [:get, :post, :delete, :put, :patch]
end
