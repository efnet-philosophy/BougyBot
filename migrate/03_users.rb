require 'sequel_postgresql_triggers'
Sequel.migration do
  change do
    create_table(:users) do
      primary_key :id
      String :nick
      String :mask
      DateTime :at
      DateTime :last
    end
    pgt_updated_at :users, :last
    pgt_created_at :users, :at
  end
end
