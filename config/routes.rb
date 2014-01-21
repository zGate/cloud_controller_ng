CloudController::Application.routes.draw do
  get "rails", :to => proc { |env| [200, {}, ['From Rails!']] }
  get '(*path)', :to => Rails.application.sinatra_cc_app
end
