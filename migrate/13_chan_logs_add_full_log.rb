Sequel.migration do
  up do
    alter_table(:channel_logs) do
      add_column :full_message, :text
    end
    DB[:channel_logs].update("full_message = '<' || nick || '> ' || message")
  end

  down do
    alter_table(:channel_logs) do
      remove_column :full_message
    end
  end
end
