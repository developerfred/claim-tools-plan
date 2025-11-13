# 🎯 Qual Contrato Devo Usar?

## Resposta Rápida

**Use `ClankerUniversalBatchClaim.sol`** se você tem tokens de diferentes versões do Clanker.

**Use `ClankerBatchClaim_V4Only.sol`** se você APENAS tem tokens v4.0 (deployados após Julho 2025).

## 📊 Comparação

| Aspecto | Universal | V4 Only |
|---------|-----------|---------|
| **Versões suportadas** | v1.0, v2.0, v3.0, v3.1, v4.0 | Apenas v4.0 |
| **Visualizar rewards** | Apenas v4 | ✅ Todos |
| **Gas** | Moderado | ⚡ Otimizado |
| **Complexidade** | Média | Simples |
| **Quando usar** | Tokens mistos | Só tokens novos |

## 🔍 Como Descobrir a Versão do Meu Token?

### Método 1: Verificar pela data de deployment

1. Vá no Basescan: `https://basescan.org/token/[SEU_TOKEN]`
2. Veja a data de criação do contrato:
   - **Após Julho 2025**: v4.0 ✅
   - **Março-Julho 2025**: v3.1
   - **Nov 2024-Mar 2025**: v3.0
   - **Antes de Nov 2024**: v2.0 ou v1.0

### Método 2: Usar a API do Clanker

```bash
curl https://api.clanker.world/tokens/0xSEU_TOKEN_ADDRESS
```

A resposta incluirá o campo `version`.

### Método 3: Verificar qual Factory deployou

No Basescan, procure pelo evento `TokenCreated` e veja qual contrato emitiu:

- `0xE85A59c628F7d27878ACeB4bf3b35733630083a9` → v4.0 ✅
- `0x2A787b2362021cC3eEa3C24C4748a6cD5B687382` → v3.1
- `0x375C15db32D28cEcdcAB5C03Ab889bf15cbD2c5E` → v3.0
- `0x732560fa1d1A76350b1A500155BA978031B53833` → v2.0

## 💡 Exemplo de Decisão

### Cenário 1: Você deployou 3 tokens em Setembro 2025
✅ **Use: `ClankerBatchClaim_V4Only.sol`**
- Todos são v4.0
- Máxima eficiência de gas
- Pode visualizar todos os rewards

### Cenário 2: Você tem 5 tokens, 2 de Abril 2025 e 3 de Agosto 2025
✅ **Use: `ClankerUniversalBatchClaim.sol`**
- Mix de v3.1 (Abril) e v4.0 (Agosto)
- Claim todos de uma vez
- Especifica versão de cada token

### Cenário 3: Você não tem certeza das versões
✅ **Use: `ClankerUniversalBatchClaim.sol`**
- Funciona com qualquer versão
- Mais seguro
- Pequeno custo extra de gas

## 🚀 Deploy Rápido

### Para V4 Only:
```bash
forge create --rpc-url https://mainnet.base.org \
  --private-key $PRIVATE_KEY \
  --verify \
  src/ClankerBatchClaim_V4Only.sol:ClankerBatchClaim
```

### Para Universal:
```bash
forge create --rpc-url https://mainnet.base.org \
  --private-key $PRIVATE_KEY \
  --verify \
  src/ClankerUniversalBatchClaim.sol:ClankerUniversalBatchClaim
```

## 📋 Checklist de Deploy

- [ ] Identifiquei as versões dos meus tokens
- [ ] Escolhi o contrato adequado
- [ ] Testei na Base Sepolia primeiro (opcional mas recomendado)
- [ ] Deploy na Base Mainnet
- [ ] Verifiquei o contrato no Basescan
- [ ] Testei com 1 token pequeno primeiro
- [ ] Integrei no meu frontend

## 🆘 Ainda em Dúvida?

**Regra de Ouro**: Na dúvida, use o **Universal**. Funciona com tudo!

A diferença de gas entre os dois é pequena (~10-20%) e vale a pena pela tranquilidade de saber que funciona com qualquer token do Clanker.

## 📞 Suporte

- [Documentação Clanker](https://clanker.gitbook.io/)
- [Discord do Clanker](https://discord.gg/clanker)
- [Basescan](https://basescan.org)
