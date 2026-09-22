-- Studio Model Serializer
-- Use only with models you own or are authorized to export.
-- Install this file as a Roblox Studio Plugin. It is not a runtime LocalScript.
--
-- It intentionally skips executable code and networking objects:
-- Script, LocalScript, ModuleScript, RemoteEvent, RemoteFunction, BindableEvent,
-- BindableFunction, and UnreliableRemoteEvent.

local Selection = game:GetService("Selection")

if not plugin then
	error("StudioModelSerializer.plugin.lua must run as a Roblox Studio plugin.")
end

local PLUGIN_ID = "SnakeHubAuthorizedModelSerializer_v1"
local MAX_INSTANCES = 2000

local toolbar = plugin:CreateToolbar("Model Tools")
local toolbarButton = toolbar:CreateButton(
	"Model Serializer",
	"Generate Command Bar reconstruction code for one selected model you own.",
	""
)
toolbarButton.ClickableWhenViewportHidden = true

local widgetInfo = DockWidgetPluginGuiInfo.new(
	Enum.InitialDockState.Float,
	false,
	false,
	760,
	600,
	480,
	360
)
local widget = plugin:CreateDockWidgetPluginGui(PLUGIN_ID, widgetInfo)
widget.Title = "Model → Command Bar serializer"

local root = Instance.new("Frame")
root.Name = "Root"
root.BackgroundColor3 = Color3.fromRGB(25, 27, 34)
root.BorderSizePixel = 0
root.Size = UDim2.fromScale(1, 1)
root.Parent = widget

local padding = Instance.new("UIPadding")
padding.PaddingTop = UDim.new(0, 10)
padding.PaddingBottom = UDim.new(0, 10)
padding.PaddingLeft = UDim.new(0, 10)
padding.PaddingRight = UDim.new(0, 10)
padding.Parent = root

local title = Instance.new("TextLabel")
title.Name = "Title"
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold
title.Text = "Modelo selecionado → script para Command Bar"
title.TextColor3 = Color3.fromRGB(240, 242, 255)
title.TextSize = 16
title.TextXAlignment = Enum.TextXAlignment.Left
title.Size = UDim2.new(1, 0, 0, 24)
title.Parent = root

local description = Instance.new("TextLabel")
description.Name = "Description"
description.BackgroundTransparency = 1
description.Font = Enum.Font.Gotham
description.Text = "Selecione um Model, Folder ou BasePart no Explorer/viewport. Scripts, remotes e código nunca são exportados."
description.TextColor3 = Color3.fromRGB(180, 185, 205)
description.TextSize = 12
description.TextWrapped = true
description.TextXAlignment = Enum.TextXAlignment.Left
description.TextYAlignment = Enum.TextYAlignment.Top
description.Position = UDim2.new(0, 0, 0, 28)
description.Size = UDim2.new(1, 0, 0, 34)
description.Parent = root

local function makeButton(name, text, position, size, color)
	local button = Instance.new("TextButton")
	button.Name = name
	button.AutoButtonColor = true
	button.BackgroundColor3 = color
	button.BorderSizePixel = 0
	button.Font = Enum.Font.GothamSemibold
	button.Text = text
	button.TextColor3 = Color3.fromRGB(255, 255, 255)
	button.TextSize = 13
	button.Position = position
	button.Size = size
	button.Parent = root

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = button
	return button
end

local generateButton = makeButton(
	"Generate",
	"Gerar script",
	UDim2.new(0, 0, 0, 68),
	UDim2.new(0, 145, 0, 30),
	Color3.fromRGB(52, 111, 208)
)
local selectButton = makeButton(
	"SelectOutput",
	"Selecionar saída (Ctrl+C)",
	UDim2.new(0, 154, 0, 68),
	UDim2.new(0, 190, 0, 30),
	Color3.fromRGB(61, 135, 98)
)
local clearButton = makeButton(
	"Clear",
	"Limpar",
	UDim2.new(0, 353, 0, 68),
	UDim2.new(0, 90, 0, 30),
	Color3.fromRGB(96, 69, 77)
)

