# 🐍 SnakeHub V3 LITE — Realistic Street Soccer

Script completo para o jogo **Realistic Street Soccer** (Roblox) com interface **Rayfield de 10 abas**, agora em versão **V3 LITE**: motor reescrito ultra-leve para **celular fraco** (ex: Itel A70), com **teclas reais simuladas + auto-calibração** para as features funcionarem de verdade.

> Sem Key System. Sem dependências de funções específicas de executor. Se o Rayfield falhar, abre uma **Mini UI nativa** automaticamente.

## 🚀 Como usar

### Opção 1 — Loadstring (recomendado)

Cole no seu executor dentro do jogo:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/WhiteXz7/SnakeHub/arena/01a0c6cb-snakehub/SnakeHubV3.lua"))()
```

### Opção 2 — Colar o código

Abra o arquivo [`SnakeHubV3.lua`](SnakeHubV3.lua), copie tudo, cole no executor e execute.

### Primeiros passos (importante)

1. O **Detector automático do Explorer** inicia sozinho e indexa os objetos visíveis ao cliente; aperte **DIAGNÓSTICO** para ver o resultado
2. Se a bola não for encontrada: fique perto dela e aperte **TRAVAR BOLA**
3. No **Delta**, o padrão é **VIM somente**: os botões emitem input PC virtual, sem remote; ajuste o mapeamento em **Ajustes → Entrada real (Delta / VIM)** se o jogo usar outras teclas
4. Para reescanear após o campo carregar: aba **Início** → **DETECTAR TUDO DO EXPLORER**
5. O botão **CALIBRAR REMOTE** é apenas para o modo legado; não é necessário no modo VIM
6. Travando? Aba **Ajustes** → **ANTI-LAG ULTRA** ou **MODO ITEL A70**

### Controles

| Plataforma | Abrir/fechar menu | Chute instantâneo |
|---|---|---|
| 🖥️ PC | `RightShift` (configurável) | Tecla `G` (configurável) |
| 📱 Mobile | Botão flutuante verde `S` | Botão flutuante vermelho `CHUTE` |

Os botões flutuantes podem ser **arrastados** para qualquer lugar da tela.

## 📑 As 10 abas

| # | Aba | Conteúdo |
|---|---|---|
| 1 | 🏠 **Início** | Ativação rápida do Top 1 Global, botão de pânico, Anti-AFK, Server Hop |
| 2 | ⚽ **Auto Shoot** | Chute automático 99% (força máxima, curva/normal aleatório, campo inteiro até do escanteio), botão CHUTAR AGORA, Aim Lock, Power Shot |
| 3 | 🌀 **Auto Drible** | Drible perfeito anti-roubo (já vem configurado), estilos, escudo corporal |
| 4 | 🛡️ **Auto Tackle** | Bote limpo sem falta (já vem configurado), interceptação de passes |
| 5 | 🤸 **Auto Actions** | Bicicleta, cabeceio, voleio/chapa e cavadinha automáticos + botões manuais |
| 6 | 🧤 **Goleiro GK** | Auto dive, defesa legit OP, soco/afasta bola e mergulhos manuais |
| 7 | 👑 **Top 1 Global** | Modo 100%: liga tudo + movimento PRO + espelho de movimento avançado. Você joga normal, o script eleva seu nível |
| 8 | 🔓 **Unlock All** | Cards, chuteiras, dribles, luvas, Copa do Mundo, diárias, quests, códigos e coleta de itens |
| 9 | ⚡ **Partida** | Stamina infinita, velocidade, sem tremor de câmera, pular comemoração, FPS Boost, faceoff/pênalti auto, times, teleportes, ESP |
| 10 | ⚙️ **Ajustes** | Teclas (PC), botões flutuantes (mobile), notificações, unload |

## 🎯 Precisão

- **Autos individuais:** 99% de acerto com erro humano simulado (parece legítimo)
- **Modo Top 1 Global:** 100% (mira cravada, reação 0ms)

## ⚠️ Aviso

Use por sua conta e risco. O uso de exploits pode resultar em punição dentro do jogo. Recomenda-se testar em conta alternativa.

## ⚡ Novidades da V3 LITE

- **Motor 12Hz por evento** (antes: 60Hz com varreduras pesadas) — 5x mais leve, FPS adaptativo
- **Adaptador VIM para Delta**: botões do hub enviam input PC configurável (Mouse1/Q/E/X/F/Space) e o padrão é **VIM somente**, sem RemoteEvent nas ações mapeadas
- **Mapeamento configurável**: escolha no Rayfield qual tecla/clique PC corresponde a chute, drible, tackle, mergulho, power shot e passe; a calibração de remote ficou como modo legado opcional
- **Anti-lag**: modo ULTRA, modo Batata, sem chapéus, Mini UI nativa, modo ITEL A70 em 1 toque
- **Diagnóstico na tela** + botões de teste em cada feature + trava manual da bola
- **À prova de erros**: motor protegido por pcall total, cada aba isolada
- **Botão exclusivo AUTO SHOOT**: semitransparente, aparece sozinho ao iniciar, liga/desliga + chuta
- **Detector automático do Explorer**: inicia sozinho, percorre toda a árvore visível ao cliente, seleciona candidatos locais de bola/gols, atualiza os remotes já conhecidos e pode salvar um snapshot TXT ao reescanear
- **99% travado em tudo** (sem teleporte na bola)

## 📁 Arquivos

- [`SnakeHubV3.lua`](SnakeHubV3.lua) — script principal (10 abas, versão LITE recomendada)
- [`SnakeHubV2.lua`](SnakeHubV2.lua) — versão anterior (mantida para referência)
- `SnakeHubV1` — primeira versão (mantida para referência)
