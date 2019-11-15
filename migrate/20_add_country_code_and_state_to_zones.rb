require 'sequel_postgresql_triggers'
Sequel.migration do
  change do
    alter_table(:zones) do
      add_column :principality, String
      add_column :country_code, String
      add_column :region, String
      add_column :region_code, String
      add_column :zip, String
    end
  end
end

