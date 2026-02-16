local Players = game:GetService("Players")
local TextChatService = game:GetService("TextChatService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Player = Players.LocalPlayer

-- ==============================================================================
-- 1. CONFIGURAÇÕES E VARIÁVEIS
-- ==============================================================================
local AutoAgacharAtivado = false 
local TelaPretaAtivada = false
local ModoAtual = "Canguru" 
local SaldoGiro = 0 
local Rodando = false
local ScriptVivo = true 

-- Paleta de Cores (Estilo XIT/Free Fire)
local THEME = {
	Background = Color3.fromRGB(20, 20, 20),      -- Fundo Geral Escuro
	Sidebar    = Color3.fromRGB(30, 0, 0),        -- Barra lateral Vermelho Escuro
	Header     = Color3.fromRGB(180, 0, 0),       -- Cabeçalho Vermelho Vivo
	Accent     = Color3.fromRGB(255, 30, 30),     -- Detalhes/Botões Ativos
	TextLight  = Color3.fromRGB(240, 240, 240),   -- Texto Claro
	TextDim    = Color3.fromRGB(150, 150, 150),   -- Texto Escuro
	ItemBg     = Color3.fromRGB(35, 35, 35)       -- Fundo dos inputs
}

-- ==============================================================================
-- 2. FUNÇÕES LÓGICAS (O motor do script)
-- ==============================================================================
local function ConverterParaExtensoCaps(n)
	n = math.floor(tonumber(n) or 0)
	if n == 0 then return "ZERO" end
	if n == 100 then return "CEM" end
	if n > 999 then return tostring(n) end
	local unidades = {"", "UM", "DOIS", "TRÊS", "QUATRO", "CINCO", "SEIS", "SETE", "OITO", "NOVE"}
	local especiais = {"DEZ", "ONZE", "DOZE", "TREZE", "QUATORZE", "QUINZE", "DEZESSEIS", "DEZESSETE", "DEZOITO", "DEZENOVE"}
	local dezenas = {"", "", "VINTE", "TRINTA", "QUARENTA", "CINQUENTA", "SESSENTA", "SETENTA", "OITENTA", "NOVENTA"}
	local centenas = {"", "CENTO", "DUZENTOS", "TREZENTOS", "QUATROCENTOS", "QUINHENTOS", "SEISCENTOS", "SETECENTOS", "OITOCENTOS", "NOVECENTOS"}
	local res = ""
	if n >= 100 then local c = math.floor(n/100); res = centenas[c+1]; n = n%100; if n>0 then res = res.." E " end end
	if n >= 10 and n <= 19 then res = res .. especiais[n-9]
	elseif n >= 20 then local d = math.floor(n/10); res = res .. dezenas[d+1]; local u = n%10; if u>0 then res = res.." E "..unidades[u+1] end
	elseif n > 0 then res = res .. unidades[n+1] end
	return res
end

local function ApertarC()
	if not AutoAgacharAtivado or not ScriptVivo then return end
	pcall(function()
		VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.C, false, game)
		task.wait() 
		VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.C, false, game)
	end)
end

local function ForcarPulo(hum)
	if not ScriptVivo then return end
	hum.Jump = true
	hum:ChangeState(Enum.HumanoidStateType.Jumping)
end

local function GiroDinamico(char)
	if not ScriptVivo then return end
	local root = char:FindFirstChild("HumanoidRootPart")
	local hum = char:FindFirstChild("Humanoid")
	if root and hum then
		hum.AutoRotate = false 
		task.spawn(function()
			local variacao = math.random(-30, 30)
			local alvoTotal = 360 + variacao - (SaldoGiro * 0.5) 
			SaldoGiro = variacao
			local girado = 0
			local velocidadeBase = math.random(40, 55)
			while girado < alvoTotal and ScriptVivo do
				if not root then break end
				local passo = velocidadeBase
				if (girado + passo) > alvoTotal then passo = alvoTotal - girado end
				root.CFrame = root.CFrame * CFrame.Angles(0, math.rad(-passo), 0)
				girado = girado + passo
				if girado > (alvoTotal * 0.6) then velocidadeBase = math.max(4, velocidadeBase * 0.85) end
				task.wait(0.02) 
			end
			if hum then hum.AutoRotate = true end
		end)
	end
