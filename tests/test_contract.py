"""contract.cairo test file."""
import os

import pytest
import logging
from starkware.starknet.testing.starknet import Starknet

# The path to the contract source code.
DEX_CONTRACT_FILE = os.path.join("contracts", "mock_dex.cairo")
BASIC_SOLVER_FILE = os.path.join("contracts", "basic_solver.cairo")

# The testing library uses python's asyncio. So the following
# decorator and the ``async`` keyword are needed.
@pytest.mark.asyncio
async def test_solver():
    """Test Solver Savings"""
    # Create a new Starknet class that simulates the StarkNet
    # system.
    starknet = await Starknet.empty()

    # Deploy DEX1.
    dex1_contract = await starknet.deploy(
        source=DEX_CONTRACT_FILE,
    )

    # Deploy DEX2.
    dex2_contract = await starknet.deploy(
        source=DEX_CONTRACT_FILE,
    )

    # Deploy DEX3.
    dex3_contract = await starknet.deploy(
        source=DEX_CONTRACT_FILE,
    )
    
    # Deploy Solver.
    solver_contract = await starknet.deploy(
        source=BASIC_SOLVER_FILE,
    )

    #Set Dex Stats
    await dex1_contract.set_reserves_and_fee(997,8000,8000).invoke()
    await dex2_contract.set_reserves_and_fee(996,5000,5000).invoke()
    await dex3_contract.set_reserves_and_fee(997,3000,3000).invoke()
    #xgradient = solver_contract.xgradient(997,996,997,8000,8000,5000,5000,3000,3000).call()

    #perform trade
    dex_trade1 = await dex1_contract.trade(1000).call()
    dex_trade2 = await dex2_contract.trade(1000).call()
    dex_trade3 = await dex3_contract.trade(1000).call()

    # Set Dex addresses.
    await solver_contract.set_dex(dex1_contract.contract_address,dex2_contract.contract_address,dex3_contract.contract_address).invoke()

    # Check the result of get_balance().
    solve_result = await solver_contract.solve(1000).call()

    print("------------------------------------------")
    print("TRADING 1000 USD FOR 1000 USD")
    print("------------------------------------------")
    print("Trade on DEX1: ",dex_trade1.result)
    print("------------------------------------------")
    print("Trade on DEX2: ",dex_trade2.result)
    print("------------------------------------------")
    print("Trade on DEX3: ",dex_trade3.result)
    print("------------------------------------------")
    print("Solver result: ",solve_result.result)
