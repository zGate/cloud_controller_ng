require 'services/api'

module VCAP::CloudController
  class ManagedServiceInstance < RestController::ModelController
    allow_unauthenticated_access

    define_attributes do
      to_one :service_plan
      to_one :space
      to_many :service_bindings
    end

    def read(guid)
      redirect "v2/service_instances/#{guid}"
    end

    get '/v2/managed_service_instances/:guid', :read
  end
end
