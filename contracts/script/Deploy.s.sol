// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Script.sol";
import "../UniversalClaimHub.sol";
import "../modules/ClankerModule.sol";
import "../modules/ZoraModule.sol";
import "../modules/FlaunchModule.sol";

/**
 * @title DeployScript
 * @notice Script para deploy de todos os contratos do claimtools.xyz
 * @author claimtools.xyz
 *
 * Usage:
 * forge script script/Deploy.s.sol:DeployScript --rpc-url base --broadcast --verify
 */
contract DeployScript is Script {

    // Configuração
    address constant FEE_COLLECTOR = address(0); // TODO: Definir endereço real
    uint256 constant PLATFORM_FEE = 0; // 0% inicialmente (free tier)

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        console.log("=================================");
        console.log("Deploying ClaimTools Contracts");
        console.log("=================================");
        console.log("Deployer:", vm.addr(deployerPrivateKey));
        console.log("Chain ID:", block.chainid);
        console.log("");

        vm.startBroadcast(deployerPrivateKey);

        // ========== STEP 1: Deploy Modules ==========
        console.log("Step 1: Deploying Protocol Modules...");

        ClankerModule clankerModule = new ClankerModule();
        console.log("ClankerModule deployed at:", address(clankerModule));

        ZoraModule zoraModule = new ZoraModule();
        console.log("ZoraModule deployed at:", address(zoraModule));

        FlaunchModule flaunchModule = new FlaunchModule();
        console.log("FlaunchModule deployed at:", address(flaunchModule));

        console.log("");

        // ========== STEP 2: Deploy Hub ==========
        console.log("Step 2: Deploying UniversalClaimHub...");

        address feeCollectorAddress = FEE_COLLECTOR == address(0)
            ? vm.addr(deployerPrivateKey)
            : FEE_COLLECTOR;

        UniversalClaimHub hub = new UniversalClaimHub(
            feeCollectorAddress,
            PLATFORM_FEE
        );
        console.log("UniversalClaimHub deployed at:", address(hub));
        console.log("");

        // ========== STEP 3: Register Modules ==========
        console.log("Step 3: Registering Modules in Hub...");

        // Registrar Clanker
        hub.registerModule(
            UniversalClaimHub.Protocol.CLANKER_V4,
            address(clankerModule)
        );
        console.log("✓ ClankerModule registered for CLANKER_V4");

        // Registrar Zora
        hub.registerModule(
            UniversalClaimHub.Protocol.ZORA,
            address(zoraModule)
        );
        console.log("✓ ZoraModule registered for ZORA");

        // Registrar Flaunch
        hub.registerModule(
            UniversalClaimHub.Protocol.FLAUNCH,
            address(flaunchModule)
        );
        console.log("✓ FlaunchModule registered for FLAUNCH");

        console.log("");

        vm.stopBroadcast();

        // ========== SUMMARY ==========
        console.log("=================================");
        console.log("Deployment Summary");
        console.log("=================================");
        console.log("UniversalClaimHub:", address(hub));
        console.log("ClankerModule:    ", address(clankerModule));
        console.log("ZoraModule:       ", address(zoraModule));
        console.log("FlaunchModule:    ", address(flaunchModule));
        console.log("");
        console.log("Fee Collector:    ", feeCollectorAddress);
        console.log("Platform Fee:     ", PLATFORM_FEE, "bps");
        console.log("=================================");
        console.log("");

        // Salvar endereços em arquivo JSON
        string memory json = string(
            abi.encodePacked(
                '{\n',
                '  "chainId": ', vm.toString(block.chainid), ',\n',
                '  "contracts": {\n',
                '    "UniversalClaimHub": "', vm.toString(address(hub)), '",\n',
                '    "ClankerModule": "', vm.toString(address(clankerModule)), '",\n',
                '    "ZoraModule": "', vm.toString(address(zoraModule)), '",\n',
                '    "FlaunchModule": "', vm.toString(address(flaunchModule)), '"\n',
                '  },\n',
                '  "config": {\n',
                '    "feeCollector": "', vm.toString(feeCollectorAddress), '",\n',
                '    "platformFee": ', vm.toString(PLATFORM_FEE), '\n',
                '  }\n',
                '}'
            )
        );

        vm.writeFile("deployments/base-mainnet.json", json);
        console.log("✓ Deployment addresses saved to deployments/base-mainnet.json");
    }
}

/**
 * @title DeployTestnetScript
 * @notice Script para deploy na testnet (Base Sepolia)
 */
contract DeployTestnetScript is Script {

    address constant FEE_COLLECTOR = address(0);
    uint256 constant PLATFORM_FEE = 0;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        console.log("=================================");
        console.log("Deploying to TESTNET (Base Sepolia)");
        console.log("=================================");

        vm.startBroadcast(deployerPrivateKey);

        // Deploy módulos
        ClankerModule clankerModule = new ClankerModule();
        ZoraModule zoraModule = new ZoraModule();
        FlaunchModule flaunchModule = new FlaunchModule();

        // Deploy hub
        address feeCollectorAddress = FEE_COLLECTOR == address(0)
            ? vm.addr(deployerPrivateKey)
            : FEE_COLLECTOR;

        UniversalClaimHub hub = new UniversalClaimHub(
            feeCollectorAddress,
            PLATFORM_FEE
        );

        // Registrar módulos
        hub.registerModule(
            UniversalClaimHub.Protocol.CLANKER_V4,
            address(clankerModule)
        );
        hub.registerModule(
            UniversalClaimHub.Protocol.ZORA,
            address(zoraModule)
        );
        hub.registerModule(
            UniversalClaimHub.Protocol.FLAUNCH,
            address(flaunchModule)
        );

        vm.stopBroadcast();

        console.log("UniversalClaimHub:", address(hub));
        console.log("ClankerModule:    ", address(clankerModule));
        console.log("ZoraModule:       ", address(zoraModule));
        console.log("FlaunchModule:    ", address(flaunchModule));

        // Salvar endereços testnet
        string memory json = string(
            abi.encodePacked(
                '{\n',
                '  "chainId": ', vm.toString(block.chainid), ',\n',
                '  "network": "base-sepolia",\n',
                '  "contracts": {\n',
                '    "UniversalClaimHub": "', vm.toString(address(hub)), '",\n',
                '    "ClankerModule": "', vm.toString(address(clankerModule)), '",\n',
                '    "ZoraModule": "', vm.toString(address(zoraModule)), '",\n',
                '    "FlaunchModule": "', vm.toString(address(flaunchModule)), '"\n',
                '  }\n',
                '}'
            )
        );

        vm.writeFile("deployments/base-sepolia.json", json);
        console.log("✓ Saved to deployments/base-sepolia.json");
    }
}
