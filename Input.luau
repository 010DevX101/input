--!strict
type Context = {
	Name: string,
	Enabled: boolean,
	Priority: number,
	Sink: boolean,
	Actions: {[string]: Action}
}

type Action = {
	Enabled: boolean,
	Type: Enum.InputActionType,
	KeyboardBinding: Binding?,
	TouchBinding: Binding?,
	GamepadBinding: Binding?,
	StateChanged: (value: any) -> (),
	Pressed: (() -> ())?,
	Released: (() -> ())?
}

type Binding = {
	KeyCode: Enum.KeyCode?,
	UIButton: GuiButton?,
	Scale: number?,
	Vector2Scale: Vector2?,
	Backward: Enum.KeyCode?,
	Down: Enum.KeyCode?,
	Forward: Enum.KeyCode?,
	Left: Enum.KeyCode?,
	Right: Enum.KeyCode?,
	Up: Enum.KeyCode?,
	PressedThreshold: number?,
	ReleasedThreshold: number?,
	ResponseCurve: number?
}

local INPUT_DIRECTORY = script
local KEY_CODES_WITH_THRESHOLD = {
	Enum.KeyCode.ButtonL2,
	Enum.KeyCode.ButtonR2,
	Enum.KeyCode.Thumbstick1Down,
	Enum.KeyCode.Thumbstick1Left,
	Enum.KeyCode.Thumbstick1Right,
	Enum.KeyCode.Thumbstick1Up,
	Enum.KeyCode.Thumbstick2Down,
	Enum.KeyCode.Thumbstick2Left,
	Enum.KeyCode.Thumbstick2Right,
	Enum.KeyCode.Thumbstick2Up
}
local KEY_CODES_WITH_RESPONSE_CURVE = {
	Enum.KeyCode.Thumbstick1,
	Enum.KeyCode.Thumbstick2Up
}

local function applyThreshold(
	binding: InputBinding,
	pressedThreshold: number?,
	releasedThreshold: number?,
	keyCode: Enum.KeyCode
)
	if not table.find(KEY_CODES_WITH_THRESHOLD, keyCode) and (pressedThreshold or releasedThreshold) then
		warn(`Key code {keyCode} does not support pressed threshold nor released threshold!`)
		return
	end
	if pressedThreshold then
		binding.PressedThreshold = pressedThreshold
	end
	if releasedThreshold then
		binding.ReleasedThreshold = releasedThreshold
	end
end

local function applyResponseCurve(
	binding: InputBinding,
	responseCurve: number?,
	keyCode: Enum.KeyCode
)
	if not table.find(KEY_CODES_WITH_RESPONSE_CURVE, keyCode) and responseCurve then
		warn(`Key code {keyCode} does not support response curve!`)
		return
	end
	if responseCurve then
		binding.ResponseCurve = responseCurve
	end
end

function createBinding(
	data: Binding,
	action: InputAction
): InputBinding
	local binding = Instance.new("InputBinding")
	if data.KeyCode and binding.KeyCode then
		binding.KeyCode = data.KeyCode
		applyThreshold(binding, data.PressedThreshold, data.ReleasedThreshold, data.KeyCode)
		applyResponseCurve(binding, data.ResponseCurve, data.KeyCode)
	end
	if data.Scale then
		binding.Scale = data.Scale
	end
	if data.UIButton then
		binding.UIButton = data.UIButton
	end
	if data.Forward then
		binding.Forward = data.Forward
	end
	if data.Backward then
		binding.Backward = data.Backward
	end
	if data.Left then
		binding.Left = data.Left
	end
	if data.Right then
		binding.Right = data.Right
	end
	if data.Down then
		binding.Down = data.Down
	end
	if data.Up then
		binding.Up = data.Up
	end
	if data.Vector2Scale then
		binding.Vector2Scale = data.Vector2Scale
	end
	binding.Parent = action
	return binding
end

function createAction(
	name: string,
	data: Action,
	context: InputContext
): InputAction
	local action = Instance.new("InputAction")
	action.Name = name
	action.Enabled = data.Enabled
	action.Type = data.Type
	if data.Pressed then
		action.Pressed:Connect(data.Pressed)
	end
	if data.Released then
		action.Released:Connect(data.Released)
	end
	action.StateChanged:Connect(data.StateChanged)
	action.Parent = context
	for _, binding in { data.KeyboardBinding, data.GamepadBinding, data.TouchBinding } do
		if not binding then
			continue
		end
		createBinding(binding, action)
	end
	return action
end

function createContext(
	data: Context
): InputContext
	local context = Instance.new("InputContext")
	context.Name = data.Name
	context.Enabled = data.Enabled
	context.Sink = data.Sink
	context.Priority = data.Priority
	context.Parent = INPUT_DIRECTORY
	for name, actionData in data.Actions do
		createAction(name, actionData, context)
	end
	return context
end

return {
	createContext = createContext,
	createAction = createAction,
	createBinding = createBinding
}
