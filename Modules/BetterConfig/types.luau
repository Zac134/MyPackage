local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Signal = require(ReplicatedStorage.Packages.signal)

type hasValuePropertyObject =
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

type ConfigSrc = Configuration | Instance | { [string]: any }

export type BaseConfigClass<T = string> = {
	ConfigSrc: ConfigSrc,

	Get: <K>(self: BaseConfigClass<T>, key: K & keyof<T>) -> index<T, K>,
	Set: <K>(self: BaseConfigClass<T>, key: K & keyof<T>, value: index<T, K>) -> (),
    GetValueChangedSignal: <K>(self: BaseConfigClass<T>, key: K & keyof<T>) -> Signal.Signal<index<T, K>>,
	Destroy: (self: BaseConfigClass<T>) -> (),
}

return {}
