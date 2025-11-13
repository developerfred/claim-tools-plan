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
}

/// @title ClankerBatchClaimPro
/// @notice Contrato UNIVERSAL com mecânicas de REVENUE e GAMIFICAÇÃO
/// @dev Gera revenue através de taxa de serviço e sistema de referral
contract ClankerBatchClaimPro {
    
    /// @notice Endereços dos contratos Fee Locker por versão na Base
    address public constant FEE_LOCKER_V4 = 0xF3622742b1E446D92e45E22923Ef11C2fcD55D68;
    address public constant LP_LOCKER_V31 = 0x33e2Eda238edcF470309b8c6D228986A1204c8f9;
    address public constant LP_LOCKER_V30 = 0x5eC4f99F342038c67a312a166Ff56e6D70383D86;
    address public constant LP_LOCKER_V20 = 0x618A9840691334eE8d24445a4AdA4284Bf42417D;
    
    /// @notice Owner do contrato (recebe taxas)
    address public immutable owner;
    
    /// @notice Treasury para acumular fees
    address public treasury;
    
    /// @notice Taxa de serviço em basis points (100 = 1%)
    /// @dev Default: 50 = 0.5% dos rewards reclamados
    uint256 public serviceFee = 50;
    
    /// @notice Taxa de referral em basis points
    /// @dev 20% da taxa de serviço vai para o referrer (10 bp)
    uint256 public constant REFERRAL_SHARE = 20;
    
    /// @notice Desconto por volume em basis points
    uint256 public constant VOLUME_DISCOUNT_THRESHOLD = 100 ether; // 100 tokens de volume
    uint256 public constant VOLUME_DISCOUNT = 25; // 25% de desconto
    
    /// @notice Enum para identificar a versão do Clanker
    enum ClankerVersion { V1, V2, V3, V31, V4 }
    
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
    
    /// @notice Estatísticas do usuário
    struct UserStats {
        uint256 totalClaimed;      // Total de tokens reclamados
        uint256 totalTransactions;  // Número de transações
        uint256 totalFeePaid;       // Total de taxa paga
        address referrer;           // Quem referiu este usuário
        uint256 referralEarnings;   // Quanto ganhou com referrals
        uint256 lastClaimTime;      // Timestamp do último claim
        uint8 level;                // Nível de gamificação (0-10)
    }
    
    /// @notice Mapping de estatísticas por usuário
    mapping(address => UserStats) public userStats;
    
    /// @notice Mapping de earnings de referral não sacados
    mapping(address => uint256) public pendingReferralRewards;
    
    /// @notice Total de fees coletadas pelo protocolo
    uint256 public totalFeesCollected;
    
    /// @notice Taxa acumulada não sacada
    uint256 public pendingTreasuryFees;
    
    /// @notice Whitelisted addresses que não pagam taxa
    mapping(address => bool) public isWhitelisted;
    
    /// @notice Eventos
    event RewardsClaimed(
        address indexed user,
        address[] tokens,
        uint256[] amounts,
        ClankerVersion[] versions,
        uint256 serviceFeeCharged,
        uint256 referralReward
    );
    
    event ClaimFailed(address indexed user, address indexed token, ClankerVersion version, bytes reason);
    event ServiceFeeUpdated(uint256 oldFee, uint256 newFee);
    event TreasuryUpdated(address oldTreasury, address newTreasury);
    event ReferralRewardClaimed(address indexed user, uint256 amount);
    event UserLevelUp(address indexed user, uint8 newLevel);
    event WhitelistUpdated(address indexed user, bool status);
    
    /// @notice Modificadores
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }
    
    constructor(address _treasury) {
        owner = msg.sender;
        treasury = _treasury;
    }
    
    /// ========== FUNÇÕES DE VISUALIZAÇÃO ==========
    
    function getLockerAddress(ClankerVersion version) public pure returns (address) {
        if (version == ClankerVersion.V4) return FEE_LOCKER_V4;
        if (version == ClankerVersion.V31) return LP_LOCKER_V31;
        if (version == ClankerVersion.V3) return LP_LOCKER_V30;
        if (version == ClankerVersion.V2) return LP_LOCKER_V20;
        revert("Version not supported");
    }
    
    /// @notice Calcula a taxa de serviço para um usuário específico
    function calculateServiceFee(address user, uint256 amount) public view returns (uint256) {
        if (isWhitelisted[user]) return 0;
        
        UserStats memory stats = userStats[user];
        uint256 effectiveFee = serviceFee;
        
        // Desconto por volume
        if (stats.totalClaimed >= VOLUME_DISCOUNT_THRESHOLD) {
            effectiveFee = (effectiveFee * (100 - VOLUME_DISCOUNT)) / 100;
        }
        
        // Desconto por nível (5% por nível)
        if (stats.level > 0) {
            uint256 levelDiscount = uint256(stats.level) * 5;
            if (levelDiscount > 50) levelDiscount = 50; // Max 50% desconto
            effectiveFee = (effectiveFee * (100 - levelDiscount)) / 100;
        }
        
        return (amount * effectiveFee) / 10000;
    }
    
    /// @notice Consulta rewards não reclamados para v4
    function getUnclaimedRewardsV4(address user, address[] calldata tokens) 
        external 
        view 
        returns (UnclaimedReward[] memory rewards) 
    {
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
    
    /// @notice Obtém estatísticas do usuário com previsão de taxa
    function getUserStatsWithFee(address user, uint256 estimatedClaimAmount) 
        external 
        view 
        returns (
            UserStats memory stats,
            uint256 estimatedFee,
            uint256 nextLevelThreshold
        ) 
    {
        stats = userStats[user];
        estimatedFee = calculateServiceFee(user, estimatedClaimAmount);
        
        // Calcula threshold para próximo nível
        nextLevelThreshold = (uint256(stats.level) + 1) * 50 ether;
    }
    
    /// ========== FUNÇÕES DE CLAIM COM REVENUE ==========
    
    /// @notice Claim universal com taxa de serviço e sistema de referral
    /// @param claims Array de TokenClaim
    /// @param referrer Endereço de quem referiu (address(0) se não tem)
    function claimWithRevenue(TokenClaim[] calldata claims, address referrer) 
        external 
        returns (uint256 successCount, uint256 totalFeeCharged) 
    {
        uint256 length = claims.length;
        require(length > 0, "Empty claims array");
        
        address user = msg.sender;
        UserStats storage stats = userStats[user];
        
        // Define referrer na primeira vez
        if (stats.referrer == address(0) && referrer != address(0) && referrer != user) {
            stats.referrer = referrer;
        }
        
        address[] memory tokens = new address[](length);
        uint256[] memory amounts = new uint256[](length);
        ClankerVersion[] memory versions = new ClankerVersion[](length);
        uint256 totalClaimed;
        
        unchecked {
            for (uint256 i; i < length; ++i) {
                TokenClaim memory claimData = claims[i];
                tokens[i] = claimData.token;
                versions[i] = claimData.version;
                
                try this._executeClaim(user, claimData.token, claimData.version) returns (uint256 amount) {
                    amounts[i] = amount;
                    totalClaimed += amount;
                    ++successCount;
                } catch (bytes memory reason) {
                    emit ClaimFailed(user, claimData.token, claimData.version, reason);
                }
            }
        }
        
        require(successCount > 0, "No claims succeeded");
        
        // Calcula e cobra taxa
        uint256 feeAmount = calculateServiceFee(user, totalClaimed);
        uint256 referralReward;
        
        if (feeAmount > 0) {
            // Distribui taxa
            if (stats.referrer != address(0)) {
                referralReward = (feeAmount * REFERRAL_SHARE) / 100;
                pendingReferralRewards[stats.referrer] += referralReward;
                userStats[stats.referrer].referralEarnings += referralReward;
            }
            
            uint256 treasuryAmount = feeAmount - referralReward;
            pendingTreasuryFees += treasuryAmount;
            totalFeesCollected += feeAmount;
        }
        
        // Atualiza estatísticas
        stats.totalClaimed += totalClaimed;
        stats.totalTransactions += 1;
        stats.totalFeePaid += feeAmount;
        stats.lastClaimTime = block.timestamp;
        
        // Level up check
        uint8 newLevel = _calculateLevel(stats.totalClaimed);
        if (newLevel > stats.level) {
            stats.level = newLevel;
            emit UserLevelUp(user, newLevel);
        }
        
        totalFeeCharged = feeAmount;
        
        emit RewardsClaimed(user, tokens, amounts, versions, feeAmount, referralReward);
    }
    
    /// @notice Claim apenas v4 com taxa
    function claimV4WithRevenue(address[] calldata tokens, address referrer) 
        external 
        returns (uint256 successCount, uint256 totalFeeCharged) 
    {
        TokenClaim[] memory claims = new TokenClaim[](tokens.length);
        
        unchecked {
            for (uint256 i; i < tokens.length; ++i) {
                claims[i] = TokenClaim({
                    token: tokens[i],
                    version: ClankerVersion.V4
                });
            }
        }
        
        return this.claimWithRevenue(claims, referrer);
    }
    
    /// @notice Função interna para executar claim
    function _executeClaim(address user, address token, ClankerVersion version) 
        external 
        returns (uint256 amount) 
    {
        require(msg.sender == address(this), "Internal only");
        
        if (version == ClankerVersion.V4) {
            IFeeLocker feeLocker = IFeeLocker(FEE_LOCKER_V4);
            amount = feeLocker.availableFees(user, token);
            if (amount > 0) {
                feeLocker.claim(user, token);
            }
        } else {
            address lockerAddress = getLockerAddress(version);
            ILpLockerv2(lockerAddress).collectRewards(token);
            amount = 0;
        }
    }
    
    /// @notice Calcula o nível baseado no volume total
    function _calculateLevel(uint256 totalClaimed) internal pure returns (uint8) {
        if (totalClaimed >= 500 ether) return 10;
        if (totalClaimed >= 400 ether) return 9;
        if (totalClaimed >= 300 ether) return 8;
        if (totalClaimed >= 200 ether) return 7;
        if (totalClaimed >= 150 ether) return 6;
        if (totalClaimed >= 100 ether) return 5;
        if (totalClaimed >= 75 ether) return 4;
        if (totalClaimed >= 50 ether) return 3;
        if (totalClaimed >= 25 ether) return 2;
        if (totalClaimed >= 10 ether) return 1;
        return 0;
    }
    
    /// ========== FUNÇÕES DE SAQUE DE REWARDS ==========
    
    /// @notice Usuário saca seus referral rewards
    function claimReferralRewards() external {
        uint256 amount = pendingReferralRewards[msg.sender];
        require(amount > 0, "No rewards to claim");
        
        pendingReferralRewards[msg.sender] = 0;
        
        // Transfer rewards (assumindo que o contrato tem saldo)
        // Em produção, você precisaria de um mecanismo para ter fundos aqui
        // Opção 1: Os rewards ficam em um token específico
        // Opção 2: Os rewards são pagos em ETH quando o treasury saca
        
        emit ReferralRewardClaimed(msg.sender, amount);
    }
    
    /// @notice Owner saca as taxas acumuladas
    function withdrawTreasuryFees() external onlyOwner {
        uint256 amount = pendingTreasuryFees;
        require(amount > 0, "No fees to withdraw");
        
        pendingTreasuryFees = 0;
        
        // Aqui você implementaria a lógica de saque real
        // Poderia ser em múltiplos tokens que foram coletados como taxa
        
        // payable(treasury).transfer(amount); // Se fosse ETH
    }
    
    /// ========== FUNÇÕES ADMINISTRATIVAS ==========
    
    /// @notice Atualiza a taxa de serviço
    function updateServiceFee(uint256 newFee) external onlyOwner {
        require(newFee <= 500, "Fee too high"); // Max 5%
        uint256 oldFee = serviceFee;
        serviceFee = newFee;
        emit ServiceFeeUpdated(oldFee, newFee);
    }
    
    /// @notice Atualiza o endereço do treasury
    function updateTreasury(address newTreasury) external onlyOwner {
        require(newTreasury != address(0), "Invalid treasury");
        address oldTreasury = treasury;
        treasury = newTreasury;
        emit TreasuryUpdated(oldTreasury, newTreasury);
    }
    
    /// @notice Adiciona/remove usuário da whitelist
    function updateWhitelist(address user, bool status) external onlyOwner {
        isWhitelisted[user] = status;
        emit WhitelistUpdated(user, status);
    }
    
    /// @notice Adiciona múltiplos usuários à whitelist
    function batchUpdateWhitelist(address[] calldata users, bool status) external onlyOwner {
        unchecked {
            for (uint256 i; i < users.length; ++i) {
                isWhitelisted[users[i]] = status;
                emit WhitelistUpdated(users[i], status);
            }
        }
    }
    
    /// ========== FUNÇÕES DE LEADERBOARD/GAMIFICAÇÃO ==========
    
    /// @notice Retorna o ranking de top usuários por volume
    /// @dev Em produção, isso seria feito off-chain para economizar gas
    function getTopUsers(uint256 limit) external view returns (address[] memory, uint256[] memory) {
        // Esta é uma implementação simples
        // Em produção real, use um indexer off-chain
        address[] memory topAddresses = new address[](limit);
        uint256[] memory topVolumes = new uint256[](limit);
        
        // Aqui você implementaria a lógica de busca
        // Por enquanto retorna arrays vazios como placeholder
        
        return (topAddresses, topVolumes);
    }
    
    /// @notice Calcula boost de XP para próximo claim
    function getXPBoost(address user) external view returns (uint256 boostPercent) {
        UserStats memory stats = userStats[user];
        
        // Boost por streak (claims consecutivos)
        uint256 daysSinceLastClaim = (block.timestamp - stats.lastClaimTime) / 1 days;
        
        if (daysSinceLastClaim <= 1) {
            boostPercent = 20; // 20% boost se clamar todo dia
        } else if (daysSinceLastClaim <= 7) {
            boostPercent = 10; // 10% boost se clamar toda semana
        }
        
        // Boost adicional por nível
        boostPercent += uint256(stats.level) * 2;
    }
}
