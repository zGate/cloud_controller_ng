require "cloud_controller/db"

Sequel.migration do
  up do
    if self.class.name.match /mysql/i
      tables.each do |table|
        columns = schema(table).map do |column| column[0] end
        if  columns.include? :created_at
          run("ALTER TABLE #{table} CHANGE created_at created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP;")
        end
      end
    end
  end
  
  down do
    if self.class.name.match /mysql/i
      tables.each do |table|
        columns = schema(table).map do |column| column[0] end
        if  columns.include? :created_at
          run("ALTER TABLE #{table} CHANGE created_at created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP;")
        end
      end
    end
  end
end

