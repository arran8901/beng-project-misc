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
    address[] public funders;
    uint public totalRaised;

    function contribute() external payable {
        updateState();
        require(state == State.FUNDRAISING, "campaign not in fundraising state");
        contributions[msg.sender] += msg.value;
        totalRaised += msg.value;

        // Check if sender is already in funders array
        for (uint i = 0; i < funders.length; i++) {
            if (funders[i] == msg.sender) {
                return;
            }
        }
        // Sender was not in funders array, so add it
        funders.push(msg.sender);
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

        // Remove sender from funders array
        for (uint i = 0; i < funders.length; i++) {
            if (funders[i] == msg.sender) {
                // Delete by replacing with last
                funders[i] = funders[funders.length - 1];
                funders.pop();
            }
        }

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

    function getFunders() external view returns (address[] memory) {
        return funders;
    }

    function getFundersAboveX(uint x) external view returns (address[] memory) {
        address[] memory fundersAboveX = new address[](funders.length);
        uint nextIndex = 0;
        for (uint i = 0; i < funders.length; i++) {
            address funder = funders[i];
            if (contributions[funder] > x) {
                fundersAboveX[nextIndex++] = funder;
            }
        }
        address[] memory result = new address[](nextIndex);
        for (uint i = 0; i < nextIndex; i++) {
            result[i] = fundersAboveX[i];
        }
        return result;
    }
}

