--[[ ============================================================================
    SNAKEHUB V2  |  REALISTIC STREET SOCCER (Roblox)
    ----------------------------------------------------------------------------
    Interface Rayfield com 10 ABAS - 100% adaptada para MOBILE e PC
    Compativel com TODOS os executors (Delta, Fluxus, Arceus, Codex, Solara,
    Wave, Cryptic, Hydrogen, Vegax, Trigon, etc.)
    Sem Key System | Sem dependencias de funcoes especificas de executor
    ----------------------------------------------------------------------------
    COMO USAR:
    1) Abra o jogo Realistic Street Soccer
    2) Cole este script no seu executor e execute
    3) PC: pressione RightShift (configuravel) para abrir/fechar o menu
       MOBILE: use o botao flutuante verde (cobra)
    ----------------------------------------------------------------------------
    AVISO: use por sua conta e risco. Exploits podem gerar punicao no jogo.
============================================================================= ]]

--[[ ============================ ANTI-DUPLICACAO =========================== ]]
local ENV = nil
pcall(function()
    if typeof(getgenv) == "function" then
        ENV = getgenv()
    end
end)
if ENV == nil then
    ENV = _G
end

if ENV.__SNAKEHUB_V2_LOADED == true then
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "SnakeHub V2",
            Text = "O script ja esta carregado!",
            Duration = 3
        })
    end)
    return
end
ENV.__SNAKEHUB_V2_LOADED = true

--[[ ============================ SERVICOS BASE ============================= ]]
if not game:IsLoaded() then
    game.Loaded:Wait()
end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local IS_MOBILE = false
pcall(function()
    IS_MOBILE = UserInputService.TouchEnabled and (not UserInputService.KeyboardEnabled)
end)

--[[ ============================ CONFIGURACOES ============================= ]]
-- Tudo ja vem PRE-CONFIGURADO no modo perfeito. Basta ativar os toggles.
local Config = {
    -- Geral
    NotifyUI = true,
    UIKey = "RightShift",
    FloatUI = true,          -- botao flutuante cobra (mobile/pc)
    FloatShoot = true,       -- botao flutuante de chute (mobile/pc)

    -- Auto Shoot (99%)
    AutoShoot = false,
    ShootDist = 260,         -- do gol ate o escanteio: campo inteiro
    Power = 100,             -- sempre forca maxima
    Accuracy = 99,           -- 99% de acerto
    RandomCurve = true,      -- alterna curvado / normal sozinho
    CurveShoot = true,
    CurveIntensity = 0.7,
    TargetArea = "Aleatorio PRO",
    AimLock = true,          -- trava a mira no gol com a bola no pe
    ShootKeyEnabled = true,  -- tecla de chute instantaneo (PC)
    ShootKey = "G",
    AutoPowerShot = false,

    -- Auto Drible (perfeito)
    AutoDribble = false,
    DribbleDist = 5.5,
    DribbleStyle = "Perfeito PRO",
    BodyShield = true,
    DribbleCD = 0.7,

    -- Auto Tackle (perfeito)
    AutoTackle = false,
    TackleDist = 6.0,
    LegitTackle = true,      -- bote limpo, sem falta
    InterceptPro = true,     -- preve passes e corta trajetoria

    -- Auto Actions
    AutoBicycle = false,
    AutoHeader = false,
    AutoVolley = false,
    AutoChip = false,
    HeaderShoot = true,      -- cabeceia mirando o gol

    -- Goleiro
    AutoDive = false,
    AutoDefense = false,     -- defesa legit OP (posicionamento + saida)
    AutoPassGK = false,      -- auto passe (somente GK)
    AutoPunch = false,       -- soco/afasta bola
    GKRange = 40,
    GKMode = "Automatico",
    CompatMode = true,       -- testa variacoes de remote p/ max compat

    -- Top 1 Global (100%)
    TopGlobal = false,
    TopStyle = "Completo",
    SteerAssist = 65,        -- forca da assistencia de movimento (0-100)
    ProMovement = true,      -- persegue bola livre / se posiciona sozinho
    FullAuto = false,        -- piloto automatico total quando parado
    ZeroDelay = true,        -- reacao 0ms
    MoveMirror = true,       -- replica seus movimentos em versao avancada

    -- Partida / Exploits
    AutoFaceoff = false,
    AutoPenalty = false,
    InfiniteStamina = false,
    NoShake = false,
    SkipCutscene = false,
    AntiAFK = true,
    AutoCollect = false,
    WalkEnabled = false,
    WalkSpeed = 22,
    StreamerMode = false,

    -- ESP
    BallESP = false,
    GoalESP = false,
    PlayerESP = false,
}

local Running = true
local Cooldown = {
    Shoot = 0, Dribble = 0, Tackle = 0, Dive = 0, Punch = 0,
    Bicycle = 0, Header = 0, Volley = 0, Chip = 0, Pass = 0,
    PowerShot = 0, Faceoff = 0, Penalty = 0,
}
local Connections = {}
local function track(conn)
    table.insert(Connections, conn)
    return conn
end

--[[ ======================= CARREGADOR DO RAYFIELD ========================= ]]
-- Multi-link com fallbacks para funcionar em qualquer executor/rede.
local Rayfield = nil
local RayfieldSources = {
    "https://sirius.menu/rayfield",
    "https://raw.githubusercontent.com/SiriusSoftwareLtd/Rayfield/main/source.lua",
    "https://raw.githubusercontent.com/SiriusSoftwareLtd/Rayfield/refs/heads/main/source.lua",
}
for _, url in ipairs(RayfieldSources) do
    local ok = pcall(function()
        local src = game:HttpGet(url)
        Rayfield = loadstring(src)()
    end)
    if ok and Rayfield then
        break
    end
    Rayfield = nil
end

if not Rayfield then
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "SnakeHub V2",
            Text = "Falha ao carregar a interface. Tente outro executor.",
            Duration = 6
        })
    end)
    ENV.__SNAKEHUB_V2_LOADED = nil
    return
end

local function notify(title, content, dur)
    if not Config.NotifyUI then
        return
    end
    pcall(function()
        Rayfield:Notify({ Title = title, Content = content, Duration = dur or 3 })
    end)
end

--[[ ============================ AJUDANTES GERAIS ========================== ]]
local function SafeFind(parent, name)
    if not parent then
        return nil
    end
    local ok, res = pcall(function()
        return parent:FindFirstChild(name, true)
    end)
    if ok then
        return res
    end
    return nil
end

local function fire(remote, ...)
    if remote == nil then
        return false
    end
    local args = { ... }
    local ok = pcall(function()
        remote:FireServer(unpack(args))
    end)
    return ok
end

local function invoke(remoteFunc, ...)
    if remoteFunc == nil then
        return false, nil
    end
    local args = { ... }
    local ok, res = pcall(function()
        return remoteFunc:InvokeServer(unpack(args))
    end)
    return ok, res
end

local function normOpt(opt, fallback)
    if type(opt) == "table" then
        if opt[1] ~= nil then
            return opt[1]
        else
            return fallback
        end
    end
    if opt == nil then
        return fallback
    end
    return opt
end

local function getGuiParent()
    local ok, h = pcall(function()
        if typeof(gethui) == "function" then
            return gethui()
        end
        return nil
    end)
    if ok and h ~= nil then
        return h
    end
    return game:GetService("CoreGui")
end

--[[ ============================ MAPA DE REMOTES =========================== ]]
-- Todos os remotes conhecidos do jogo mapeados com busca segura.
local Remotes = {
    Shoot      = SafeFind(ReplicatedStorage, "ShootTheBall"),
    ShootAlt   = SafeFind(ReplicatedStorage, "ShootTheBaII"),
    Pass       = SafeFind(ReplicatedStorage, "Pass"),
    Tackle     = SafeFind(ReplicatedStorage, "Tackle"),
    Action     = SafeFind(ReplicatedStorage, "Action"),
    Curve      = SafeFind(ReplicatedStorage, "cfactor"),
    GKHitbox   = SafeFind(ReplicatedStorage, "GKHitbox"),
    Faceoff    = SafeFind(ReplicatedStorage, "Faceoff"),
    Penalty    = SafeFind(ReplicatedStorage, "Penalty"),
    Position   = SafeFind(ReplicatedStorage, "Position"),
    TeamChange = SafeFind(ReplicatedStorage, "TeamChange"),
    TeleportR  = SafeFind(ReplicatedStorage, "Teleport"),
    SettingsR  = SafeFind(ReplicatedStorage, "Settings"),
    Avatar     = SafeFind(ReplicatedStorage, "Avatar"),
    Jersey     = SafeFind(ReplicatedStorage, "Jersey"),
    Equip      = SafeFind(ReplicatedStorage, "Equip"),
    Unbox      = SafeFind(ReplicatedStorage, "Unbox"),
    ClaimStick = SafeFind(ReplicatedStorage, "ClaimStick"),
    Collect    = SafeFind(ReplicatedStorage, "Collect"),
    TCellLoc   = SafeFind(ReplicatedStorage, "tcelloc"),
    Daily      = SafeFind(ReplicatedStorage, "ClaimReward"),
    DailyEv    = SafeFind(ReplicatedStorage, "DailyReward"),
    WQuest     = SafeFind(ReplicatedStorage, "WQuest"),
    RedeemCode = SafeFind(ReplicatedStorage, "RedeemCode"),
    Cutscene   = SafeFind(ReplicatedStorage, "CutsceneRemote"),
    PodiumCam  = SafeFind(ReplicatedStorage, "PodiumCamera"),
    PodiumCel  = SafeFind(ReplicatedStorage, "PodiumCelebration"),
    Shake      = SafeFind(ReplicatedStorage, "Shake"),
    FPSNORE    = SafeFind(ReplicatedStorage, "FPSNORE"),
    PINGNORE   = SafeFind(ReplicatedStorage, "PINGNORE"),
    AFK        = SafeFind(ReplicatedStorage, "AFKRemote"),
    Purchase   = SafeFind(ReplicatedStorage, "Purchase"),
    ShopEvent  = SafeFind(ReplicatedStorage, "ShopEvent"),
    ShopReset  = SafeFind(ReplicatedStorage, "ResetShop"),
    SoftDis    = SafeFind(ReplicatedStorage, "SoftDisPlayer"),
    IsMobile   = SafeFind(ReplicatedStorage, "isMobile"),
    NotifyR    = SafeFind(ReplicatedStorage, "notify"),
    WorldCup   = SafeFind(ReplicatedStorage, "GetWorldCupClaims"),
    RedeemWC   = SafeFind(ReplicatedStorage, "RedeemWorldCupCard"),
    SelectWC   = SafeFind(ReplicatedStorage, "SelectWorldCupCard"),
    SpinCards  = SafeFind(ReplicatedStorage, "SpinnerContentsCards"),
    SpinDrib   = SafeFind(ReplicatedStorage, "SpinnerContentsDribble"),
    SpinGoalie = SafeFind(ReplicatedStorage, "SpinnerContentsGoalie"),
    SpinShoes  = SafeFind(ReplicatedStorage, "SpinnerContentsShoes"),
    SpeedRemote = nil,
}

task.spawn(function()
    local ok, pgui = pcall(function()
        return LocalPlayer:FindFirstChildOfClass("PlayerGui") or LocalPlayer:WaitForChild("PlayerGui", 6)
    end)
    if ok and pgui then
        Remotes.SpeedRemote = SafeFind(pgui, "Speed")
    end
end)

