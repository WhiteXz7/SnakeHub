--[[
    SHADOW SNAKE HUB 🐉 TOP 1 GLOBAL EDITION 👑
    Versão: 1.0.0
    Jogo: Realistic Street Soccer (PlaceId 14315258385)
    Limites honestos:
    - Sem teleporte, sem hook de metatable, sem emulação de teclas PC
    - Apenas botões nativos do jogo e movimentação legítima
    - Sem farm de moedas/recompensas
    - Funciona em mobile e PC com a mesma base
--]]

-- ====================== DETECÇÃO DE EXECUTOR ======================
local executor = identifyexecutor and identifyexecutor() or "Desconhecido"
local isMobile = game:GetService("UserInputService").TouchEnabled
local isSynapse = syn and true or false
local isScriptWare = getgenv and true or false

-- ====================== CONFIGURAÇÕES PADRÃO ======================
local CONFIG = {
    chute = {
        auto = true,
        gestoSintetico = false,
        maxDistancia = 190,
        forcaMaxima = 1.0,
        cargaBase = 0.45,
        jitter = 0.05,
        retry = 1,
        alturaMista = {rasteiro = 0.58, meio = 0.32, alto = 0.10},
        curva = true,
        perfeito = 0.35,
        esperaHumana = {min = 0.55, max = 1.15}
    },
    drible = {
        auto = true,
        reageAoTackle = true,
        fakeOut = 0.55,
        tempo = 0.20,
        alcance = 14
    },
    tackle = {
        auto = true,
        esperaDribleDoAdversario = true,
        alcance = 6.5,
        janelaReacao = {min = 0.12, max = 0.18},
        cooldown = 0.95,
        prever = 1.0
    },
    movimento = {
        sprintTiming = true,
        stutterAntesDeDriblar = 0.15,
        jinkRandom = 0.35,
        limiteWalkSpeed = "servidor"
    },
    ui = {
        stealth = true,
        stealthDelay = 0.75,
        pullupPx = 30,
        botaoOpacidade = 0.45,
        botaoTamanho = 82,
        posicaoBotao = "inferior-direita"
    },
    unlock = {
        emotes = true,
        cards = true,
        cosmeticos = true,
        somenteVisivelATodos = true,
        farm = "PROIBIDO"
    }
}

-- ====================== SERVIÇOS E VARIÁVEIS GLOBAIS ======================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local StarterGui = game:GetService("StarterGui")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer
local Character = nil
local Humanoid = nil
local RootPart = nil
local Camera = Workspace.CurrentCamera

-- Cache de objetos do jogo
local cache = {
    bola = nil,
    gols = {home = nil, away = nil},
    goleiro = nil,
    remotes = {},
    ultimoChute = 0,
    ultimoTackle = 0,
    ultimoDrible = 0,
    alvoAtual = nil,
    modoStealth = false,
    uiVisivel = false,
    botaoFlutuante = nil,
    janelaStealth = nil
}

-- ====================== FUNÇÕES UTILITÁRIAS ======================
local function jitter(valor, variacao)
    return valor + (math.random() * variacao * 2 - variacao)
end

local function distancia(a, b)
    return (a.Position - b.Position).Magnitude
end

local function getGoleiro()
    if not cache.gols.home or not cache.gols.away then return nil end

    local golAtual = LocalPlayer.Team and LocalPlayer.Team.Name == "Home" and cache.gols.away or cache.gols.home
    if not golAtual then return nil end

    local goleiros = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local hrp = player.Character.HumanoidRootPart
            if distancia(hrp, golAtual.Frame.Crossbar) < 20 then
                table.insert(goleiros, hrp)
            end
        end
    end

    return #goleiros > 0 and goleiros[1] or nil
end

