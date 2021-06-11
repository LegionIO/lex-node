Sequel.migration do
  up do
    run "
    create table node_extensions
    (
      `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
      node_id int(11) unsigned not null,
      extension_id int(11) unsigned not null,
      `record_created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
      PRIMARY KEY (`id`),
      KEY `node_id` (`node_id`),
      KEY `version` (`version`),
      CONSTRAINT `node_id` FOREIGN KEY (`nodes`) REFERENCES `nodes` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
      CONSTRAINT `extension_id` FOREIGN KEY (`extensions`) REFERENCES `extensions` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
    );
    "
  end

  down do
    drop_table :node_extensions
  end
end

