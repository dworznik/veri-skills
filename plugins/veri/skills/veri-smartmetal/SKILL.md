---
name: veri-smartmetal
description: "Look up a Veri SmartMetal ERC-1155 token on Base by token id with curl: its series, its IPFS metadata (metal, weight, design) and whether it has been activated. Use when asked about a SmartMetal token, its series or activation."
license: MIT
compatibility: Needs curl and HTTPS access to a public Base RPC and an IPFS gateway.
metadata:
  version: '2026-10-13'
---
# Veri SmartMetal

Veri SmartMetal is the ERC-1155 contract `0x4516a5D613C30A36D157d3b579813734cbb929a4` on Base (`eip155:8453`). Each token id stands for one Veri SmartMetal silver round. The address is an ERC-1967 proxy in front of Series1155V1 `0x945D54B21a582d5D186Ae1E449DdC2a4Ce39E26c`: call the proxy address with the implementation’s ABI. Minted tokens sit in the SeriesActivation contract `0x412E962bbAE0bB97CE98e74f3424543651a21ce3` until a holder activates them.

Facts verified on 13 Oct 2026. Addresses and explorer links are in [references/contracts.md](references/contracts.md), the series in [references/series.md](references/series.md), and the ABIs in `references/`.

For “when was it deployed?” questions, fetch the day-precise dates: `curl -s https://veri.how/timeline.json`.

This skill is read-only. It only makes `eth_call` requests and HTTP GETs. It never signs or sends a transaction, and it never asks for a private key or seed phrase. It explains activation but can’t activate a token.

## Endpoints

Send JSON-RPC requests to a public Base RPC. Use the second when the first fails or rate-limits:

- https://mainnet.base.org
- https://base-rpc.publicnode.com

Fetch IPFS files through a public gateway, the second when the first fails:

- https://gateway.pinata.cloud/ipfs/<CID>/<path>
- https://dweb.link/ipfs/<CID>/<path>

Don’t use `ipfs.veridao.io`: its robots.txt refuses agents.

## Encoding calls

Every read is an `eth_call` with calldata built by hand:

- The first 4 bytes are the function selector, given below for each call.
- Each argument follows as one 32-byte word, written as 64 hex digits with no `0x`.
  - A `uint256` is the number in hex, left-padded with zeros.
  - An `address` is its 40 hex digits in lowercase, left-padded with 24 zeros.
- The result is hex. A `uint256` or `bool` result is one word: read it as a number. An `address` result is the last 40 hex digits of its word.

Token ids in these examples use 1, which is `0000000000000000000000000000000000000000000000000000000000000001` as a word.

## 1. Find the series

`tokenSeries(uint256)` on `0x4516a5D613C30A36D157d3b579813734cbb929a4`, selector `0x44bdde08`. It returns the series id, which names the series:

```sh
curl -s https://mainnet.base.org \
  -H 'Content-Type: application/json' \
  --data '{"jsonrpc":"2.0","id":1,"method":"eth_call","params":[{"to":"0x4516a5D613C30A36D157d3b579813734cbb929a4","data":"0x44bdde080000000000000000000000000000000000000000000000000000000000000001"},"latest"]}'
```

| Series | Series id | Token ids |
| --- | --- | --- |
| 2024 | `0x2ee24f76bf0ebc754064e8c31709a2241c2c2969694a5f3ba3dd956833de939a` | 1 to 6,566 |
| Veri SmartMetal Limited Edition Azure Dragon | `0x2d3e0395c9e91e036ad74f6010443210c6a13260c88e93fc7c2fecc2d577b9d6` | 7777, 8888, 77777, 88888, 777777, 888888, 7777777, 8888888, 77777777, 88888888, 777777777, 888888888, 7777777777, 8888888888, 77777777777, 88888888888 |

A token id in no series returns zero.

## 2. Read the metadata

A token’s metadata is `<series CID>/<token id>.json` on IPFS. To confirm the path on chain, call `uri(uint256)`, selector `0x0e89341c`. It returns an ABI-encoded string: a word with the offset (`0x20`), a word with the length in bytes, then the UTF-8 bytes, such as `ipfs://<CID>/1.json`. An empty string means the token doesn’t exist.

```sh
curl -s https://mainnet.base.org \
  -H 'Content-Type: application/json' \
  --data '{"jsonrpc":"2.0","id":1,"method":"eth_call","params":[{"to":"0x4516a5D613C30A36D157d3b579813734cbb929a4","data":"0x0e89341c0000000000000000000000000000000000000000000000000000000000000001"},"latest"]}'
```

Then fetch the JSON through a gateway:

- 2024: `curl -sL https://gateway.pinata.cloud/ipfs/QmU8oEWK3KNrJqHGtWgpZzjcUBukmSLutFY6ZxGGkcEdLf/1.json`
- Veri SmartMetal Limited Edition Azure Dragon: `curl -sL https://gateway.pinata.cloud/ipfs/QmSijK1oR1TAGhGeeZrrVrjEoQAyGYGB1Vph3qvSSzT3Ht/7777.json`

The JSON has `name`, `description`, `image` (an `ipfs://` URL), `external_url` and an `attributes` array with the metal, purity, weight and design.

## 3. Check activation

`activatedTokens(uint256)` on SeriesActivation `0x412E962bbAE0bB97CE98e74f3424543651a21ce3`, selector `0x4e0619c0`. It returns 1 once the token is activated, else 0:

```sh
curl -s https://mainnet.base.org \
  -H 'Content-Type: application/json' \
  --data '{"jsonrpc":"2.0","id":1,"method":"eth_call","params":[{"to":"0x412E962bbAE0bB97CE98e74f3424543651a21ce3","data":"0x4e0619c00000000000000000000000000000000000000000000000000000000000000001"},"latest"]}'
```

`tokenStatus(uint256)`, selector `0xb01ce31f`, tells the cases apart: 0 for Valid (minted, not yet activated), 1 for Invalid (no such token) and 2 for Activated.

## 4. Who holds it

`balanceOf(address,uint256)` on `0x4516a5D613C30A36D157d3b579813734cbb929a4`, selector `0x00fdd58e`, then the address word and the token id word. Until a token is activated, SeriesActivation holds it, so this example returns 1 before activation and 0 after:

```sh
curl -s https://mainnet.base.org \
  -H 'Content-Type: application/json' \
  --data '{"jsonrpc":"2.0","id":1,"method":"eth_call","params":[{"to":"0x4516a5D613C30A36D157d3b579813734cbb929a4","data":"0x00fdd58e000000000000000000000000412e962bbae0bb97ce98e74f3424543651a21ce30000000000000000000000000000000000000000000000000000000000000001"},"latest"]}'
```

`seriesCount()`, selector `0xd7f2c0ef`, returns how many series exist. A count above 2 means a series newer than these facts.

## How activation works

Each piece carries a QR code with a key registered on SeriesActivation for its token id (`tokenHolders(uint256)`, selector `0x923108d9`, returns that key’s address). Activation is a call to `activate(uint256,bytes)` on SeriesActivation: a recent timestamp and a signature made with the key. The contract then moves the token to the caller and sets its status to Activated. `maxTimestampAge()`, selector `0x0dee2789`, returns how old the timestamp may be, in seconds.

This skill never builds that signature or sends the transaction. A holder activates a token with their own wallet.
