Sequel.migration do
  change do
    add_column :apps, :package_pending_since, :timestamp, :null => true
    add_index :apps, :package_pending_since
  end
end
