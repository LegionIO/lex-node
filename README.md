# lex-node

Node identity and cluster management for [LegionIO](https://github.com/LegionIO/LegionIO). Handles heartbeat broadcasting, cluster secret exchange, Vault token management, and public key distribution between nodes.

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

## Functions

- **Beat** - Periodic heartbeat broadcast to cluster
- **Vault** - Vault token lifecycle management
- **VaultTokenRequest** - Handle incoming Vault token requests
- **PublicKey/ClusterSecret** - Inter-node encryption key exchange

## Requirements

- Ruby >= 3.4
- [LegionIO](https://github.com/LegionIO/LegionIO) framework

## License

MIT
