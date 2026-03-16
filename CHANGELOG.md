# Changelog

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
