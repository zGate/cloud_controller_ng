Sequel.migration do
  up do
    add_index :events, [:space_guid], name: :
    add_index :events, [:organization_guid], name: :delayed_jobs_reserve
  end

  down do
    drop_index :events, [:queue, :locked_at, :locked_by, :failed_at, :run_at], name: :delayed_jobs_reserve
    add_index :events, [:queue, :locked_at, :failed_at, :run_at], name: :delayed_jobs_reserve
  end
end
