# frozen_string_literal: true

Sequel.migration do
  up do
    next unless table_exists?(:nodes)

    # nodes: WHERE status = 'healthy' AND active IS TRUE AND (updated <= ? OR ...)
    alter_table(:nodes) do
      add_index %i[status active updated], name: :idx_nodes_status_active_updated, if_not_exists: true
    end
  end

  down do
    next unless table_exists?(:nodes)

    alter_table(:nodes) do
      drop_index %i[status active updated], name: :idx_nodes_status_active_updated, if_exists: true
    end
  end
end
