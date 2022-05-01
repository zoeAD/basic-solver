# Basic-Solver

A basic solver to find the optimal trading distribution between 3 given UniV2 style exchanges.

## Commands

To run basic tests:
`make test`

This is a nile project. So to setup run:

`pip install cairo-nile`

`nile install`

## Summary

`basic_solver.cairo` implements a basic gradient descent algorithm to find the amount trading input required for each DEX to receive the maximum output.

This implementation is extremely inflexible and not close to production ready. It is also overkill for the task that is being solved. However, it has been a good first step for me in getting more accustomed with cairo and is the first step in creating more powerful solvers that:

<ol>
  <li>Utilizes Uint256</li>
  <li>Utilizes a larger and flexible number of DEXes</li>
  <li>Finds an optimal route and performs multiple jumps </li>
</ol>

With this implementation I have also prioritized performance over readability. Future iterations will include a document that explains the execution process and the math behind the model. 
