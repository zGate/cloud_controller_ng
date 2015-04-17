Sequel.migration do
  change do
    add_column :apps_v3, :diego, TrueClass, default: false
  end
end
