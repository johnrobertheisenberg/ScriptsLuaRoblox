--[[

	CAMERA EM PRIMEIRA PESSOA
	Suporte a Mouse e controle
	- 
	- 
	
]]

-- SERVIÇOS
local Players = game["Players"]
local UserInputService = game["UserInputService"]
local RunService = game["Run Service"]

-- PLAYER
local Player = Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
local Head = Character:WaitForChild("Head")

-- CÂMERA
local Camera = workspace.CurrentCamera
Camera.CameraType = Enum.CameraType.Scriptable
Camera.FieldOfView = 90

-- CONFIG
local MAX_VERTICAL_ANGLE = 60
local MOUSE_SENS = 0.2
local GAMEPAD_SENS = 100
local DEADZONE = 0.15

local OFFSET = CFrame.new(0, 2, 1) -- posição da câmera na cabeça
local INVERT_Y = true
-- ESTADO
local horizontal = 0 -- yaw -- euler angle 
local vertical = 0   -- pitch
local usingMouse = false

-- ESCONDER PERSONAGEM
local function stayInvisible()
	for _, v in ipairs(Character:GetDescendants()) do
		if v:IsA("BasePart") then
			v.LocalTransparencyModifier = 1
		elseif v:IsA("Decal") then
			v.Transparency = 1
		end
	end
end

-- MOUSE
local function updateCameraRotationMouse(delta)
	horizontal += delta.X * MOUSE_SENS
	vertical   -= delta.Y * MOUSE_SENS
	vertical = math.clamp(vertical, -MAX_VERTICAL_ANGLE, MAX_VERTICAL_ANGLE)
end

-- Pega o analógico direito do controle e retorna a posição 
local function getRightThumbstick()
	for _, input in ipairs(UserInputService:GetGamepadState(Enum.UserInputType.Gamepad1)) do
		if input.KeyCode == Enum.KeyCode.Thumbstick2 then
			return input.Position
		end
	end
	return Vector2.zero 
end

local function updateCameraRotationGamepad(dt)
	local stick = getRightThumbstick() 

	if stick.Magnitude < DEADZONE then -- evitar drift gay
		return -- retorna gay se tiver deadzone
	end
	local invert = INVERT_Y and 1 or -1
	horizontal += stick.X * GAMEPAD_SENS * dt 
	if INVERT_Y then
		vertical += stick.Y * GAMEPAD_SENS * dt 
	else
		vertical  -= stick.Y * GAMEPAD_SENS * dt 
	end
	
	print(INVERT_Y)
	print(vertical)
	vertical = math.clamp(vertical, -MAX_VERTICAL_ANGLE, MAX_VERTICAL_ANGLE)
end

-- ROTACIONA PERSONAGEM
local function updateCharacterRotation()
	HumanoidRootPart.CFrame =
		CFrame.new(HumanoidRootPart.Position)
		* CFrame.Angles(0, math.rad(-horizontal), 0)
end

-- POSICIONA CÂMERA
local function updateCamera()
	local base =
		CFrame.new(Head.Position)
		* CFrame.Angles(0, math.rad(-horizontal), 0)
		* CFrame.Angles(math.rad(vertical), 0, 0)

	Camera.CFrame = base * OFFSET
	updateCharacterRotation()
end
local function updateFov()
	local speed = HumanoidRootPart.AssemblyLinearVelocity.Magnitude
	local fov = 90 + speed * 0.1  -- 0.1 = multiplicador de intensidade
	Camera.FieldOfView = math.clamp(fov, 70, 90)

end
-- INPUT
UserInputService.InputChanged:Connect(function(input, processed)
	if processed then return end

	if input.UserInputType == Enum.UserInputType.MouseMovement then
		updateCameraRotationMouse(input.Delta)
		usingMouse = true
	end
end)

-- LOOP
local function main()
	stayInvisible()
	
	UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
	UserInputService.MouseIconEnabled = false
	
	RunService.RenderStepped:Connect(function(dt)
		updateFov()
		
		if usingMouse then
			updateCamera()
			usingMouse = false
		else
			updateCameraRotationGamepad(dt)
			updateCamera()
		end
		
		
	end)
end

main()
