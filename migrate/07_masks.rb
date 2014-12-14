require 'sequel_postgresql_triggers'
Sequel.migration do
  change do
    create_table(:masks) do
      primary_key :id
      String :mask
      DateTime :at
      DateTime :last
      foreign_key :user_id
    end
    pgt_created_at :masks, :at
    pgt_updated_at :masks, :last
  end
end
