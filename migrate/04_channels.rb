require 'sequel_postgresql_triggers'
Sequel.migration do
  change do
    create_table(:channels) do
      primary_key :id
      DateTime :at
      String :name
    end
    pgt_created_at :channels, :at
  end
end
