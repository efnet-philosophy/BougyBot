# frozen_string_literal: true
require 'sequel_postgresql_triggers'
Sequel.migration do
  change do
    create_table(:responses) do
      primary_key :id
      DateTime :at
      DateTime :updated
      String :by, null: false
      String :mask, null: false
      String :comment
      TrueClass :affirm, null: false
      TrueClass :active, null: false, default: true
      foreign_key :vote_id, :votes
    end
    pgt_created_at :responses, :at
    pgt_updated_at :responses, :updated
  end
end
