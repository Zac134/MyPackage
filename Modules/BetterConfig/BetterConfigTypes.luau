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

	Get: <K>(self: BaseConfigClass<T>, key: keyof<T>) -> index<T, K>,
	Set: <K>(self: BaseConfigClass<T>, key: keyof<T>, value: any) -> (),
	GetValueChangedSignal: <K>(self: BaseConfigClass<T>, key: keyof<T>) -> Signal.Signal<index<T, K>>,
	Destroy: (self: BaseConfigClass<T>) -> (),

	-- Internal state
	_connections: { [string]: RBXScriptConnection },
	_signals: { [string]: Signal.Signal<any> },
}

return {}
