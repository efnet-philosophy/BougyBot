require 'sequel_postgresql_triggers'
Sequel.migration do
  change do
    create_table(:notes) do
      primary_key :id
      DateTime :at
      DateTime :updated
      String :from, null: false
      String :to, null: false
      String :message, null: false
      FalseClass :sent, default: false
    end
    pgt_created_at :notes, :at
    pgt_updated_at :notes, :updated
  end
end

