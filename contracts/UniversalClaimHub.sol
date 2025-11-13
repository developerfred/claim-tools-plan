// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/**
 * @title UniversalClaimHub
 * @notice Hub central para batch claiming de múltiplos protocolos na Base Network
 * @author claimtools.xyz
 * @dev Arquitetura modular com suporte para Clanker, Zora, Flaunch, e mais
 */
contract UniversalClaimHub {

    // ========== TYPES ==========

    enum Protocol {
        CLANKER_V4,
        CLANKER_V31,
        CLANKER_V3,
        CLANKER_V2,
        ZORA,
        FLAUNCH,
        MINT_CLUB,
        AERODROME,
        UNISWAP_V3,
        UNISWAP_V4
    }

    struct ClaimRequest {
        Protocol protocol;
        address[] tokens;
        bytes extraData;
    }

    struct ClaimResult {
        Protocol protocol;
        address token;
        uint256 amount;
        bool success;
        string errorMessage;
    }

    struct ProtocolModule {
        address moduleAddress;
        bool isActive;
        uint256 totalClaims;
        uint256 totalAmount;
    }

    // ========== STATE VARIABLES ==========

    address public owner;
    address public feeCollector;
    uint256 public platformFeePercent; // basis points (e.g., 50 = 0.5%)

    // Protocol => Module
    mapping(Protocol => ProtocolModule) public modules;

    // User => Protocol => Total Claimed
    mapping(address => mapping(Protocol => uint256)) public userClaimedByProtocol;

    // User => Total Claims Count
    mapping(address => uint256) public userTotalClaims;

    // Reentrancy guard
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;

    bool public paused;

    // ========== EVENTS ==========

    event ModuleRegistered(Protocol indexed protocol, address indexed moduleAddress);
    event ModuleUpdated(Protocol indexed protocol, address oldModule, address newModule);
    event ProtocolStatusChanged(Protocol indexed protocol, bool isActive);
    event BatchClaimExecuted(
        address indexed user,
        Protocol[] protocols,
        uint256 totalAmount,
        uint256 gasUsed
    );
    event ClaimSuccessful(
        address indexed user,
        Protocol indexed protocol,
        address indexed token,
        uint256 amount
    );
    event ClaimFailed(
        address indexed user,
        Protocol indexed protocol,
        address token,
        string reason
    );
    event FeeCollected(address indexed user, uint256 amount);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event Paused(address account);
    event Unpaused(address account);

    // ========== ERRORS ==========

    error Unauthorized();
    error InvalidProtocol();
    error ProtocolNotActive();
    error InvalidModuleAddress();
    error ReentrancyGuard();
    error ContractPaused();
    error InvalidFeePercent();
    error NoModuleRegistered();
    error InvalidRequestCount();

    // ========== MODIFIERS ==========

    modifier onlyOwner() {
        if (msg.sender != owner) revert Unauthorized();
        _;
    }

    modifier nonReentrant() {
        if (_status == _ENTERED) revert ReentrancyGuard();
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }

    modifier whenNotPaused() {
        if (paused) revert ContractPaused();
        _;
    }

    modifier validProtocol(Protocol protocol) {
        if (modules[protocol].moduleAddress == address(0)) {
            revert NoModuleRegistered();
        }
        if (!modules[protocol].isActive) {
            revert ProtocolNotActive();
        }
        _;
    }

    // ========== CONSTRUCTOR ==========

    constructor(address _feeCollector, uint256 _platformFeePercent) {
        if (_platformFeePercent > 1000) revert InvalidFeePercent(); // Max 10%

        owner = msg.sender;
        feeCollector = _feeCollector;
        platformFeePercent = _platformFeePercent;
        _status = _NOT_ENTERED;

        emit OwnershipTransferred(address(0), msg.sender);
    }

    // ========== EXTERNAL FUNCTIONS ==========

    /**
     * @notice Batch claim de múltiplos protocolos em uma única transação
     * @param requests Array de requests, um por protocolo
     * @return results Array de resultados para cada claim
     */
    function batchClaimMultiProtocol(ClaimRequest[] calldata requests)
        external
        nonReentrant
        whenNotPaused
        returns (ClaimResult[] memory results)
    {
        uint256 requestCount = requests.length;
        if (requestCount == 0 || requestCount > 10) revert InvalidRequestCount();

        uint256 startGas = gasleft();
        results = new ClaimResult[](requestCount);
        uint256 totalAmountClaimed = 0;

        Protocol[] memory protocolsUsed = new Protocol[](requestCount);

        for (uint256 i = 0; i < requestCount;) {
            ClaimRequest calldata request = requests[i];
            protocolsUsed[i] = request.protocol;

            // Validar protocolo
            if (modules[request.protocol].moduleAddress == address(0) ||
                !modules[request.protocol].isActive) {
                results[i] = ClaimResult({
                    protocol: request.protocol,
                    token: address(0),
                    amount: 0,
                    success: false,
                    errorMessage: "Protocol not available"
                });

                unchecked { ++i; }
                continue;
            }

            // Executar claim via módulo
            try this._executeModuleClaim(msg.sender, request) returns (
                ClaimResult memory result
            ) {
                results[i] = result;

                if (result.success && result.amount > 0) {
                    totalAmountClaimed += result.amount;

                    // Atualizar estatísticas
                    modules[request.protocol].totalClaims++;
                    modules[request.protocol].totalAmount += result.amount;
                    userClaimedByProtocol[msg.sender][request.protocol] += result.amount;

                    emit ClaimSuccessful(
                        msg.sender,
                        request.protocol,
                        result.token,
                        result.amount
                    );
                }
            } catch Error(string memory reason) {
                results[i] = ClaimResult({
                    protocol: request.protocol,
                    token: address(0),
                    amount: 0,
                    success: false,
                    errorMessage: reason
                });

                emit ClaimFailed(msg.sender, request.protocol, address(0), reason);
            } catch {
                results[i] = ClaimResult({
                    protocol: request.protocol,
                    token: address(0),
                    amount: 0,
                    success: false,
                    errorMessage: "Unknown error"
                });

                emit ClaimFailed(msg.sender, request.protocol, address(0), "Unknown error");
            }

            unchecked { ++i; }
        }

        // Atualizar contador de claims do usuário
        userTotalClaims[msg.sender]++;

        uint256 gasUsed = startGas - gasleft();

        emit BatchClaimExecuted(msg.sender, protocolsUsed, totalAmountClaimed, gasUsed);

        return results;
    }

    /**
     * @notice Claim de um único protocolo (mais eficiente)
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
        returns (ClaimResult memory result)
    {
        ClaimRequest memory request = ClaimRequest({
            protocol: protocol,
            tokens: tokens,
            extraData: extraData
        });

        ClaimRequest[] memory requests = new ClaimRequest[](1);
        requests[0] = request;

        ClaimResult[] memory results = this.batchClaimMultiProtocol(requests);
        return results[0];
    }

    /**
     * @dev Executa claim em módulo específico (função pública para try-catch)
     * @dev IMPORTANTE: Só pode ser chamada pelo próprio contrato
     */
    function _executeModuleClaim(
        address user,
        ClaimRequest calldata request
    )
        external
        returns (ClaimResult memory)
    {
        if (msg.sender != address(this)) revert Unauthorized();

        IClaimModule module = IClaimModule(modules[request.protocol].moduleAddress);

        return module.executeClaim(user, request.tokens, request.extraData);
    }

    // ========== VIEW FUNCTIONS ==========

    /**
     * @notice Ver total claimable para um usuário em protocolos específicos
     * @param user Endereço do usuário
     * @param protocols Array de protocolos a verificar
     * @return total Total disponível para claim
     */
    function getTotalClaimable(
        address user,
        Protocol[] calldata protocols
    )
        external
        view
        returns (uint256 total)
    {
        for (uint256 i = 0; i < protocols.length;) {
            Protocol protocol = protocols[i];

            if (modules[protocol].moduleAddress != address(0) &&
                modules[protocol].isActive) {

                IClaimModule module = IClaimModule(modules[protocol].moduleAddress);
                total += module.getClaimableAmount(user, new address[](0));
            }

            unchecked { ++i; }
        }

        return total;
    }

    /**
     * @notice Ver estatísticas de um usuário
     * @param user Endereço do usuário
     * @return totalClaims Total de claims feitos
     * @return claimedByProtocol Array com amounts por protocolo
     */
    function getUserStats(address user)
        external
        view
        returns (
            uint256 totalClaims,
            uint256[] memory claimedByProtocol
        )
    {
        totalClaims = userTotalClaims[user];

        // Retornar claimed amount para cada protocolo (10 protocolos)
        claimedByProtocol = new uint256[](10);
        for (uint256 i = 0; i < 10;) {
            claimedByProtocol[i] = userClaimedByProtocol[user][Protocol(i)];
            unchecked { ++i; }
        }

        return (totalClaims, claimedByProtocol);
    }

    /**
     * @notice Ver informações de um módulo
     * @param protocol Protocolo
     * @return moduleAddress Endereço do módulo
     * @return isActive Se está ativo
     * @return totalClaims Total de claims
     * @return totalAmount Total claimed
     */
    function getModuleInfo(Protocol protocol)
        external
        view
        returns (
            address moduleAddress,
            bool isActive,
            uint256 totalClaims,
            uint256 totalAmount
        )
    {
        ProtocolModule memory module = modules[protocol];
        return (
            module.moduleAddress,
            module.isActive,
            module.totalClaims,
            module.totalAmount
        );
    }

    // ========== ADMIN FUNCTIONS ==========

    /**
     * @notice Registrar novo módulo de protocolo
     * @param protocol Protocolo
     * @param moduleAddress Endereço do módulo
     */
    function registerModule(Protocol protocol, address moduleAddress)
        external
        onlyOwner
    {
        if (moduleAddress == address(0)) revert InvalidModuleAddress();
        if (modules[protocol].moduleAddress != address(0)) {
            revert InvalidProtocol(); // Já registrado, use updateModule
        }

        modules[protocol] = ProtocolModule({
            moduleAddress: moduleAddress,
            isActive: true,
            totalClaims: 0,
            totalAmount: 0
        });

        emit ModuleRegistered(protocol, moduleAddress);
    }

    /**
     * @notice Atualizar módulo existente
     * @param protocol Protocolo
     * @param newModuleAddress Novo endereço do módulo
     */
    function updateModule(Protocol protocol, address newModuleAddress)
        external
        onlyOwner
    {
        if (newModuleAddress == address(0)) revert InvalidModuleAddress();
        if (modules[protocol].moduleAddress == address(0)) {
            revert NoModuleRegistered();
        }

        address oldModule = modules[protocol].moduleAddress;
        modules[protocol].moduleAddress = newModuleAddress;

        emit ModuleUpdated(protocol, oldModule, newModuleAddress);
    }

    /**
     * @notice Ativar/desativar protocolo
     * @param protocol Protocolo
     * @param active Novo status
     */
    function setProtocolActive(Protocol protocol, bool active)
        external
        onlyOwner
    {
        if (modules[protocol].moduleAddress == address(0)) {
            revert NoModuleRegistered();
        }

        modules[protocol].isActive = active;
        emit ProtocolStatusChanged(protocol, active);
    }

    /**
     * @notice Atualizar configuração de fees
     * @param newFeePercent Nova porcentagem (basis points)
     * @param newFeeCollector Novo collector
     */
    function updateFeeConfig(uint256 newFeePercent, address newFeeCollector)
        external
        onlyOwner
    {
        if (newFeePercent > 1000) revert InvalidFeePercent(); // Max 10%
        if (newFeeCollector == address(0)) revert InvalidModuleAddress();

        platformFeePercent = newFeePercent;
        feeCollector = newFeeCollector;
    }

    /**
     * @notice Pausar/despausar contrato
     * @param _paused Novo status
     */
    function setPaused(bool _paused) external onlyOwner {
        paused = _paused;

        if (_paused) {
            emit Paused(msg.sender);
        } else {
            emit Unpaused(msg.sender);
        }
    }

    /**
     * @notice Transferir ownership
     * @param newOwner Novo owner
     */
    function transferOwnership(address newOwner) external onlyOwner {
        if (newOwner == address(0)) revert InvalidModuleAddress();

        address oldOwner = owner;
        owner = newOwner;

        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

/**
 * @title IClaimModule
 * @notice Interface que todos os módulos devem implementar
 */
interface IClaimModule {

    enum Protocol {
        CLANKER_V4,
        CLANKER_V31,
        CLANKER_V3,
        CLANKER_V2,
        ZORA,
        FLAUNCH,
        MINT_CLUB,
        AERODROME,
        UNISWAP_V3,
        UNISWAP_V4
    }

    struct ClaimResult {
        Protocol protocol;
        address token;
        uint256 amount;
        bool success;
        string errorMessage;
    }

    function executeClaim(
        address user,
        address[] calldata tokens,
        bytes calldata extraData
    ) external returns (ClaimResult memory result);

    function getClaimableAmount(
        address user,
        address[] calldata tokens
    ) external view returns (uint256 claimable);

    function discoverUserTokens(address user)
        external
        view
        returns (address[] memory tokens);

    function getProtocolInfo()
        external
        view
        returns (
            string memory name,
            string memory version,
            address[] memory protocolAddresses
        );
}
