# 🔷 Smart Contracts - Multi-Protocolo

## 📋 Visão Geral

Arquitetura modular de smart contracts para suportar batch claiming de múltiplos protocolos de token launch na Base Network.

## 🏗️ Arquitetura

### Design Pattern: Modular + Hub-and-Spoke

```
                    ┌──────────────────────┐
                    │  UniversalClaimHub   │
                    │  (Orchestrator)      │
                    └──────────┬───────────┘
                               │
              ┌────────────────┼────────────────┐
              │                │                │
       ┌──────▼──────┐  ┌─────▼──────┐  ┌─────▼──────┐
       │  Clanker    │  │   Zora     │  │  Flaunch   │
       │  Module     │  │   Module   │  │  Module    │
       └─────────────┘  └────────────┘  └────────────┘
```

**Benefícios:**
- ✅ Modularidade - Adicionar novos protocolos sem refactor
- ✅ Separação de concerns - Cada módulo é independente
- ✅ Testabilidade - Testar cada módulo isoladamente
- ✅ Upgradeability - Trocar módulos sem afetar o hub
- ✅ Gas efficiency - Usuário só paga pelo que usa

---

## 📁 Estrutura de Arquivos

```
contracts/
├── core/
│   ├── UniversalClaimHub.sol          # Hub principal
│   ├── IClaimModule.sol                # Interface dos módulos
│   └── ClaimHubStorage.sol             # Storage pattern
│
├── modules/
│   ├── ClankerModule.sol               # Clanker (já existe)
│   ├── ZoraModule.sol                  # Zora claiming
│   ├── FlaunchModule.sol               # Flaunch claiming
│   ├── MintClubModule.sol              # Mint Club
│   ├── AerodromeModule.sol             # Aerodrome LP
│   └── UniswapModule.sol               # Uniswap V3/V4
│
├── libraries/
│   ├── SafeTransfer.sol                # Safe ERC20 transfers
│   ├── GasOptimizer.sol                # Gas optimization helpers
│   └── ProtocolHelpers.sol             # Common helpers
│
├── interfaces/
│   ├── IClankerFeeLocker.sol
│   ├── IZoraToken.sol
│   ├── IFlaunchToken.sol
│   └── ... (outros protocolos)
│
└── utils/
    ├── ReentrancyGuard.sol
    └── Pausable.sol
```

---

## 🔷 Contratos Core

### 1. UniversalClaimHub.sol

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "./IClaimModule.sol";
import "./ClaimHubStorage.sol";
import "../utils/ReentrancyGuard.sol";
import "../utils/Pausable.sol";

/**
 * @title UniversalClaimHub
 * @notice Hub central para batch claiming de múltiplos protocolos
 * @dev Arquitetura modular usando módulos plugáveis
 */
