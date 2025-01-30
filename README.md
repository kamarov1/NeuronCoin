# ⚡ Neuron Network (NRN)

<div align="center">
  <img src="./neuro.pjg" alt="Neuron Logo" width="200"/>
  
  [![Avalanche Node](https://img.shields.io/badge/Avalanche-Node%20Ready-red)](https://avax.network)
  [![Whitepaper](https://img.shields.io/badge/Whitepaper-v1.0-blue)](https://github.com/neuron-network/docs/blob/main/whitepaper.md)
  [![Miner Version](https://img.shields.io/badge/Miner-v2.1.0-green)](https://github.com/neuron-network/miner)

  **A Primeira Criptomoeda para Mineração Justa em CPUs**
</div>

---

## 📌 Índice Rápido
- [Arquitetura Técnica](#-arquitetura-técnica)
- [Comece a Minerar](#-comece-a-minerar)
- [Dados da Rede](#-dados-da-rede)
- [Governança](#-governança)
- [Recursos](#-recursos)

---

## 🧠 Arquitetura Técnica

### Consenso Híbrido PoW/PoS

graph LR
A[CPU Miner] --> B{Validação}
B -->|Proof-of-Work| C[RandomX+]
B -->|Proof-of-Stake| D[Staking Pool]
C --> E[Bloco Validado]
D --> E
E --> F[Rede Avalanche]


**Especificações-Chave:**
- Algoritmo: `RandomX+` (RAM-intensive)
- Bloco/2min | Taxa: 0.001 NRN
- Supply: 21M (halving a cada 4 anos)
- Consumo: 85W/CPU (médio)

---

## ⛏️ Comece a Minerar

### Pré-requisitos
- CPU x64 com AES-NI
- 4GB RAM livre
- Linux/Windows 10+

### Passo a Passo
1. **Instale o Minerador Oficial**  

       git clone https://github.com/neuron-network/miner

       cd miner && ./install.sh


3. **Configure sua Carteira**  

       ./neuron-miner --config wallet=YOU

3. **Inicie a Mineração**  

       ./neuron-miner --start --threads $(nproc)


[📘 Guia Completo de Mineração](https://github.com/neuron-network/miner/wiki) |

---

## 📊 Dados da Rede em Tempo Real

| Métrica               | Valor              | Variação 24h |
|-----------------------|--------------------|--------------|
| **Hashrate Total**    | 1.8 PH/s           | ▲ 8.2%       |
| **Mineradores Ativos**| 12,450             | ▼ 1.1%       |
| **Dificuldade**       | 18K                | ▲ 4.7%       |
| **Preço NRN**         | $0.92              | ↗ 3.4%       |


---

## 🗳️ Governança DAO

Participe das decisões do protocolo:

1. Adquira NRN
2. Delegue votos via:

       neuron-cli delegate --wallet YOUR_WALLET --amount 1000


3. Vote em propostas:

       neuron-cli vote --proposal 42 --choice yes


[📜 Regras de Governança](https://docs.neuron.network/governance)

---

## 📚 Recursos Essenciais

<div align="center">

[![Whitepaper](https://img.shields.io/badge/📄-Whitepaper_Technical-blue)](https://github.com/neuron-network/docs/blob/main/whitepaper.md)
[![Documentação](https://img.shields.io/badge/📚-Documentação_Completa-green)](https://docs.neuron.network)
[![YouTube](https://img.shields.io/badge/▶️-Tutoriais_em_Vídeo-red)](https://youtube.com/neuron-network)

</div>

---

## ❓ FAQ

<details>
<summary>Quanto tempo para o primeiro pagamento?</summary>
Pagamentos automáticos ocorrem a cada 100 blocos (~3h). Mínimo de 10 NRN para saque.
</details>

<details>
<summary>Posso minerar com GPU?</summary>
Não. O algoritmo RandomX+ é otimizado exclusivamente para CPUs.
</details>

---

<div align="center">
<sub>Feito com ❤️ por mineradores, para mineradores</sub><br>
<sub>© 2024 Neuron Network | [Relatório de Auditoria](https://audits.neuron.network)</sub>
</div>
