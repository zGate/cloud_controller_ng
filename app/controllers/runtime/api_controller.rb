module VCAP::CloudController
  class ApiController < ActionController::Base
    before_filter { inject_dependencies(::CloudController::DependencyLocator.instance) }
  end
end
