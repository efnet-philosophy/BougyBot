Sequel.migration do
  change do
    alter_table(:votes) do
      add_column :last_voter, String
    end
  end
end