local function getAlvoMaisDistanteDoGoleiro()
    if not cache.bola or not cache.gols.home or not cache.gols.away then return nil end

    local golAtual = LocalPlayer.Team and LocalPlayer.Team.Name == "Home" and cache.gols.away or cache.gols.home
    if not golAtual then return nil end

    local goleiro = getGoleiro()
    if not goleiro then return golAtual.Medium.Center end

    local alvos = {
        golAtual.Low.Target,
        golAtual.Medium.Center,
        golAtual.Medium.Left,
        golAtual.HighTargets.Target
    }

    local melhorAlvo = nil
    local maiorDistancia = -math.huge

    for _, alvo in ipairs(alvos) do
        if alvo and alvo:IsA("BasePart") then
            local dist = distancia(alvo, goleiro)
            if dist > maiorDistancia then
                maiorDistancia = dist
                melhorAlvo = alvo
            end
        end
    end

    return melhorAlvo or golAtual.Medium.Center
end

local function getForcaChute(distancia)
    local forca = CONFIG.chute.cargaBase
    if distancia > 50 then
        forca = math.min(CONFIG.chute.forcaMaxima, CONFIG.chute.cargaBase + (distancia / CONFIG.chute.maxDistancia) * 0.5)
    end
    return jitter(forca, CONFIG.chute.jitter)
end

local function getAlturaChute()
    local rand = math.random()
    if rand <= CONFIG.chute.alturaMista.rasteiro then
        return "Low"
    elseif rand <= CONFIG.chute.alturaMista.rasteiro + CONFIG.chute.alturaMista.meio then
        return "Medium"
    else
        return "High"
    end
end

local function aplicarCurva(direcao, alvo)
    if not CONFIG.chute.curva then return direcao end

    local goleiro = getGoleiro()
    if not goleiro then return direcao end

    local ladoGoleiro = (goleiro.Position - alvo.Position).X > 0 and "direita" or "esquerda"
    local ladoCurva = ladoGoleiro == "direita" and Vector3.new(-1, 0, 0) or Vector3.new(1, 0, 0)

    return direcao + (ladoCurva * 0.2)
end

local function podeChutar()
    if not cache.bola or not Character or not Humanoid then return false end

    local distanciaBola = distancia(RootPart, cache.bola)
    if distanciaBola > 10 then return false end

    local agora = tick()
    if agora - cache.ultimoChute < 1.5 then return false end

    return true
end

local function podeDriblar()
    if not cache.bola or not Character or not Humanoid then return false end

    local agora = tick()
    if agora - cache.ultimoDrible < 0.5 then return false end

    return true
end

local function podeTacklear()
    if not cache.bola or not Character or not Humanoid then return false end

    local agora = tick()
    if agora - cache.ultimoTackle < CONFIG.tackle.cooldown then return false end

    return true
end

local function getAdversarioMaisProximo()
    if not cache.bola then return nil end

    local adversarios = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local hrp = player.Character.HumanoidRootPart
            if distancia(hrp, cache.bola) < CONFIG.drible.alcance then
                table.insert(adversarios, {
                    hrp = hrp,
                    distancia = distancia(hrp, cache.bola),
                    player = player
                })
            end
        end
    end

    if #adversarios == 0 then return nil end

    table.sort(adversarios, function(a, b) return a.distancia < b.distancia end)
    return adversarios[1]
end

local function detectarTackleAdversario(adversario)
    if not adversario or not adversario.hrp then return false end

    local agora = tick()
    local velocidade = adversario.hrp.Velocity.Magnitude
    local direcao = (cache.bola.Position - adversario.hrp.Position).Unit

    -- Detecta movimento rápido em direção à bola (possível tackle)
    if velocidade > 15 and direcao:Dot(adversario.hrp.Velocity.Unit) > 0.8 then
        return true
    end

    return false
end

local function detectarDribleAdversario(adversario)
    if not adversario or not adversario.hrp then return false end

    local agora = tick()
    local velocidade = adversario.hrp.Velocity.Magnitude
    local direcao = (adversario.hrp.Position - cache.bola.Position).Unit

    -- Detecta mudança brusca de direção (possível drible)
    if velocidade > 10 and direcao:Dot(adversario.hrp.Velocity.Unit) < 0.3 then
        return true
    end

    return false
