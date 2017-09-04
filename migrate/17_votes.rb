# frozen_string_literal: true
require 'sequel_postgresql_triggers'
Sequel.migration do
  change do
    create_table(:votes) do
      primary_key :id
      DateTime :at
      DateTime :updated
      String :by, null: false
      String :deactivated_by
      String :question, null: false
      TrueClass :active, null: false
      foreign_key :channel_id, :channels
    end
    pgt_created_at :votes, :at
    pgt_updated_at :votes, :updated
  end
end
