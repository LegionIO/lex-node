# lex-node: Node Identity and Cluster Management for LegionIO

**Repository Level 3 Documentation**
- **Category**: `/Users/miverso2/rubymine/legion/CLAUDE.md`

## Purpose

Core Legion Extension responsible for node identity within a LegionIO cluster. Handles heartbeat broadcasting, dynamic configuration distribution, cluster secret exchange, Vault token management, and public key distribution between nodes.

**GitHub**: https://github.com/LegionIO/lex-node
**License**: MIT

## Architecture

```
Legion::Extensions::Node
├── Actors/
│   ├── Beat                # Heartbeat actor (periodic broadcast)
│   ├── Vault               # Vault token lifecycle management
│   └── VaultTokenRequest   # Handles incoming Vault token requests
├── Transport/
│   ├── Exchanges/Node      # Node communication exchange
│   ├── Queues/
│   │   ├── Node            # General node queue
│   │   ├── Vault           # Vault token queue
│   │   ├── Health          # Health check queue
│   │   └── Crypt           # Encryption key exchange queue
│   └── Messages/
│       ├── Beat            # Heartbeat message
│       ├── PublicKey        # Public key distribution
│       ├── RequestPublicKeys    # Request cluster public keys
│       ├── PushClusterSecret    # Distribute cluster secret
│       ├── RequestClusterSecret # Request cluster secret
│       ├── RequestVaultToken    # Request Vault token
│       └── PushVaultToken       # Distribute Vault token
└── DataTest/
    └── Migrations/         # Database schema for nodes table, history, extensions
```

## Key Files

| Path | Purpose |
|------|---------|
| `lib/legion/extensions/node.rb` | Entry point, extension registration |
| `lib/legion/extensions/node/actors/beat.rb` | Heartbeat broadcasting |
| `lib/legion/extensions/node/actors/vault.rb` | Vault token management |
| `lib/legion/extensions/node/transport/messages/` | All node-to-node message types |
| `lib/legion/extensions/node/data_test/migrations/` | DB migrations (nodes, history, extensions) |

## Database Migrations

1. `001_nodes_table` - Core nodes table
2. `002_node_history_table` - Node activity history
3. `003_legion_version_colume` - Legion version tracking column
4. `004_node_extensions` - Installed extensions per node

## Testing

```bash
bundle install
bundle exec rspec
bundle exec rubocop
```

---

**Maintained By**: Matthew Iverson (@Esity)
