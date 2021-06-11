Sequel.migration do
  up do
    run "
    create table node_history
    (
      `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
      node_id int(11) unsigned not null,
      previous_staus varchar(255) null,
      status varchar(255) default active not null,
      `modified_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
      `record_created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
      modified_by varchar(255) default 'node' not null,
      PRIMARY KEY (`id`),
      KEY `node_id` (`node_id`),
      KEY `status` (`status`),
      KEY `status` (`previous_status`),
      CONSTRAINT `node_id` FOREIGN KEY (`nodes`) REFERENCES `nodes` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
    );
    "
  end

  down do
    drop_table :node_history
  end
end

