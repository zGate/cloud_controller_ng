module VCAP::CloudController
  class FeatureFlag < Sequel::Model

    def self.some_method_that_we_can_test_in_isolation_and_not_have_to_test_everywhere_we_use_it(feature_flag_name)
      raise if Config.config[:feature_flag_defaults][feature_flag_name.to_sym].nil?
      feature_flag = FeatureFlag.find(name: feature_flag_name)
      return feature_flag.enabled if feature_flag
      Config.config[:feature_flag_defaults][feature_flag_name.to_sym]
    end

    export_attributes :name, :enabled
    import_attributes :name, :enabled

    def validate
      validates_presence :name
      validates_unique :name
      validates_presence :enabled

      validates_includes Config.config[:feature_flag_defaults].keys.map{|k| k.to_s}, :name
    end
  end
end
