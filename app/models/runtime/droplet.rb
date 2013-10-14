module VCAP::CloudController
  class Droplet < Sequel::Model
    many_to_one :app

    export_attributes :app_guid, :droplet_hash
    import_attributes :app_guid, :droplet_hash

    def validate
      validates_presence :app
      validates_presence :droplet_hash
    end
  end
end