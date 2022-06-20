// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

contract Insurance {

    address public constant POLICYHOLDER = 0x4A02caF9c411332F5917af19289FDC74A6fB079c;
    address public constant DATA_SOURCE = 0xF237A1826aA6Fc931B04bDeE1536224BF7E63C90;
    address public constant INSURER = 0x0460c3fb9ce497308777020199Eb553F31E1bcE7;

    uint public constant POLICY_EXPIRATION = 1672534800;

    uint public constant CYCLONE_PAYOUT_LIMIT = 100 ether;
    uint public constant EARTHQUAKE_PAYOUT_LIMIT = 100 ether;
    uint public constant FLOOD_PAYOUT_LIMIT = 10 ether;

    uint public cyclonePayoutPercentage = 0;
    uint public earthquakePayoutPercentage = 0;
    uint public floodPayoutPercentage = 0;

    uint public nextCycloneEligibleTime;
    uint public nextEarthquakeEligibleTime;
    uint public nextFloodEligibleTime;

    uint internal constant VIOLENT_TYPHOON_WIND_SPEED = 105;
    uint internal constant V_STRONG_TYPHOON_WIND_SPEED = 85;
    uint internal constant TYPHOON_WIND_SPEED = 64;

    uint[10] internal rainfallRecordings;
    uint internal nextRainfallIndex = 0;
    uint internal rainfall10DaySum = 0;

    constructor() payable {}

    modifier onlyDataSource() {
        require(msg.sender == DATA_SOURCE, "caller is not the data source");
        _;
    }

    modifier onlyPolicyholder() {
        require(msg.sender == POLICYHOLDER, "caller is not the policyholder");
        _;
    }

    modifier beforeExpiration() {
        require(block.timestamp < POLICY_EXPIRATION, "policy has expired");
        _;
    }

    function inputWindSpeedData(uint speed, uint timestamp) external onlyDataSource {
        // Ignore data if not eligible for cyclone payout yet.
        if (timestamp < nextCycloneEligibleTime) {
            return;
        }

        // Compare speed against policy parameters.
        if (speed >= VIOLENT_TYPHOON_WIND_SPEED) {
            cyclonePayoutPercentage = 100;
        } else if (speed >= V_STRONG_TYPHOON_WIND_SPEED) {
            if (cyclonePayoutPercentage < 80) {
                cyclonePayoutPercentage = 80;
            }
        } else if (speed >= TYPHOON_WIND_SPEED) {
            if (cyclonePayoutPercentage < 40) {
                cyclonePayoutPercentage = 40;
            }
        }
    }

    function inputSeismicIntensityData(string calldata intensity, uint timestamp) external onlyDataSource {
        // Ignore data if not eligible for earthquake payout yet.
        if (timestamp < nextEarthquakeEligibleTime) {
            return;
        }

        // Compare intensity against policy parameters.
        if (stringsEqual(intensity, "6+") || stringsEqual(intensity, "7")) {
            earthquakePayoutPercentage = 100;
        } else if (stringsEqual(intensity, "6-")) {
            if (earthquakePayoutPercentage < 80) {
                earthquakePayoutPercentage = 80;
            }
        } else if (stringsEqual(intensity, "5+")) {
            if (earthquakePayoutPercentage < 40) {
                earthquakePayoutPercentage = 40;
            }
        }
    }

    function inputRainfallData(uint rainfall, uint timestamp) external onlyDataSource {
        // Ignore data if not eligible for flood payout yet.
        if (timestamp < nextFloodEligibleTime) {
            return;
        }
        
        // Update the circular queue and running 10 day sum.
        rainfall10DaySum = rainfall10DaySum + rainfall - rainfallRecordings[nextRainfallIndex];
        rainfallRecordings[nextRainfallIndex] = rainfall;
        nextRainfallIndex = (nextRainfallIndex + 1) % 10;

        // Compare 10 day sum against policy parameter.
        if (rainfall10DaySum > 800) {
            floodPayoutPercentage = 100;
        }
    }

    function claimCyclonePayout() external onlyPolicyholder beforeExpiration {
        require(cyclonePayoutPercentage > 0, "not eligible for cyclone payout");
        uint payout = CYCLONE_PAYOUT_LIMIT * cyclonePayoutPercentage / 100;

        nextCycloneEligibleTime = block.timestamp + 4 weeks;
        cyclonePayoutPercentage = 0;
        
        payable(msg.sender).transfer(payout);
    }

    function claimEarthquakePayout() external onlyPolicyholder beforeExpiration {
        require(earthquakePayoutPercentage > 0, "not eligible for earthquake payout");
        uint payout = EARTHQUAKE_PAYOUT_LIMIT * earthquakePayoutPercentage / 100;

        nextEarthquakeEligibleTime = block.timestamp + 4 weeks;
        earthquakePayoutPercentage = 0;

        payable(msg.sender).transfer(payout);
    }

    function claimFloodPayout() external onlyPolicyholder beforeExpiration {
        require(floodPayoutPercentage > 0, "not eligible for flood payout");

        nextFloodEligibleTime = block.timestamp + 4 weeks;
        floodPayoutPercentage = 0;
        delete rainfallRecordings;
        rainfall10DaySum = 0;

        payable(msg.sender).transfer(FLOOD_PAYOUT_LIMIT);
    }

    function terminate() external {
        require(msg.sender == INSURER, "caller is not the insurer");
        require(block.timestamp > POLICY_EXPIRATION, "policy has not expired yet");

        payable(msg.sender).transfer(address(this).balance);
    }

    function stringsEqual(string calldata s1, string memory s2) internal pure returns (bool) {
        return keccak256(abi.encodePacked(s1)) == keccak256(abi.encodePacked(s2));
    }
}

