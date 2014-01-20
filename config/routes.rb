CloudController::Application.routes.draw do
  get '(*path)', :to => VCAP::CloudController::Runner.new([]).rack_app
end