contract UniversalClaimHub is ClaimHubStorage, ReentrancyGuard, Pausable {

    // ========== EVENTOS ==========

    event ModuleRegistered(Protocol indexed protocol, address indexed module);
    event ModuleUpdated(Protocol indexed protocol, address indexed oldModule, address indexed newModule);
    event BatchClaimExecuted(
        address indexed user,
        Protocol[] protocols,
        uint256 totalTokensClaimed,
        uint256 gasUsed
    );
    event SingleClaimExecuted(
        address indexed user,
        Protocol indexed protocol,
        address indexed token,
        uint256 amount
    );

    // ========== ENUMS ==========

    enum Protocol {
        CLANKER_V4,
        CLANKER_V31,
        CLANKER_V3,
        ZORA,
        FLAUNCH,
        MINT_CLUB,
        AERODROME,
        UNISWAP_V3,
        UNISWAP_V4
    }

    // ========== STRUCTS ==========

    struct ClaimRequest {
        Protocol protocol;
        address[] tokens;
        bytes extraData; // Dados específicos do protocolo
    }

    struct ClaimResult {
        Protocol protocol;
        address token;
        uint256 amount;
        bool success;
        string errorMessage;
    }

    struct ProtocolStats {
        uint256 totalClaims;
        uint256 totalAmount;
        uint256 totalUsers;
        bool isActive;
    }

    // ========== STATE VARIABLES ==========

    // Mapping: Protocol => Module Address
    mapping(Protocol => address) public protocolModules;

    // Mapping: Protocol => Stats
    mapping(Protocol => ProtocolStats) public protocolStats;

    // Mapping: User => Protocol => Total Claimed
    mapping(address => mapping(Protocol => uint256)) public userClaimedByProtocol;

    // Mapping: User => Total Claims Count
    mapping(address => uint256) public userTotalClaims;

    // Owner
    address public owner;

    // Fee configuration (opcional, para revenue model)
    uint256 public platformFeePercent; // Basis points (0-10000)
    address public feeCollector;

    // ========== MODIFIERS ==========

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    modifier validProtocol(Protocol protocol) {
        require(protocolModules[protocol] != address(0), "Protocol not supported");
        require(protocolStats[protocol].isActive, "Protocol not active");
        _;
    }

    // ========== CONSTRUCTOR ==========

    constructor(address _feeCollector, uint256 _platformFeePercent) {
        owner = msg.sender;
        feeCollector = _feeCollector;
        platformFeePercent = _platformFeePercent; // e.g., 50 = 0.5%
    }

    // ========== EXTERNAL FUNCTIONS ==========

    /**
     * @notice Batch claim de múltiplos protocolos em uma transação
     * @param requests Array de requests, um por protocolo
     * @return results Array de resultados para cada claim
     */
    function batchClaimMultiProtocol(ClaimRequest[] calldata requests)
        external
        nonReentrant
        whenNotPaused
        returns (ClaimResult[] memory results)
    {
        uint256 startGas = gasleft();
        uint256 totalRequests = requests.length;
        require(totalRequests > 0 && totalRequests <= 10, "Invalid requests count");

        results = new ClaimResult[](totalRequests);
        Protocol[] memory protocolsUsed = new Protocol[](totalRequests);
        uint256 totalTokensClaimed = 0;

        for (uint256 i = 0; i < totalRequests;) {
            ClaimRequest calldata request = requests[i];
            protocolsUsed[i] = request.protocol;

            // Validar protocolo
            if (protocolModules[request.protocol] == address(0) ||
                !protocolStats[request.protocol].isActive) {
                results[i] = ClaimResult({
                    protocol: request.protocol,
                    token: address(0),
                    amount: 0,
                    success: false,
                    errorMessage: "Protocol not supported or inactive"
                });
                unchecked { ++i; }
                continue;
            }

            // Executar claim via módulo
            try this._executeModuleClaim(request) returns (ClaimResult memory result) {
                results[i] = result;

                if (result.success) {
                    totalTokensClaimed += result.amount;

                    // Atualizar stats
                    protocolStats[request.protocol].totalClaims++;
                    protocolStats[request.protocol].totalAmount += result.amount;
                    userClaimedByProtocol[msg.sender][request.protocol] += result.amount;
                }
            } catch Error(string memory reason) {
                results[i] = ClaimResult({
                    protocol: request.protocol,
                    token: address(0),
                    amount: 0,
                    success: false,
                    errorMessage: reason
                });
            } catch {
                results[i] = ClaimResult({
                    protocol: request.protocol,
                    token: address(0),
                    amount: 0,
                    success: false,
                    errorMessage: "Unknown error"
                });
            }

            unchecked { ++i; }
        }

        // Atualizar user stats
        userTotalClaims[msg.sender]++;

        uint256 gasUsed = startGas - gasleft();

        emit BatchClaimExecuted(
            msg.sender,
            protocolsUsed,
            totalTokensClaimed,
            gasUsed
        );

        return results;
    }

    /**
     * @notice Claim de um único protocolo (mais gas eficiente)
     * @param protocol Protocolo a claimar
     * @param tokens Array de tokens
     * @param extraData Dados extras (opcional)
     */
    function claimSingleProtocol(
        Protocol protocol,
        address[] calldata tokens,
        bytes calldata extraData
    )
        external
        nonReentrant
        whenNotPaused
        validProtocol(protocol)
        returns (ClaimResult[] memory results)
    {
        ClaimRequest memory request = ClaimRequest({
            protocol: protocol,
            tokens: tokens,
            extraData: extraData
        });

        ClaimRequest[] memory requests = new ClaimRequest[](1);
        requests[0] = request;

        return batchClaimMultiProtocol(requests);
    }

    /**
     * @dev Executa claim em um módulo específico (função interna pública para try-catch)
     */
    function _executeModuleClaim(ClaimRequest calldata request)
        external
        returns (ClaimResult memory)
    {
        require(msg.sender == address(this), "Only self-call");

        IClaimModule module = IClaimModule(protocolModules[request.protocol]);

        return module.executeClaim(
            msg.sender,
            request.tokens,
            request.extraData
        );
    }

    // ========== VIEW FUNCTIONS ==========

    /**
     * @notice Ver total claimable de um usuário em todos os protocolos
     * @param user Endereço do usuário
     * @param protocolsToCheck Array de protocolos a verificar
     * @return totalClaimable Total disponível para claim
     */
    function getTotalClaimable(address user, Protocol[] calldata protocolsToCheck)
        external
        view
        returns (uint256 totalClaimable)
    {
        for (uint256 i = 0; i < protocolsToCheck.length;) {
            Protocol protocol = protocolsToCheck[i];

            if (protocolModules[protocol] != address(0) &&
                protocolStats[protocol].isActive) {

                IClaimModule module = IClaimModule(protocolModules[protocol]);
                totalClaimable += module.getClaimableAmount(user, new address[](0));
            }

            unchecked { ++i; }
        }

        return totalClaimable;
    }

    /**
     * @notice Ver estatísticas de um usuário
     */
    function getUserStats(address user)
        external
        view
        returns (
            uint256 totalClaimsMade,
            uint256[] memory claimedByProtocol
        )
    {
        totalClaimsMade = userTotalClaims[user];

        // Retornar claimed amount para cada protocolo
        claimedByProtocol = new uint256[](9); // 9 protocolos
        for (uint256 i = 0; i < 9;) {
            claimedByProtocol[i] = userClaimedByProtocol[user][Protocol(i)];
            unchecked { ++i; }
        }

        return (totalClaimsMade, claimedByProtocol);
    }

    // ========== ADMIN FUNCTIONS ==========

    /**
     * @notice Registrar um novo módulo de protocolo
     */
    function registerModule(Protocol protocol, address moduleAddress)
        external
        onlyOwner
    {
        require(moduleAddress != address(0), "Invalid module address");
        require(protocolModules[protocol] == address(0), "Protocol already registered");

        protocolModules[protocol] = moduleAddress;
        protocolStats[protocol].isActive = true;

        emit ModuleRegistered(protocol, moduleAddress);
    }

    /**
     * @notice Atualizar módulo existente
     */
    function updateModule(Protocol protocol, address newModuleAddress)
        external
        onlyOwner
    {
        require(newModuleAddress != address(0), "Invalid module address");

        address oldModule = protocolModules[protocol];
        require(oldModule != address(0), "Protocol not registered");

        protocolModules[protocol] = newModuleAddress;

        emit ModuleUpdated(protocol, oldModule, newModuleAddress);
    }

    /**
     * @notice Ativar/desativar protocolo
     */
    function setProtocolActive(Protocol protocol, bool active)
        external
        onlyOwner
    {
        require(protocolModules[protocol] != address(0), "Protocol not registered");
        protocolStats[protocol].isActive = active;
    }

    /**
     * @notice Atualizar configuração de fees
     */
    function updateFeeConfig(uint256 newFeePercent, address newFeeCollector)
        external
        onlyOwner
    {
        require(newFeePercent <= 1000, "Fee too high"); // Max 10%
        require(newFeeCollector != address(0), "Invalid collector");

        platformFeePercent = newFeePercent;
        feeCollector = newFeeCollector;
    }

    /**
     * @notice Pausar/despausar contrato
     */
    function setPaused(bool paused) external onlyOwner {
        if (paused) {
            _pause();
        } else {
            _unpause();
        }
    }

    /**
     * @notice Transferir ownership
     */
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Invalid new owner");
        owner = newOwner;
    }
}
```

---

### 2. IClaimModule.sol (Interface)

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/**
 * @title IClaimModule
 * @notice Interface que todos os módulos devem implementar
 */
interface IClaimModule {

    struct ClaimResult {
        Protocol protocol;
        address token;
        uint256 amount;
        bool success;
        string errorMessage;
    }

    enum Protocol {
        CLANKER_V4,
        CLANKER_V31,
        CLANKER_V3,
        ZORA,
        FLAUNCH,
        MINT_CLUB,
        AERODROME,
        UNISWAP_V3,
        UNISWAP_V4
    }

    /**
     * @notice Executar claim de rewards
     * @param user Usuário que está fazendo o claim
     * @param tokens Array de tokens/positions a claimar
     * @param extraData Dados extras específicos do protocolo
     * @return result Resultado do claim
     */
    function executeClaim(
        address user,
        address[] calldata tokens,
        bytes calldata extraData
    ) external returns (ClaimResult memory result);

    /**
     * @notice Ver quantidade claimable para um usuário
     * @param user Endereço do usuário
     * @param tokens Array de tokens a verificar (vazio = todos)
     * @return claimable Total disponível para claim
     */
    function getClaimableAmount(
        address user,
        address[] calldata tokens
    ) external view returns (uint256 claimable);

    /**
     * @notice Descobrir tokens de um usuário neste protocolo
     * @param user Endereço do usuário
     * @return tokens Array de tokens que o usuário criou/possui
     */
    function discoverUserTokens(address user)
        external
        view
        returns (address[] memory tokens);

    /**
     * @notice Informações sobre o protocolo
     * @return name Nome do protocolo
     * @return version Versão do módulo
     * @return protocolAddresses Endereços relevantes do protocolo
     */
    function getProtocolInfo()
        external
        view
        returns (
            string memory name,
            string memory version,
            address[] memory protocolAddresses
        );
}
```

