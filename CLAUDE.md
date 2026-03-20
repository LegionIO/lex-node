# lex-node: Node Identity and Cluster Management for LegionIO

**Repository Level 3 Documentation**
- **Parent**: `/Users/miverso2/rubymine/legion/extensions-core/CLAUDE.md`
- **Grandparent**: `/Users/miverso2/rubymine/legion/CLAUDE.md`

## Purpose

Core Legion Extension responsible for node identity within a LegionIO cluster. Handles heartbeat broadcasting, dynamic configuration distribution, cluster secret exchange, Vault token management, and RSA public key distribution between nodes.

**GitHub**: https://github.com/LegionIO/lex-node
**License**: MIT
**Version**: 0.3.1

## Architecture

```
Legion::Extensions::Node
├── Actors/
│   ├── Beat                # Periodic heartbeat broadcast
│   ├── Crypt               # Cryptographic key exchange actor
│   ├── PushKey             # Once actor: calls request_public_keys on startup
│   ├── Vault               # Vault token lifecycle management
│   └── VaultTokenRequest   # Once actor: calls 'request_token' on Vault runner (request_token delegates to request_vault_token)
├── Runners/
│   ├── Beat                # beat: publishes heartbeat message with node status
│   ├── Crypt               # RSA key exchange: push_public_key, update_public_key,
│   │                       #   delete_public_key, request_public_keys,
│   │                       #   push_cluster_secret, request_cluster_secret,
│   │                       #   receive_cluster_secret
│   ├── Node                # Dynamic config and remote ops: message, update_settings,
│   │                       #   update_gem, push_public_key, update_public_key,
│   │                       #   push_cluster_secret, receive_cluster_secret,
│   │                       #   receive_vault_token
│   └── Vault               # Vault: request_token, request_vault_token,
│                           #   receive_vault_token, push_vault_token
├── Transport/
│   ├── Exchanges/Node      # Node communication exchange
│   ├── Queues/
│   │   ├── Node            # node.<name> (exclusive, auto-delete, per-node)
│   │   ├── Vault           # Vault token queue
│   │   ├── Health          # Health check queue
│   │   └── Crypt           # Encryption key exchange queue
│   └── Messages/
│       ├── Beat                  # Heartbeat message (routing_key: 'status', TTL 5s, includes metrics/worker_ids/version)
│       ├── PublicKey             # Public key distribution
│       ├── RequestPublicKeys     # Broadcast request for cluster public keys
│       ├── PushClusterSecret     # Distribute encrypted cluster secret
│       ├── RequestClusterSecret  # Request cluster secret from peer
│       ├── RequestVaultToken     # Request Vault token from peer
│       ├── PushVaultToken        # Distribute encrypted Vault token
│       └── UpdateResult          # Operation result (update_gem / update_settings outcomes)
└── DataTest/
    └── Migrations/
        ├── 001_nodes_table          # Core nodes table
        ├── 002_node_history_table   # Node activity history
        ├── 003_legion_version_colume # Legion version column (note: typo in filename)
        └── 004_node_extensions      # Installed extensions per node
```

## Key Files

| Path | Purpose |
|------|---------|
| `lib/legion/extensions/node.rb` | Entry point, extension registration |
| `lib/legion/extensions/node/runners/beat.rb` | Heartbeat broadcasting |
| `lib/legion/extensions/node/runners/crypt.rb` | RSA keypair and cluster secret exchange |
| `lib/legion/extensions/node/runners/node.rb` | Dynamic config distribution, update_settings, update_gem, public key relay |
| `lib/legion/extensions/node/runners/vault.rb` | Vault token request/receive/push lifecycle |
| `lib/legion/extensions/node/transport/messages/beat.rb` | Heartbeat message (routing_key: 'status', TTL 5s) with resource metrics, hosted worker IDs, and Legion version |
| `lib/legion/extensions/node/transport/messages/update_result.rb` | Operation result message for update_gem/update_settings |
| `lib/legion/extensions/node/transport/messages/` | All node-to-node message types |
| `lib/legion/extensions/node/transport/queues/node.rb` | Per-node queue (exclusive, auto-delete, classic type) |
| `lib/legion/extensions/node/data_test/migrations/` | DB migrations |

## Cluster Secret Exchange Flow

1. Node starts, calls `request_public_keys` (broadcasts to all nodes)
2. Nodes respond with `push_public_key` (RSA public key, base64-encoded)
3. Node with cluster secret calls `push_cluster_secret`: encrypts secret with recipient's RSA public key, publishes to their queue
4. Recipient calls `receive_cluster_secret`: decrypts with own private key, stores in settings

## Vault Token Flow

1. Node starts without Vault token; `VaultTokenRequest` (Once actor) calls `request_token`
2. `request_token` checks `vault.enabled` and `vault.connected` before broadcasting `request_vault_token`
3. Node with Vault token calls `push_vault_token`: encrypts token with recipient's RSA public key
4. Recipient calls `receive_vault_token`: decrypts, stores token, calls `Legion::Crypt.connect_vault`

## Remote Settings and Gem Updates

`update_settings` and `update_gem` enable runtime cluster management without redeployment:

- `update_settings(settings:, restart: false)` - Merges the provided hash into `Legion::Settings`. Nested hashes are merged key-by-key. Set `restart: true` to trigger `Legion.reload` after applying. Publishes `UpdateResult` with `action: 'update_settings'` and the merged key names.
- `update_gem(extension:, version: nil, reload: true)` - Installs or upgrades a LEX gem (`lex-<name>`) via `Gem.install`. Set `reload: false` to skip `Legion.reload`. Publishes `UpdateResult` with `action: 'update_gem'` and the gem name/version.

Both functions rescue `StandardError` and publish a failed `UpdateResult` on error. The `UpdateResult` message routes to `node.<name>.update_result` so callers can observe outcomes.

## Testing

```bash
bundle install
bundle exec rspec
bundle exec rubocop
```

---

**Maintained By**: Matthew Iverson (@Esity)
