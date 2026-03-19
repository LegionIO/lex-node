# Changelog

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
