Sequel.migration do
  change do
    alter_table(:users) do
      add_column :level, :text
      add_column :password_hash, :text
      add_column :approved, :boolean
    end
  end
end