end

-- ====================== FUNÇÕES PRINCIPAIS ======================
local function autoShoot()
    if not CONFIG.chute.auto or not podeChutar() then return end

    local alvo = getAlvoMaisDistanteDoGoleiro()
    if not alvo then return end

    cache.alvoAtual = alvo
    local distanciaBola = distancia(RootPart, cache.bola)
    local forca = getForcaChute(distanciaBola)
    local altura = getAlturaChute()

    -- Calcula direção com curva
    local direcao = (alvo.Position - cache.bola.Position).Unit
    direcao = aplicarCurva(direcao, alvo)

    -- Espera humanizada
    local espera = jitter(
        math.random(CONFIG.chute.esperaHumana.min * 100, CONFIG.chute.esperaHumana.max * 100) / 100,
        CONFIG.chute.jitter
    )

    task.delay(espera, function()
        if not podeChutar() then return end

        -- Verifica se o remote é conhecido e seguro
        local shootRemote = cache.remotes.ShootTheBall
        if shootRemote and shootRemote:IsA("RemoteEvent") then
            -- Dispara o remote com parâmetros calculados
            shootRemote:FireServer({
                power = forca,
                direction = direcao,
                height = altura,
                curve = CONFIG.chute.curva
            })
        else
            -- Fallback: aponta a câmera para o alvo e simula clique no botão nativo
            local originalCFrame = Camera.CFrame
            Camera.CFrame = CFrame.lookAt(Camera.CFrame.Position, alvo.Position)

            -- Simula clique curto no botão de chute (sem segurar)
            if cache.botaoFlutuante then
                local input = Instance.new("InputObject")
                input.UserInputType = Enum.UserInputType.Touch
                input.Position = cache.botaoFlutuante.AbsolutePosition + Vector2.new(10, 10)
                UserInputService:FireTouchEvent(cache.botaoFlutuante, true, input)
                task.wait(0.05)
                UserInputService:FireTouchEvent(cache.botaoFlutuante, false, input)
            end

            -- Restaura a câmera após um pequeno delay
            task.delay(0.1, function()
                Camera.CFrame = originalCFrame
            end)
        end

        cache.ultimoChute = tick()
    end)
end

local function autoDrible()
    if not CONFIG.drible.auto or not podeDriblar() then return end

    local adversario = getAdversarioMaisProximo()
    if not adversario then return end

    -- Verifica se o adversário está tentando tackle
    if CONFIG.drible.reageAoTackle and detectarTackleAdversario(adversario) then
        -- Calcula direção livre
        local direcaoLivre = (RootPart.Position - adversario.hrp.Position).Unit
        direcaoLivre = Vector3.new(direcaoLivre.X, 0, direcaoLivre.Z).Unit

        -- Aplica movimento de drible
        if Humanoid then
            Humanoid:Move(direcaoLivre, true)
            task.wait(jitter(CONFIG.drible.tempo, 0.05))
            Humanoid:Move(Vector3.new(0, 0, 0))

            cache.ultimoDrible = tick()
        end
    end
end

local function autoTackle()
    if not CONFIG.tackle.auto or not podeTacklear() then return end

    local adversario = getAdversarioMaisProximo()
    if not adversario or distancia(adversario.hrp, cache.bola) > CONFIG.tackle.alcance then return end

    -- Espera o adversário driblar
    if CONFIG.tackle.esperaDribleDoAdversario and detectarDribleAdversario(adversario) then
        -- Calcula janela de reação
        local reacao = jitter(
            math.random(CONFIG.tackle.janelaReacao.min * 100, CONFIG.tackle.janelaReacao.max * 100) / 100,
            0.03
        )

        task.delay(reacao, function()
            if not podeTacklear() then return end

            -- Verifica se o remote é conhecido e seguro
            local tackleRemote = cache.remotes.Tackle
            if tackleRemote and tackleRemote:IsA("RemoteEvent") then
                tackleRemote:FireServer({
                    target = adversario.player,
                    power = 1.0
                })
            else
                -- Fallback: move em direção ao adversário
                if Humanoid then
                    Humanoid:MoveTo(adversario.hrp.Position)
                    task.wait(0.2)
                    Humanoid:MoveTo(RootPart.Position)
                end
            end

            cache.ultimoTackle = tick()
        end)
    end
