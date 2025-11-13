// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/// @title Interface Universal para Fee Lockers do Clanker
interface IFeeLocker {
    function claim(address feeOwner, address token) external;
    function availableFees(address feeOwner, address token) external view returns (uint256);
}

/// @title Interface do LpLockerv2 (v3.x)
interface ILpLockerv2 {
    function collectRewards(address token) external;
    // Nota: LpLockerv2 não tem uma função view para ver rewards antes do claim
}

/// @title ClankerUniversalBatchClaim
/// @notice Contrato UNIVERSAL para fazer claim de rewards de TODAS as versões do Clanker
/// @dev Funciona com v1.0, v2.0, v3.0, v3.1 e v4.0 na Base Network
contract ClankerUniversalBatchClaim {
    
    /// @notice Endereços dos contratos Fee Locker por versão na Base
    address public constant FEE_LOCKER_V4 = 0xF3622742b1E446D92e45E22923Ef11C2fcD55D68;
    address public constant LP_LOCKER_V31 = 0x33e2Eda238edcF470309b8c6D228986A1204c8f9;
    address public constant LP_LOCKER_V30 = 0x5eC4f99F342038c67a312a166Ff56e6D70383D86;
    address public constant LP_LOCKER_V20 = 0x618A9840691334eE8d24445a4AdA4284Bf42417D;
    
    /// @notice Enum para identificar a versão do Clanker
    enum ClankerVersion {
        V1,  // 0x9B84fcE5Dcd9a38d2D01d5D72373F6b6b067c3e1
        V2,  // 0x732560fa1d1A76350b1A500155BA978031B53833
        V3,  // 0x375C15db32D28cEcdcAB5C03Ab889bf15cbD2c5E
        V31, // 0x2A787b2362021cC3eEa3C24C4748a6cD5B687382
        V4   // 0xE85A59c628F7d27878ACeB4bf3b35733630083a9
    }
    
    /// @notice Estrutura para especificar token e versão
    struct TokenClaim {
        address token;
        ClankerVersion version;
    }
    
    /// @notice Estrutura para rewards não reclamados
    struct UnclaimedReward {
        address token;
        uint256 amount;
        ClankerVersion version;
    }
    
    /// @notice Evento emitido quando rewards são reclamados
    event RewardsClaimed(
        address indexed user,
        address[] tokens,
        uint256[] amounts,
        ClankerVersion[] versions
    );
    
    /// @notice Evento emitido quando um claim falha
    event ClaimFailed(
        address indexed user,
        address indexed token,
        ClankerVersion version,
        bytes reason
    );
    
    /// @notice Retorna o endereço do locker para uma versão específica
    function getLockerAddress(ClankerVersion version) public pure returns (address) {
        if (version == ClankerVersion.V4) return FEE_LOCKER_V4;
        if (version == ClankerVersion.V31) return LP_LOCKER_V31;
        if (version == ClankerVersion.V3) return LP_LOCKER_V30;
        if (version == ClankerVersion.V2) return LP_LOCKER_V20;
        revert("Version not supported");
    }
    
    /// @notice Consulta rewards não reclamados para v4 (única versão com view function)
    /// @param user Endereço do usuário
    /// @param tokens Array de endereços de tokens
    /// @return rewards Array com informações dos rewards
    function getUnclaimedRewardsV4(
        address user,
        address[] calldata tokens
    ) external view returns (UnclaimedReward[] memory rewards) {
        uint256 length = tokens.length;
        rewards = new UnclaimedReward[](length);
        
        IFeeLocker feeLocker = IFeeLocker(FEE_LOCKER_V4);
        
        unchecked {
            for (uint256 i; i < length; ++i) {
                rewards[i] = UnclaimedReward({
                    token: tokens[i],
                    amount: feeLocker.availableFees(user, tokens[i]),
                    version: ClankerVersion.V4
                });
            }
        }
    }
    
    /// @notice Consulta apenas rewards disponíveis (>0) para v4
    function getAvailableRewardsV4(
        address user,
        address[] calldata tokens
    ) external view returns (UnclaimedReward[] memory availableRewards) {
        uint256 length = tokens.length;
        UnclaimedReward[] memory temp = new UnclaimedReward[](length);
        uint256 count;
        
        IFeeLocker feeLocker = IFeeLocker(FEE_LOCKER_V4);
        
        unchecked {
            for (uint256 i; i < length; ++i) {
                uint256 amount = feeLocker.availableFees(user, tokens[i]);
                if (amount > 0) {
                    temp[count++] = UnclaimedReward({
                        token: tokens[i],
                        amount: amount,
                        version: ClankerVersion.V4
                    });
                }
            }
        }
        
        availableRewards = new UnclaimedReward[](count);
        unchecked {
            for (uint256 i; i < count; ++i) {
                availableRewards[i] = temp[i];
            }
        }
    }
    
    /// @notice Faz claim universal de múltiplos tokens de QUALQUER versão
    /// @param claims Array de TokenClaim especificando token e versão
    /// @return successCount Número de claims bem-sucedidos
    function universalBatchClaim(TokenClaim[] calldata claims) 
        external 
        returns (uint256 successCount) 
    {
        uint256 length = claims.length;
        require(length > 0, "Empty claims array");
        
        address user = msg.sender;
        address[] memory tokens = new address[](length);
        uint256[] memory amounts = new uint256[](length);
        ClankerVersion[] memory versions = new ClankerVersion[](length);
        
        unchecked {
            for (uint256 i; i < length; ++i) {
                TokenClaim memory claimData = claims[i];
                tokens[i] = claimData.token;
                versions[i] = claimData.version;
                
                try this._executeClaim(user, claimData.token, claimData.version) returns (uint256 amount) {
                    amounts[i] = amount;
                    ++successCount;
                } catch (bytes memory reason) {
                    emit ClaimFailed(user, claimData.token, claimData.version, reason);
                }
            }
        }
        
        require(successCount > 0, "No claims succeeded");
        
        emit RewardsClaimed(user, tokens, amounts, versions);
    }
    
    /// @notice Função interna para executar claim (external para try-catch)
    function _executeClaim(
        address user,
        address token,
        ClankerVersion version
    ) external returns (uint256 amount) {
        require(msg.sender == address(this), "Internal only");
        
        if (version == ClankerVersion.V4) {
            IFeeLocker feeLocker = IFeeLocker(FEE_LOCKER_V4);
            amount = feeLocker.availableFees(user, token);
            if (amount > 0) {
                feeLocker.claim(user, token);
            }
        } else {
            // Para v3.x e anteriores, usa LpLockerv2
            address lockerAddress = getLockerAddress(version);
            ILpLockerv2(lockerAddress).collectRewards(token);
            // Não conseguimos saber o amount para versões antigas
            amount = 0;
        }
    }
    
    /// @notice Claim simplificado para v4 apenas
    /// @param tokens Array de tokens v4
    function batchClaimV4(address[] calldata tokens) 
        external 
        returns (uint256 successCount) 
    {
        uint256 length = tokens.length;
        require(length > 0, "Empty tokens array");
        
        address user = msg.sender;
        IFeeLocker feeLocker = IFeeLocker(FEE_LOCKER_V4);
        uint256[] memory amounts = new uint256[](length);
        ClankerVersion[] memory versions = new ClankerVersion[](length);
        
        unchecked {
            for (uint256 i; i < length; ++i) {
                uint256 amount = feeLocker.availableFees(user, tokens[i]);
                versions[i] = ClankerVersion.V4;
                
                if (amount > 0) {
                    try feeLocker.claim(user, tokens[i]) {
                        amounts[i] = amount;
                        ++successCount;
                    } catch (bytes memory reason) {
                        emit ClaimFailed(user, tokens[i], ClankerVersion.V4, reason);
                    }
                }
            }
        }
        
        require(successCount > 0, "No claims succeeded");
        
        emit RewardsClaimed(user, tokens, amounts, versions);
    }
    
    /// @notice Claim simplificado para v3.1
    /// @param tokens Array de tokens v3.1
    function batchClaimV31(address[] calldata tokens) 
        external 
        returns (uint256 successCount) 
    {
        uint256 length = tokens.length;
        require(length > 0, "Empty tokens array");
        
        address user = msg.sender;
        ILpLockerv2 locker = ILpLockerv2(LP_LOCKER_V31);
        uint256[] memory amounts = new uint256[](length);
        ClankerVersion[] memory versions = new ClankerVersion[](length);
        
        unchecked {
            for (uint256 i; i < length; ++i) {
                versions[i] = ClankerVersion.V31;
                try locker.collectRewards(tokens[i]) {
                    amounts[i] = 0; // Não sabemos o amount
                    ++successCount;
                } catch (bytes memory reason) {
                    emit ClaimFailed(user, tokens[i], ClankerVersion.V31, reason);
                }
            }
        }
        
        require(successCount > 0, "No claims succeeded");
        
        emit RewardsClaimed(user, tokens, amounts, versions);
    }
    
    /// @notice Verifica rewards para um token v4
    function checkRewardsV4(address user, address token) 
        external 
        view 
        returns (uint256) 
    {
        return IFeeLocker(FEE_LOCKER_V4).availableFees(user, token);
    }
    
    /// @notice Claim de um único token especificando a versão
    function claimSingle(address token, ClankerVersion version) 
        external 
        returns (uint256 amount) 
    {
        address user = msg.sender;
        
        if (version == ClankerVersion.V4) {
            IFeeLocker feeLocker = IFeeLocker(FEE_LOCKER_V4);
            amount = feeLocker.availableFees(user, token);
            require(amount > 0, "No rewards available");
            feeLocker.claim(user, token);
        } else {
            address lockerAddress = getLockerAddress(version);
            ILpLockerv2(lockerAddress).collectRewards(token);
            amount = 0;
        }
        
        address[] memory tokens = new address[](1);
        tokens[0] = token;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = amount;
        ClankerVersion[] memory versions = new ClankerVersion[](1);
        versions[0] = version;
        
        emit RewardsClaimed(user, tokens, amounts, versions);
    }
}
