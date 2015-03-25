Sequel.migration do
  change do
    # alter_table(:packages) do
    #   # add_index :app_guid
    #   add_foreign_key [:app_guid], :apps_v3, key: :guid
    # end
    # alter_table(:apps) do
    #   add_index :app_guid
    #   add_foreign_key [:app_guid], :apps_v3, key: :guid
    # end
    alter_table(:v3_droplets) do
      drop_column :app_guid
      add_column :app_guid, String, null: false
      # add_index :app_guid
      add_foreign_key([:app_guid], :apps_v3, key: :guid, on_delete: :restrict, name: 'potato')
    end
  end
end
