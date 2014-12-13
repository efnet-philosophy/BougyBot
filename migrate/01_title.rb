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
  end
end
