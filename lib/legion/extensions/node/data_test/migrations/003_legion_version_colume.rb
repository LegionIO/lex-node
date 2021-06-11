Sequel.migration do
  change do
    alter_table(:nodes) do
      add_column :version, String, null: true
      add_index :nodes_version, :version
    end
  end
end
