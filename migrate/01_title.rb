require 'sequel_postgresql_triggers'
Sequel.migration do
  change do
    create_table(:urls) do
      primary_key :id
      Integer :times
      String :by
      DateTime :at
      DateTime :last
      String :title
      String :short
      String :original
    end
    pgt_updated_at :urls, :last
    pgt_created_at :urls, :at
  end
end