---

## 🔷 Módulos de Protocolos

### 3. ZoraModule.sol (NOVO)

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "../interfaces/IZoraToken.sol";
import "../core/IClaimModule.sol";
import "../utils/ReentrancyGuard.sol";

/**
 * @title ZoraModule
 * @notice Módulo para claiming de creator fees da Zora
 */
contract ZoraModule is IClaimModule, ReentrancyGuard {

    // Endereço do contrato principal da Zora na Base
    address public constant ZORA_FACTORY = 0x...; // TODO: Adicionar endereço real

    // Mapping de tokens conhecidos
    mapping(address => bool) public isZoraToken;

    // Events
    event ZoraFeeClaimed(address indexed user, address indexed token, uint256 amount);

    /**
     * @notice Executar batch claim de fees da Zora
     */
    function executeClaim(
        address user,
        address[] calldata tokens,
        bytes calldata extraData
    )
        external
        override
        nonReentrant
        returns (ClaimResult memory result)
    {
        require(tokens.length > 0, "No tokens provided");

        uint256 totalClaimed = 0;

        for (uint256 i = 0; i < tokens.length;) {
            address token = tokens[i];

            // Verificar se é token Zora válido
            if (!isZoraToken[token]) {
                unchecked { ++i; }
                continue;
            }

            // Claimar fees de creator
            try IZoraToken(token).claimCreatorFees(user) returns (uint256 amount) {
                totalClaimed += amount;
                emit ZoraFeeClaimed(user, token, amount);
            } catch {
                // Continuar para próximo token se falhar
            }

            unchecked { ++i; }
        }

        return ClaimResult({
            protocol: Protocol.ZORA,
            token: address(0), // Múltiplos tokens
            amount: totalClaimed,
            success: totalClaimed > 0,
            errorMessage: totalClaimed > 0 ? "" : "No fees to claim"
        });
    }

    /**
     * @notice Ver fees claimable de Zora
     */
    function getClaimableAmount(
        address user,
        address[] calldata tokens
    )
        external
        view
        override
        returns (uint256 claimable)
    {
        for (uint256 i = 0; i < tokens.length;) {
            if (isZoraToken[tokens[i]]) {
                claimable += IZoraToken(tokens[i]).pendingCreatorFees(user);
            }
            unchecked { ++i; }
        }
        return claimable;
    }

    /**
     * @notice Descobrir tokens Zora de um usuário
     * @dev Precisa de subgraph ou API para implementação completa
     */
    function discoverUserTokens(address user)
        external
        view
        override
        returns (address[] memory tokens)
    {
        // TODO: Implementar com subgraph ou cache
        // Por enquanto, retorna array vazio
        return new address[](0);
    }

    /**
     * @notice Info do protocolo
     */
    function getProtocolInfo()
        external
        pure
        override
        returns (
            string memory name,
            string memory version,
            address[] memory protocolAddresses
        )
    {
        name = "Zora";
        version = "1.0.0";
        protocolAddresses = new address[](1);
        protocolAddresses[0] = ZORA_FACTORY;

        return (name, version, protocolAddresses);
    }

    /**
     * @notice Admin: Registrar token Zora
     */
    function registerZoraToken(address token) external {
        // TODO: Adicionar access control
        isZoraToken[token] = true;
    }
}
```

---

### 4. FlaunchModule.sol (NOVO)

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "../interfaces/IFlaunchToken.sol";
import "../core/IClaimModule.sol";
import "../utils/ReentrancyGuard.sol";

/**
 * @title FlaunchModule
 * @notice Módulo para claiming de dev fees da Flaunch (Uniswap V4)
 */
contract FlaunchModule is IClaimModule, ReentrancyGuard {

    // FLAY token address
    address public constant FLAY_TOKEN = 0xf1a7000000950c7ad8aff13118bb7ab561a448ee;

    // Events
    event FlaunchFeeClaimed(
        address indexed user,
        address indexed token,
        uint256 amount,
        bool buybackTriggered
    );

    /**
     * @notice Executar batch claim de fees da Flaunch
     * @dev extraData pode conter flag para trigger buyback
     */
    function executeClaim(
        address user,
        address[] calldata tokens,
        bytes calldata extraData
    )
        external
        override
        nonReentrant
        returns (ClaimResult memory result)
    {
        require(tokens.length > 0, "No tokens provided");

        // Decode extraData para ver se deve trigger buyback
        bool triggerBuyback = extraData.length > 0 ? abi.decode(extraData, (bool)) : false;

        uint256 totalClaimed = 0;

        for (uint256 i = 0; i < tokens.length;) {
            address token = tokens[i];

            try IFlaunchToken(token).claimDevFees(user) returns (uint256 amount) {
                totalClaimed += amount;

                // Trigger buyback se solicitado e se threshold atingido
                if (triggerBuyback) {
                    try IFlaunchToken(token).triggerBuyback() {
                        emit FlaunchFeeClaimed(user, token, amount, true);
                    } catch {
                        emit FlaunchFeeClaimed(user, token, amount, false);
                    }
                } else {
                    emit FlaunchFeeClaimed(user, token, amount, false);
                }
            } catch {
                // Continuar para próximo
            }

            unchecked { ++i; }
        }

        return ClaimResult({
            protocol: Protocol.FLAUNCH,
            token: address(0),
            amount: totalClaimed,
            success: totalClaimed > 0,
            errorMessage: totalClaimed > 0 ? "" : "No fees to claim"
        });
    }

    /**
     * @notice Ver fees claimable de Flaunch
     */
    function getClaimableAmount(
        address user,
        address[] calldata tokens
    )
        external
        view
        override
        returns (uint256 claimable)
    {
        for (uint256 i = 0; i < tokens.length;) {
            try IFlaunchToken(tokens[i]).pendingDevFees(user) returns (uint256 amount) {
                claimable += amount;
            } catch {}
            unchecked { ++i; }
        }
        return claimable;
    }

    /**
     * @notice Descobrir tokens Flaunch de um usuário
     */
    function discoverUserTokens(address user)
        external
        view
        override
        returns (address[] memory tokens)
    {
        // TODO: Implementar via subgraph
        return new address[](0);
    }

    /**
     * @notice Info do protocolo
     */
    function getProtocolInfo()
        external
        pure
        override
        returns (
            string memory name,
            string memory version,
            address[] memory protocolAddresses
        )
    {
        name = "Flaunch";
        version = "1.0.0";
        protocolAddresses = new address[](1);
        protocolAddresses[0] = FLAY_TOKEN;

        return (name, version, protocolAddresses);
    }
}
```