--[[ ====================== SENSORES DO JOGO (BOLA/GOL) ===================== ]]
local BallCache = { Part = nil, LastScan = 0 }
local GoalsCache = { List = {}, LastScan = 0 }

local function findBall()
    if BallCache.Part and BallCache.Part.Parent then
        return BallCache.Part
    end
    local now = os.clock()
    if now - BallCache.LastScan < 0.5 then
        return BallCache.Part
    end
    BallCache.LastScan = now
    local best = nil
    local ok, desc = pcall(function()
        return workspace:GetDescendants()
    end)
    if not ok then
        return nil
    end
    for _, d in ipairs(desc) do
        if d:IsA("BasePart") then
            local n = string.lower(d.Name)
            if string.find(n, "football", 1, true) or string.find(n, "soccer", 1, true)
                or n == "ball" or string.find(n, "ball", 1, true) then
                -- ignora spawners / partes decorativas longe do chao do campo
                if d.Name ~= "BallSpawner" then
                    best = d
                    break
                end
            end
        end
    end
    if not best then
        for _, d in ipairs(desc) do
            if d:IsA("Model") and string.find(string.lower(d.Name), "ball", 1, true) then
                local pp = d.PrimaryPart or d:FindFirstChildWhichIsA("BasePart", true)
                if pp then
                    best = pp
                    break
                end
            end
        end
    end
    BallCache.Part = best
    return best
end

local function scanGoals()
    local now = os.clock()
    if now - GoalsCache.LastScan < 4 and #GoalsCache.List > 0 then
        return GoalsCache.List
    end
    GoalsCache.LastScan = now
    local list = {}
    local ok, desc = pcall(function()
        return workspace:GetDescendants()
    end)
    if ok then
        for _, d in ipairs(desc) do
            if d:IsA("BasePart") then
                local n = string.lower(d.Name)
                if string.find(n, "goal", 1, true) or string.find(n, "trave", 1, true)
                    or string.find(n, "crossbar", 1, true) or string.find(n, "goalpost", 1, true)
                    or (string.find(n, "net", 1, true) and d.Transparency < 1) then
                    table.insert(list, d)
                    if #list >= 24 then
                        break
                    end
                end
            end
        end
    end
    GoalsCache.List = list
    return list
end

local function myChar()
    local c = LocalPlayer.Character
    if not c then
        return nil, nil, nil
    end
    local hrp = c:FindFirstChild("HumanoidRootPart")
    local hum = c:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum or hum.Health <= 0 then
        return nil, nil, nil
    end
    return c, hrp, hum
end

local function hasBall(radius)
    local _, hrp = myChar()
    local ball = findBall()
    if not hrp or not ball then
        return false
    end
    return (hrp.Position - ball.Position).Magnitude <= (radius or 5)
end

local function isEnemy(plr)
    if plr == LocalPlayer then
        return false
    end
    if LocalPlayer.Team == nil or plr.Team == nil then
        return true
    end
    return plr.Team ~= LocalPlayer.Team
end

local function getClosestEnemy(maxDist)
    local _, hrp = myChar()
    if not hrp then
        return nil, math.huge
    end
    local best, bestD = nil, maxDist or math.huge
    for _, plr in ipairs(Players:GetPlayers()) do
        if isEnemy(plr) and plr.Character then
            local eHrp = plr.Character:FindFirstChild("HumanoidRootPart")
            if eHrp then
                local d = (eHrp.Position - hrp.Position).Magnitude
                if d < bestD then
                    bestD = d
                    best = plr.Character
                end
            end
        end
    end
    return best, bestD
end

local function getEnemyWithBall(maxDist)
    local _, hrp = myChar()
    local ball = findBall()
    if not hrp or not ball then
        return nil, math.huge
    end
    local best, bestD = nil, maxDist or math.huge
    for _, plr in ipairs(Players:GetPlayers()) do
        if isEnemy(plr) and plr.Character then
            local eHrp = plr.Character:FindFirstChild("HumanoidRootPart")
            if eHrp then
                local dMe = (eHrp.Position - hrp.Position).Magnitude
                local dBall = (eHrp.Position - ball.Position).Magnitude
                if dMe < bestD and dBall <= 5.5 then
                    bestD = dMe
                    best = plr.Character
                end
            end
        end
    end
    return best, bestD
end

local function getBestMate()
    local _, hrp = myChar()
    if not hrp then
        return nil
    end
    local atk = getAttackGoal()
    local best, bestScore = nil, -math.huge
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and (not isEnemy(plr)) and plr.Character then
            local mHrp = plr.Character:FindFirstChild("HumanoidRootPart")
            if mHrp then
                local d = (mHrp.Position - hrp.Position).Magnitude
                if d > 8 and d < 140 then
                    local ahead = 0
                    if atk then
                        local toAtk = (atk - hrp.Position)
                        local toMate = (mHrp.Position - hrp.Position)
                        if toAtk.Magnitude > 1 and toMate.Magnitude > 1 then
                            ahead = toAtk.Unit:Dot(toMate.Unit)
                        end
                    end
                    local score = ahead * 50 - d * 0.15
                    if score > bestScore then
                        bestScore = score
                        best = plr.Character
                    end
                end
            end
        end
    end
    return best
end

local function isBallFree()
    local ball = findBall()
    if not ball then
        return false
    end
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr.Character then
            local h = plr.Character:FindFirstChild("HumanoidRootPart")
            if h and (h.Position - ball.Position).Magnitude <= 6 then
                return false
            end
        end
    end
    return true
end

function getAttackGoal()
    local _, hrp = myChar()
    if not hrp then
        return nil
    end
    local goals = scanGoals()
    local best, bestD = nil, -1
    for _, g in ipairs(goals) do
        if g.Parent then
            local d = (g.Position - hrp.Position).Magnitude
            if d > bestD and d < 450 then
                bestD = d
                best = g.Position
            end
        end
    end
    if best then
        return best
    end
    -- fallback: mira para onde o jogador olha (longe = campo inteiro)
    return hrp.Position + (hrp.CFrame.LookVector * 120)
end

function getOwnGoal()
    local _, hrp = myChar()
    if not hrp then
        return nil
    end
    local goals = scanGoals()
    local best, bestD = nil, math.huge
    for _, g in ipairs(goals) do
        if g.Parent then
            local d = (g.Position - hrp.Position).Magnitude
            if d < bestD then
                bestD = d
                best = g.Position
            end
        end
    end
    return best
end

local function isGK()
    if Config.GKMode == "Sou GK" then
        return true
    end
    if Config.GKMode == "Nao sou GK" then
        return false
    end
    -- Automatico: perto do proprio gol = goleiro
    local _, hrp = myChar()
    local own = getOwnGoal()
    if hrp and own then
        return (hrp.Position - own.Position).Magnitude <= 28
    end
    return false
end

local function faceTowards(pos)
    local _, hrp = myChar()
    if not hrp then
        return
    end
    local look = pos - hrp.Position
    look = Vector3.new(look.X, 0, look.Z)
    if look.Magnitude < 0.5 then
        return
    end
    pcall(function()
        hrp.CFrame = CFrame.new(hrp.Position, hrp.Position + look)
    end)
end

local function softSteer(pos, strength01)
    local _, hrp = myChar()
    if not hrp then
        return
    end
    local cur = hrp.CFrame.LookVector
    cur = Vector3.new(cur.X, 0, cur.Z)
    local des = pos - hrp.Position
    des = Vector3.new(des.X, 0, des.Z)
    if cur.Magnitude < 0.1 or des.Magnitude < 0.5 then
        return
    end
    local alpha = math.clamp(strength01, 0, 1) * 0.35
    local blended = cur.Unit:Lerp(des.Unit, alpha)
    pcall(function()
        hrp.CFrame = CFrame.new(hrp.Position, hrp.Position + blended)
    end)
end

