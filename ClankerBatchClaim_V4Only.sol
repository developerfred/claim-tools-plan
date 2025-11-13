// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/// @title Interface do ClankerFeeLocker
interface IClankerFeeLocker {
    function claim(address feeOwner, address token) external;
    function availableFees(address feeOwner, address token) external view returns (uint256);
}

/// @title ClankerBatchClaim
/// @notice Contrato otimizado para fazer claim de múltiplos rewards do Clanker em uma única transação
/// @dev Implementação gas-efficient para a Base Network
contract ClankerBatchClaim {
    
    /// @notice Endereço do ClankerFeeLocker v4.0.0 na Base
    IClankerFeeLocker public constant FEE_LOCKER = IClankerFeeLocker(0xF3622742b1E446D92e45E22923Ef11C2fcD55D68);
    
    /// @notice Evento emitido quando rewards são reclamados com sucesso
    event RewardsClaimed(address indexed user, address[] tokens, uint256[] amounts);
    
    /// @notice Evento emitido quando um claim individual falha
    event ClaimFailed(address indexed user, address indexed token, bytes reason);
    
    /// @notice Estrutura para armazenar informações de rewards não reclamados
    struct UnclaimedReward {
        address token;
        uint256 amount;
    }
    
    /// @notice Consulta rewards não reclamados para múltiplos tokens
    /// @param user Endereço do usuário
    /// @param tokens Array de endereços de tokens para consultar
    /// @return rewards Array com informações dos rewards não reclamados
    function getUnclaimedRewards(
        address user,
        address[] calldata tokens
    ) external view returns (UnclaimedReward[] memory rewards) {
        uint256 length = tokens.length;
        rewards = new UnclaimedReward[](length);
        
        unchecked {
            for (uint256 i; i < length; ++i) {
                rewards[i] = UnclaimedReward({
                    token: tokens[i],
                    amount: FEE_LOCKER.availableFees(user, tokens[i])
                });
            }
        }
    }
    
    /// @notice Consulta apenas tokens com rewards disponíveis
    /// @param user Endereço do usuário
    /// @param tokens Array de endereços de tokens para consultar
    /// @return availableRewards Array apenas com tokens que possuem rewards > 0
    function getAvailableRewards(
        address user,
        address[] calldata tokens
    ) external view returns (UnclaimedReward[] memory availableRewards) {
        uint256 length = tokens.length;
        UnclaimedReward[] memory temp = new UnclaimedReward[](length);
        uint256 count;
        
        unchecked {
            for (uint256 i; i < length; ++i) {
                uint256 amount = FEE_LOCKER.availableFees(user, tokens[i]);
                if (amount > 0) {
                    temp[count++] = UnclaimedReward({
                        token: tokens[i],
                        amount: amount
                    });
                }
            }
        }
        
        // Cria array com tamanho exato
        availableRewards = new UnclaimedReward[](count);
        unchecked {
            for (uint256 i; i < count; ++i) {
                availableRewards[i] = temp[i];
            }
        }
    }
    
    /// @notice Faz claim de rewards de múltiplos tokens em uma única transação
    /// @param tokens Array de endereços de tokens para fazer claim
    /// @return successCount Número de claims bem-sucedidos
    /// @dev Continua executando mesmo se algum claim falhar
    function batchClaim(address[] calldata tokens) 
        external 
        returns (uint256 successCount) 
    {
        uint256 length = tokens.length;
        require(length > 0, "Empty tokens array");
        
        address user = msg.sender;
        uint256[] memory claimedAmounts = new uint256[](length);
        
        unchecked {
            for (uint256 i; i < length; ++i) {
                address token = tokens[i];
                
                // Verifica se há rewards para claim antes de tentar
                uint256 availableAmount = FEE_LOCKER.availableFees(user, token);
                
                if (availableAmount > 0) {
                    try FEE_LOCKER.claim(user, token) {
                        claimedAmounts[i] = availableAmount;
                        ++successCount;
                    } catch (bytes memory reason) {
                        emit ClaimFailed(user, token, reason);
                    }
                }
            }
        }
        
        require(successCount > 0, "No claims succeeded");
        
        emit RewardsClaimed(user, tokens, claimedAmounts);
    }
    
    /// @notice Faz claim de rewards apenas de tokens com saldo disponível
    /// @param tokens Array de endereços de tokens para verificar e fazer claim
    /// @return claimedTokens Array de tokens que tiveram claim bem-sucedido
    /// @return claimedAmounts Array de quantidades reclamadas
    function batchClaimAvailable(address[] calldata tokens) 
        external 
        returns (address[] memory claimedTokens, uint256[] memory claimedAmounts) 
    {
        uint256 length = tokens.length;
        require(length > 0, "Empty tokens array");
        
        address user = msg.sender;
        address[] memory tempTokens = new address[](length);
        uint256[] memory tempAmounts = new uint256[](length);
        uint256 count;
        
        unchecked {
            for (uint256 i; i < length; ++i) {
                address token = tokens[i];
                uint256 availableAmount = FEE_LOCKER.availableFees(user, token);
                
                if (availableAmount > 0) {
                    try FEE_LOCKER.claim(user, token) {
                        tempTokens[count] = token;
                        tempAmounts[count] = availableAmount;
                        ++count;
                    } catch (bytes memory reason) {
                        emit ClaimFailed(user, token, reason);
                    }
                }
            }
        }
        
        require(count > 0, "No rewards to claim");
        
        // Retorna arrays com tamanho exato
        claimedTokens = new address[](count);
        claimedAmounts = new uint256[](count);
        
        unchecked {
            for (uint256 i; i < count; ++i) {
                claimedTokens[i] = tempTokens[i];
                claimedAmounts[i] = tempAmounts[i];
            }
        }
        
        emit RewardsClaimed(user, claimedTokens, claimedAmounts);
    }
    
    /// @notice Faz claim de todos os rewards de um único token
    /// @param token Endereço do token
    /// @return amount Quantidade reclamada
    function claimSingle(address token) 
        external 
        returns (uint256 amount) 
    {
        address user = msg.sender;
        amount = FEE_LOCKER.availableFees(user, token);
        require(amount > 0, "No rewards available");
        
        FEE_LOCKER.claim(user, token);
        
        address[] memory tokens = new address[](1);
        tokens[0] = token;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = amount;
        
        emit RewardsClaimed(user, tokens, amounts);
    }
    
    /// @notice Verifica se um usuário tem rewards disponíveis para um token específico
    /// @param user Endereço do usuário
    /// @param token Endereço do token
    /// @return amount Quantidade de rewards disponíveis
    function checkRewards(address user, address token) 
        external 
        view 
        returns (uint256 amount) 
    {
        return FEE_LOCKER.availableFees(user, token);
    }
}