local output = Instance.new("TextBox")
output.Name = "Output"
output.BackgroundColor3 = Color3.fromRGB(15, 16, 21)
output.BorderColor3 = Color3.fromRGB(60, 64, 78)
output.ClearTextOnFocus = false
output.Font = Enum.Font.Code
output.MultiLine = true
output.PlaceholderColor3 = Color3.fromRGB(120, 125, 145)
output.PlaceholderText = "Clique em ‘Gerar script’, depois use ‘Selecionar saída (Ctrl+C)’ e cole no Command Bar."
output.Text = ""
output.TextColor3 = Color3.fromRGB(223, 228, 245)
output.TextEditable = true
output.TextSize = 13
output.TextWrapped = false
output.TextXAlignment = Enum.TextXAlignment.Left
output.TextYAlignment = Enum.TextYAlignment.Top
output.Position = UDim2.new(0, 0, 0, 108)
output.Size = UDim2.new(1, 0, 1, -146)
output.Parent = root

local outputCorner = Instance.new("UICorner")
outputCorner.CornerRadius = UDim.new(0, 6)
outputCorner.Parent = output

local status = Instance.new("TextLabel")
status.Name = "Status"
status.BackgroundTransparency = 1
status.Font = Enum.Font.Gotham
status.Text = "Aguardando a seleção de um modelo."
status.TextColor3 = Color3.fromRGB(165, 174, 198)
status.TextSize = 12
status.TextXAlignment = Enum.TextXAlignment.Left
status.TextTruncate = Enum.TextTruncate.AtEnd
status.Position = UDim2.new(0, 0, 1, -28)
status.Size = UDim2.new(1, 0, 0, 22)
status.Parent = root

local function setStatus(message, isError)
	status.Text = message
	if isError then
		status.TextColor3 = Color3.fromRGB(255, 140, 140)
	else
		status.TextColor3 = Color3.fromRGB(165, 210, 180)
	end
end

local function quote(value)
	return string.format("%q", value)
end

local function numberLiteral(value)
	if value ~= value then
		return "0 --[[ original value was NaN ]]"
	end
	if value == math.huge then
		return "math.huge"
	end
	if value == -math.huge then
		return "-math.huge"
	end
	return string.format("%.17g", value)
end

local function join(parts, separator)
	return table.concat(parts, separator)
end