---

## 📊 Gas Optimization Strategies

### 1. Unchecked Loops
```solidity
for (uint256 i = 0; i < length;) {
    // ... código ...
    unchecked { ++i; }
}
```

### 2. Calldata vs Memory
```solidity
// Use calldata quando possível
function batchClaim(address[] calldata tokens) external
```

### 3. Short-Circuit Evaluation
```solidity
// Verificações baratas primeiro
if (amount == 0 || !isActive || paused) return;
```

### 4. Batch Operations
```solidity
// Agrupar múltiplas operações em uma transação
// Economiza overhead de transação
```

### 5. Event Indexing
```solidity
// Indexar apenas campos necessários (max 3)
event Claimed(
    address indexed user,
    address indexed token,
    uint256 amount // não indexado
);
```

---

## 🧪 Testing Strategy

### Unit Tests
```solidity
// test/UniversalClaimHub.t.sol
contract UniversalClaimHubTest is Test {

    function testBatchClaimMultiProtocol() public {
        // Setup
        // Execute
        // Assert
    }

    function testGasUsage() public {
        // Benchmark gas para diferentes cenários
    }

    function testFailures() public {
        // Testar edge cases e failures
    }
}
```

### Integration Tests
```solidity
// test/integration/MultiProtocol.t.sol
contract MultiProtocolIntegrationTest is Test {

    function testClankerPlusZora() public {
        // Testar claim de Clanker + Zora juntos
    }

    function testAllProtocols() public {
        // Testar todos os protocolos simultaneamente
    }
}
```

