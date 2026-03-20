# lex-node

Node identity and cluster management for [LegionIO](https://github.com/LegionIO/LegionIO). Handles heartbeat broadcasting, dynamic configuration distribution, cluster secret exchange, Vault token management, and RSA public key distribution between nodes.

**Version**: 0.3.1

This is a core LEX installed by default with LegionIO.

## Installation

Installed automatically as a dependency of `legionio`. To disable:

```json
{
  "extensions": {
    "node": {
      "enabled": false
    }
  }
}
```

## Runners

### Beat

Periodic heartbeat broadcast to the cluster.

- `beat(status:)` - Publishes a heartbeat message with the node hostname, PID, timestamp, and status. Interval is controlled by the `beat_interval` setting.

### Crypt

RSA keypair and cluster secret exchange.

- `push_public_key` - Broadcasts this node's RSA public key to all peers
- `update_public_key(name:, public_key:)` - Stores a received public key in cluster settings
- `delete_public_key(name:)` - Removes a stored public key from cluster settings
- `request_public_keys` - Broadcasts a request for all nodes to send their public keys
- `push_cluster_secret(public_key:, queue_name:)` - Encrypts the cluster secret with a peer's RSA public key and delivers it to their queue
- `request_cluster_secret` - Requests the cluster secret from peers
- `receive_cluster_secret(message:)` - Decrypts and stores the cluster secret received from a peer

### Node

Dynamic configuration distribution and node management.

- `message(**hash)` - Merges arbitrary key/value pairs into `Legion::Settings` at runtime
- `update_settings(settings:, restart: false)` - Merges a settings hash into `Legion::Settings`; optionally restarts Legion. Publishes an `UpdateResult` message on completion.
- `update_gem(extension:, version: nil, reload: true)` - Installs or upgrades a LEX gem via `Gem.install`, then reloads Legion. Publishes an `UpdateResult` message on completion.
- `push_public_key` - Broadcasts this node's RSA public key (raw string form)
- `update_public_key(name:, public_key:)` - Stores a received public key in cluster settings
- `push_cluster_secret(public_key:, queue_name:)` - Encrypts and delivers the cluster secret to a peer
- `receive_cluster_secret(message:)` - Decrypts and stores the received cluster secret
- `receive_vault_token(message:, routing_key:, public_key:)` - Delegates to the Vault runner

### Vault

Vault token lifecycle management.

- `request_token` - Checks if Vault is enabled but not connected, then calls `request_vault_token`
- `request_vault_token` - Broadcasts a request for a Vault token from peers
- `receive_vault_token(message:)` - Decrypts the received Vault token, stores it, and calls `Legion::Crypt.connect_vault`
- `push_vault_token(public_key:, node_name:)` - Encrypts the local Vault token with a peer's RSA public key and delivers it to their queue

## How It Works

Each node periodically calls `beat` to broadcast its presence. On startup, nodes exchange RSA public keys, then use them to securely distribute the cluster shared secret (AES encryption key) and Vault tokens - all encrypted peer-to-peer so no secrets traverse the bus in plaintext.

Dynamic config changes (`update_settings`) and gem upgrades (`update_gem`) can be pushed to individual nodes or broadcast to all nodes at runtime. Both operations publish an `UpdateResult` message to `node.<name>.update_result` so the outcome can be observed cluster-wide.

## Transport

- **Exchange**: `node` (topic exchange)
- **Queues**: `node.<name>` (node-specific, exclusive, auto-delete), `crypt`, `vault`, `health`
- **Messages**: Beat, PublicKey, RequestPublicKeys, PushClusterSecret, RequestClusterSecret, RequestVaultToken, PushVaultToken, UpdateResult

## Requirements

- Ruby >= 3.4
- [LegionIO](https://github.com/LegionIO/LegionIO) framework

## License

MIT