end

-- ==============================================================================
-- 3. INTERFACE VISUAL (UI XIT STYLE)
-- ==============================================================================
local ScreenGui = Instance.new("ScreenGui"); ScreenGui.Name = "XitMenuUI"; ScreenGui.Parent = Player:WaitForChild("PlayerGui"); ScreenGui.ResetOnSpawn = false

-- Função para arrastar a UI (Draggable)
local function MakeDraggable(frame, titleBar)
	local dragging, dragInput, dragStart, startPos
	titleBar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true; dragStart = input.Position; startPos = frame.Position
			input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false end end)
		end
	end)
	frame.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement then dragInput = input end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if input == dragInput and dragging then
			local delta = input.Position - dragStart
			frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
		end
	end)
end

-- Tela Preta
local BlackScreen = Instance.new("Frame")
BlackScreen.Size = UDim2.new(10,0,10,0); BlackScreen.Position = UDim2.new(-5,0,-5,0); BlackScreen.BackgroundColor3 = Color3.new(0,0,0); BlackScreen.Visible = false; BlackScreen.ZIndex = 0; BlackScreen.Parent = ScreenGui

-- Frame Principal
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 450, 0, 300)
MainFrame.Position = UDim2.new(0.5, -225, 0.5, -150)
MainFrame.BackgroundColor3 = THEME.Background
MainFrame.BorderSizePixel = 0
MainFrame.Parent = ScreenGui
local UICorner = Instance.new("UICorner"); UICorner.CornerRadius = UDim.new(0, 6); UICorner.Parent = MainFrame

-- Barra Superior (Header)
local Header = Instance.new("Frame"); Header.Size = UDim2.new(1, 0, 0, 35); Header.BackgroundColor3 = THEME.Header; Header.Parent = MainFrame
local HeaderCorner = Instance.new("UICorner"); HeaderCorner.CornerRadius = UDim.new(0, 6); HeaderCorner.Parent = Header
local HeaderFix = Instance.new("Frame"); HeaderFix.Size = UDim2.new(1, 0, 0, 10); HeaderFix.Position = UDim2.new(0,0,1,-10); HeaderFix.BackgroundColor3 = THEME.Header; HeaderFix.BorderSizePixel=0; HeaderFix.Parent = Header

local TitleLbl = Instance.new("TextLabel")
TitleLbl.Text = "AUTO TREINO - 1NXITER STYLE"
TitleLbl.Size = UDim2.new(0.8, 0, 1, 0); TitleLbl.Position = UDim2.new(0.05, 0, 0, 0)
TitleLbl.BackgroundTransparency = 1; TitleLbl.TextColor3 = THEME.TextLight; TitleLbl.Font = Enum.Font.GothamBlack; TitleLbl.TextSize = 14; TitleLbl.TextXAlignment = Enum.TextXAlignment.Left; TitleLbl.Parent = Header

local CloseBtn = Instance.new("TextButton")
CloseBtn.Text = "X"; CloseBtn.Size = UDim2.new(0, 35, 1, 0); CloseBtn.Position = UDim2.new(1, -35, 0, 0)
CloseBtn.BackgroundTransparency = 1; CloseBtn.TextColor3 = THEME.TextLight; CloseBtn.Font = Enum.Font.GothamBold; CloseBtn.TextSize = 16; CloseBtn.Parent = Header
CloseBtn.MouseButton1Click:Connect(function() ScriptVivo = false; ScreenGui:Destroy() end)

MakeDraggable(MainFrame, Header)

