Sequel.migration do
  up do
    DB[:channel_logs].update("message = full_message")
    alter_table(:channel_logs) do
      drop_column :full_message
    end
  end
end
