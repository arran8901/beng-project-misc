// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

contract ShippingAgreement {
    address payable public constant SUPPLIER = 0x565A2E68718D17679cb776C12Fe8647244853349;
    address payable public constant CARRIER = 0x66aC8c984B8788677747771033a35cF02F03Bbc7;
    address public constant SUPPLIER_SMART_SENSOR = 0x943D5f8C0e72B27265bA283b2Ce53102A4503001;
    address public constant CARRIER_SMART_SENSOR = 0x87569C781822B4cAd83Cfe30AaaD71cb75457460;
    address public constant CONSIGNEE_SMART_SENSOR = 0xf116E59c60b56B42473033D86C1c911449f3173b;

    uint public constant SHIPPING_COST = 0.025 ether;

    mapping(uint => uint) public dispatchTimes;
    mapping(uint => bool) public damaged;

    function supplierPayment() external payable {
        require(msg.sender == SUPPLIER);
    }

    function shipmentDispatched(uint shipmentID) external {
        require(msg.sender == SUPPLIER_SMART_SENSOR);
        dispatchTimes[shipmentID] = block.timestamp;
    }

    function monitoringData(uint shipmentID, int temp, uint humidity) external {
        require(msg.sender == CARRIER_SMART_SENSOR);
        if (temp < 10 || temp > 12 || humidity < 85 || humidity > 90) {
            damaged[shipmentID] = true;
        }
    }

    function shipmentDelivered(uint shipmentID) external {
        require(msg.sender == CONSIGNEE_SMART_SENSOR);
        bool isDamaged = damaged[shipmentID];
        uint dispatchTime = dispatchTimes[shipmentID];
        uint shippingTime = block.timestamp - dispatchTime;

        if (isDamaged || shippingTime >= 4 days) {
            // Total refund
            SUPPLIER.transfer(SHIPPING_COST);
        } else if (shippingTime >= 3 days && shippingTime < 4 days && !isDamaged) {
            // Partial refund
            uint halfCost = SHIPPING_COST / 2;
            SUPPLIER.transfer(halfCost);
            CARRIER.transfer(halfCost);
        } else {
            // No refund
            CARRIER.transfer(SHIPPING_COST);
        }
    }
}

