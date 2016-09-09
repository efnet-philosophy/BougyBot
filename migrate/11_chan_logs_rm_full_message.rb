Sequel.migration do
  up do
    alter_table(:channel_logs) do
      drop_column :full_message
    end
  end
end