-- Sidebar (Barra Lateral)
local Sidebar = Instance.new("Frame"); Sidebar.Size = UDim2.new(0, 50, 1, -35); Sidebar.Position = UDim2.new(0,0,0,35); Sidebar.BackgroundColor3 = THEME.Sidebar; Sidebar.BorderSizePixel = 0; Sidebar.Parent = MainFrame
local SidebarCorner = Instance.new("UICorner"); SidebarCorner.CornerRadius = UDim.new(0, 6); SidebarCorner.Parent = Sidebar
local SidebarFix = Instance.new("Frame"); SidebarFix.Size = UDim2.new(1, 0, 0, 20); SidebarFix.Position = UDim2.new(0,0,0,0); SidebarFix.BackgroundColor3 = THEME.Sidebar; SidebarFix.BorderSizePixel=0; SidebarFix.Parent = Sidebar

-- Conteúdo Principal
local Content = Instance.new("Frame"); Content.Size = UDim2.new(1, -60, 1, -45); Content.Position = UDim2.new(0, 55, 0, 40); Content.BackgroundTransparency = 1; Content.Parent = MainFrame

-- Elementos de UI Customizados (Checkbox e Inputs)
local function CreateCheckbox(parent, text, default, callback)
	local container = Instance.new("Frame"); container.Size = UDim2.new(1, 0, 0, 30); container.BackgroundTransparency = 1; container.Parent = parent
	
	local box = Instance.new("TextButton"); box.Size = UDim2.new(0, 20, 0, 20); box.Position = UDim2.new(0, 0, 0.5, -10); box.BackgroundColor3 = THEME.ItemBg; box.Text = ""; box.AutoButtonColor = false; box.Parent = container
	local stroke = Instance.new("UIStroke"); stroke.Color = THEME.TextDim; stroke.Thickness = 1; stroke.Parent = box
	local check = Instance.new("Frame"); check.Size = UDim2.new(0, 14, 0, 14); check.AnchorPoint = Vector2.new(0.5,0.5); check.Position = UDim2.new(0.5,0,0.5,0); check.BackgroundColor3 = THEME.Accent; check.BorderSizePixel = 0; check.Visible = default; check.Parent = box
	
	local lbl = Instance.new("TextLabel"); lbl.Text = text; lbl.Size = UDim2.new(1, -30, 1, 0); lbl.Position = UDim2.new(0, 30, 0, 0); lbl.BackgroundTransparency = 1; lbl.TextColor3 = THEME.TextLight; lbl.Font = Enum.Font.GothamMedium; lbl.TextSize = 12; lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.Parent = container
	
	local active = default
	box.MouseButton1Click:Connect(function()
		active = not active
		check.Visible = active
		if active then stroke.Color = THEME.Accent else stroke.Color = THEME.TextDim end
		callback(active)
	end)
	return container
end

local function CreateInput(parent, text, defaultVal)
	local container = Instance.new("Frame"); container.Size = UDim2.new(0.48, 0, 0, 45); container.BackgroundTransparency = 1; container.Parent = parent
	local lbl = Instance.new("TextLabel"); lbl.Text = text; lbl.Size = UDim2.new(1, 0, 0, 15); lbl.BackgroundTransparency = 1; lbl.TextColor3 = THEME.TextDim; lbl.Font = Enum.Font.Gotham; lbl.TextSize = 11; lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.Parent = container
	local inpBg = Instance.new("Frame"); inpBg.Size = UDim2.new(1, 0, 0, 25); inpBg.Position = UDim2.new(0,0,0,18); inpBg.BackgroundColor3 = THEME.ItemBg; inpBg.Parent = container; Instance.new("UICorner", inpBg).CornerRadius = UDim.new(0,4)
	local inp = Instance.new("TextBox"); inp.Text = defaultVal; inp.Size = UDim2.new(1, -10, 1, 0); inp.Position = UDim2.new(0,5,0,0); inp.BackgroundTransparency = 1; inp.TextColor3 = THEME.TextLight; inp.Font = Enum.Font.GothamBold; inp.TextXAlignment = Enum.TextXAlignment.Left; inp.Parent = inpBg
	return inp, container
