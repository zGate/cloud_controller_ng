module VCAP::CloudController
  class ProcessTypesController < RestController::ModelController
    define_attributes do
      attribute :instances, Integer
    end

    define_messages
    define_routes
  end
end