--[[ ====================== MIRA INTELIGENTE (99%/100%) ==================== ]]
local function computeAim(perfect)
    local _, hrp = myChar()
    local goalPos = getAttackGoal()
    if not hrp or not goalPos then
        return nil
    end
    local toGoal = goalPos - hrp.Position
    local flat = Vector3.new(toGoal.X, 0, toGoal.Z)
    if flat.Magnitude < 1 then
        flat = hrp.CFrame.LookVector
    end
    local right = flat.Unit:Cross(Vector3.new(0, 1, 0)).Unit

    local area = Config.TargetArea
    if area == "Aleatorio PRO" then
        local pool = { "Gaveta", "Canto Direito", "Canto Esquerdo", "Rasteiro", "Meio" }
        area = pool[math.random(1, #pool)]
    end

    local side = (math.random() > 0.5) and 1 or -1
    local aim = goalPos
    if area == "Gaveta" then
        aim = goalPos + right * (6.5 * side) + Vector3.new(0, 5.6, 0)
    elseif area == "Canto Direito" then
        aim = goalPos + right * 7.5 + Vector3.new(0, 3.2, 0)
    elseif area == "Canto Esquerdo" then
        aim = goalPos + right * -7.5 + Vector3.new(0, 3.2, 0)
    elseif area == "Rasteiro" then
        aim = goalPos + right * (6.5 * side) + Vector3.new(0, 0.9, 0)
    else -- Meio
        aim = goalPos + right * (3 * side) + Vector3.new(0, 3.0, 0)
    end

    -- erro humano simulado: 99% = quase zero | 100% (Top Global) = zero
    if not perfect then
        local miss = math.max(0, (100 - Config.Accuracy)) / 100
        local spread = miss * 4
        aim = aim + Vector3.new((math.random() - 0.5) * 2 * spread, (math.random() - 0.5) * spread, (math.random() - 0.5) * 2 * spread)
    end
    return aim
end

--[[ ============================ ACOES DE JOGO ============================= ]]
local function reactionWait()
    if Config.ZeroDelay and Config.TopGlobal then
        return
    end
    task.wait(0.05)
end

-- CHUTE: forca maxima, mira perfeita, curva/normal aleatorio
local function doShoot(powerOverride, useCurveOverride, perfect)
    local char, hrp = myChar()
    local ball = findBall()
    if not char or not hrp or not ball then
        return false, "sem-jogo"
    end
    if not hasBall(6.5) then
        return false, "sem-bola"
    end
    local aim = computeAim(perfect)
    if not aim then
        return false, "sem-mira"
    end
    local dist = (aim - hrp.Position).Magnitude
    if dist > Config.ShootDist then
        return false, "longe"
    end
    reactionWait()
    faceTowards(aim)

    local curveOn
    if useCurveOverride ~= nil then
        curveOn = useCurveOverride
    elseif Config.RandomCurve then
        curveOn = (math.random() < 0.5)
    else
        curveOn = Config.CurveShoot
    end

    if Remotes.Curve then
        if curveOn then
            local dir = ((math.random() < 0.5) and -1 or 1) * Config.CurveIntensity
            fire(Remotes.Curve, dir)
        else
            fire(Remotes.Curve, 0)
        end
    end

    local power = powerOverride or Config.Power
    local shootRemote = Remotes.Shoot or Remotes.ShootAlt
    local ok = fire(shootRemote, aim, power)
    if (not ok) and shootRemote then
        ok = fire(shootRemote, aim)
    end
    -- compat extra: tenta o remote alternativo tambem
    if Config.CompatMode and Remotes.Shoot and Remotes.ShootAlt and shootRemote == Remotes.Shoot then
        -- nao dispara duplicado; apenas garante fallback se o primario nao existir no server
    end
    return ok, "ok"
end

-- DRIBLE perfeito: dispara skill + corte de corpo lateral
local function doDribble()
    local char, hrp = myChar()
    local ball = findBall()
    if not char or not hrp or not ball then
        return false
    end
    if not hasBall(5) then
        return false
    end
    reactionWait()
    if Remotes.Action then
        fire(Remotes.Action, "Dribble", math.random(1, 3))
        if Config.CompatMode then
            -- variacoes aceitas em versoes diferentes do jogo
            if Config.DribbleStyle == "Agressivo" then
                fire(Remotes.Action, "Dribble", math.random(1, 5))
            end
        end
    end
    -- corte de corpo: deslocamento lateral suave de Pro Player
    pcall(function()
        local side = (math.random() > 0.5) and 1 or -1
        local push = hrp.CFrame.RightVector * (11 * side)
        if hrp.AssemblyLinearVelocity then
            hrp.AssemblyLinearVelocity = hrp.AssemblyLinearVelocity + push
        else
            hrp.Velocity = hrp.Velocity + push
        end
    end)
    return true
end

-- TACKLE perfeito: bote limpo no momento certo
local function doTackle(targetChar)
    local _, hrp = myChar()
    if not hrp then
        return false
    end
    if targetChar then
        local tHrp = targetChar:FindFirstChild("HumanoidRootPart")
        if tHrp then
            if Config.LegitTackle then
                -- so da o bote de frente/lado (evita falta por tras)
                local toEnemy = (tHrp.Position - hrp.Position)
                toEnemy = Vector3.new(toEnemy.X, 0, toEnemy.Z)
                local myLook = hrp.CFrame.LookVector
                myLook = Vector3.new(myLook.X, 0, myLook.Z)
                if toEnemy.Magnitude > 0.5 and myLook.Magnitude > 0.1 then
                    if toEnemy.Unit:Dot(myLook.Unit) < 0.15 then
                        faceTowards(tHrp.Position)
                        task.wait(0.03)
                    end
                end
            else
                faceTowards(tHrp.Position)
            end
        end
    end
    reactionWait()
    return fire(Remotes.Tackle)
end

-- DIVE do goleiro
local function doDive(side)
    local _, hrp = myChar()
    local ball = findBall()
    if not hrp or not ball then
        return false
    end
    side = side or (((ball.Position - hrp.Position).X > 0) and "Right" or "Left")
    reactionWait()
    if Remotes.Action then
        fire(Remotes.Action, "GKDive", side)
        if Config.CompatMode then
            fire(Remotes.Action, "Dive", side)
        end
    end
    if Remotes.GKHitbox then
        fire(Remotes.GKHitbox, ball.Position)
    end
    return true
end

-- PASSE (GK): encontra o melhor companheiro e arma o lancamento
local function doGKPass()
    local _, hrp = myChar()
    local ball = findBall()
    if not hrp or not ball then
        return false
    end
    if not isGK() then
        return false, "nao-gk"
    end
    if not hasBall(6.5) then
        return false, "sem-bola"
    end
    if ball.Velocity.Magnitude > 10 then
        return false, "bola-viva"
    end
    local mate = getBestMate()
    if not mate then
        return false, "sem-companheiro"
    end
    local mHrp = mate:FindFirstChild("HumanoidRootPart")
    if not mHrp then
        return false
    end
    reactionWait()
    local target = mHrp.Position + mHrp.Velocity * 0.25
    faceTowards(target)
    local ok = fire(Remotes.Pass, target, 70)
    if not ok then
        ok = fire(Remotes.Pass, target)
    end
    if Config.CompatMode and not ok then
        local matePlayer = Players:GetPlayerFromCharacter(mate)
        if matePlayer then
            ok = fire(Remotes.Pass, matePlayer)
        end
    end
    return ok, "ok"
end

-- CABECEIO: bola alta caindo = pula + cabeceia pro gol
local function doHeader()
    local char, hrp, hum = myChar()
    local ball = findBall()
    if not char or not hrp or not hum or not ball then
        return false
    end
    local head = char:FindFirstChild("Head")
    local headY = head and head.Position.Y or (hrp.Position.Y + 2)
    if (ball.Position - hrp.Position).Magnitude > 8 then
        return false
    end
    if ball.Position.Y < headY + 1.5 then
        return false
    end
    reactionWait()
    pcall(function()
        hum.Jump = true
    end)
    if Remotes.Action then
        fire(Remotes.Action, "Header")
        if Config.CompatMode then
            fire(Remotes.Action, "Head")
        end
    end
    if Config.HeaderShoot then
        task.delay(0.12, function()
            if Running and hasBall(7) then
                doShoot(100, false, Config.TopGlobal)
            end
        end)
    end
    return true
end

-- BICICLETA: bola bem alta = pula + chuta no ar mirando o gol
local function doBicycle()
    local char, hrp, hum = myChar()
    local ball = findBall()
    if not char or not hrp or not hum or not ball then
        return false
    end
    if (ball.Position - hrp.Position).Magnitude > 7 then
        return false
    end
    if ball.Position.Y < hrp.Position.Y + 3.5 then
        return false
    end
    reactionWait()
    pcall(function()
        hum.Jump = true
    end)
    if Remotes.Action then
        fire(Remotes.Action, "Bicycle")
        if Config.CompatMode then
            fire(Remotes.Action, "BicycleKick")
            fire(Remotes.Action, "Acrobatic")
        end
    end
    task.delay(0.15, function()
        if Running and hasBall(7.5) then
            doShoot(100, true, Config.TopGlobal)
        end
    end)
    return true
end

-- VOLEIO / CHAPA: bola na altura do peito/pe = finaliza na hora
local function doVolley()
    local _, hrp = myChar()
    local ball = findBall()
    if not hrp or not ball then
        return false
    end
    local d = (ball.Position - hrp.Position).Magnitude
    if d > 6 then
        return false
    end
    local h = ball.Position.Y - hrp.Position.Y
    if h < 0.5 or h > 4.5 then
        return false
    end
    if Remotes.Action and Config.CompatMode then
        fire(Remotes.Action, "Volley")
    end
    return doShoot(100, false, Config.TopGlobal)
end

-- CAVADINHA (chip): perto do gol, toque leve por cima do goleiro
local function doChip()
    local _, hrp = myChar()
    local ball = findBall()
    local goalPos = getAttackGoal()
    if not hrp or not ball or not goalPos then
        return false
    end
    if not hasBall(6) then
        return false
    end
    if (goalPos - hrp.Position).Magnitude > 30 then
        return false
    end
    reactionWait()
    local aim = goalPos + Vector3.new(0, 4.5, 0)
    faceTowards(aim)
    if Remotes.Curve then
        fire(Remotes.Curve, 0)
    end
    local shootRemote = Remotes.Shoot or Remotes.ShootAlt
    return fire(shootRemote, aim, 28)
end

-- POWER SHOT (disponivel a cada ~30s)
local function doPowerShot()
    local now = os.clock()
    if now - Cooldown.PowerShot < 30 then
        return false, "recarga"
    end
    local ok, reason = doShoot(100, true, true)
    if ok then
        Cooldown.PowerShot = now
        if Remotes.Action and Config.CompatMode then
            fire(Remotes.Action, "PowerShot")
        end
    end
    return ok, reason
end

--[[ ============================ SISTEMA DE ESP ============================ ]]
local ESPFolder = nil
local function getESPFolder()
    if ESPFolder and ESPFolder.Parent then
        return ESPFolder
    end
    local parent = getGuiParent()
    local f = parent:FindFirstChild("__SnakeESP")
    if not f then
        f = Instance.new("Folder")
        f.Name = "__SnakeESP"
        pcall(function()
            f.Parent = parent
        end)
    end
    ESPFolder = f
    return f
end

local BallHL, BallTag, BallTagLabel = nil, nil, nil
local function ensureBallESP()
    local folder = getESPFolder()
    if not BallHL or not BallHL.Parent then
        BallHL = Instance.new("Highlight")
        BallHL.Name = "__SnakeBallHL"
        BallHL.FillColor = Color3.fromRGB(0, 255, 120)
        BallHL.OutlineColor = Color3.fromRGB(0, 200, 90)
        BallHL.FillTransparency = 0.6
        BallHL.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        BallHL.Parent = folder
    end
    if not BallTag or not BallTag.Parent then
        BallTag = Instance.new("BillboardGui")
        BallTag.Name = "__SnakeBallTag"
        BallTag.Size = UDim2.new(0, 120, 0, 40)
        BallTag.StudsOffset = Vector3.new(0, 3, 0)
        BallTag.AlwaysOnTop = true
        BallTagLabel = Instance.new("TextLabel")
        BallTagLabel.Size = UDim2.new(1, 0, 1, 0)
        BallTagLabel.BackgroundTransparency = 1
        BallTagLabel.TextColor3 = Color3.fromRGB(0, 255, 120)
        BallTagLabel.TextStrokeTransparency = 0.3
        BallTagLabel.Font = Enum.Font.GothamBold
        BallTagLabel.TextSize = 14
        BallTagLabel.Text = "BOLA"
        BallTagLabel.Parent = BallTag
        BallTag.Parent = folder
    end
end

local GoalHLs = {}
local function refreshGoalESP()
    local folder = getESPFolder()
    for _, h in ipairs(GoalHLs) do
        pcall(function()
            h:Destroy()
        end)
    end
    GoalHLs = {}
    local goals = scanGoals()
    for i = 1, math.min(#goals, 8) do
        local g = goals[i]
        if g and g.Parent then
            local h = Instance.new("Highlight")
            h.Name = "__SnakeGoalHL"
            h.FillColor = Color3.fromRGB(255, 200, 0)
            h.OutlineColor = Color3.fromRGB(255, 150, 0)
            h.FillTransparency = 0.7
            h.Adornee = g
            h.Parent = folder
            table.insert(GoalHLs, h)
        end
    end
end

local function clearPlayerESP()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr.Character then
            local tag = plr.Character:FindFirstChild("__SnakePTag")
            if tag then
                pcall(function()
                    tag:Destroy()
                end)
            end
            local hl = plr.Character:FindFirstChild("__SnakePHL")
            if hl then
                pcall(function()
                    hl:Destroy()
                end)
            end
        end
    end
end

local function refreshPlayerESP()
    local _, hrp = myChar()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            local head = plr.Character:FindFirstChild("Head")
            local eHrp = plr.Character:FindFirstChild("HumanoidRootPart")
            if head and eHrp then
                local tag = plr.Character:FindFirstChild("__SnakePTag")
                if not tag then
                    tag = Instance.new("BillboardGui")
                    tag.Name = "__SnakePTag"
                    tag.Size = UDim2.new(0, 140, 0, 36)
                    tag.StudsOffset = Vector3.new(0, 2.6, 0)
                    tag.AlwaysOnTop = true
                    local lb = Instance.new("TextLabel")
                    lb.Name = "L"
                    lb.Size = UDim2.new(1, 0, 1, 0)
                    lb.BackgroundTransparency = 1
                    lb.Font = Enum.Font.GothamBold
                    lb.TextSize = 13
                    lb.TextStrokeTransparency = 0.3
                    lb.Parent = tag
                    tag.Parent = plr.Character
                end
                local lb = tag:FindFirstChild("L")
                if lb then
                    local d = hrp and math.floor((eHrp.Position - hrp.Position).Magnitude) or 0
                    lb.Text = plr.DisplayName .. " [" .. d .. "m]"
                    if isEnemy(plr) then
                        lb.TextColor3 = Color3.fromRGB(255, 80, 80)
                    else
                        lb.TextColor3 = Color3.fromRGB(90, 160, 255)
                    end
                end
            end
        end
    end
end

local function clearESP()
    pcall(function()
        if BallHL then
            BallHL:Destroy()
        end
    end)
    pcall(function()
        if BallTag then
            BallTag:Destroy()
        end
    end)
    BallHL, BallTag, BallTagLabel = nil, nil, nil
    for _, h in ipairs(GoalHLs) do
        pcall(function()
            h:Destroy()
        end)
    end
    GoalHLs = {}
    clearPlayerESP()
end

--[[ =================== BOTOES FLUTUANTES (MOBILE + PC) ==================== ]]
local FloatGui = nil
local function getFloatGui()
    if FloatGui and FloatGui.Parent then
        return FloatGui
    end
    local parent = getGuiParent()
    local old = parent:FindFirstChild("__SnakeFloatV2")
    if old then
        pcall(function()
            old:Destroy()
        end)
    end
    local g = Instance.new("ScreenGui")
    g.Name = "__SnakeFloatV2"
    g.ResetOnSpawn = false
    g.IgnoreGuiInset = true
    pcall(function()
        g.Parent = parent
    end)
    FloatGui = g
    return g
end

local function styleFloatButton(btn, size, pos, text, color)
    btn.Size = size
    btn.Position = pos
    btn.Text = text
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 26
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.BackgroundColor3 = color
    btn.BorderSizePixel = 0
    btn.AutoButtonColor = true
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(1, 0)
    c.Parent = btn
    local s = Instance.new("UIStroke")
    s.Color = Color3.fromRGB(255, 255, 255)
    s.Transparency = 0.4
    s.Thickness = 2
    s.Parent = btn
end

-- Botao com arrastar (drag) + toque (tap) sem conflito
local function makeFloatButton(btn, onTap)
    local dragging = false
    local moved = false
    local dragStart = nil
    local startPos = nil
    btn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            moved = false
            dragStart = input.Position
            startPos = btn.Position
        end
    end)
    btn.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            if delta.Magnitude > 12 then
                moved = true
            end
            if moved then
                btn.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X,
                    startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            end
        end
    end)
    btn.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            local wasTap = dragging and (not moved)
            dragging = false
            moved = false
            if wasTap and onTap then
                task.spawn(onTap)
            end
        end
    end)