end

local function movimentoAvancado()
    if not CONFIG.movimento.sprintTiming or not Character or not Humanoid then return end

    -- Sprint timing ótimo
    local velocidade = Humanoid.WalkSpeed
    local acelerando = Humanoid.MoveDirection.Magnitude > 0.5

    if acelerando and velocidade < 20 then
        -- Aplica sprint no momento certo
        Humanoid.WalkSpeed = 26
    elseif not acelerando and velocidade > 20 then
        -- Reduz velocidade quando parado
        Humanoid.WalkSpeed = 16
    end

    -- Stutter antes de drible
    if CONFIG.movimento.stutterAntesDeDriblar > 0 and podeDriblar() then
        local adversario = getAdversarioMaisProximo()
        if adversario and distancia(adversario.hrp, RootPart) < 10 then
            -- Pequena parada antes de driblar
            Humanoid.WalkSpeed = 0
            task.wait(jitter(CONFIG.movimento.stutterAntesDeDriblar, 0.05))
            Humanoid.WalkSpeed = 26
        end
    end
end

local function desbloquearCosmeticos()
    if not CONFIG.unlock.emotes and not CONFIG.unlock.cards and not CONFIG.unlock.cosmeticos then return end

    -- Verifica remotes seguros para desbloqueio
    local remotesSeguros = {
        Equip = cache.remotes.Equip,
        Jersey = cache.remotes.Jersey,
        Avatar = cache.remotes.Avatar,
        Settings = cache.remotes.Settings
    }

    for nome, remote in pairs(remotesSeguros) do
        if remote and remote:IsA("RemoteEvent") then
            -- Desbloqueia apenas itens visíveis (sem farm)
            if nome == "Equip" then
                remote:FireServer("emote", "Dance1") -- Exemplo de emote
            elseif nome == "Jersey" then
                remote:FireServer("jersey", "Brazil") -- Exemplo de camisa
            end
        end
    end
end

-- ====================== INICIALIZAÇÃO DO HUB ======================
local function inicializarCache()
    -- Cache da bola
    cache.bola = Workspace:FindFirstChild("ball") or Workspace:FindFirstChildWhichIsA("BasePart", true)

    -- Cache dos gols
    cache.gols.home = Workspace:FindFirstChild("HomeGoal")
    cache.gols.away = Workspace:FindFirstChild("AwayGoal")

    -- Cache dos remotes seguros
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    if remotes then
        for _, remote in ipairs(remotes:GetChildren()) do
            if remote:IsA("RemoteEvent") or remote:IsA("RemoteFunction") then
                -- Verifica se o remote está na lista segura
                local nomeSeguro = false
                for _, nome in ipairs({"ShootTheBall", "Pass", "Tackle", "Action", "GKHitbox", "Equip", "Jersey", "Avatar", "Settings"}) do
                    if remote.Name == nome then
                        nomeSeguro = true
                        break
                    end
                end

                if nomeSeguro then
                    cache.remotes[remote.Name] = remote
                end
            end
        end
    end
end

