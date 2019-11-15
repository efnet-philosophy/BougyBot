require 'sequel_postgresql_triggers'
Sequel.migration do
  change do
    create_table(:zones) do
      primary_key :id
      DateTime :at
      DateTime :updated
      String :name, null: false
      String :city, null: false
      String :country, null: false
      String :aircode
      String :weather_code
      Float :longitude
      Float :latitude
    end
    pgt_created_at :zones, :at
    pgt_updated_at :zones, :updated
    add_index :zones, :name
    add_index :zones, :aircode
    add_index :zones, :city
  end
end

