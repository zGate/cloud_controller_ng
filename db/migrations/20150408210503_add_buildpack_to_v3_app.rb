Sequel.migration do
  change do
    alter_table(:apps_v3) do
      add_column :buildpack, String, text: true
    end
  end
end