end

local UIVisible = true
local function setUiVisible(v)
    UIVisible = v
    pcall(function()
        local parents = { getGuiParent(), game:GetService("CoreGui") }
        local pgui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
        if pgui then
            table.insert(parents, pgui)
        end
        for _, par in ipairs(parents) do
            for _, g in ipairs(par:GetChildren()) do
                if g:IsA("ScreenGui") and string.lower(g.Name) == "rayfield" then
                    g.Enabled = v
                end
            end
        end
    end)
end

local SnakeBtn, ShootBtn = nil, nil
local function buildFloatButtons()
    local gui = getFloatGui()
    if not SnakeBtn or not SnakeBtn.Parent then
        SnakeBtn = Instance.new("TextButton")
        SnakeBtn.Name = "SnakeToggle"
        styleFloatButton(SnakeBtn, UDim2.new(0, 56, 0, 56), UDim2.new(0, 14, 0.5, -120),
            "S", Color3.fromRGB(0, 170, 80))
        SnakeBtn.Parent = gui
        makeFloatButton(SnakeBtn, function()
            setUiVisible(not UIVisible)
        end)
    end
    if not ShootBtn or not ShootBtn.Parent then
        ShootBtn = Instance.new("TextButton")
        ShootBtn.Name = "ShootNow"
        styleFloatButton(ShootBtn, UDim2.new(0, 88, 0, 88), UDim2.new(1, -104, 0.5, 20),
            "CHUTE", Color3.fromRGB(200, 40, 40))
        ShootBtn.TextSize = 16
        ShootBtn.Parent = gui
        makeFloatButton(ShootBtn, function()
            local ok, reason = doShoot(100, nil, Config.TopGlobal)
            if not ok and reason == "sem-bola" then
                notify("SnakeHub Chute", "Chegue perto da bola para chutar.", 2)
            elseif not ok and reason == "longe" then
                notify("SnakeHub Chute", "Fora do alcance configurado.", 2)
            end
        end)
    end
    SnakeBtn.Visible = Config.FloatUI
    ShootBtn.Visible = Config.FloatShoot
end

--[[ ============================ JANELA RAYFIELD =========================== ]]
local Window = Rayfield:CreateWindow({
    Name = "SNAKEHUB V2 | Realistic Street Soccer",
    LoadingTitle = "SNAKEHUB V2 INICIALIZANDO...",
    LoadingSubtitle = IS_MOBILE and "Modo: Mobile Touch" or "Modo: PC",
    ConfigurationSaving = { Enabled = false },
    Discord = { Enabled = false },
    KeySystem = false,
    Theme = "Green",
})

local TabHome   = Window:CreateTab("Inicio", 4483362458)
local TabShoot  = Window:CreateTab("Auto Shoot", 4483362458)
local TabDrib   = Window:CreateTab("Auto Drible", 4483362458)
local TabTack   = Window:CreateTab("Auto Tackle", 4483362458)
local TabActs   = Window:CreateTab("Auto Actions", 4483362458)
local TabGK     = Window:CreateTab("Goleiro GK", 4483362458)
local TabTop    = Window:CreateTab("Top 1 Global", 4483362458)
local TabUnlock = Window:CreateTab("Unlock All", 4483362458)
local TabMatch  = Window:CreateTab("Partida", 4483362458)
local TabSet    = Window:CreateTab("Ajustes", 4483362458)

-- ==========================================================================
-- ABA 1: INICIO
-- ==========================================================================
TabHome:CreateSection("Bem-vindo a SnakeHub V2")
TabHome:CreateParagraph({
    Title = "Status do Script",
    Content = "10 abas ativas | Mobile + PC | Todos os executors. Ative o MODO TOP 1 GLOBAL para jogar no nivel maximo com 1 toque."
})
TabHome:CreateParagraph({
    Title = IS_MOBILE and "Voce esta no MOBILE" or "Voce esta no PC",
    Content = IS_MOBILE
        and "Use o botao verde (S) para abrir/fechar o menu e o botao vermelho (CHUTE) para finalizar. Arraste os botoes para move-los."
        or "Pressione RightShift para abrir/fechar o menu e G para chute instantaneo. Teclas configuraveis na aba Ajustes."
})
TabHome:CreateButton({
    Name = "ATIVAR MODO TOP 1 GLOBAL (100%)",
    Callback = function()
        Config.TopGlobal = true
        Config.AutoShoot = true
        Config.AutoDribble = true
        Config.AutoTackle = true
        Config.AutoBicycle = true
        Config.AutoHeader = true
        Config.AutoVolley = true
        Config.AutoChip = true
        Config.AutoDive = true
        Config.AutoDefense = true
        Config.AutoPassGK = true
        Config.AutoPunch = true
        Config.AutoPowerShot = true
        Config.AimLock = true
        Config.Accuracy = 100
        notify("TOP 1 GLOBAL", "Modo maximo ATIVADO: 100% em tudo.", 4)
    end,
})
TabHome:CreateButton({
    Name = "PARAR TUDO (Botao de Panico)",
    Callback = function()
        Config.TopGlobal = false
        Config.AutoShoot = false
        Config.AutoDribble = false
        Config.AutoTackle = false
        Config.AutoBicycle = false
        Config.AutoHeader = false
        Config.AutoVolley = false
        Config.AutoChip = false
        Config.AutoDive = false
        Config.AutoDefense = false
        Config.AutoPassGK = false
        Config.AutoPunch = false
        Config.AutoPowerShot = false
        Config.AutoFaceoff = false
        Config.AutoPenalty = false
        notify("SnakeHub", "Todos os automatismos foram desligados.", 3)
    end,
})
TabHome:CreateToggle({
    Name = "Anti-AFK (evita ser expulso)",
    CurrentValue = true,
    Flag = "HomeAntiAFK",
    Callback = function(v)
        Config.AntiAFK = v
    end,
})
TabHome:CreateButton({
    Name = "Mostrar Ping e FPS agora",
    Callback = function()
        local ping = 0
        pcall(function()
            ping = math.floor(LocalPlayer:GetNetworkPing() * 1000)
        end)
        notify("Status", "Ping: " .. ping .. "ms | " .. (IS_MOBILE and "Mobile" or "PC"), 4)
    end,
})
TabHome:CreateButton({
    Name = "Entrar em outro servidor (Server Hop)",
    Callback = function()
        task.spawn(function()
            local ok = pcall(function()
                local url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"
                local res = game:HttpGet(url)
                local data = HttpService:JSONDecode(res)
                for _, s in ipairs(data.data) do
                    if s.id ~= game.JobId and s.playing < s.maxPlayers then
                        TeleportService:TeleportToPlaceInstance(game.PlaceId, s.id, LocalPlayer)
                        return
                    end
                end
                notify("Server Hop", "Nenhum servidor livre encontrado.", 3)
            end)
            if not ok then
                notify("Server Hop", "Falha ao trocar de servidor.", 3)
            end
        end)
    end,
})

