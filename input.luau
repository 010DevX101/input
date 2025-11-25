--!strict
export type Context = {
	Enabled: boolean?,
	Priority: number?,
	Sink: boolean?,
	Actions: {[string]: Action}?
}

export type Action = {
	Enabled: boolean?,
	Type: Enum.InputActionType,
	Bindings: {[BindingType]: Binding}?,
	StateChanged: ((value: any) -> ())?,
	Pressed: (() -> ())?,
	Released: (() -> ())?
}

export type Binding = {
	Type: BindingType,
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

export type BindingType = |
	"Keyboard" |
	"Gamepad" |
	"Touch"

export type ContextFn =
	((name: string) -> InputContext)
	& ((name: string, data: Context?) -> InputContext?)
export type ActionFn =
	((action: string, context: InputContext, data: Action) -> (InputAction))
	& ((action: string, context: string) -> (InputAction?))
export type BindingFn =
	((type: BindingType, action: InputAction, data: Binding) -> (InputBinding))
	& ((type: BindingType, action: string, context: string) -> (InputBinding?))

local INPUT_DIRECTORY = script
local DEFAULT_CONTEXT = {
	Enabled = true,
	Priority = 1000,
	Sink = false
}
local DEFAULT_ACTION = {
	Enabled = true
}

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
	Enum.KeyCode.Thumbstick2
}

local contextList: {[string]: InputContext} = {}

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

local function getContext(
	name: string
): InputContext?
	local context = contextList[name]
	if not context then
		warn(`Could not retrieve context with name {name}!`)
		return nil
	end
	return context
end

local function getAction(
	actionName: string,
	contextName: string
): InputAction?
	local context = contextList[contextName]
	if not context then
		warn(`Could not retrieve action from context of name {contextName}!`)
		return nil
	end
	local action = context:FindFirstChild(actionName)
	if not action or not action:IsA("InputAction") then
		warn(`Could not retrieve action with name {actionName} in context {contextName}!`)
		return nil
	end
	return action
end

local function getBinding(
	type: BindingType,
	contextName: string,
	actionName: string
): InputBinding?
	local action = getAction(actionName, contextName)
	if not action then
		return nil
	end
	local binding = action:FindFirstChild(type)
	if not binding or not binding:IsA("InputBinding") then
		warn(`Could not retrieve binding of type {type} in action {actionName}!`)
		return nil
	end
	return binding
end

local function createBinding(
	type: BindingType,
	action: InputAction,
	data: Binding
): InputBinding
	local binding = Instance.new("InputBinding")
	binding.Name = type
	if data.KeyCode then
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

local function createAction(
	actionName: string,
	context: InputContext,
	data: Action
): InputAction
	local action = Instance.new("InputAction")
	action.Name = actionName
	action.Enabled = data.Enabled or DEFAULT_ACTION.Enabled
	action.Type = data.Type
	if data.Pressed then
		action.Pressed:Connect(data.Pressed)
	end
	if data.Released then
		action.Released:Connect(data.Released)
	end
	if data.StateChanged then
		action.StateChanged:Connect(data.StateChanged)
	end
	action.Parent = context
	if data.Bindings then
		for type: BindingType, binding: Binding? in data.Bindings do
			if not binding then
				continue
			end
			createBinding(type, action, binding)
		end
	end
	return action
end

local function createContext(
	name: string,
	data: Context
): InputContext
	local context = Instance.new("InputContext")
	context.Name = name
	context.Enabled = data.Enabled or DEFAULT_CONTEXT.Enabled
	context.Sink = data.Sink or DEFAULT_CONTEXT.Sink
	context.Priority = data.Priority or DEFAULT_CONTEXT.Priority
	context.Parent = INPUT_DIRECTORY
	contextList[name] = context
	if data.Actions then
		for actionName, actionData in data.Actions do
			createAction(actionName, context, actionData)
		end
	end
	return context
end

return {
	context = function(
		name: string,
		data: Context?
	): InputContext?
		return data and createContext(name, data) or getContext(name)
	end :: ContextFn,
	action = function(
		name: string,
		context: any,
		data: any
	): InputAction?
		if typeof(context) == "string" then
			return getAction(name, context)
		end
		return data and createAction(name, context, data)
	end :: ActionFn,
	binding = function(
		type: BindingType,
		action: InputAction | string,
		context: string,
		data: Binding?
	): InputBinding?
		if typeof(action) == "string" then
			return context and getBinding(type, context, action)
		end
		return data and createBinding(type, action, data)
	end :: BindingFn
}
