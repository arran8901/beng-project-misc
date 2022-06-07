// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

contract CrowdFunding {

    address public constant BENEFICIARY = 0xAa596dFfeA2f94668A2E667Ced218442cA3F10DE;
    uint public constant DEADLINE = 1656633600;
    uint public constant GOAL = 100 ether;

    enum State {
        FUNDRAISING,
        UNSUCCESSFUL,
        SUCCESSFUL,
        CLOSED
    }

    State public state = State.FUNDRAISING;
    mapping(address => uint) public contributions;
    uint public totalRaised;

    function contribute() external payable {
        updateState();
        require(state == State.FUNDRAISING, "campaign not in fundraising state");
        contributions[msg.sender] += msg.value;
        totalRaised += msg.value;
    }

    function claimFunds() external {
        updateState();
        require(state == State.SUCCESSFUL, "campaign not in successful state");
        require(msg.sender == BENEFICIARY, "caller is not the beneficiary");
        state = State.CLOSED;
        payable(msg.sender).transfer(totalRaised);
    }

    function refund() external {
        updateState();
        require(state == State.UNSUCCESSFUL, "campaign not in unsuccessful state");
        uint contribution = contributions[msg.sender];
        totalRaised -= contribution;
        delete contributions[msg.sender];
        payable(msg.sender).transfer(contribution);
    }

    function updateState() public {
        if (state == State.CLOSED) {
            return;
        }
        if (block.timestamp > DEADLINE) {
            if (totalRaised < GOAL) {
                state = State.UNSUCCESSFUL;
            } else {
                state = State.SUCCESSFUL;
            }
        }
    }
}