### Fuzz Testing
```solidity
function testFuzz_batchClaim(uint256[] memory amounts) public {
    // Foundry fuzz testing
}
```

---

## 📝 Deploy Script

```solidity
// script/Deploy.s.sol
contract DeployScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // 1. Deploy hub
        UniversalClaimHub hub = new UniversalClaimHub(
            feeCollector,
            platformFee
        );

        // 2. Deploy módulos
        ClankerModule clankerModule = new ClankerModule();
        ZoraModule zoraModule = new ZoraModule();
        FlaunchModule flaunchModule = new FlaunchModule();

        // 3. Registrar módulos
        hub.registerModule(Protocol.CLANKER_V4, address(clankerModule));
        hub.registerModule(Protocol.ZORA, address(zoraModule));
        hub.registerModule(Protocol.FLAUNCH, address(flaunchModule));

        vm.stopBroadcast();

        console.log("UniversalClaimHub:", address(hub));
    }
}
```

---

## ✅ Checklist de Implementação

### Contratos Core
- [ ] UniversalClaimHub.sol
- [ ] IClaimModule.sol interface
- [ ] ClaimHubStorage.sol
- [ ] ReentrancyGuard.sol
- [ ] Pausable.sol

### Módulos
- [ ] ClankerModule (já existe, adaptar)
- [ ] ZoraModule
- [ ] FlaunchModule
- [ ] MintClubModule
- [ ] AerodromeModule
- [ ] UniswapModule

