Sequel.migration do
  up do
    create_table :droplets do
      VCAP::Migration.common(self)

      Integer :app_id, :null => false
      String :droplet_hash, :null => false
      index :app_id

      foreign_key [:app_id], :apps, :name => :fk_droplets_app_id
    end

  end

  down do
    drop_table :droplets
  end
end
