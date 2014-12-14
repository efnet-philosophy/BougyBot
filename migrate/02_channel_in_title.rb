Sequel.migration do
  change do
    alter_table(:urls) do
      add_column :channel, String
    end
  end
end