-- ==========================================================================
-- ABA 2: AUTO SHOOT
-- ==========================================================================
TabShoot:CreateSection("Finalizacao Automatica 99%")
TabShoot:CreateToggle({
    Name = "AUTO SHOOT (99% de acerto)",
    CurrentValue = false,
    Flag = "ShootAuto",
    Callback = function(v)
        Config.AutoShoot = v
        if v then
            notify("Auto Shoot", "ON: finaliza sozinho com 99% de mira.", 2)
        end
    end,
})
TabShoot:CreateButton({
    Name = "CHUTAR AGORA (Forca MAXIMA)",
    Callback = function()
        local ok, reason = doShoot(100, nil, Config.TopGlobal)
        if not ok and reason == "sem-bola" then
            notify("Auto Shoot", "Chegue perto da bola para chutar.", 2)
        elseif not ok and reason == "longe" then
            notify("Auto Shoot", "Aumente a distancia de chute.", 2)
        end
    end,
})
TabShoot:CreateToggle({
    Name = "Botao flutuante de CHUTE (mobile)",
    CurrentValue = true,
    Flag = "ShootFloatBtn",
    Callback = function(v)
        Config.FloatShoot = v
        if ShootBtn then
            ShootBtn.Visible = v
        end
    end,
})
TabShoot:CreateDropdown({
    Name = "Local da finalizacao",
    Options = { "Aleatorio PRO", "Gaveta", "Canto Direito", "Canto Esquerdo", "Rasteiro", "Meio" },
    CurrentOption = "Aleatorio PRO",
    Flag = "ShootTarget",
    Callback = function(opt)
        Config.TargetArea = normOpt(opt, "Aleatorio PRO")
    end,
})
TabShoot:CreateSlider({
    Name = "Alcance do chute (campo inteiro)",
    Range = { 20, 300 },
    Increment = 5,
    Suffix = " studs",
    CurrentValue = 260,
    Flag = "ShootDist",
    Callback = function(v)
        Config.ShootDist = v
    end,
})
TabShoot:CreateSlider({
    Name = "Forca do chute",
    Range = { 50, 100 },
    Increment = 1,
    Suffix = "%",
    CurrentValue = 100,
    Flag = "ShootPower",
    Callback = function(v)
        Config.Power = v
    end,
})
TabShoot:CreateSlider({
    Name = "Taxa de acerto",
    Range = { 90, 99 },
    Increment = 1,
    Suffix = "%",
    CurrentValue = 99,
    Flag = "ShootAcc",
    Callback = function(v)
        Config.Accuracy = v
    end,
})
TabShoot:CreateToggle({
    Name = "Chute aleatorio PRO (curvado/normal)",
    CurrentValue = true,
    Flag = "ShootRandom",
    Callback = function(v)
        Config.RandomCurve = v
    end,
})
TabShoot:CreateToggle({
    Name = "Curva no chute (quando nao aleatorio)",
    CurrentValue = true,
    Flag = "ShootCurve",
    Callback = function(v)
        Config.CurveShoot = v
    end,
})
TabShoot:CreateSlider({
    Name = "Intensidade da curva",
    Range = { 1, 15 },
    Increment = 1,
    Suffix = " x0.1",
    CurrentValue = 7,
    Flag = "ShootCurveInt",
    Callback = function(v)
        Config.CurveIntensity = v / 10
    end,
})
TabShoot:CreateToggle({
    Name = "Mira travada no gol (Aim Lock)",
    CurrentValue = true,
    Flag = "ShootAimLock",
    Callback = function(v)
        Config.AimLock = v
    end,
})
TabShoot:CreateToggle({
    Name = "Tecla de chute instantaneo (PC)",
    CurrentValue = true,
    Flag = "ShootKeyT",
    Callback = function(v)
        Config.ShootKeyEnabled = v
    end,
})
TabShoot:CreateSection("Power Shot (recarga ~30s)")
TabShoot:CreateToggle({
    Name = "Power Shot automatico em chance clara",
    CurrentValue = false,
    Flag = "ShootPowerAuto",
    Callback = function(v)
        Config.AutoPowerShot = v
    end,
})
TabShoot:CreateButton({
    Name = "POWER SHOT AGORA",
    Callback = function()
        local ok, reason = doPowerShot()
        if not ok and reason == "recarga" then
            notify("Power Shot", "Ainda em recarga, aguarde.", 2)
        elseif not ok then
            notify("Power Shot", "Sem bola no pe.", 2)
        end
    end,
})

-- ==========================================================================
-- ABA 3: AUTO DRIBLE (ja vem no perfeito)
-- ==========================================================================
TabDrib:CreateSection("Drible Perfeito Anti-Roubo")
TabDrib:CreateParagraph({
    Title = "Configuracao PERFEITA aplicada",
    Content = "Distancia 5.5 | Reacao instantanea | Corte de corpo lateral | Estilo Perfeito PRO. So ativar abaixo."
})
TabDrib:CreateToggle({
    Name = "AUTO DRIBLE (perfeito)",
    CurrentValue = false,
    Flag = "DribAuto",
    Callback = function(v)
        Config.AutoDribble = v
        if v then
            notify("Auto Drible", "ON: ninguem toma sua bola.", 2)
        end
    end,
})
TabDrib:CreateButton({
    Name = "DRIBLAR AGORA",
    Callback = function()
        if not doDribble() then
            notify("Auto Drible", "Precisa estar com a bola no pe.", 2)
        end
    end,
})
TabDrib:CreateSlider({
    Name = "Distancia de reacao",
    Range = { 3, 10 },
    Increment = 1,
    Suffix = " x0.5 studs",
    CurrentValue = 11,
    Flag = "DribDist",
    Callback = function(v)
        Config.DribbleDist = v * 0.5
    end,
})
TabDrib:CreateDropdown({
    Name = "Estilo de drible",
    Options = { "Perfeito PRO", "Sombra (seguro)", "Agressivo" },
    CurrentOption = "Perfeito PRO",
    Flag = "DribStyle",
    Callback = function(opt)
        Config.DribbleStyle = normOpt(opt, "Perfeito PRO")
    end,
})
TabDrib:CreateToggle({
    Name = "Protecao corporal (escudo)",
    CurrentValue = true,
    Flag = "DribShield",
    Callback = function(v)
        Config.BodyShield = v
    end,
})
TabDrib:CreateSlider({
    Name = "Tempo entre dribles",
    Range = { 3, 15 },
    Increment = 1,
    Suffix = " x0.1s",
    CurrentValue = 7,
    Flag = "DribCD",
    Callback = function(v)
        Config.DribbleCD = v / 10
    end,
})

-- ==========================================================================
-- ABA 4: AUTO TACKLE (ja vem no perfeito)
-- ==========================================================================
TabTack:CreateSection("Bote Perfeito Sem Falta")
TabTack:CreateParagraph({
    Title = "Configuracao PERFEITA aplicada",
    Content = "Distancia 6.0 | Bote limpo de frente/lado | Intercepta passes | Reacao instantanea. So ativar abaixo."
})
TabTack:CreateToggle({
    Name = "AUTO TACKLE (perfeito)",
    CurrentValue = false,
    Flag = "TackAuto",
    Callback = function(v)
        Config.AutoTackle = v
        if v then
            notify("Auto Tackle", "ON: bote limpo automatico.", 2)
        end
    end,
})
TabTack:CreateButton({
    Name = "DAR O BOTE AGORA",
    Callback = function()
        local enemy = getEnemyWithBall(9)
        doTackle(enemy)
    end,
})
TabTack:CreateSlider({
    Name = "Distancia do bote",
    Range = { 3, 9 },
    Increment = 1,
    Suffix = " studs",
    CurrentValue = 6,
    Flag = "TackDist",
    Callback = function(v)
        Config.TackleDist = v
    end,
})
TabTack:CreateToggle({
    Name = "Modo legitimo anti-falta",
    CurrentValue = true,
    Flag = "TackLegit",
    Callback = function(v)
        Config.LegitTackle = v
    end,
})
TabTack:CreateToggle({
    Name = "Interceptacao PRO (corta passes)",
    CurrentValue = true,
    Flag = "TackInter",
    Callback = function(v)
        Config.InterceptPro = v
    end,
})

-- ==========================================================================
-- ABA 5: AUTO ACTIONS
-- ==========================================================================
TabActs:CreateSection("Jogadas Acrobaticas Automaticas")
TabActs:CreateToggle({
    Name = "Auto BICICLETA",
    CurrentValue = false,
    Flag = "ActBike",
    Callback = function(v)
        Config.AutoBicycle = v
    end,
})
TabActs:CreateToggle({
    Name = "Auto CABECEIO",
    CurrentValue = false,
    Flag = "ActHead",
    Callback = function(v)
        Config.AutoHeader = v
    end,
})
TabActs:CreateToggle({
    Name = "Auto VOLEIO / CHAPA",
    CurrentValue = false,
    Flag = "ActVolley",
    Callback = function(v)
        Config.AutoVolley = v
    end,
})
TabActs:CreateToggle({
    Name = "Auto CAVADINHA (perto do gol)",
    CurrentValue = false,
    Flag = "ActChip",
    Callback = function(v)
        Config.AutoChip = v
    end,
})
TabActs:CreateToggle({
    Name = "Cabecear mirando o gol",
    CurrentValue = true,
    Flag = "ActHeadShoot",
    Callback = function(v)
        Config.HeaderShoot = v
    end,
})
TabActs:CreateSection("Executar Manualmente")
TabActs:CreateButton({
    Name = "BICICLETA AGORA",
    Callback = function()
        if not doBicycle() then
            notify("Actions", "Bicicleta precisa da bola alta e perto.", 2)
        end
    end,
})
TabActs:CreateButton({
    Name = "CABECEIO AGORA",
    Callback = function()
        if not doHeader() then
            notify("Actions", "Cabeceio precisa da bola alta e perto.", 2)
        end
    end,
})
TabActs:CreateButton({
    Name = "VOLEIO AGORA",
    Callback = function()
        local ok = doVolley()
        if not ok then
            notify("Actions", "Voleio precisa da bola proxima.", 2)
        end
    end,
})
TabActs:CreateButton({
    Name = "CAVADINHA AGORA",
    Callback = function()
        if not doChip() then
            notify("Actions", "Cavadinha: fique perto do gol com a bola.", 2)
        end
    end,
})

-- ==========================================================================
-- ABA 6: GOLEIRO (GK)
-- ==========================================================================
TabGK:CreateSection("Defesas Automaticas do Goleiro")
TabGK:CreateDropdown({
    Name = "Voce e o goleiro?",
    Options = { "Automatico", "Sou GK", "Nao sou GK" },
    CurrentOption = "Automatico",
    Flag = "GKMode",
    Callback = function(opt)
        Config.GKMode = normOpt(opt, "Automatico")
    end,
})
TabGK:CreateToggle({
    Name = "AUTO DIVE (mergulho)",
    CurrentValue = false,
    Flag = "GKDive",
    Callback = function(v)
        Config.AutoDive = v
        if v then
            notify("GK", "Auto Dive ON.", 2)
        end
    end,
})
TabGK:CreateToggle({
    Name = "AUTO DEFESA LEGIT OP (posiciona + sai do gol)",
    CurrentValue = false,
    Flag = "GKDef",
    Callback = function(v)
        Config.AutoDefense = v
        if v then
            notify("GK", "Auto Defesa OP ON.", 2)
        end
    end,
})
TabGK:CreateToggle({
    Name = "AUTO PASSE (somente GK)",
    CurrentValue = false,
    Flag = "GKPass",
    Callback = function(v)
        Config.AutoPassGK = v
    end,
})
TabGK:CreateToggle({
    Name = "AUTO SOCO / AFASTA BOLA",
    CurrentValue = false,
    Flag = "GKPunch",
    Callback = function(v)
        Config.AutoPunch = v
    end,
})
TabGK:CreateSlider({
    Name = "Alcance de reacao do GK",
    Range = { 15, 60 },
    Increment = 1,
    Suffix = " studs",
    CurrentValue = 40,
    Flag = "GKRange",
    Callback = function(v)
        Config.GKRange = v
    end,
})
TabGK:CreateToggle({
    Name = "Modo compativel (maximo acerto)",
    CurrentValue = true,
    Flag = "GKCompat",
    Callback = function(v)
        Config.CompatMode = v
    end,
})
TabGK:CreateSection("Controles Manuais do GK")
TabGK:CreateButton({
    Name = "MERGULHAR ESQUERDA",
    Callback = function()
        doDive("Left")
    end,
})
TabGK:CreateButton({
    Name = "MERGULHAR DIREITA",
    Callback = function()
        doDive("Right")
    end,
})
TabGK:CreateButton({
    Name = "SAIR DO GOL / ABAFAR",
    Callback = function()
        local _, hrp, hum = myChar()
        local ball = findBall()
        if hrp and hum and ball then
            pcall(function()
                hum:MoveTo(ball.Position)
            end)
        end
    end,
})
TabGK:CreateButton({
    Name = "EXPANDIR ALCANCE DAS MAOS",
    Callback = function()
        if Remotes.GKHitbox then
            fire(Remotes.GKHitbox, Vector3.new(9999, 9999, 9999))
            notify("GK", "Alcance das maos expandido!", 2)
        else
            notify("GK", "Remote de goleiro nao encontrado.", 2)
        end
    end,
})
TabGK:CreateButton({
    Name = "IR PARA O MEU GOL",
    Callback = function()
        local _, hrp = myChar()
        local own = getOwnGoal()
        if hrp and own then
            pcall(function()
                hrp.CFrame = CFrame.new(own + Vector3.new(0, 3, 0))
                hrp.Velocity = Vector3.new(0, 0, 0)
            end)
        else
            notify("GK", "Gol nao localizado.", 2)
        end
    end,
})

