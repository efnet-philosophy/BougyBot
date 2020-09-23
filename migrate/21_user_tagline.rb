Sequel.migration do
  change do
    alter_table(:users) do
      add_column :tagline, :text
    end
  end
end
