module VCAP
  module CloudController
    class ProcessFactory
      def self.make(attributes={})
        app_guid = attributes[:app_guid] || AppModel.make.guid
        process = AppFactory.make(attributes.merge(app_guid: app_guid))
        ProcessMapper.map_model_to_domain(process)
      end
    end
  end
end