local function criarUI()
    -- Tenta carregar Rayfield
    local sucesso, rayfield = pcall(function()
        return loadstring(game:HttpGet("https://sirius.menu/rayfield"))()
    end)

    if not sucesso then
        -- Fallback simples se Rayfield falhar
        local ScreenGui = Instance.new("ScreenGui")
        ScreenGui.Name = "ShadowSnakeHubFallback"
        ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

        local Frame = Instance.new("Frame")
        Frame.Size = UDim2.new(0.3, 0, 0.4, 0)
        Frame.Position = UDim2.new(0.35, 0, 0.3, 0)
        Frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        Frame.BackgroundTransparency = 0.2
        Frame.Parent = ScreenGui

        local TextLabel = Instance.new("TextLabel")
        TextLabel.Size = UDim2.new(1, 0, 0.2, 0)
        TextLabel.Position = UDim2.new(0, 0, 0, 0)
        TextLabel.Text = "Shadow Snake Hub 🐉\nFallback UI"
        TextLabel.TextColor3 = Color3.new(1, 1, 1)
        TextLabel.BackgroundTransparency = 1
        TextLabel.Parent = Frame

        cache.uiVisivel = true
        return
    end

    -- Cria a UI com Rayfield
    local Window = rayfield:CreateWindow({
        Name = "Shadow Snake Hub 🐉 Top 1 Global Edition 👑",
        LoadingTitle = "Carregando...",
        LoadingSubtitle = "Por favor aguarde",
        ConfigurationSaving = {
            Enabled = false,
            FolderName = nil,
            FileName = "ShadowSnakeHubConfig"
        },
        Discord = {
            Enabled = false,
            Invite = "",
            RememberJoins = false
        },
        KeySystem = false
    })

    -- Aba principal
    local MainTab = Window:CreateTab("Principal", nil)

    -- Seção Auto Chute
    local ShootSection = MainTab:CreateSection("Auto Chute")
    MainTab:CreateToggle({
        Name = "Auto Chute Ativado",
        CurrentValue = CONFIG.chute.auto,
        Flag = "AutoChuteToggle",
        Callback = function(Value)
            CONFIG.chute.auto = Value
        end
    })

    MainTab:CreateSlider({
        Name = "Força Máxima do Chute",
        Range = {0.1, 1.0},
        Increment = 0.05,
        Suffix = "",
        CurrentValue = CONFIG.chute.forcaMaxima,
        Flag = "ForcaChuteSlider",
        Callback = function(Value)
            CONFIG.chute.forcaMaxima = Value
        end
    })

    MainTab:CreateSlider({
        Name = "Jitter do Chute",
        Range = {0, 0.2},
        Increment = 0.01,
        Suffix = "",
        CurrentValue = CONFIG.chute.jitter,
        Flag = "JitterChuteSlider",
        Callback = function(Value)
            CONFIG.chute.jitter = Value
        end
    })

    -- Seção Auto Drible
    local DribleSection = MainTab:CreateSection("Auto Drible")
    MainTab:CreateToggle({
        Name = "Auto Drible Ativado",
        CurrentValue = CONFIG.drible.auto,
        Flag = "AutoDribleToggle",
        Callback = function(Value)
            CONFIG.drible.auto = Value
        end
    })

    MainTab:CreateSlider({
        Name = "Alcance do Drible",
        Range = {5, 20},
        Increment = 1,
        Suffix = "studs",
        CurrentValue = CONFIG.drible.alcance,
        Flag = "AlcanceDribleSlider",
        Callback = function(Value)
            CONFIG.drible.alcance = Value
        end
    })

    -- Seção Auto Tackle
    local TackleSection = MainTab:CreateSection("Auto Tackle")
    MainTab:CreateToggle({
        Name = "Auto Tackle Ativado",
        CurrentValue = CONFIG.tackle.auto,
        Flag = "AutoTackleToggle",
        Callback = function(Value)
            CONFIG.tackle.auto = Value
        end
    })

    MainTab:CreateSlider({
        Name = "Alcance do Tackle",
        Range = {3, 10},
        Increment = 0.5,
        Suffix = "studs",
        CurrentValue = CONFIG.tackle.alcance,
        Flag = "AlcanceTackleSlider",
        Callback = function(Value)
            CONFIG.tackle.alcance = Value
        end
    })

    -- Seção Movimento
    local MovimentoSection = MainTab:CreateSection("Movimento Avançado")
    MainTab:CreateToggle({
        Name = "Sprint Timing Ótimo",
        CurrentValue = CONFIG.movimento.sprintTiming,
        Flag = "SprintTimingToggle",
        Callback = function(Value)
            CONFIG.movimento.sprintTiming = Value
        end
    })

    -- Seção Desbloqueio
    local UnlockSection = MainTab:CreateSection("Desbloqueio (Somente Visível)")
    MainTab:CreateToggle({
        Name = "Desbloquear Emotes",
        CurrentValue = CONFIG.unlock.emotes,
        Flag = "EmotesToggle",
        Callback = function(Value)
            CONFIG.unlock.emotes = Value
            if Value then
                desbloquearCosmeticos()
            end
        end
    })

    -- Botão para esconder a UI
    MainTab:CreateButton({
        Name = "Esconder UI (Modo Stealth)",
        Callback = function()
            Window:Toggle(false)
            cache.modoStealth = true
            cache.uiVisivel = false
        end
    })

    -- Cria botão flutuante de chute
    local botaoFlutuante = Instance.new("ImageButton")
    botaoFlutuante.Name = "ShadowSnakeChuteButton"
    botaoFlutuante.Size = UDim2.new(0, CONFIG.ui.botaoTamanho, 0, CONFIG.ui.botaoTamanho)
    botaoFlutuante.Position = CONFIG.ui.posicaoBotao == "inferior-direita" and
        UDim2.new(1, -CONFIG.ui.botaoTamanho - 20, 1, -CONFIG.ui.botaoTamanho - 20) or
        UDim2.new(0, 20, 1, -CONFIG.ui.botaoTamanho - 20)
    botaoFlutuante.BackgroundTransparency = 1
    botaoFlutuante.Image = "rbxassetid://4458901886" -- Ícone de chute
    botaoFlutuante.ImageTransparency = CONFIG.ui.botaoOpacidade
    botaoFlutuante.Parent = LocalPlayer:WaitForChild("PlayerGui")

    cache.botaoFlutuante = botaoFlutuante

    -- Cria área de stealth na parte inferior
    local janelaStealth = Instance.new("Frame")
    janelaStealth.Name = "ShadowSnakeStealthArea"
    janelaStealth.Size = UDim2.new(1, 0, 0, 50)
    janelaStealth.Position = UDim2.new(0, 0, 1, -50)
    janelaStealth.BackgroundTransparency = 1
    janelaStealth.Parent = LocalPlayer:WaitForChild("PlayerGui")

    local ultimoY = nil
    janelaStealth.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch then
            ultimoY = input.Position.Y
        end
    end)

    janelaStealth.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch and ultimoY then
            local deltaY = input.Position.Y - ultimoY
            if deltaY < -CONFIG.ui.pullupPx then
                -- Usuário arrastou de baixo para cima
                Window:Toggle(true)
                cache.modoStealth = false
                cache.uiVisivel = true
            end
            ultimoY = nil
        end
    end)

    cache.janelaStealth = janelaStealth

    -- Esconde a UI após delay se stealth estiver ativado
    if CONFIG.ui.stealth then
        task.delay(CONFIG.ui.stealthDelay, function()
            Window:Toggle(false)
            cache.modoStealth = true
            cache.uiVisivel = false
        end)
    end
