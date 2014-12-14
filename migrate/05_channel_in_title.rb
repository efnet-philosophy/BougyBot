Sequel.migration do
  change do
    alter_table(:urls) do
      drop_column :channel
      add_foreign_key :channel_id, :channels
    end
  end
end