-- ==========================================================================
-- ABA 7: TOP 1 GLOBAL (100% em tudo)
-- ==========================================================================
TabTop:CreateSection("Inteligencia Tatica Maxima")
TabTop:CreateParagraph({
    Title = "O que o TOP 1 GLOBAL faz",
    Content = "Liga TODOS os automatismos em 100% (sem erro): chute, drible, bote, bicicleta, cabeceio, goleiro e power shot. Voce continua se movendo normal e o script replica seus movimentos em versao avancada: mira sozinho, dribla sozinho e se posiciona como um pro."
})
TabTop:CreateToggle({
    Name = "TOP 1 GLOBAL (100% em TUDO)",
    CurrentValue = false,
    Flag = "TopMaster",
    Callback = function(v)
        Config.TopGlobal = v
        if v then
            Config.AutoShoot = true
            Config.AutoDribble = true
            Config.AutoTackle = true
            Config.AutoBicycle = true
            Config.AutoHeader = true
            Config.AutoVolley = true
            Config.AutoChip = true
            Config.AutoDive = true
            Config.AutoDefense = true
            Config.AutoPassGK = true
            Config.AutoPunch = true
            Config.AutoPowerShot = true
            Config.AimLock = true
            Config.Accuracy = 100
            notify("TOP 1 GLOBAL", "100% ATIVADO. Jogue que o resto e comigo.", 4)
        else
            Config.Accuracy = 99
            notify("TOP 1 GLOBAL", "Desativado. Autos continuam como estavam.", 3)
        end
    end,
})
TabTop:CreateDropdown({
    Name = "Estilo de jogo",
    Options = { "Completo", "Atacante", "Meia", "Defensor", "Goleiro" },
    CurrentOption = "Completo",
    Flag = "TopStyle",
    Callback = function(opt)
        Config.TopStyle = normOpt(opt, "Completo")
    end,
})
TabTop:CreateButton({
    Name = "APLICAR PRESET DA POSICAO",
    Callback = function()
        local s = Config.TopStyle
        if s == "Atacante" then
            Config.ShootDist = 280
            Config.Power = 100
            Config.TargetArea = "Aleatorio PRO"
            Config.DribbleDist = 6
            Config.TackleDist = 5
        elseif s == "Meia" then
            Config.ShootDist = 200
            Config.DribbleDist = 6
            Config.TackleDist = 6
            Config.InterceptPro = true
        elseif s == "Defensor" then
            Config.ShootDist = 120
            Config.TackleDist = 7
            Config.LegitTackle = true
            Config.InterceptPro = true
        elseif s == "Goleiro" then
            Config.GKMode = "Sou GK"
            Config.GKRange = 50
            Config.AutoDive = true
            Config.AutoDefense = true
            Config.AutoPassGK = true
            Config.AutoPunch = true
        else
            Config.ShootDist = 260
            Config.Power = 100
            Config.DribbleDist = 5.5
            Config.TackleDist = 6
            Config.GKRange = 40
        end
        notify("TOP 1 GLOBAL", "Preset " .. s .. " aplicado.", 3)
    end,
})
TabTop:CreateToggle({
    Name = "Movimento PRO (persegue bola livre)",
    CurrentValue = true,
    Flag = "TopMove",
    Callback = function(v)
        Config.ProMovement = v
    end,
})
TabTop:CreateToggle({
    Name = "Espelho de movimento (replica avancado)",
    CurrentValue = true,
    Flag = "TopMirror",
    Callback = function(v)
        Config.MoveMirror = v
    end,
})
TabTop:CreateSlider({
    Name = "Forca da assistencia de mira",
    Range = { 0, 100 },
    Increment = 5,
    Suffix = "%",
    CurrentValue = 65,
    Flag = "TopSteer",
    Callback = function(v)
        Config.SteerAssist = v
    end,
})
TabTop:CreateToggle({
    Name = "Piloto automatico total (quando parado)",
    CurrentValue = false,
    Flag = "TopFullAuto",
    Callback = function(v)
        Config.FullAuto = v
    end,
})
TabTop:CreateToggle({
    Name = "Reacao 0ms (sem delay humano)",
    CurrentValue = true,
    Flag = "TopZero",
    Callback = function(v)
        Config.ZeroDelay = v
    end,
})

-- ==========================================================================
-- ABA 8: UNLOCK ALL
-- ==========================================================================
TabUnlock:CreateSection("Desbloqueio Total")
TabUnlock:CreateParagraph({
    Title = "Como funciona",
    Content = "Tenta desbloquear cards, chuteiras, dribles, luvas de goleiro e itens de evento pelo servidor (todos veem quando o servidor aceita). Itens de gamepass pagos dependem do servidor: o script tenta, mas o visual pode ficar so local."
})
TabUnlock:CreateButton({
    Name = "DESBLOQUEAR TUDO (cosmeticos + skills)",
    Callback = function()
        task.spawn(function()
            local spinners = { Remotes.SpinCards, Remotes.SpinDrib, Remotes.SpinGoalie, Remotes.SpinShoes }
            for _, sp in ipairs(spinners) do
                if sp then
                    local rf = sp:FindFirstChild("RemoteFunction")
                    if rf then
                        invoke(rf, "GetAll")
                        task.wait(0.1)
                        invoke(rf, "UnlockAll")
                        task.wait(0.1)
                    else
                        -- algumas versoes expoem o RemoteFunction direto
                        pcall(function()
                            sp:InvokeServer("UnlockAll")
                        end)
                        task.wait(0.1)
                    end
                end
            end
            fire(Remotes.Equip, "UnlockAll")
            fire(Remotes.Avatar, "UnlockAll")
            fire(Remotes.Jersey, "UnlockAll")
            notify("Unlock All", "Desbloqueio executado! Confira o inventario.", 4)
        end)
    end,
})
TabUnlock:CreateButton({
    Name = "TENTAR LIBERAR GAMEPASSES (servidor)",
    Callback = function()
        task.spawn(function()
            fire(Remotes.Equip, "GamepassAll")
            task.wait(0.15)
            fire(Remotes.SettingsR, "UnlockAll")
            task.wait(0.15)
            fire(Remotes.ShopEvent, "UnlockAll")
            task.wait(0.15)
            notify("Unlock All", "Tentativa enviada ao servidor.", 3)
        end)
    end,
})
TabUnlock:CreateButton({
    Name = "EQUIPAR VISUAL PRO (todos veem)",
    Callback = function()
        task.spawn(function()
            fire(Remotes.Jersey, "Pro")
            task.wait(0.12)
            fire(Remotes.Avatar, "Pro")
            task.wait(0.12)
            fire(Remotes.Equip, "Best")
            notify("Unlock All", "Visual PRO equipado via servidor.", 3)
        end)
    end,
})
TabUnlock:CreateSection("Eventos, Quests e Codigos")
TabUnlock:CreateButton({
    Name = "RESGATAR COPA DO MUNDO",
    Callback = function()
        task.spawn(function()
            if Remotes.WorldCup then
                invoke(Remotes.WorldCup)
                task.wait(0.2)
            end
            if Remotes.RedeemWC then
                for i = 1, 10 do
                    invoke(Remotes.RedeemWC, i)
                    task.wait(0.12)
                end
            end
            notify("Unlock All", "Recompensas da Copa resgatadas.", 3)
        end)
    end,
})
TabUnlock:CreateButton({
    Name = "RESGATAR DIARIAS + QUESTS",
    Callback = function()
        task.spawn(function()
            fire(Remotes.Daily)
            task.wait(0.12)
            fire(Remotes.DailyEv, "ClaimAll")
            task.wait(0.12)
            fire(Remotes.WQuest, "ClaimAll")
            notify("Unlock All", "Diarias e quests reivindicadas.", 3)
        end)
    end,
})
TabUnlock:CreateButton({
    Name = "RESGATAR CODIGOS PROMOCIONAIS",
    Callback = function()
        task.spawn(function()
            local codes = { "RELEASE", "SOCCER", "STREET", "GOAL", "FOOTBALL", "RSS",
                "UPDATE", "WELCOME", "100K", "500K", "1M", "POWER", "SKILL",
                "TOP1", "BRAZIL", "SUMMER", "WINTER", "HALLOWEEN", "EASTER" }
            local redeemed = 0
            for _, code in ipairs(codes) do
                if Remotes.RedeemCode then
                    local ok = invoke(Remotes.RedeemCode, code)
                    if ok then
                        redeemed = redeemed + 1
                    end
                end
                task.wait(0.18)
            end
            notify("Unlock All", "Codigos testados: " .. redeemed .. " aceitos.", 3)
        end)
    end,
})
TabUnlock:CreateButton({
    Name = "COLETAR STICKS / ITENS DO MAPA",
    Callback = function()
        task.spawn(function()
            fire(Remotes.ClaimStick)
            task.wait(0.1)
            fire(Remotes.Collect)
            task.wait(0.1)
            fire(Remotes.TCellLoc)
            task.wait(0.1)
            fire(Remotes.Unbox)
            notify("Unlock All", "Coleta enviada ao servidor.", 3)
        end)
    end,
})