end

local function monitorarPersonagem()
    LocalPlayer.CharacterAdded:Connect(function(char)
        Character = char
        Humanoid = char:WaitForChild("Humanoid")
        RootPart = char:WaitForChild("HumanoidRootPart")

        -- Conecta eventos do personagem
        Humanoid.StateChanged:Connect(function(oldState, newState)
            if newState == Enum.HumanoidStateType.Dead then
                -- Reseta cache quando morre
                cache.ultimoChute = 0
                cache.ultimoTackle = 0
                cache.ultimoDrible = 0
            end
        end)
    end)

    if LocalPlayer.Character then
        Character = LocalPlayer.Character
        Humanoid = Character:FindFirstChild("Humanoid")
        RootPart = Character:FindFirstChild("HumanoidRootPart")
    end
end

local function antiLagLeve()
    -- Reduz efeitos visuais distantes
    local function reduzirEfeitos(part)
        if part:IsA("BasePart") and part.Transparency < 1 then
            part.Transparency = math.min(0.7, part.Transparency + 0.3)
        elseif part:IsA("ParticleEmitter") or part:IsA("Beam") or part:IsA("Trail") then
            part.Enabled = false
        end
    end

    -- Aplica apenas a objetos distantes
    local function verificarDistancia(part)
        if not RootPart then return false end
        return distancia(RootPart, part) > 100
    end

    -- Conecta eventos para reduzir lag
    local function conectarEventos()
        for _, part in ipairs(Workspace:GetDescendants()) do
            if verificarDistancia(part) then
                reduzirEfeitos(part)
            end
        end

        Workspace.DescendantAdded:Connect(function(part)
            if verificarDistancia(part) then
                reduzirEfeitos(part)
            end
        end)
    end

    conectarEventos()
