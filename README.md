# Fully Decentralized Sybil-Resistant Quadratic Voting System

> based on [Chainlink-VRF](https://docs.chain.link/docs/chainlink-vrf/) and [Matic](https://polygon.technology)

## Abstract

Fair voting system is really important for DAO. However, even the most developed voting system, Quadratic Voting (QV), is exposed to the risk of sybil attack.

Therefore we develops **```Governor C```** contract which is a fully decentralized sybil resistant quadratic voting system based on Chainlink-VRF. To achieve sybil resistant, we suggest Probabilistic Quadratic Voting (PQV) method which apply probabilitic element on QV and make it always a loss to do sybil attack.

For the perfect decentralization, we used Chainlink-VRF and scalable blockchain Matic.

# Features

The goal of this project is activate the whole decentralized DAO ecosystem. For doing it, we create and built three novel things:

* Probabilistic Quadratic Voting
* Smart contract ```Governor C``` that embodies PQV
* Example of service using ```Governor C```

## Probabilistic Quadratic Voting

> [*Junmo Lee, Sanghyeon Park, and Soo-Mook Moon. "Secure Voting System with Sybil Attack Resistance using Probabilistic Quadratic Voting and Trusted Execution Environment." KIISE Transactions on Computing Practices 27.8 (2021): 382-387.*](https://www.dbpia.co.kr/Journal/articleDetail?nodeId=NODE10594648)

Make it always a loss to do sybil attack by applying probabilitic element on quadratic voting. In PQV, spliting voting power makes the expected value of voting power lower that executing 1 voting power.

QV and PQV shows high similarity through simulation. Also PQV's sybil resistance has been proved.

The details are in the [`PQV.md`](./docs/PQV.md) and [`PQV-simulator`](https://github.com/Team-DAppO/PQV-simulator).

## Governor Charlie

The details are in the [`GovernorCharlie.md`](./docs/GovernorCharlie.md).

## Example Service

![demo](docs/images/governance_demo.gif)

TBA

# Future Work

## Governor Delta

> Work-In-Progress.

D stands for Dynamic.

TBA

# Contact

Luke Park (Sanghyeon Park)

> [🖥 https://github.com/lukepark327](https://github.com/lukepark327)\
> [✉️ lukepark327@gmail.com](mailto:lukepark327@gmail.com)

# License

The Governor-C project is licensed under the [MIT](https://opensource.org/licenses/MIT), also included in our repository in the [LICENSE](./LICENSE) file.