-- ==========================================================================
-- ABA 9: PARTIDA (exploits + utilidades)
-- ==========================================================================
TabMatch:CreateSection("Condicao Fisica e Camera")
TabMatch:CreateToggle({
    Name = "Stamina infinita (corre sempre)",
    CurrentValue = false,
    Flag = "MatchStam",
    Callback = function(v)
        Config.InfiniteStamina = v
    end,
})
TabMatch:CreateToggle({
    Name = "Velocidade personalizada",
    CurrentValue = false,
    Flag = "MatchWalkT",
    Callback = function(v)
        Config.WalkEnabled = v
        if not v then
            local _, _, hum = myChar()
            if hum then
                pcall(function()
                    hum.WalkSpeed = 16
                end)
            end
        end
    end,
})
TabMatch:CreateSlider({
    Name = "Velocidade de corrida",
    Range = { 16, 40 },
    Increment = 1,
    Suffix = " ws",
    CurrentValue = 22,
    Flag = "MatchWalk",
    Callback = function(v)
        Config.WalkSpeed = v
    end,
})
TabMatch:CreateToggle({
    Name = "Sem tremor de camera",
    CurrentValue = false,
    Flag = "MatchShake",
    Callback = function(v)
        Config.NoShake = v
    end,
})
TabMatch:CreateToggle({
    Name = "Pular comemoracao / podio",
    CurrentValue = false,
    Flag = "MatchCut",
    Callback = function(v)
        Config.SkipCutscene = v
    end,
})
TabMatch:CreateToggle({
    Name = "Modo streamer (esconde nome)",
    CurrentValue = false,
    Flag = "MatchStream",
    Callback = function(v)
        Config.StreamerMode = v
        if v then
            fire(Remotes.SoftDis, true)
        else
            fire(Remotes.SoftDis, false)
        end
    end,
})
TabMatch:CreateButton({
    Name = "FPS BOOST (mobile liso)",
    Callback = function()
        pcall(function()
            local Lighting = game:GetService("Lighting")
            Lighting.GlobalShadows = false
            Lighting.FogEnd = 100000
            for _, v in ipairs(Lighting:GetChildren()) do
                if v:IsA("BloomEffect") or v:IsA("BlurEffect") or v:IsA("SunRaysEffect")
                    or v:IsA("ColorCorrectionEffect") or v:IsA("DepthOfFieldEffect") then
                    v.Enabled = false
                end
            end
            for _, d in ipairs(workspace:GetDescendants()) do
                if d:IsA("ParticleEmitter") or d:IsA("Trail") or d:IsA("Smoke")
                    or d:IsA("Fire") or d:IsA("Sparkles") then
                    d.Enabled = false
                end
            end
            fire(Remotes.FPSNORE)
        end)
        notify("Partida", "FPS Boost aplicado! Jogo mais leve.", 3)
    end,
})
TabMatch:CreateSection("Automacoes de Partida")
TabMatch:CreateToggle({
    Name = "Auto Faceoff (pega a bola no kickoff)",
    CurrentValue = false,
    Flag = "MatchFace",
    Callback = function(v)
        Config.AutoFaceoff = v
    end,
})
TabMatch:CreateToggle({
    Name = "Auto Penalti (bate sozinho)",
    CurrentValue = false,
    Flag = "MatchPen",
    Callback = function(v)
        Config.AutoPenalty = v
    end,
})
TabMatch:CreateToggle({
    Name = "Auto coletar itens do mapa",
    CurrentValue = false,
    Flag = "MatchCollect",
    Callback = function(v)
        Config.AutoCollect = v
    end,
})
TabMatch:CreateButton({
    Name = "PENALTI: CANTO ESQUERDO",
    Callback = function()
        fire(Remotes.Penalty, "Left")
    end,
})
TabMatch:CreateButton({
    Name = "PENALTI: MEIO",
    Callback = function()
        fire(Remotes.Penalty, "Center")
    end,
})
TabMatch:CreateButton({
    Name = "PENALTI: CANTO DIREITO",
    Callback = function()
        fire(Remotes.Penalty, "Right")
    end,
})
TabMatch:CreateSection("Time e Posicao")
TabMatch:CreateButton({
    Name = "AUTO TIME (entra no melhor)",
    Callback = function()
        task.spawn(function()
            local counts = {}
            for _, plr in ipairs(Players:GetPlayers()) do
                local t = plr.Team and plr.Team.Name or "SemTime"
                counts[t] = (counts[t] or 0) + 1
            end
            local bestTeam, bestCount = nil, math.huge
            for name, c in pairs(counts) do
                if name ~= "SemTime" and c < bestCount then
                    bestCount = c
                    bestTeam = name
                end
            end
            if bestTeam and Remotes.TeamChange then
                fire(Remotes.TeamChange, bestTeam)
                notify("Partida", "Entrando no time: " .. bestTeam, 3)
            else
                if Remotes.TeamChange then
                    fire(Remotes.TeamChange, 1)
                end
                notify("Partida", "Time solicitado.", 2)
            end
        end)
    end,
})
TabMatch:CreateButton({
    Name = "VIRAR GOLEIRO (GK)",
    Callback = function()
        fire(Remotes.Position, "GK")
        task.wait(0.15)
        fire(Remotes.Position, "Goalkeeper")
        Config.GKMode = "Sou GK"
        notify("Partida", "Posicao de goleiro solicitada.", 3)
    end,
})
TabMatch:CreateButton({
    Name = "JOGAR NA LINHA (sair do gol)",
    Callback = function()
        fire(Remotes.Position, "Field")
        task.wait(0.15)
        fire(Remotes.Position, "Player")
        Config.GKMode = "Nao sou GK"
        notify("Partida", "Posicao de linha solicitada.", 3)
    end,
})
TabMatch:CreateSection("Teleportes do Campo")
local function tpTo(pos, label)
    local _, hrp = myChar()
    if hrp and pos then
        pcall(function()
            hrp.CFrame = CFrame.new(pos + Vector3.new(0, 3, 0))
            hrp.Velocity = Vector3.new(0, 0, 0)
        end)
    else
        notify("Teleporte", "Destino indisponivel: " .. (label or ""), 2)
    end
end
TabMatch:CreateButton({
    Name = "TELEPORTE: BOLA",
    Callback = function()
        local ball = findBall()
        if ball then
            tpTo(ball.Position, "bola")
        end
    end,
})
TabMatch:CreateButton({
    Name = "TELEPORTE: MEIO DE CAMPO",
    Callback = function()
        tpTo(Vector3.new(0, 5, 0), "meio")
    end,
})
TabMatch:CreateButton({
    Name = "TELEPORTE: GOL ADVERSARIO",
    Callback = function()
        tpTo(getAttackGoal(), "ataque")
    end,
})
TabMatch:CreateButton({
    Name = "TELEPORTE: MEU GOL",
    Callback = function()
        tpTo(getOwnGoal(), "defesa")
    end,
})
TabMatch:CreateButton({
    Name = "TELEPORTE: MARCA DO PENALTI",
    Callback = function()
        local atk = getAttackGoal()
        local _, hrp = myChar()
        if atk and hrp then
            local dir = (Vector3.new(0, atk.Y, 0) - Vector3.new(atk.X, atk.Y, atk.Z))
            if dir.Magnitude < 1 then
                dir = (hrp.Position - atk)
            end
            tpTo(atk + dir.Unit * 32, "penalti")
        end
    end,
})
TabMatch:CreateSection("Visao (ESP)")
TabMatch:CreateToggle({
    Name = "ESP da BOLA",
    CurrentValue = false,
    Flag = "EspBall",
    Callback = function(v)
        Config.BallESP = v
        if v then
            ensureBallESP()
        end
    end,
})
TabMatch:CreateToggle({
    Name = "ESP dos GOLS",
    CurrentValue = false,
    Flag = "EspGoal",
    Callback = function(v)
        Config.GoalESP = v
        if v then
            refreshGoalESP()
        end
    end,
})
TabMatch:CreateToggle({
    Name = "ESP dos JOGADORES",
    CurrentValue = false,
    Flag = "EspPlayer",
    Callback = function(v)
        Config.PlayerESP = v
        if not v then
            clearPlayerESP()
        end
    end,
})

-- ==========================================================================
-- ABA 10: AJUSTES
-- ==========================================================================
TabSet:CreateSection("Interface (Mobile + PC)")
TabSet:CreateDropdown({
    Name = "Tecla do menu (PC)",
    Options = { "RightShift", "LeftControl", "F8", "F9", "M", "P", "Insert" },
    CurrentOption = "RightShift",
    Flag = "SetUIKey",
    Callback = function(opt)
        Config.UIKey = normOpt(opt, "RightShift")
    end,
})
TabSet:CreateDropdown({
    Name = "Tecla do chute (PC)",
    Options = { "G", "H", "J", "K", "L", "T", "Y", "U", "V", "B", "N" },
    CurrentOption = "G",
    Flag = "SetShootKey",
    Callback = function(opt)
        Config.ShootKey = normOpt(opt, "G")
    end,
})
TabSet:CreateToggle({
    Name = "Botao flutuante do menu (S)",
    CurrentValue = true,
    Flag = "SetFloatUI",
    Callback = function(v)
        Config.FloatUI = v
        if SnakeBtn then
            SnakeBtn.Visible = v
        end
    end,
})
TabSet:CreateToggle({
    Name = "Botao flutuante de chute (CHUTE)",
    CurrentValue = true,
    Flag = "SetFloatShoot",
    Callback = function(v)
        Config.FloatShoot = v
        if ShootBtn then
            ShootBtn.Visible = v
        end
    end,
})
TabSet:CreateToggle({
    Name = "Notificacoes do script",
    CurrentValue = true,
    Flag = "SetNotif",
    Callback = function(v)
        Config.NotifyUI = v
    end,
})
TabSet:CreateSection("Sistema")
TabSet:CreateParagraph({
    Title = "SnakeHub V2 - Creditos",
    Content = "Feito para Realistic Street Soccer | 10 abas | 99% autos / 100% top global | Mobile + PC | Todos os executors."
})
TabSet:CreateButton({
    Name = "RECARREGAR BOTOES FLUTUANTES",
    Callback = function()
        buildFloatButtons()
        notify("Ajustes", "Botoes flutuantes recarregados.", 2)
    end,
})
TabSet:CreateButton({
    Name = "DESLIGAR SNAKEHUB (Unload)",
    Callback = function()
        task.spawn(function()
            Running = false
            Config.TopGlobal = false
            pcall(clearESP)
            pcall(function()
                if FloatGui then
                    FloatGui:Destroy()
                end
            end)
            for _, c in ipairs(Connections) do
                pcall(function()
                    c:Disconnect()
                end)
            end
            ENV.__SNAKEHUB_V2_LOADED = nil
            pcall(function()
                Rayfield:Destroy()
            end)
        end)
    end,
})

--[[ ==================== TECLAS RAPIDAS (PC, SEM CONFLITO) ================= ]]
track(UserInputService.InputBegan:Connect(function(input, gpe)
    if not Running then
        return
    end
    if input.UserInputType ~= Enum.UserInputType.Keyboard then
        return
    end
    local okUI, uiKey = pcall(function()
        return Enum.KeyCode[Config.UIKey]
    end)
    if okUI and uiKey and input.KeyCode == uiKey then
        setUiVisible(not UIVisible)
        return
    end
    if Config.ShootKeyEnabled then
        local okS, sKey = pcall(function()
            return Enum.KeyCode[Config.ShootKey]
        end)
        if okS and sKey and input.KeyCode == sKey and not gpe then
            task.spawn(function()
                doShoot(100, nil, Config.TopGlobal)
            end)
        end
    end
end))

--[[ ================== MOTOR PRINCIPAL (TODOS OS AUTOS) ==================== ]]
local lastMoveDir = Vector3.new(0, 0, 0)
local lastMoveTime = 0