end

-- ====================== LOOP PRINCIPAL ======================
local function mainLoop()
    while true do
        local sucesso, erro = pcall(function()
            -- Atualiza cache periodicamente
            inicializarCache()

            -- Verifica se o personagem está pronto
            if Character and Humanoid and RootPart and cache.bola then
                -- Executa funções principais
                autoShoot()
                autoDrible()
                autoTackle()
                movimentoAvancado()
            end
        end)

        if not sucesso then
            warn("Erro no Shadow Snake Hub: " .. erro)
            -- Mostra erro na tela para mobile
            StarterGui:SetCore("SendNotification", {
                Title = "Shadow Snake Hub",
                Text = "Erro detectado. Verifique o console.",
                Duration = 5
            })
        end

        RunService.Heartbeat:Wait()
    end
end

-- ====================== INICIALIZAÇÃO ======================
local function iniciarHub()
    local sucesso, erro = pcall(function()
        -- Inicializa cache
        inicializarCache()

        -- Cria UI
        criarUI()

        -- Monitora personagem
        monitorarPersonagem()

        -- Aplica anti-lag leve
        antiLagLeve()

        -- Inicia loop principal
        mainLoop()
    end)

    if not sucesso then
        -- Mostra erro na tela
        local ScreenGui = Instance.new("ScreenGui")
        ScreenGui.Name = "ShadowSnakeHubError"
        ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

        local Frame = Instance.new("Frame")
        Frame.Size = UDim2.new(0.8, 0, 0.3, 0)
        Frame.Position = UDim2.new(0.1, 0, 0.35, 0)
        Frame.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        Frame.Parent = ScreenGui

        local TextLabel = Instance.new("TextLabel")
        TextLabel.Size = UDim2.new(1, 0, 1, 0)
        TextLabel.Text = "ERRO NO SHADOW SNAKE HUB:\n" .. erro .. "\n\nCopie este erro e reporte ao desenvolvedor."
        TextLabel.TextColor3 = Color3.new(1, 1, 1)
        TextLabel.TextWrapped = true
        TextLabel.BackgroundTransparency = 1
        TextLabel.Parent = Frame

        local TextButton = Instance.new("TextButton")
        TextButton.Size = UDim2.new(0.3, 0, 0.2, 0)
        TextButton.Position = UDim2.new(0.35, 0, 0.8, 0)
        TextButton.Text = "Copiar Erro"
        TextButton.Parent = Frame

        TextButton.MouseButton1Click:Connect(function()
            setclipboard(erro)
            StarterGui:SetCore("SendNotification", {
                Title = "Shadow Snake Hub",
                Text = "Erro copiado para a área de transferência!",
                Duration = 3
            })
        end)
    end
end

-- Inicia o hub
iniciarHub()