end

-- --- ORGANIZAÇÃO DAS ABAS ---
local Tab1 = Instance.new("Frame"); Tab1.Name = "Home"; Tab1.Size = UDim2.new(1,0,1,0); Tab1.BackgroundTransparency = 1; Tab1.Parent = Content
local Tab2 = Instance.new("Frame"); Tab2.Name = "Settings"; Tab2.Size = UDim2.new(1,0,1,0); Tab2.BackgroundTransparency = 1; Tab2.Visible = false; Tab2.Parent = Content

-- --- CONTEÚDO ABA 1 (HOME) ---
local CountLbl = Instance.new("TextLabel")
CountLbl.Text = "AGUARDANDO"
CountLbl.Size = UDim2.new(1, 0, 0, 40); CountLbl.Position = UDim2.new(0, 0, 0, 10)
CountLbl.BackgroundTransparency = 1; CountLbl.TextColor3 = THEME.Accent; CountLbl.Font = Enum.Font.GothamBlack; CountLbl.TextSize = 28; CountLbl.Parent = Tab1

local StatusLbl = Instance.new("TextLabel")
StatusLbl.Text = "Status: Parado"
StatusLbl.Size = UDim2.new(1, 0, 0, 20); StatusLbl.Position = UDim2.new(0, 0, 0, 50)
StatusLbl.BackgroundTransparency = 1; StatusLbl.TextColor3 = THEME.TextDim; StatusLbl.Font = Enum.Font.Gotham; StatusLbl.TextSize = 12; StatusLbl.Parent = Tab1

-- Checkboxes Principais
local checksContainer = Instance.new("ScrollingFrame"); checksContainer.Size = UDim2.new(1, 0, 0, 100); checksContainer.Position = UDim2.new(0,0,0,80); checksContainer.BackgroundTransparency = 1; checksContainer.BorderSizePixel=0; checksContainer.Parent = Tab1
local uiList = Instance.new("UIListLayout"); uiList.Parent = checksContainer; uiList.Padding = UDim.new(0, 5)

CreateCheckbox(checksContainer, "Ativar Auto Agachar (C)", false, function(v) AutoAgacharAtivado = v end)
CreateCheckbox(checksContainer, "Modo Tela Preta (Economia)", false, function(v) 
	TelaPretaAtivada = v
	BlackScreen.Visible = v
end)
CreateCheckbox(checksContainer, "Modo Flexão (Somente Chat)", false, function(v) 
	if v then ModoAtual = "Flexao" else ModoAtual = "Canguru" end
end)

-- Botão Iniciar (Estilo "Enable")
local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Text = "INICIAR SCRIPT"; ToggleBtn.Size = UDim2.new(1, 0, 0, 35); ToggleBtn.Position = UDim2.new(0, 0, 1, -35)
ToggleBtn.BackgroundColor3 = THEME.ItemBg; ToggleBtn.TextColor3 = THEME.TextLight; ToggleBtn.Font = Enum.Font.GothamBold; ToggleBtn.TextSize = 14; ToggleBtn.Parent = Tab1
local ToggleStroke = Instance.new("UIStroke"); ToggleStroke.Color = THEME.Accent; ToggleStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; ToggleStroke.Thickness = 1; ToggleStroke.Parent = ToggleBtn
Instance.new("UICorner", ToggleBtn).CornerRadius = UDim.new(0, 4)

-- --- CONTEÚDO ABA 2 (SETTINGS) ---
local SetsTitle = Instance.new("TextLabel"); SetsTitle.Text = "CONFIGURAÇÕES DE VALOR"; SetsTitle.Size = UDim2.new(1,0,0,20); SetsTitle.BackgroundTransparency=1; SetsTitle.TextColor3=THEME.Accent; SetsTitle.Font=Enum.Font.GothamBold; SetsTitle.TextSize=12; SetsTitle.TextXAlignment=Enum.TextXAlignment.Left; SetsTitle.Parent = Tab2

