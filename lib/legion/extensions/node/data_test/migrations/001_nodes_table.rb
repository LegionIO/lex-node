Sequel.migration do
  up do
    run "CREATE TABLE `nodes` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(128) NOT NULL DEFAULT '',
  `datacenter_id` int(11) unsigned DEFAULT NULL,
  `environment_id` int(11) unsigned DEFAULT NULL,
  `status` varchar(255) NOT NULL DEFAULT 'unknown',
  `active` tinyint(1) unsigned NOT NULL DEFAULT '1',
  `created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated` timestamp NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `name` (`name`),
  KEY `active` (`active`),
  KEY `status` (`status`),
  KEY `node_datacenter_id` (`datacenter_id`),
  KEY `node_environment_id` (`environment_id`),
  CONSTRAINT `node_datacenter_id` FOREIGN KEY (`datacenter_id`) REFERENCES `datacenters` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `node_environment_id` FOREIGN KEY (`environment_id`) REFERENCES `environments` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8;"
  end

  down do
    drop_table :nodes
  end
end
