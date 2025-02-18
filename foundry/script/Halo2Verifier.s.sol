// Script to call verifyProof without deploying
// File: Script.s.sol
// Run: forge script Script.s.sol --fork-url <RPC_URL> --sig "run()"
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "forge-std/Vm.sol";

contract Halo2Verifier is Script {
    address contractAddr;

    function run() external {
        vm.startBroadcast();
        
        // Load the contract's bytecode from out/
        bytes memory bytecode = vm.readFileBinary("out/Halo2Verifier.sol/Halo2Verifier.json");
        
        // Etch the contract into a specific address (simulate deploy)
        contractAddr = address(0x100); // Any arbitrary address
        vm.etch(contractAddr, bytecode);
        
        // Call verifyProof
        (bool success, bytes memory result) = contractAddr.call(
            abi.encodeWithSignature("verifyProof(bytes,uint256)")
        );

        require(success, "Call failed");
        bool output = abi.decode(result, (bool));

        console.log("Result:", output);
    }
}