local InpStart, C1 = CreateInput(Tab2, "Número Inicial:", "0"); C1.Position = UDim2.new(0,0,0,30)
local InpQtd, C2   = CreateInput(Tab2, "Quantidade:", "130"); C2.Position = UDim2.new(0.52,0,0,30)
local InpDelay, C3 = CreateInput(Tab2, "Delay (Segundos):", "1.4"); C3.Position = UDim2.new(0,0,0,85)

-- --- BOTÕES DA SIDEBAR ---
local function CreateSideBtn(icon, tabToOpen)
	local b = Instance.new("TextButton"); b.Size = UDim2.new(0, 30, 0, 30); b.BackgroundTransparency = 1; b.Text = icon; b.TextColor3 = THEME.TextDim; b.TextSize = 20; b.Parent = Sidebar
	b.MouseButton1Click:Connect(function()
		Tab1.Visible = false; Tab2.Visible = false
		tabToOpen.Visible = true
	end)
	local layout = Sidebar:FindFirstChildOfClass("UIListLayout") or Instance.new("UIListLayout", Sidebar)
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center; layout.Padding = UDim.new(0, 15); layout.VerticalAlignment = Enum.VerticalAlignment.Center
end

CreateSideBtn("⚔", Tab1) -- Espada/Mira
CreateSideBtn("⚙", Tab2) -- Engrenagem

-- ==============================================================================
-- 4. LOOP PRINCIPAL (INTEGRADO)
-- ==============================================================================
ToggleBtn.MouseButton1Click:Connect(function()
	if Rodando then
		Rodando = false
		ToggleBtn.Text = "INICIAR SCRIPT"
		ToggleBtn.BackgroundColor3 = THEME.ItemBg
		StatusLbl.Text = "Status: Parado"
		StatusLbl.TextColor3 = THEME.TextDim
		return
	end
	
	Rodando = true
	ToggleBtn.Text = "PARAR SCRIPT"
	ToggleBtn.BackgroundColor3 = THEME.Sidebar -- Fica vermelho escuro
	StatusLbl.Text = "Status: EXECUTANDO"
	StatusLbl.TextColor3 = THEME.Accent
	
	local inicio = tonumber(InpStart.Text) or 0
	local qtd = tonumber(InpQtd.Text) or 130
	local fim = inicio + qtd - 1
	SaldoGiro = 0 
	
	task.spawn(function()
		for i = inicio, fim do
			if not Rodando or not ScriptVivo then break end
			
			CountLbl.Text = tostring(i)
			
			local char = Player.Character
			if char and char:FindFirstChild("Humanoid") then
				local hum = char.Humanoid
				local delayAtual = tonumber(InpDelay.Text) or 1.4
				
				local msgFinal = ConverterParaExtensoCaps(i) .. " !"
				if TextChatService.ChatInputBarConfiguration.TargetTextChannel then
					TextChatService.ChatInputBarConfiguration.TargetTextChannel:SendAsync(msgFinal)
				else
					game:GetService("ReplicatedStorage").DefaultChatSystemChatEvents.SayMessageRequest:FireServer(msgFinal, "All")
				end
				
				if ModoAtual == "Canguru" then
					if AutoAgacharAtivado then ApertarC() end
					task.wait(0.15) 
					if AutoAgacharAtivado then ApertarC() end
					ForcarPulo(hum)
					task.wait(0.05) 
					GiroDinamico(char)
					local tempoParaEsperar = delayAtual - 0.30 
					if tempoParaEsperar < 0 then tempoParaEsperar = 0 end
					task.wait(tempoParaEsperar)
				else
					task.wait(delayAtual)
				end
			end
		end
		Rodando = false
		if ScriptVivo then
			ToggleBtn.Text = "INICIAR SCRIPT"
			ToggleBtn.BackgroundColor3 = THEME.ItemBg
			CountLbl.Text = "FIM"
			StatusLbl.Text = "Status: Finalizado"
			StatusLbl.TextColor3 = THEME.TextLight
		end
	end)
end)
