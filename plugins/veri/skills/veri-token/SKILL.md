---
name: veri-token
description: "Read the VERI ERC-20 token on Ethereum with curl over public JSON-RPC: total supply, decimals, owner and the VERI balance of any address. Use when asked about VERI balances, supply or contract facts."
license: MIT
compatibility: Needs curl and HTTPS access to a public Ethereum RPC.
metadata:
  version: '2026-10-13'
---
# VERI token

VERI is the ERC-20 contract `0x8f3470A7388c05eE4e7AF3d01D8C722b0FF52374` on Ethereum (`eip155:1`), with 18 decimals. Facts verified on 13 Oct 2026. Addresses and explorer links are in [references/contracts.md](references/contracts.md), and the ABI is [references/veri.abi.json](references/veri.abi.json).

This skill is read-only. It only makes `eth_call` requests and HTTP GETs. It never signs or sends a transaction, and it never asks for a private key or seed phrase. Don’t use it to move VERI.

## Endpoints

Send JSON-RPC requests to a public Ethereum RPC. Use the second when the first fails or rate-limits:

- https://ethereum-rpc.publicnode.com
- https://eth.drpc.org

## Encoding calls

Every read is an `eth_call` with calldata built by hand:

- The first 4 bytes are the function selector, given below for each call.
- Each argument follows as one 32-byte word, written as 64 hex digits with no `0x`.
  - A `uint256` is the number in hex, left-padded with zeros.
  - An `address` is its 40 hex digits in lowercase, left-padded with 24 zeros.
- The result is hex. A `uint256` or `bool` result is one word: read it as a number. An `address` result is the last 40 hex digits of its word.

## Total supply

`totalSupply()`, selector `0x18160ddd`. The result is in base units: divide by 10^18.

```sh
curl -s https://ethereum-rpc.publicnode.com \
  -H 'Content-Type: application/json' \
  --data '{"jsonrpc":"2.0","id":1,"method":"eth_call","params":[{"to":"0x8f3470A7388c05eE4e7AF3d01D8C722b0FF52374","data":"0x18160ddd"},"latest"]}'
```

## Balance of an address

`balanceOf(address)`, selector `0x70a08231`, then the address as one word. The result is in base units: divide by 10^18. This example reads `0x82c48875C17EE5812f909a9d75C0F64f7A8719FE`:

```sh
curl -s https://ethereum-rpc.publicnode.com \
  -H 'Content-Type: application/json' \
  --data '{"jsonrpc":"2.0","id":1,"method":"eth_call","params":[{"to":"0x8f3470A7388c05eE4e7AF3d01D8C722b0FF52374","data":"0x70a0823100000000000000000000000082c48875c17ee5812f909a9d75c0f64f7a8719fe"},"latest"]}'
```

**Balances come from `balanceOf`, not from Transfer logs.** VERI predates later ERC-20 conventions and moves tokens without a `Transfer` event twice:

- The constructor wrote the whole initial supply to the deployer without a `Transfer` event.
- `transferOwnership` moves the old owner’s entire balance to the new owner, overwriting what the new owner held, without a `Transfer` event.

So a balance rebuilt by summing `Transfer` logs is wrong for those addresses. Always read `balanceOf`.

## Decimals and owner

- `decimals()`, selector `0x313ce567`. It returns a `uint256`, not the usual `uint8`.
- `owner()`, selector `0x8da5cb5b`. The result word holds an address.

```sh
curl -s https://ethereum-rpc.publicnode.com \
  -H 'Content-Type: application/json' \
  --data '{"jsonrpc":"2.0","id":1,"method":"eth_call","params":[{"to":"0x8f3470A7388c05eE4e7AF3d01D8C722b0FF52374","data":"0x8da5cb5b"},"latest"]}'
```