local function valueToLua(value, references)
	local valueType = typeof(value)

	if valueType == "nil" then
		return "nil"
	elseif valueType == "boolean" then
		return value and "true" or "false"
	elseif valueType == "number" then
		return numberLiteral(value)
	elseif valueType == "string" then
		return quote(value)
	elseif valueType == "EnumItem" then
		return tostring(value)
	elseif valueType == "Vector2" then
		return ("Vector2.new(%s, %s)"):format(numberLiteral(value.X), numberLiteral(value.Y))
	elseif valueType == "Vector3" then
		return ("Vector3.new(%s, %s, %s)"):format(
			numberLiteral(value.X),
			numberLiteral(value.Y),
			numberLiteral(value.Z)
		)
	elseif valueType == "Color3" then
		return ("Color3.new(%s, %s, %s)"):format(
			numberLiteral(value.R),
			numberLiteral(value.G),
			numberLiteral(value.B)
		)
	elseif valueType == "CFrame" then
		local components = { value:GetComponents() }
		local strings = {}
		for _, component in ipairs(components) do
			table.insert(strings, numberLiteral(component))
		end
		return "CFrame.new(" .. join(strings, ", ") .. ")"
	elseif valueType == "UDim" then
		return ("UDim.new(%s, %s)"):format(numberLiteral(value.Scale), numberLiteral(value.Offset))
	elseif valueType == "UDim2" then
		return ("UDim2.new(%s, %s, %s, %s)"):format(
			numberLiteral(value.X.Scale),
			numberLiteral(value.X.Offset),
			numberLiteral(value.Y.Scale),
			numberLiteral(value.Y.Offset)
		)
	elseif valueType == "BrickColor" then
		return "BrickColor.new(" .. numberLiteral(value.Number) .. ")"
	elseif valueType == "NumberRange" then
		return ("NumberRange.new(%s, %s)"):format(numberLiteral(value.Min), numberLiteral(value.Max))
	elseif valueType == "ColorSequence" then
		local keypoints = {}
		for _, keypoint in ipairs(value.Keypoints) do
			local color = valueToLua(keypoint.Value, references)
			if color then
				table.insert(keypoints, ("ColorSequenceKeypoint.new(%s, %s)"):format(numberLiteral(keypoint.Time), color))
			end
		end
		return "ColorSequence.new({" .. join(keypoints, ", ") .. "})"
	elseif valueType == "NumberSequence" then
		local keypoints = {}
		for _, keypoint in ipairs(value.Keypoints) do
			table.insert(keypoints, ("NumberSequenceKeypoint.new(%s, %s, %s)"):format(
				numberLiteral(keypoint.Time),
				numberLiteral(keypoint.Value),
				numberLiteral(keypoint.Envelope)
			))
		end
		return "NumberSequence.new({" .. join(keypoints, ", ") .. "})"
	elseif valueType == "PhysicalProperties" then
		return ("PhysicalProperties.new(%s, %s, %s, %s, %s)"):format(
			numberLiteral(value.Density),
			numberLiteral(value.Friction),
			numberLiteral(value.Elasticity),
			numberLiteral(value.FrictionWeight),
			numberLiteral(value.ElasticityWeight)
		)
	elseif valueType == "Rect" then
		return ("Rect.new(%s, %s, %s, %s)"):format(
			numberLiteral(value.Min.X),
			numberLiteral(value.Min.Y),
			numberLiteral(value.Max.X),
			numberLiteral(value.Max.Y)
		)
	elseif valueType == "Instance" then
		local reference = references[value]
		if reference then
			return reference
		end
		return nil, "references an Instance outside the selected model"
	end

	return nil, "unsupported value type " .. valueType
end

local function addProperties(target, seen, properties)
	for _, property in ipairs(properties) do
		if not seen[property] then
			seen[property] = true
			table.insert(target, property)
		end
	end
end

