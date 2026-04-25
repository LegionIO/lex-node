# Changelog

## [0.3.8] - 2026-04-25

### Added
- Signed cluster-control payloads with timestamp freshness and nonce format validation for settings and killswitch broadcasts.

### Changed
- `ClusterControl` queues are now durable and non-auto-delete so per-node commands survive node restarts.
- Beat no longer runs immediately at actor construction, avoiding startup reconciliation before extension boot completes.
- `update_gem` now installs through `Legion::Extensions::GemSource` and calls extension-scoped reload instead of full daemon reload.

## [0.3.7] - 2026-03-31

### Fixed
- `ClusterControl` exchange now inherits from `Legion::Transport::Exchange` instead of being a bare PORO with constants, fixing `NOT_FOUND` error during autobuild queue binding

## [0.3.6] - 2026-03-31

### Added
- `legion.cluster.control` topic exchange for cluster-wide broadcast (durable, topic type)
- Per-node auto-delete queue `legion.cluster.control.<name>` bound to the exchange on boot
- `ClusterSettings` message: publishes settings changes with configurable routing key to the cluster control exchange
- `ClusterKillswitch` message: publishes emergency extension block via routing key `settings.extensions.blocked`
- `ClusterControl` subscription actor: subscribes to the per-node cluster control queue, routes to existing runners by routing key
- `Runners::Node#broadcast_settings(settings:, routing_key: 'settings', restart: false)`: sends settings to all nodes via the cluster control exchange
- `Runners::Node#killswitch(extension:)`: blocks an extension cluster-wide with immediate reload
- 51 new specs covering all new components (162 total, 0 failures)

## [0.3.5] - 2026-03-30

### Changed
- update to rubocop-legion 0.1.7, resolve all offenses

## [Unreleased]

### Added
- Migration 005: composite index on (status, active, updated) for nodes table
- Migration 006: indexes on created, updated, and composite (status, active, created) for nodes table to fix slow health watchdog query

## [0.3.3] - 2026-03-22

### Changed
- Add legion-cache, legion-crypt, legion-data, legion-json, legion-logging, legion-settings, legion-transport as runtime dependencies
- Update spec_helper with real sub-gem helper stubs (Legion::Logging::Helper, Legion::Settings::Helper, Legion::Cache::Helper, Legion::Crypt::Helper, Legion::Data::Helper, Legion::JSON::Helper, Legion::Transport::Helper)
- Update specs to stub Legion::Crypt methods explicitly now that the real gem is loaded in tests
- Update beat actor spec to stub `settings` at instance level for beat_interval lookup

## [0.3.2] - 2026-03-21

### Added
- `Helpers::Rabbitmq` module: queries RabbitMQ Management API for cluster health metrics (node count, quorum queue leaders, shovel link status)
- Beat heartbeat message now includes `rabbitmq_cluster` section with node count, quorum leaders, and shovel links
- 15 new specs covering all Rabbitmq helper methods (111 total, 0 failures)

## [0.3.1] - 2026-03-19

### Fixed
- `push_key` actor referenced removed `Runners::Crypt` (consolidated into `Runners::Node` in v0.3.0); updated actor and spec to use `Runners::Node`

## [0.3.0] - 2026-03-18

### Fixed
- `update_public_key` changed from class method to instance method (was unreachable by AMQP dispatch)
- `request_cluster_secret` now uses correct message namespace
- Beat message uses `[:name]` instead of `[:hostname]` for node identity
- Boot time tracked as class constant (uptime_seconds was always ~0)
- Added `require 'base64'` for Ruby 3.4+ compatibility
- Public key encoding standardized to Base64 across all messages
- Transport settings access uses safe navigation (nil crash prevention)
- Beat actor uses symbol key for `beat_interval` setting
- VaultTokenRequest actor now has `use_runner? true` (was dead wiring)
- Request vault token message Base64-encodes public key

### Changed
- Consolidated Runners::Crypt into Runners::Node (deleted runners/crypt.rb)
- Deleted data_test/ directory (broken MySQL-only migrations, zero consumers)
- Vault runners support multi-cluster token storage (backward-compatible)

### Removed
- Duplicate push_public_key/receive_cluster_secret in Runners::Node (used Crypt versions)
- Unused `require 'socket'` in transport queue
- `|| nil` redundancies in push_cluster_secret message

## [0.2.3] - 2026-03-16

### Added
- Beat message now includes `version` (Legion::VERSION), `metrics` (memory RSS, extension count, uptime), and `hosted_worker_ids` (active digital worker IDs on this node)
- Platform-aware resource metrics collection (macOS `ps` vs Linux `/proc`)

## [0.2.2] - 2026-03-16

### Added
- `update_gem` runner function for remote gem installation and reload
- `update_settings` runner function for remote settings propagation
- `UpdateResult` message class for publishing operation results

## [0.2.1] - 2026-03-13

### Added
- Initial release
