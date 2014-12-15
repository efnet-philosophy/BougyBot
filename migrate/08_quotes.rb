require 'sequel_postgresql_triggers'
require 'pg_array'
Sequel.migration do
  change do
    create_table(:quotes) do
      primary_key :id
      String :quote
      String :author
      column :tags, 'text[]'
      DateTime :at
      DateTime :last
      index :author
    end
    pgt_created_at :quotes, :at
    pgt_updated_at :quotes, :last
  end
end
