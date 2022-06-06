// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

contract License {
    address public constant ARBITER = 0x8018BB94ed02632ED1cc95d2aB10484edebBd5f0;

    bool public hasLicense;
    bool public hasApproval;
    bool public isCommissioned;

    bool public use;
    bool public usePermission;
    bool public useForbidden;

    bool public publish;
    bool public publishPermission;
    bool public publishForbidden;
    bool public publishObligation;

    bool public comment;
    bool public commentPermission;
    bool public commentForbidden;

    bool public remove;
    bool public removeObligation;

    bool public violation;
    bool public terminated;

    constructor() {
        useForbidden = true;
        publishForbidden = true;
        commentForbidden = true;
    }

    function evaluateLicenseContract() public {
        // Article 1
        if (hasLicense) {
            useForbidden = false;
            usePermission = true;
        }
        // Articles 2 and 4
        if (hasLicense && (hasApproval || isCommissioned)) {
            publishForbidden = false;
            publishPermission = true;
        }
        // Article 2
        if (hasLicense && !hasApproval && !isCommissioned && publish) {
            removeObligation = true;
        }
        // Article 3
        if (publishPermission) {
            commentForbidden = false;
            commentPermission = true;
        }
        // Article 4
        if (hasLicense && isCommissioned) {
            publishForbidden = false;
            publishPermission = true;
            publishObligation = true;
        }
        // Article 5
        if (useForbidden && use
            || publishForbidden && publish
            || publishObligation && !publish
            || commentForbidden && comment
            || removeObligation && !remove) {
            violation = true;
            terminated = true;
        }
    }

    modifier onlyArbiter() {
        require(msg.sender == ARBITER);
        _;
    }

    function grantLicense() onlyArbiter external {
        hasLicense = true;
        evaluateLicenseContract();
    }

    function grantApproval() external onlyArbiter {
        hasApproval = true;
        evaluateLicenseContract();
    }

    function commission() external onlyArbiter {
        isCommissioned = true;
        evaluateLicenseContract();
    }

    function declareUse() external onlyArbiter {
        use = true;
        evaluateLicenseContract();
    }

    function declarePublish() external onlyArbiter {
        publish = true;
        evaluateLicenseContract();
    }

    function declareComment() external onlyArbiter {
        comment = true;
        evaluateLicenseContract();
    }

    function declareRemove() external onlyArbiter {
        remove = true;
        evaluateLicenseContract();
    }
}

