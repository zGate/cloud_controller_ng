Sequel.migration do
  up do
    alter_table :packages do
      drop_column :space_guid
      add_column :app_guid, String
    end
  end
  down do
    alter_table :packages do
      add_column :space_guid, String
      drop_column :app_guid
    end
  end
end