local function propertyNames(instance)
	local properties = {}
	local seen = {}
	local function add(list)
		addProperties(properties, seen, list)
	end

	add({ "Name" })

	if instance:IsA("Model") then
		add({ "PrimaryPart", "WorldPivot" })
	end
	if instance:IsA("BasePart") then
		add({
			"Anchored", "CanCollide", "CanQuery", "CanTouch", "CastShadow", "CollisionGroup",
			"Color", "CFrame", "CustomPhysicalProperties", "Massless", "Material", "MaterialVariant",
			"PivotOffset", "Reflectance", "RootPriority", "Size", "Transparency",
		})
	end
	if instance:IsA("Part") then
		add({ "Shape", "TopSurface", "BottomSurface" })
	end
	if instance:IsA("MeshPart") then
		add({ "MeshId", "TextureID", "RenderFidelity", "DoubleSided" })
	end
	if instance:IsA("SpecialMesh") then
		add({ "MeshId", "MeshType", "Offset", "Scale", "TextureId", "VertexColor" })
	end
	if instance:IsA("Decal") then
		add({ "Color3", "Face", "Texture", "Transparency", "ZIndex" })
	end
	if instance:IsA("Texture") then
		add({ "Color3", "Face", "Texture", "Transparency", "ZIndex", "StudsPerTileU", "StudsPerTileV", "OffsetStudsU", "OffsetStudsV" })
	end
	if instance:IsA("SurfaceAppearance") then
		add({ "AlphaMode", "ColorMap", "MetalnessMap", "NormalMap", "RoughnessMap" })
	end
	if instance:IsA("Attachment") then
		add({ "CFrame", "Axis", "SecondaryAxis", "Visible" })
	end
	if instance:IsA("WeldConstraint") then
		add({ "Enabled", "Part0", "Part1" })
	end
	if instance:IsA("JointInstance") then
		add({ "C0", "C1", "Enabled", "Part0", "Part1" })
	end
	if instance:IsA("Constraint") then
		add({ "Attachment0", "Attachment1", "Enabled", "Visible" })
	end
	if instance:IsA("RopeConstraint") then
		add({ "Length", "Restitution", "Thickness", "Visible" })
	end
	if instance:IsA("HingeConstraint") then
		add({ "ActuatorType", "AngularResponsiveness", "AngularSpeed", "LimitsEnabled", "LowerAngle", "MotorMaxAcceleration", "MotorMaxTorque", "Radius", "Restitution", "ServoMaxTorque", "TargetAngle", "UpperAngle" })
	end
	if instance:IsA("SpringConstraint") then
		add({ "Damping", "FreeLength", "LimitsEnabled", "MaxForce", "MinLength", "Radius", "Stiffness", "Thickness" })
	end
	if instance:IsA("Beam") then
		add({ "Attachment0", "Attachment1", "Color", "CurveSize0", "CurveSize1", "Enabled", "FaceCamera", "LightEmission", "LightInfluence", "Segments", "Texture", "TextureLength", "TextureMode", "TextureSpeed", "Transparency", "Width0", "Width1", "ZOffset" })
	end
	if instance:IsA("Trail") then
		add({ "Attachment0", "Attachment1", "Color", "Enabled", "FaceCamera", "Lifetime", "LightEmission", "LightInfluence", "MinLength", "Texture", "TextureLength", "TextureMode", "TextureSpeed", "Transparency", "WidthScale", "ZOffset" })
	end
	if instance:IsA("ParticleEmitter") then
		add({ "Acceleration", "Brightness", "Color", "Drag", "EmissionDirection", "Enabled", "FlipbookFramerate", "FlipbookLayout", "FlipbookMode", "LightEmission", "LightInfluence", "Lifetime", "LockedToPart", "Orientation", "Rate", "Rotation", "RotSpeed", "Shape", "ShapeInOut", "ShapeStyle", "Size", "Speed", "SpreadAngle", "Squash", "Texture", "TimeScale", "Transparency", "VelocityInheritance", "WindAffectsDrag", "ZOffset" })
	end
	if instance:IsA("Fire") then
		add({ "Color", "Enabled", "Heat", "SecondaryColor", "Size", "TimeScale" })
	end
	if instance:IsA("Smoke") then
		add({ "Color", "Enabled", "Opacity", "RiseVelocity", "Size", "TimeScale" })
	end
	if instance:IsA("Sparkles") then
		add({ "Enabled", "SparkleColor", "TimeScale" })
	end
	if instance:IsA("Light") then
		add({ "Brightness", "Color", "Enabled", "Range", "Shadows" })
	end
	if instance:IsA("SpotLight") then
		add({ "Angle", "Face" })
	end
	if instance:IsA("SurfaceLight") then
		add({ "Angle", "Face" })
	end
	if instance:IsA("Sound") then
		add({ "EmitterSize", "Looped", "MaxDistance", "PlaybackSpeed", "RollOffMaxDistance", "RollOffMinDistance", "RollOffMode", "SoundGroup", "SoundId", "Volume" })
	end
	if instance:IsA("Highlight") then
		add({ "Adornee", "DepthMode", "Enabled", "FillColor", "FillTransparency", "OutlineColor", "OutlineTransparency" })
	end
	if instance:IsA("Tool") then
		add({ "CanBeDropped", "Enabled", "Grip", "RequiresHandle", "ToolTip" })
	end
	if instance:IsA("Humanoid") then
		add({ "AutoRotate", "BreakJointsOnDeath", "DisplayName", "Health", "HipHeight", "JumpPower", "MaxHealth", "PlatformStand", "Sit", "UseJumpPower", "WalkSpeed" })
	end
	if instance:IsA("ValueBase") then
		add({ "Value" })
	end
	if instance:IsA("ProximityPrompt") then
		add({ "ActionText", "ClickablePrompt", "Enabled", "Exclusivity", "GamepadKeyCode", "HoldDuration", "KeyboardKeyCode", "MaxActivationDistance", "ObjectText", "RequiresLineOfSight", "UIOffset" })
	end
	if instance:IsA("ClickDetector") then
		add({ "CursorIcon", "MaxActivationDistance" })
	end

	return properties
