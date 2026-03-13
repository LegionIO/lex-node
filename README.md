# lex-node

Node identity and cluster management for [LegionIO](https://github.com/LegionIO/LegionIO). Handles heartbeat broadcasting, cluster secret exchange, Vault token management, and RSA public key distribution between nodes.

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

- **Beat** - Periodic heartbeat broadcast to the cluster
- **Crypt** - RSA keypair exchange: distribute and receive public keys and cluster secrets
- **Node** - Dynamic configuration distribution across cluster nodes
- **Vault** - Vault token lifecycle: request, receive, and push Vault tokens between nodes

## How It Works

Each node periodically calls `beat` to broadcast its presence. On startup, nodes exchange RSA public keys, then use them to securely distribute the cluster shared secret (AES encryption key) and Vault tokens - all encrypted peer-to-peer so no secrets traverse the bus in plaintext.

## Requirements

- Ruby >= 3.4
- [LegionIO](https://github.com/LegionIO/LegionIO) framework

## License

MIT
