// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/**
 * @title ClankerModule
 * @notice Módulo para claiming de fees do Clanker (v1-v4)
 * @author claimtools.xyz
 */
contract ClankerModule {

    // ========== CONSTANTS ==========

    // Clanker v4.0 - ClankerFeeLocker (atual)
    address public constant FEE_LOCKER_V4 = 0xF3622742b1E446D92e45E22923Ef11C2fcD55D68;

    // Clanker v3.1 - LpLockerv2
    address public constant LP_LOCKER_V31 = 0x33e2Eda238edcF470309b8c6D228986A1204c8f9;

    // Clanker v3.0 - LpLockerv2
    address public constant LP_LOCKER_V30 = 0x5eC4f99F342038c67a312a166Ff56e6D70383D86;

    // Clanker v2.0 - LpLockerv2
    address public constant LP_LOCKER_V20 = 0x618A9840691334eE8d24445a4AdA4284Bf42417D;

    // ========== ENUMS ==========

    enum ClankerVersion {
        V4,
        V31,
        V3,
        V2
    }

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

    struct TokenVersion {
        address token;
        ClankerVersion version;
    }

    // ========== EVENTS ==========

    event ClankerClaimed(
        address indexed user,
        address indexed token,
        ClankerVersion version,
        uint256 amount
    );

    // ========== EXTERNAL FUNCTIONS ==========

    /**
     * @notice Executar batch claim de fees do Clanker
     * @param user Usuário que está fazendo o claim
     * @param tokens Array de endereços de tokens
     * @param extraData Versões dos tokens (encoded TokenVersion[])
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
                protocol: Protocol.CLANKER_V4,
                token: address(0),
                amount: 0,
                success: false,
                errorMessage: "No tokens provided"
            });
        }

        // Decode versões dos tokens
        TokenVersion[] memory tokenVersions;
        if (extraData.length > 0) {
            tokenVersions = abi.decode(extraData, (TokenVersion[]));
        }

        uint256 totalClaimed = 0;
        uint256 successCount = 0;

        // Iterar por cada token
        for (uint256 i = 0; i < tokens.length;) {
            address token = tokens[i];
            ClankerVersion version = ClankerVersion.V4; // Default

            // Se versões foram fornecidas, usar a versão correta
            if (tokenVersions.length > 0) {
                for (uint256 j = 0; j < tokenVersions.length;) {
                    if (tokenVersions[j].token == token) {
                        version = tokenVersions[j].version;
                        break;
                    }
                    unchecked { ++j; }
                }
            }

            // Claimar baseado na versão
            uint256 claimed = _claimByVersion(user, token, version);

            if (claimed > 0) {
                totalClaimed += claimed;
                successCount++;

                emit ClankerClaimed(user, token, version, claimed);
            }

            unchecked { ++i; }
        }

        return ClaimResult({
            protocol: Protocol.CLANKER_V4,
            token: address(0), // Múltiplos tokens
            amount: totalClaimed,
            success: successCount > 0,
            errorMessage: successCount > 0 ? "" : "No fees claimed"
        });
    }

    /**
     * @notice Ver fees claimable de Clanker
     * @param user Endereço do usuário
     * @param tokens Array de tokens (se vazio, retorna 0)
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
            // V4 tem função view, outros não
            try IClankerFeeLockerV4(FEE_LOCKER_V4).pendingFees(tokens[i], user)
                returns (uint256 amount)
            {
                claimable += amount;
            } catch {
                // V3.x e anteriores não têm view function
            }

            unchecked { ++i; }
        }

        return claimable;
    }

    /**
     * @notice Descobrir tokens Clanker de um usuário
     * @dev Precisa de indexador off-chain (The Graph)
     * @param user Endereço do usuário
     * @return tokens Array vazio (implementar com The Graph)
     */
    function discoverUserTokens(address user)
        external
        pure
        returns (address[] memory tokens)
    {
        // TODO: Implementar com The Graph subgraph
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
        name = "Clanker";
        version = "1.0.0";

        protocolAddresses = new address[](4);
        protocolAddresses[0] = FEE_LOCKER_V4;
        protocolAddresses[1] = LP_LOCKER_V31;
        protocolAddresses[2] = LP_LOCKER_V30;
        protocolAddresses[3] = LP_LOCKER_V20;

        return (name, version, protocolAddresses);
    }

    // ========== INTERNAL FUNCTIONS ==========

    /**
     * @dev Claimar fees baseado na versão do Clanker
     */
    function _claimByVersion(
        address user,
        address token,
        ClankerVersion version
    )
        internal
        returns (uint256 claimed)
    {
        if (version == ClankerVersion.V4) {
            return _claimV4(user, token);
        } else if (version == ClankerVersion.V31) {
            return _claimV31(user, token);
        } else if (version == ClankerVersion.V3) {
            return _claimV3(user, token);
        } else if (version == ClankerVersion.V2) {
            return _claimV2(user, token);
        }

        return 0;
    }

    /**
     * @dev Claim Clanker v4
     */
    function _claimV4(address user, address token) internal returns (uint256) {
        try IClankerFeeLockerV4(FEE_LOCKER_V4).claimFees(token, user) returns (
            uint256 amount
        ) {
            return amount;
        } catch {
            return 0;
        }
    }

    /**
     * @dev Claim Clanker v3.1
     */
    function _claimV31(address user, address token) internal returns (uint256) {
        try ILpLockerV2(LP_LOCKER_V31).claimFees(token, user) {
            // V3.1 não retorna amount, assumir sucesso
            return 1; // Placeholder
        } catch {
            return 0;
        }
    }

    /**
     * @dev Claim Clanker v3.0
     */
    function _claimV3(address user, address token) internal returns (uint256) {
        try ILpLockerV2(LP_LOCKER_V30).claimFees(token, user) {
            return 1; // Placeholder
        } catch {
            return 0;
        }
    }

    /**
     * @dev Claim Clanker v2.0
     */
    function _claimV2(address user, address token) internal returns (uint256) {
        try ILpLockerV2(LP_LOCKER_V20).claimFees(token, user) {
            return 1; // Placeholder
        } catch {
            return 0;
        }
    }
}

// ========== INTERFACES ==========

/**
 * @notice Interface para Clanker v4 FeeLocker
 */
interface IClankerFeeLockerV4 {
    function claimFees(address token, address feeOwner) external returns (uint256);
    function pendingFees(address token, address feeOwner) external view returns (uint256);
}

/**
 * @notice Interface para Clanker v3.x LpLockerv2
 */
interface ILpLockerV2 {
    function claimFees(address token, address user) external;
}
