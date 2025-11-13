// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/**
 * @title ZoraModule
 * @notice Módulo para claiming de creator fees da Zora na Base
 * @author claimtools.xyz
 */
contract ZoraModule {

    // ========== CONSTANTS ==========

    // Zora token na Base
    address public constant ZORA_TOKEN = 0x1111111111166b7fe7bd91427724b487980afc69;

    // ========== ENUMS ==========

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

    // ========== STRUCTS ==========

    struct ClaimResult {
        Protocol protocol;
        address token;
        uint256 amount;
        bool success;
        string errorMessage;
    }

    // ========== STATE ==========

    // Mapping de tokens Zora conhecidos
    mapping(address => bool) public isZoraToken;

    address public owner;

    // ========== EVENTS ==========

    event ZoraFeeClaimed(
        address indexed user,
        address indexed token,
        uint256 amount
    );

    event ZoraTokenRegistered(address indexed token);

    // ========== CONSTRUCTOR ==========

    constructor() {
        owner = msg.sender;
    }

    // ========== MODIFIERS ==========

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    // ========== EXTERNAL FUNCTIONS ==========

    /**
     * @notice Executar batch claim de creator fees da Zora
     * @param user Usuário que está fazendo o claim
     * @param tokens Array de tokens Zora
     * @param extraData Dados extras (não usado)
     * @return result Resultado do claim
     */
    function executeClaim(
        address user,
        address[] calldata tokens,
        bytes calldata extraData
    )
        external
        returns (ClaimResult memory result)
    {
        extraData; // Silenciar warning

        if (tokens.length == 0) {
            return ClaimResult({
                protocol: Protocol.ZORA,
                token: address(0),
                amount: 0,
                success: false,
                errorMessage: "No tokens provided"
            });
        }

        uint256 totalClaimed = 0;
        uint256 successCount = 0;

        for (uint256 i = 0; i < tokens.length;) {
            address token = tokens[i];

            // Verificar se é token Zora válido
            if (!isZoraToken[token]) {
                unchecked { ++i; }
                continue;
            }

            // Tentar claimar creator fees
            try IZoraToken(token).claimCreatorFees(user) returns (uint256 amount) {
                if (amount > 0) {
                    totalClaimed += amount;
                    successCount++;

                    emit ZoraFeeClaimed(user, token, amount);
                }
            } catch {
                // Continuar para próximo token se falhar
            }

            unchecked { ++i; }
        }

        return ClaimResult({
            protocol: Protocol.ZORA,
            token: address(0), // Múltiplos tokens
            amount: totalClaimed,
            success: successCount > 0,
            errorMessage: successCount > 0 ? "" : "No fees to claim"
        });
    }

    /**
     * @notice Ver creator fees claimable da Zora
     * @param user Endereço do usuário
     * @param tokens Array de tokens
     * @return claimable Total disponível
     */
    function getClaimableAmount(
        address user,
        address[] calldata tokens
    )
        external
        view
        returns (uint256 claimable)
    {
        for (uint256 i = 0; i < tokens.length;) {
            if (isZoraToken[tokens[i]]) {
                try IZoraToken(tokens[i]).pendingCreatorFees(user) returns (
                    uint256 amount
                ) {
                    claimable += amount;
                } catch {
                    // Token pode não ter essa função
                }
            }

            unchecked { ++i; }
        }

        return claimable;
    }

    /**
     * @notice Descobrir tokens Zora de um usuário
     * @dev Implementar com The Graph ou API
     * @param user Endereço do usuário
     * @return tokens Array vazio (implementar off-chain)
     */
    function discoverUserTokens(address user)
        external
        pure
        returns (address[] memory tokens)
    {
        user; // Silenciar warning
        return new address[](0);
    }

    /**
     * @notice Info do protocolo
     */
    function getProtocolInfo()
        external
        pure
        returns (
            string memory name,
            string memory version,
            address[] memory protocolAddresses
        )
    {
        name = "Zora";
        version = "1.0.0";

        protocolAddresses = new address[](1);
        protocolAddresses[0] = ZORA_TOKEN;

        return (name, version, protocolAddresses);
    }

    // ========== ADMIN FUNCTIONS ==========

    /**
     * @notice Registrar token Zora
     * @param token Endereço do token
     */
    function registerZoraToken(address token) external onlyOwner {
        require(token != address(0), "Invalid token");
        isZoraToken[token] = true;

        emit ZoraTokenRegistered(token);
    }

    /**
     * @notice Registrar múltiplos tokens Zora
     * @param tokens Array de tokens
     */
    function registerZoraTokens(address[] calldata tokens) external onlyOwner {
        for (uint256 i = 0; i < tokens.length;) {
            require(tokens[i] != address(0), "Invalid token");
            isZoraToken[tokens[i]] = true;

            emit ZoraTokenRegistered(tokens[i]);

            unchecked { ++i; }
        }
    }

    /**
     * @notice Transferir ownership
     * @param newOwner Novo owner
     */
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Invalid owner");
        owner = newOwner;
    }
}

// ========== INTERFACES ==========

/**
 * @notice Interface para tokens Zora
 * @dev Interface baseada no padrão Zora (pode precisar ajustes)
 */
interface IZoraToken {
    /**
     * @notice Claim creator fees
     * @param creator Endereço do creator
     * @return amount Amount claimed
     */
    function claimCreatorFees(address creator) external returns (uint256 amount);

    /**
     * @notice Ver pending creator fees
     * @param creator Endereço do creator
     * @return amount Fees pendentes
     */
    function pendingCreatorFees(address creator) external view returns (uint256 amount);
}
