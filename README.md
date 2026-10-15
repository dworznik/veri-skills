# veri-skills

The Claude plugin marketplace for the [veri.how](https://veri.how/skills) Agent Skills. It has one plugin, `veri`, with two read-only skills:

- `veri-token` reads the VERI ERC-20 token on Ethereum: total supply, decimals, owner and the VERI balance of any address.
- `veri-smartmetal` looks up a Veri SmartMetal ERC-1155 token on Base by token id: its series, its IPFS metadata and whether it has been activated.

Both skills are instructions only: curl calls over public JSON-RPC and IPFS gateways. They never sign or send a transaction.

## Install

**Claude app** (web, desktop, Cowork): open Customize, then Plugins, then Add, then Add marketplace, and enter `dworznik/veri-skills`. Then add the `veri` plugin.

**Claude Code:**

```
/plugin marketplace add dworznik/veri-skills
/plugin install veri@veri-how
```

Claude Code can also add the marketplace straight from `https://veri.how/marketplace.json`.

## Source

veri.how generates the skills from its contract facts. This repo is a copy: `scripts/sync.sh` pulls `plugins/veri/` from veri.how daily and checks it against the sha256 that veri.how pins. Don't edit the files here. Questions go to hello@veri.how.

## Licence

MIT. The ABIs in `references/` keep the licence of their verified source.
