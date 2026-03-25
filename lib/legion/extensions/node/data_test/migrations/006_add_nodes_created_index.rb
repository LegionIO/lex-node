# frozen_string_literal: true

Sequel.migration do
  up do
    next unless table_exists?(:nodes)

    alter_table(:nodes) do
      add_index :created, name: :idx_nodes_created, if_not_exists: true
      add_index :updated, name: :idx_nodes_updated, if_not_exists: true
      add_index %i[status active created], name: :idx_nodes_status_active_created, if_not_exists: true
    end
  end

  down do
    next unless table_exists?(:nodes)

    alter_table(:nodes) do
      drop_index :created, name: :idx_nodes_created, if_exists: true
      drop_index :updated, name: :idx_nodes_updated, if_exists: true
      drop_index %i[status active created], name: :idx_nodes_status_active_created, if_exists: true
    end
  end
end
