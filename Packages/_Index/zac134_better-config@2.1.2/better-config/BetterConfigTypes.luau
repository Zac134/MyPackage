local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Signal = require(ReplicatedStorage.Packages.signal)

-- Type for ValueBase objects that have a Value property
export type HasValuePropertyObject =
	ObjectValue
	| IntValue
	| BoolValue
	| StringValue
	| NumberValue
	| Color3Value
	| CFrameValue
	| Vector3Value
	| BrickColorValue
	| RayValue

-- ConfigSrc type discriminator
export type ConfigSrcType = "Configuration" | "Attribute" | "Dict"

-- Type for Config source Instance
export type ConfigSrc = Configuration | Instance | { [string]: any }

-- Internal state type
export type ConfigState = {
	_connections: { [string]: RBXScriptConnection },
	_signals: { [string]: any },
}

-- BaseConfigClass interface
export type BaseConfigClass<T = { [string]: any }> = {
	ConfigSrc: ConfigSrc,
	ConfigType: ConfigSrcType,

	Get: (self: BaseConfigClass<T>, key: keyof<T>) -> index<T, keyof<T>>,
	Set: (self: BaseConfigClass<T>, key: keyof<T>, value: index<T, keyof<T>>) -> (),
	GetValueChangedSignal: (self: BaseConfigClass<T>, key: keyof<T>) -> Signal.Signal<index<T, keyof<T>>>,
	Destroy: (self: BaseConfigClass<T>) -> (),

	-- Internal state
	_connections: { [string]: RBXScriptConnection },
	_signals: { [string]: Signal.Signal<any> },
}

return {}