end

local function skipReason(instance)
	if instance:IsA("LuaSourceContainer") then
		return "executable code is intentionally excluded"
	end
	if instance:IsA("BaseRemoteEvent") or instance:IsA("RemoteFunction") then
		return "networking objects are intentionally excluded"
	end
	if instance:IsA("BindableEvent") or instance:IsA("BindableFunction") then
		return "bindable objects are intentionally excluded"
	end
	if instance.ClassName == "Terrain" or instance:IsA("Player") then
		return "this object cannot be serialized as part of a model"
	end
	return nil
end

local function buildScript(source)
	local records = {}
	local references = {}
	local warnings = {}
	local truncated = false

	local function note(message)
		if #warnings < 100 then
			table.insert(warnings, message)
		end
	end

	local function visit(instance, includedParent)
		if #records >= MAX_INSTANCES then
			truncated = true
			return
		end

		local reason = skipReason(instance)
		if reason then
			note(("Skipped %s (%s): %s"):format(instance:GetFullName(), instance.ClassName, reason))
			for _, child in ipairs(instance:GetChildren()) do
				visit(child, includedParent)
			end
			return
		end

		local record = {
			instance = instance,
			parent = includedParent,
			variable = "i" .. tostring(#records + 1),
		}
		table.insert(records, record)
		references[instance] = record.variable

		for _, child in ipairs(instance:GetChildren()) do
			visit(child, instance)
		end
	end

	visit(source, nil)
	if #records == 0 then
		return nil, "A seleção não contém uma instância exportável."
	end

	if truncated then
		note(("The export was truncated at %d instances."):format(MAX_INSTANCES))
	end

	local deferredReferenceSets = {}
	local lines = {
		"-- Generated by Studio Model Serializer.",
		"-- Use only with models you own or are authorized to use.",
		"-- Paste into the Roblox Studio Command Bar. Change TARGET_PARENT if needed.",
		"-- Scripts, remotes, and executable code were intentionally excluded.",
		"",
		"local TARGET_PARENT = workspace",
		"",
		"local function create(className, sourcePath)",
		"\tlocal ok, object = pcall(Instance.new, className)",
		"\tif not ok then",
		"\t\twarn(\"Could not create \" .. className .. \" from \" .. sourcePath)",
		"\t\treturn nil",
		"\tend",
		"\treturn object",
		"end",
		"",
		"local function set(object, property, value)",
		"\tif object == nil then return end",
		"\tpcall(function() object[property] = value end)",
		"end",
		"",
		"local function setAttribute(object, attribute, value)",
		"\tif object == nil then return end",
		"\tpcall(function() object:SetAttribute(attribute, value) end)",
		"end",
		"",
		"do",
	}

	for _, record in ipairs(records) do
		table.insert(lines, ("\tlocal %s = create(%s, %s)"):format(
			record.variable,
			quote(record.instance.ClassName),
			quote(record.instance:GetFullName())
		))
	end

	table.insert(lines, "")
	for _, record in ipairs(records) do
		local instance = record.instance
		for _, property in ipairs(propertyNames(instance)) do
			local readOk, value = pcall(function()
				return instance[property]
			end)
			if readOk then
				local valueText, reason = valueToLua(value, references)
				if valueText then
					local line = ("\tset(%s, %s, %s)"):format(record.variable, quote(property), valueText)
					-- Instance references such as Model.PrimaryPart need both objects parented first.
					if typeof(value) == "Instance" then
						table.insert(deferredReferenceSets, line)
					else
						table.insert(lines, line)
					end
				elseif reason then
					note(("Skipped %s.%s: %s"):format(instance:GetFullName(), property, reason))
				end
			end
		end

		local attributesOk, attributes = pcall(function()
			return instance:GetAttributes()
		end)
		if attributesOk then
			for attribute, value in pairs(attributes) do
				local valueText, reason = valueToLua(value, references)
				if valueText then
					table.insert(lines, ("\tsetAttribute(%s, %s, %s)"):format(record.variable, quote(attribute), valueText))
				elseif reason then
					note(("Skipped attribute %s.%s: %s"):format(instance:GetFullName(), attribute, reason))
				end
			end
		end
	end

	table.insert(lines, "")
	for _, record in ipairs(records) do
		local parentVariable = record.parent and references[record.parent] or "TARGET_PARENT"
		table.insert(lines, ("\tif %s and %s then %s.Parent = %s end"):format(
			record.variable,
			parentVariable,
			record.variable,
			parentVariable
		))
	end

	if #deferredReferenceSets > 0 then
		table.insert(lines, "")
		for _, line in ipairs(deferredReferenceSets) do
			table.insert(lines, line)
		end
	end

	local rootVariable = records[1].variable
	table.insert(lines, "")
	table.insert(lines, ("\tlocal RECONSTRUCTED_MODEL = %s"):format(rootVariable))
	table.insert(lines, "\tif RECONSTRUCTED_MODEL then")
	table.insert(lines, "\t\tprint(\"Reconstructed model:\", RECONSTRUCTED_MODEL:GetFullName())")
	table.insert(lines, "\tend")
	table.insert(lines, "end")

	if #warnings > 0 then
		table.insert(lines, "")
		table.insert(lines, "-- Serializer notes:")
		for _, warning in ipairs(warnings) do
			table.insert(lines, "-- " .. warning)
		end
	end

	return join(lines, "\n"), ("Generated %d instance(s)%s."):format(
		#records,
		truncated and ("; truncated at " .. MAX_INSTANCES) or ""
	)
end

local function selectedSource()
	local selected = Selection:Get()
	if #selected ~= 1 then
		return nil, "Selecione exatamente um Model, Folder ou BasePart antes de gerar."
	end

	local source = selected[1]
	if not (source:IsA("Model") or source:IsA("Folder") or source:IsA("BasePart")) then
		return nil, "A seleção deve ser um Model, Folder ou BasePart."
	end
	return source, nil
end

local function updateSelectionStatus()
	local source, message = selectedSource()
	if source then
		setStatus("Selecionado: " .. source:GetFullName())
	elseif output.Text == "" then
		setStatus(message, true)
	end
end

generateButton.MouseButton1Click:Connect(function()
	local source, errorMessage = selectedSource()
	if not source then
		setStatus(errorMessage, true)
		return
	end

	local scriptText, result = buildScript(source)
	if not scriptText then
		setStatus(result, true)
		return
	end

	output.Text = scriptText
	setStatus(result .. " Clique em ‘Selecionar saída (Ctrl+C)’ para copiar.")
end)

selectButton.MouseButton1Click:Connect(function()
	if output.Text == "" then
		setStatus("Ainda não há script para copiar.", true)
		return
	end

	output:CaptureFocus()
	output.CursorPosition = #output.Text + 1
	output.SelectionStart = 1
	setStatus("Texto selecionado. Use Ctrl+C (ou Cmd+C no macOS) e cole no Command Bar.")
end)

clearButton.MouseButton1Click:Connect(function()
	output.Text = ""
	setStatus("Saída limpa.")
end)

toolbarButton.Click:Connect(function()
	widget.Enabled = not widget.Enabled
	toolbarButton:SetActive(widget.Enabled)
	if widget.Enabled then
		updateSelectionStatus()
	end
end)

widget:GetPropertyChangedSignal("Enabled"):Connect(function()
	toolbarButton:SetActive(widget.Enabled)
end)

widget:BindToClose(function()
	widget.Enabled = false
end)

Selection.SelectionChanged:Connect(updateSelectionStatus)
updateSelectionStatus()
