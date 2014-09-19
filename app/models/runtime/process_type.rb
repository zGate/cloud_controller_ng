module VCAP::CloudController
  class ProcessType < Sequel::Model
    many_to_one :app

    import_attributes :instances
    export_attributes :instances, :name, :app

    alias_method :process_type_instances, :instances
    def instances
      return app.instances if name == 'web'
      return process_type_instances
    end

    alias_method :process_type_instances=, :instances=
    def instances=(i)
      if name == 'web'
        app.instances=(i)
      else
        self.process_type_instances = i
      end
    end

    def after_commit
      super
    end
  end
end
