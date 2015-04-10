Sequel.migration do
  change do
    add_column :apps_v3, :procfile, String, text: true
  end
end
