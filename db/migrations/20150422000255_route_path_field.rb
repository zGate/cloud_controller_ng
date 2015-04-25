Sequel.migration do
  change do
    alter_table :routes do
      add_column :path, 'varchar(512)', default: nil
      drop_index [:host, :domain_id]
      add_index [:host, :domain_id, :path], unique: true
    end
  end
end
