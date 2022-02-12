# A comparison of traditional voting methodologies

## Ordinary Voting

> One-to-One

Everyone equally has only one vote.

However, in this way, it is simply determined by a majority vote, and there is no way to reflect an individual's aspiration because they have same voting power.

## One-person Multi-vote Method

> One-to-Many

To overcome these shortcomings, a one-person multi-vote method has been proposed that allows them to have as many votes as they paid,

but there is a problem here that a small number of wealthy participants can decide the result of the voting easily.

## Quadratic Voting

> One-to-Many, Suppressed

To solve this problem, a quadratic voting method is presented in which the cost of purchasing votes increases exponentially.

However, there is a limitation that quadratic voting is vulnerable to **Sybil attacks**, and it is also challenging to establish a secure system that guarantees anonymity and integrity apart from the quadratic voting protocol.

# Probabilistic Quadratic Voting

> One-to-Many, Suppressed, and Probabilistic

We introduce a secure voting system through **Probabilistic Quadratic Voting (PQV)** and show that the system can mitigate the risk of Sybil attack.


## Proof of the validity

The following is an equation that proves that PQV effectively defends Sybil attacks.

* The left-hand term is the expected value **without Sybil attack**.
* The right-hand term is the expected value **under Sybil attack**.

![](./images/PQV_Math.png)

> *X*: The number of votes.\
> *N*: The total number of votes.\
> *k*: How many parts of the votes will be divided.\
> *l*: The number of parts reflected in the vote.

This formula always holds when *```k > 1```* and *```kN/X != 0```*.

In conclusion, in PQV, it is always a loss when trying Sybil attack.
