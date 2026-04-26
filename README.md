# Hey, I'm DevNinja 🥷

I build settlement infrastructure and cross-chain systems across **Solidity, Rust, Go, TypeScript/Node, and Python** — deep in all of them, not just passing-familiar. Over the past few years I've contributed to protocols like CoW Protocol, Filecoin (via ChainSafe's Forest), and Hyperlane's cross-chain messaging stack. I care about code that's auditable, deterministic, and built to survive adversarial environments — which is most of Web3. When I'm not only writing Solidity or Move, I'm usually deep in backend systems design or experimenting with SUI's object-centric model.

Currently: freelancing across Web3 — building solvers, smart contracts, and backend infra for protocols and teams who ship fast.

## What I'm Building

| Project | Description | Stack | Status |
| --- | --- | --- | --- |
| [titular](https://github.com/0xDevNinja/titular) | Commerce layer for AI agents — multi-chain launchpad (Base/Eth/Solana) with ACP v2, GAME planner, and Agent Console | Solidity, TypeScript | Active |
| [cowSolver](https://github.com/0xDevNinja/cowSolver) | Cross-chain CoW Protocol solver with bridge integration and settlement optimization | Rust | Active |
| [ProphecyChain](https://github.com/0xDevNinja/ProphecyChain) | EVM state-vote store chain built on Cosmos SDK | Go | Active |
| [neuro-mesh](https://github.com/0xDevNinja/neuro-mesh) | Reference implementation of NeuroMesh — peer-to-peer intelligence market on Substrate | Rust, Python | Active |

## Technical Philosophy

I optimize for cross-chain interoperability and on-chain settlement correctness — bridge invariants, solver pricing, and message-passing semantics get more attention than UI polish. Modules ship behind feature gates with property tests and threat models before mainnet. Security-first by default: every external call return value gets checked, every state change emits an event.

## Ecosystem Contributions

- **ChainSafe / Forest** — Contributed to the Rust implementation of the Filecoin node: FRC-0102 signing envelope, strict address validation in `forest-wallet`, MessagePool error surfacing, fallback blockstore with bitswap. [View PRs →](https://github.com/ChainSafe/forest/pulls?q=author%3A0xDevNinja)
- **Hyperlane** — Contributed to the cross-chain messaging monorepo: `MAX_MESSAGE_BODY_BYTES` check on `MockMailbox`. [View PRs →](https://github.com/hyperlane-xyz/hyperlane-monorepo/pulls?q=author%3A0xDevNinja)
- **CoW Protocol** — Built [cowSolver](https://github.com/0xDevNinja/cowSolver): a cross-chain solver with bridge integration and settlement optimization.
- **TVL Labs / Axon** — AVS contracts for EigenLayer integration ([el-axon #1](https://github.com/tvl-labs/el-axon/pull/1)).
- **Nervos / Force Bridge** — ETH-side contract audit suggestions ([force-bridge #386](https://github.com/nervosnetwork/force-bridge/pull/386)).

## Stack

**Languages**
![Rust](https://img.shields.io/badge/Rust-000000?style=flat&logo=rust&logoColor=white)
![Go](https://img.shields.io/badge/Go-00ADD8?style=flat&logo=go&logoColor=white)
![Solidity](https://img.shields.io/badge/Solidity-363636?style=flat&logo=solidity&logoColor=white)
![TypeScript](https://img.shields.io/badge/TypeScript-3178C6?style=flat&logo=typescript&logoColor=white)
![Node.js](https://img.shields.io/badge/Node.js-339933?style=flat&logo=node.js&logoColor=white)
![Move](https://img.shields.io/badge/Move-4A90D9?style=flat&logoColor=white)
![Python](https://img.shields.io/badge/Python-3776AB?style=flat&logo=python&logoColor=white)

**Blockchain**
![Ethereum](https://img.shields.io/badge/Ethereum-3C3C3D?style=flat&logo=ethereum&logoColor=white)
![Solana](https://img.shields.io/badge/Solana-9945FF?style=flat&logo=solana&logoColor=white)
![SUI](https://img.shields.io/badge/SUI-6FBCF0?style=flat&logoColor=white)
![Cosmos SDK](https://img.shields.io/badge/Cosmos_SDK-2E3148?style=flat&logo=cosmos&logoColor=white)
![Substrate](https://img.shields.io/badge/Substrate-282828?style=flat&logo=parity-substrate&logoColor=white)
![Filecoin](https://img.shields.io/badge/Filecoin-0090FF?style=flat&logo=filecoin&logoColor=white)
![Foundry](https://img.shields.io/badge/Foundry-000000?style=flat&logo=foundry&logoColor=white)

**Infrastructure**
![Docker](https://img.shields.io/badge/Docker-2496ED?style=flat&logo=docker&logoColor=white)
![Kubernetes](https://img.shields.io/badge/Kubernetes-326CE5?style=flat&logo=kubernetes&logoColor=white)
![Terraform](https://img.shields.io/badge/Terraform-7B42BC?style=flat&logo=terraform&logoColor=white)
![AWS](https://img.shields.io/badge/AWS-232F3E?style=flat&logo=amazon-aws&logoColor=white)
![GCP](https://img.shields.io/badge/GCP-4285F4?style=flat&logo=google-cloud&logoColor=white)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-4169E1?style=flat&logo=postgresql&logoColor=white)
![Redis](https://img.shields.io/badge/Redis-DC382D?style=flat&logo=redis&logoColor=white)
![Kafka](https://img.shields.io/badge/Kafka-231F20?style=flat&logo=apache-kafka&logoColor=white)
![NATS](https://img.shields.io/badge/NATS-27AAE1?style=flat&logo=nats.io&logoColor=white)
![gRPC](https://img.shields.io/badge/gRPC-244C5A?style=flat&logo=grpc&logoColor=white)
![NGINX](https://img.shields.io/badge/NGINX-009639?style=flat&logo=nginx&logoColor=white)
![Prometheus](https://img.shields.io/badge/Prometheus-E6522C?style=flat&logo=prometheus&logoColor=white)
![Grafana](https://img.shields.io/badge/Grafana-F46800?style=flat&logo=grafana&logoColor=white)
![OpenTelemetry](https://img.shields.io/badge/OpenTelemetry-000000?style=flat&logo=opentelemetry&logoColor=white)
![libp2p](https://img.shields.io/badge/libp2p-2C2C2C?style=flat&logo=libp2p&logoColor=white)
![IPFS](https://img.shields.io/badge/IPFS-65C2CB?style=flat&logo=ipfs&logoColor=white)
![GitHub Actions](https://img.shields.io/badge/GitHub_Actions-2088FF?style=flat&logo=github-actions&logoColor=white)

## Connect

[![Email](https://img.shields.io/badge/Email-EA4335?style=flat&logo=gmail&logoColor=white)](mailto:manmit0x@gmail.com)
[![GitHub](https://img.shields.io/badge/GitHub-181717?style=flat&logo=github&logoColor=white)](https://github.com/0xDevNinja)

## Stats

![DevNinja's GitHub stats](https://github-readme-stats.vercel.app/api?username=0xDevNinja&show_icons=true&hide=contribs&count_private=true&theme=midnight-purple&hide_border=true&bg_color=0D1117&title_color=2CA58D&icon_color=5A4680&text_color=C9D1D9)
