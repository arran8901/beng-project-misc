// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

contract PharmacogenomicsData {

    struct Observation {
        string gene;
        uint variant;
        string drug;
        string outcome;
        bool relation;
        bool sideEffect;
    }

    mapping(uint => Observation) public database;
    uint public counter;

    mapping(string => uint[]) public geneMapping;
    mapping(uint => uint[]) public variantMapping;
    mapping(string => uint[]) public drugMapping;

    function insert(
        string calldata gene,
        uint variant,
        string calldata drug,
        string calldata outcome,
        bool relation,
        bool sideEffect
    ) external {
        geneMapping[gene].push(counter);
        variantMapping[variant].push(counter);
        drugMapping[drug].push(counter);
        database[counter] = Observation(gene, variant, drug, outcome, relation, sideEffect);
        counter++;
    }

    function query(
        string calldata gene,
        string calldata variant,
        string calldata drug
    ) external view returns (Observation[] memory) {
        uint[] memory idList = new uint[](counter);
        uint matchCount = 0;
        uint[] memory genes;
        uint[] memory variants;
        uint[] memory drugs;

        // If database empty, return empty
        if (counter == 0) {
            return new Observation[](0);
        }

        // Check number of fields being searched by
        uint len = 0;
        if (!stringsEqual(gene, "*")) {
            len++;
            genes = geneMapping[gene];
            if (genes.length == 0) {
                return new Observation[](0);
            }
        }
        if (!stringsEqual(variant, "*")) {
            len++;
            (bool success, uint variantUint) = stringToUint(variant);
            require(success, "variant is not a valid uint");
            variants = variantMapping[variantUint];
            if (variants.length == 0) {
                return new Observation[](0);
            }
        }
        if (!stringsEqual(drug, "*")) {
            len++;
            drugs = drugMapping[drug];
            if (drugs.length == 0) {
                return new Observation[](0);
            }
        }

        if (len == 0) {
            // All fields are wildcards; push all IDs in database
            matchCount = counter;
            for (uint i = 0; i < counter; i++) {
                idList[i] = i;
            }
        } else {
            // Compute intersection of genes, variants and drugs
            matchCount = computeIntersection(genes, variants, drugs, len, matchCount, idList);
        }

        Observation[] memory results = new Observation[](matchCount);
        for (uint i = 0; i < matchCount; i++) {
            results[i] = database[idList[i]];
        }
        return results;
    }

    function stringsEqual(
        string calldata s1,
        string memory s2
    ) internal pure returns (bool) {
        return keccak256(abi.encodePacked(s1)) == keccak256(abi.encodePacked(s2));
    }

    function stringToUint(
        string calldata s
    ) internal pure returns (bool success, uint result) {
        bytes memory b = bytes(s);
        uint j = 1;
        for (uint i = b.length - 1; i >= 0 && i < b.length;) {
            if (!(uint8(b[i]) >= 48 && uint8(b[i]) <= 57)) {
                return (false, 0);
            }
            result += j * (uint8(b[i]) - 48);
            j *= 10;
            unchecked {
                i--;
            }
        }
        success = true;
    }

    function computeIntersection(
        uint[] memory genes,
        uint[] memory variants,
        uint[] memory drugs,
        uint len,
        uint matchCount,
        uint[] memory idList
    ) internal view returns (uint) {
        uint minLength = counter;
        uint minField = 3;
        if (genes.length > 0 && genes.length <= minLength) {
            minLength = genes.length;
            minField = 0;
        }
        if (variants.length > 0 && variants.length <= minLength) {
            minLength = variants.length;
            minField = 1;
        }
        if (drugs.length > 0 && drugs.length <= minLength) {
            minLength = drugs.length;
            minField = 2;
        }

        for (uint i = 0; i < minLength; i++) {
            uint numFieldsMatched = 1;
            if (minField == 0) {
                // Shortest is genes
                if (variants.length > 0) {
                    for (uint j = 0; j < variants.length; j++) {
                        if (genes[i] == variants[j]) {
                            numFieldsMatched++;
                            break;
                        }
                    }
                }
                if (drugs.length > 0) {
                    for (uint j = 0; j < drugs.length; j++) {
                        if (genes[i] == drugs[j]) {
                            numFieldsMatched++;
                            break;
                        }
                    }
                }
                if (numFieldsMatched == len) {
                    idList[matchCount++] = genes[i];
                }
            } else if (minField == 1) {
                // Shortest is variants
                if (genes.length > 0) {
                    for (uint j = 0; j < genes.length; j++) {
                        if (variants[i] == genes[j]) {
                            numFieldsMatched++;
                            break;
                        }
                    }
                }
                if (drugs.length > 0) {
                    for (uint j = 0; j < drugs.length; j++) {
                        if (variants[i] == drugs[j]) {
                            numFieldsMatched++;
                            break;
                        }
                    }
                }
                if (numFieldsMatched == len) {
                    idList[matchCount++] = variants[i];
                }
            } else if (minField == 2) {
                // Shortest is drugs
                if (genes.length > 0) {
                    for (uint j = 0; j < genes.length; j++) {
                        if (drugs[i] == genes[j]) {
                            numFieldsMatched++;
                            break;
                        }
                    }
                }
                if (variants.length > 0) {
                    for (uint j = 0; j < variants.length; j++) {
                        if (drugs[i] == variants[j]) {
                            numFieldsMatched++;
                            break;
                        }
                    }
                }
                if (numFieldsMatched == len) {
                    idList[matchCount++] = drugs[i];
                }
            }
        }

        return matchCount;
    }

// observation('HLA-B', 57, 'abacavir', 'Improved', true, false).                                    
// observation('HLA-B', 49, 'abacavir', 'Improved', true, false).                                    
// observation('HLA-B', 57, 'abacavir', 'Deteriorated', true, true).                                 
// observation('test', 49, 'abacavir', 'Improved', true, false).                                     
// observation('HLA-B', 49, 'test', 'Improved', true, false).                                        
// observation('HLA-B', 57, 'abacavir', 'Unchanged', true, false).

// "HLA-B", 57, "abacavir", "Improved", true, false
// "HLA-B", 49, "abacavir", "Improved", true, false
// "HLA-B", 57, "abacavir", "Deteriorated", true, true
// "test", 49, "abacavir", "Improved", true, false
// "HLA-B", 49, "test", "Improved", true, false
// "HLA-B", 57, "abacavir", "Unchanged", true, false
}