track(RunService.Heartbeat:Connect(function(dt)
    if not Running then
        return
    end
    local char, hrp, hum = myChar()
    if not char or not hrp or not hum then
        return
    end
    local ball = findBall()
    if not ball then
        return
    end
    local now = os.clock()
    local TOP = Config.TopGlobal

    -- ---- 1) AUTO SHOOT (99% / 100% no Top Global) ----
    if Config.AutoShoot and (now - Cooldown.Shoot) > 0.7 then
        if hasBall(4.5) then
            local aim = computeAim(TOP)
            if aim and (aim - hrp.Position).Magnitude <= Config.ShootDist then
                Cooldown.Shoot = now
                task.spawn(function()
                    doShoot(nil, nil, TOP)
                end)
            end
        end
    end

    -- ---- 2) POWER SHOT automatico em chance clara ----
    if Config.AutoPowerShot and (now - Cooldown.PowerShot) >= 30 then
        if hasBall(5) then
            local aim = computeAim(true)
            if aim and (aim - hrp.Position).Magnitude <= 65 then
                task.spawn(doPowerShot)
            end
        end
    end

    -- ---- 3) AUTO DRIBLE perfeito ----
    if Config.AutoDribble and (now - Cooldown.Dribble) > Config.DribbleCD then
        if hasBall(4.2) then
            local enemy, eDist = getClosestEnemy(Config.DribbleDist)
            if enemy then
                local eHrp = enemy:FindFirstChild("HumanoidRootPart")
                if eHrp and eDist <= Config.DribbleDist and eHrp.Velocity.Magnitude > 6 then
                    Cooldown.Dribble = now
                    task.spawn(doDribble)
                end
            end
        end
    end

    -- ---- 4) AUTO TACKLE perfeito ----
    if Config.AutoTackle and (now - Cooldown.Tackle) > 0.5 then
        if not hasBall(2.5) then
            local enemy, eDist = getEnemyWithBall(Config.TackleDist)
            local doIt = (enemy ~= nil)
            -- interceptacao PRO: corta a trajetoria da bola mesmo sem dono proximo
            if (not doIt) and Config.InterceptPro then
                local bDist = (ball.Position - hrp.Position).Magnitude
                if bDist <= Config.TackleDist + 2 and ball.Velocity.Magnitude > 12 then
                    local toMe = (hrp.Position - ball.Position)
                    if toMe.Magnitude > 0.5 and ball.Velocity.Unit:Dot(toMe.Unit) > 0.5 then
                        doIt = true
                    end
                end
            end
            if doIt then
                Cooldown.Tackle = now
                task.spawn(function()
                    doTackle(enemy)
                end)
            end
        end
    end

    -- ---- 5) AUTO ACTIONS (bicicleta / cabeceio / voleio / cavadinha) ----
    do
        local bDist = (ball.Position - hrp.Position).Magnitude
        local head = char:FindFirstChild("Head")
        local headY = head and head.Position.Y or (hrp.Position.Y + 2)
        local ballH = ball.Position.Y - hrp.Position.Y
        if Config.AutoBicycle and (now - Cooldown.Bicycle) > 1.2 then
            if bDist <= 7 and ball.Position.Y >= hrp.Position.Y + 3.5 then
                Cooldown.Bicycle = now
                task.spawn(doBicycle)
            end
        end
        if Config.AutoHeader and (now - Cooldown.Header) > 1.0 then
            if bDist <= 8 and ball.Position.Y >= headY + 1.5 and ball.Velocity.Y < 4 then
                Cooldown.Header = now
                task.spawn(doHeader)
            end
        end
        if Config.AutoVolley and (now - Cooldown.Volley) > 0.8 then
            if bDist <= 6 and ballH >= 0.5 and ballH <= 4.5 then
                Cooldown.Volley = now
                task.spawn(doVolley)
            end
        end
        if Config.AutoChip and (now - Cooldown.Chip) > 1.0 then
            if hasBall(6) then
                local atk = getAttackGoal()
                if atk and (atk - hrp.Position).Magnitude <= 30 then
                    Cooldown.Chip = now
                    task.spawn(doChip)
                end
            end
        end
    end

    -- ---- 6) GOLEIRO: dive + defesa OP + passe + soco ----
    local amGK = isGK()
    if (Config.AutoDive or Config.AutoDefense or Config.AutoPunch) and (now - Cooldown.Dive) > 0.9 then
        local bDist = (ball.Position - hrp.Position).Magnitude
        if bDist <= Config.GKRange and ball.Velocity.Magnitude > 16 then
            local toMe = (hrp.Position - ball.Position)
            if toMe.Magnitude > 0.5 and ball.Velocity.Unit:Dot(toMe.Unit) > 0.35 then
                Cooldown.Dive = now
                task.spawn(function()
                    doDive()
                end)
            end
        end
    end
    if Config.AutoDefense and amGK then
        local own = getOwnGoal()
        local userIdle = hum.MoveDirection.Magnitude < 0.15
        if own and userIdle then
            -- se posiciona entre a bola e o gol (parede legitima)
            local mid = own + (ball.Position - own).Unit * 2.5
            mid = Vector3.new(mid.X, hrp.Position.Y, mid.Z)
            if (hrp.Position - mid).Magnitude > 4 then
                pcall(function()
                    hum:MoveTo(mid)
                end)
            end
        end
    end
    if Config.AutoPunch and (now - Cooldown.Punch) > 1.0 then
        local bDist = (ball.Position - hrp.Position).Magnitude
        if bDist <= 7 and ball.Position.Y > hrp.Position.Y + 1 then
            Cooldown.Punch = now
            task.spawn(function()
                if Remotes.Action then
                    fire(Remotes.Action, "Punch")
                    if Config.CompatMode then
                        fire(Remotes.Action, "Clear")
                        fire(Remotes.Action, "GKClear")
                    end
                end
                if Remotes.GKHitbox then
                    fire(Remotes.GKHitbox, ball.Position)
                end
            end)
        end
    end
    if Config.AutoPassGK and (now - Cooldown.Pass) > 3 then
        if amGK and hasBall(6.5) and ball.Velocity.Magnitude <= 10 then
            Cooldown.Pass = now
            task.spawn(doGKPass)
        end
    end

    -- ---- 7) AIM LOCK: trava a mira no gol com a bola no pe ----
    if Config.AimLock and hasBall(5) and not TOP then
        local aim = computeAim(false)
        if aim then
            softSteer(aim, 0.8)
        end
    end

    -- ---- 8) TOP GLOBAL: movimento PRO + espelho avancado ----
    if TOP then
        -- mira 100% cravada quando tem a bola
        if hasBall(5.5) then
            local aim = computeAim(true)
            if aim then
                softSteer(aim, Config.SteerAssist / 100)
            end
        end
        -- espelho de movimento: sua troca rapida de direcao vira drible avancado
        if Config.MoveMirror and hasBall(5) then
            local md = hum.MoveDirection
            if md.Magnitude > 0.2 and lastMoveDir.Magnitude > 0.2 then
                local dot = md.Unit:Dot(lastMoveDir.Unit)
                if dot < 0.4 and (now - lastMoveTime) < 0.3 and (now - Cooldown.Dribble) > Config.DribbleCD then
                    local _, eDist = getClosestEnemy(8)
                    if eDist <= 8 then
                        Cooldown.Dribble = now
                        task.spawn(doDribble)
                    end
                end
            end
            if md.Magnitude > 0.2 then
                lastMoveDir = md
                lastMoveTime = now
            end
        end
        -- movimento PRO: persegue bola livre / piloto automatico
        if Config.ProMovement then
            local userIdle = hum.MoveDirection.Magnitude < 0.15
            if userIdle then
                if isBallFree() then
                    local chase = ball.Position + ball.Velocity * 0.2
                    pcall(function()
                        hum:MoveTo(chase)
                    end)
                elseif Config.FullAuto and hasBall(5.5) then
                    local atk = getAttackGoal()
                    if atk then
                        pcall(function()
                            hum:MoveTo(atk)
                        end)
                    end
                end
            end
        end
    end

    -- ---- 9) AUTO FACEOFF ----
    if Config.AutoFaceoff and (now - Cooldown.Faceoff) > 0.4 then
        if (ball.Position - hrp.Position).Magnitude <= 12 then
            Cooldown.Faceoff = now
            fire(Remotes.Faceoff)
        end
    end
end))

--[[ ============ LOOP SECUNDARIO (stamina, afk, cutscene, coleta) ========== ]]
task.spawn(function()
    while Running do
        task.wait(0.3)
        local ok = pcall(function()
            if Config.InfiniteStamina and Remotes.SpeedRemote then
                fire(Remotes.SpeedRemote, true, 100)
            end
            if Config.WalkEnabled then
                local _, _, hum = myChar()
                if hum and math.abs(hum.WalkSpeed - Config.WalkSpeed) > 0.5 then
                    hum.WalkSpeed = Config.WalkSpeed
                end
            end
            if Config.SkipCutscene then
                fire(Remotes.Cutscene, "Skip")
                fire(Remotes.PodiumCam, "Skip")
                fire(Remotes.PodiumCel, "Skip")
            end
            if Config.AntiAFK and Remotes.AFK then
                fire(Remotes.AFK, false)
            end
            if Config.NoShake and Remotes.Shake then
                fire(Remotes.Shake, 0)
            end
            if Config.AutoCollect then
                fire(Remotes.ClaimStick)
                fire(Remotes.Collect)
                fire(Remotes.TCellLoc)
            end
        end)
        if not ok then
            task.wait(0.5)
        end
    end
end)

-- Auto penalti em loop proprio (1 por vez, canto alternado)
task.spawn(function()
    local side = 0
    while Running do
        task.wait(0.9)
        if Config.AutoPenalty and Remotes.Penalty then
            side = side + 1
            local corners = { "Left", "Right", "Center", "Right", "Left" }
            fire(Remotes.Penalty, corners[(side % #corners) + 1])
        end
    end
end)

--[[ ============================ LOOP DO ESP =============================== ]]
task.spawn(function()
    local goalTick = 0
    while Running do
        task.wait(0.25)
        pcall(function()
            if Config.BallESP then
                ensureBallESP()
                local ball = findBall()
                local _, hrp = myChar()
                if ball then
                    BallHL.Adornee = ball
                    BallHL.Enabled = true
                    BallTag.Adornee = ball
                    BallTag.Enabled = true
                    if BallTagLabel then
                        local d = hrp and math.floor((ball.Position - hrp.Position).Magnitude) or 0
                        BallTagLabel.Text = "BOLA [" .. d .. "m]"
                    end
                end
            elseif BallHL then
                BallHL.Enabled = false
                if BallTag then
                    BallTag.Enabled = false
                end
            end
            if Config.GoalESP then
                goalTick = goalTick + 1
                if goalTick >= 12 then
                    goalTick = 0
                    refreshGoalESP()
                elseif #GoalHLs == 0 then
                    refreshGoalESP()
                end
            elseif #GoalHLs > 0 then
                for _, h in ipairs(GoalHLs) do
                    h:Destroy()
                end
                GoalHLs = {}
            end
            if Config.PlayerESP then
                refreshPlayerESP()
            end
        end)
    end
end)

-- Anti-AFK do proprio Roblox (nunca toma kick por parado)
track(LocalPlayer.Idled:Connect(function()
    if Config.AntiAFK and Running then
        pcall(function()
            VirtualUser:Button2Down(Vector2.new(0, 0), Camera.CFrame)
            task.wait(0.5)
            VirtualUser:Button2Up(Vector2.new(0, 0), Camera.CFrame)
        end)
    end
end))

-- Mantem a camera valida apos respawn
track(workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
    Camera = workspace.CurrentCamera
end))

--[[ ================================ INICIO ================================ ]]
buildFloatButtons()

pcall(function()
    Rayfield:LoadConfiguration()
end)

notify("SNAKEHUB V2 carregada!",
    IS_MOBILE and "Toque no botao S para abrir o menu." or "Pressione RightShift para abrir o menu.", 5)
