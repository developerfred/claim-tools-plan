// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/**
 * @title FlaunchModule
 * @notice Módulo para claiming de dev fees da Flaunch (Uniswap V4)
 * @author claimtools.xyz
 */
contract FlaunchModule {

    // ========== CONSTANTS ==========

    // FLAY token na Base
    address public constant FLAY_TOKEN = 0xf1a7000000950c7ad8aff13118bb7ab561a448ee;

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

    // ========== EVENTS ==========

    event FlaunchFeeClaimed(
        address indexed user,
        address indexed token,
        uint256 amount,
        bool buybackTriggered
    );

    // ========== EXTERNAL FUNCTIONS ==========

    /**
     * @notice Executar batch claim de dev fees da Flaunch
     * @param user Usuário que está fazendo o claim
     * @param tokens Array de tokens Flaunch
     * @param extraData Flag para trigger buyback (bool encoded)
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
        if (tokens.length == 0) {
            return ClaimResult({
                protocol: Protocol.FLAUNCH,
                token: address(0),
                amount: 0,
                success: false,
                errorMessage: "No tokens provided"
            });
        }

        // Decode flag de buyback
        bool triggerBuyback = false;
        if (extraData.length > 0) {
            triggerBuyback = abi.decode(extraData, (bool));
        }

        uint256 totalClaimed = 0;
        uint256 successCount = 0;

        for (uint256 i = 0; i < tokens.length;) {
            address token = tokens[i];

            // Tentar claimar dev fees
            try IFlaunchToken(token).claimDevFees(user) returns (uint256 amount) {
                if (amount > 0) {
                    totalClaimed += amount;
                    successCount++;

                    // Tentar trigger buyback se solicitado
                    bool buybackDone = false;
                    if (triggerBuyback) {
                        try IFlaunchToken(token).triggerBuyback() {
                            buybackDone = true;
                        } catch {
                            // Buyback pode falhar se threshold não atingido
                        }
                    }

                    emit FlaunchFeeClaimed(user, token, amount, buybackDone);
                }
            } catch {
                // Continuar para próximo token se falhar
            }

            unchecked { ++i; }
        }

        return ClaimResult({
            protocol: Protocol.FLAUNCH,
            token: address(0), // Múltiplos tokens
            amount: totalClaimed,
            success: successCount > 0,
            errorMessage: successCount > 0 ? "" : "No fees to claim"
        });
    }

    /**
     * @notice Ver dev fees claimable da Flaunch
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
            try IFlaunchToken(tokens[i]).pendingDevFees(user) returns (
                uint256 amount
            ) {
                claimable += amount;
            } catch {
                // Token pode não ter essa função ou não ser Flaunch
            }

            unchecked { ++i; }
        }

        return claimable;
    }

    /**
     * @notice Descobrir tokens Flaunch de um usuário
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
        name = "Flaunch";
        version = "1.0.0";

        protocolAddresses = new address[](1);
        protocolAddresses[0] = FLAY_TOKEN;

        return (name, version, protocolAddresses);
    }
}

// ========== INTERFACES ==========

/**
 * @notice Interface para tokens Flaunch
 * @dev Interface baseada na documentação Flaunch (pode precisar ajustes)
 */
interface IFlaunchToken {
    /**
     * @notice Claim dev fees
     * @param developer Endereço do developer
     * @return amount Amount claimed
     */
    function claimDevFees(address developer) external returns (uint256 amount);

    /**
     * @notice Ver pending dev fees
     * @param developer Endereço do developer
     * @return amount Fees pendentes
     */
    function pendingDevFees(address developer) external view returns (uint256 amount);

    /**
     * @notice Trigger buyback automático
     * @dev Só funciona se threshold (0.1 ETH em fees) foi atingido
     */
    function triggerBuyback() external;

    /**
     * @notice Ver se pode trigger buyback
     * @return canTrigger True se threshold atingido
     */
    function canTriggerBuyback() external view returns (bool canTrigger);
}
