module VCAP::CloudController
  class FeatureFlagsController < RestController::ModelController
    def self.path
      "#{ROUTE_PREFIX}/config/feature_flags"
    end

    def self.translate_validation_exception(e, attributes)
      Errors::ApiError.new_from_details("FeatureFlagInvalid", e.errors.full_messages)
    end

    get path, :enumerate
    def enumerate
      raise Errors::ApiError.new_from_details("NotAuthorized") unless roles.admin?
      feature_flags = {}
      FeatureFlag.all.each { |feature| feature_flags[feature.name.to_sym] = feature.enabled }
      [
        HTTP::OK,
        MultiJson.dump(Config.config[:feature_flag_defaults].merge(feature_flags))
      ]
    end

    put "#{path}/:name", :update_feature_flag
    def update_feature_flag(name)
      raise Errors::ApiError.new_from_details("NotAuthorized") unless roles.admin?

      raise self.class.not_found_exception(name) if Config.config[:feature_flag_defaults][name.to_sym].nil?

      feature_flag_attributes = MultiJson.load(body)
      feature_flag = FeatureFlag.find_or_create(name: name){ |f| f.enabled = feature_flag_attributes["enabled"] }
      [
        HTTP::OK,
        object_renderer.render_json(self.class, feature_flag, @opts)
      ]
    end
  end
end
