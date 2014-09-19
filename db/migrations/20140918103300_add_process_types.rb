Sequel.migration do
  change do
    create_table :process_types do
      VCAP::Migration.common(self, :processtypes)

      String :name, :null => false
      Integer :instances, :default => 0
      Integer :app_id, :null => false
    end
  end
end