### Interfaces
- [ ] IZoraToken.sol
- [ ] IFlaunchToken.sol
- [ ] Outras interfaces necessárias

### Testing
- [ ] Unit tests (100% coverage)
- [ ] Integration tests
- [ ] Fuzz tests
- [ ] Gas benchmarks
- [ ] Mainnet fork tests

### Deploy
- [ ] Deploy script
- [ ] Verification script
- [ ] Upgrade path (se necessário)

### Documentação
- [ ] NatSpec comments
- [ ] Architecture docs
- [ ] Integration guide
- [ ] Security considerations

---

## 🔐 Security Considerations

### 1. Reentrancy Protection
```solidity
// Usar ReentrancyGuard em todas as funções que fazem external calls
modifier nonReentrant()
```

### 2. Access Control
```solidity
// Owner-only para funções admin
modifier onlyOwner()

// Consider usar OpenZeppelin's AccessControl para roles mais complexas
```

### 3. Input Validation
```solidity
require(tokens.length > 0 && tokens.length <= MAX_BATCH_SIZE, "Invalid length");
require(moduleAddress != address(0), "Invalid address");
```

### 4. Pausability
```solidity
// Poder pausar em caso de emergência
modifier whenNotPaused()
```

### 5. Safe External Calls
```solidity
// Usar try-catch para calls externos
try module.executeClaim(...) returns (ClaimResult memory result) {
    // Handle success
} catch {
    // Handle failure gracefully
}
```

---

## 📚 Recursos

### Foundry
```bash
# Compilar
forge build

# Testar
forge test -vvv

# Deploy
forge script script/Deploy.s.sol --rpc-url base --broadcast --verify

# Gas report
forge test --gas-report
```

### Hardhat Alternative
```bash
npx hardhat compile
npx hardhat test
npx hardhat run scripts/deploy.ts --network base
```

---

**Status:** 🚧 Em Desenvolvimento
**Próximos Passos:** Implementar módulos Zora e Flaunch
