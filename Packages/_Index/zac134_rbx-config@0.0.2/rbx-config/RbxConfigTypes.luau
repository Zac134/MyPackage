local signal = require(script.Parent.Packages.signal)

-- T represents the config defaults map
-- e.g. { wave_ui_functionality: boolean, wave_interval_time: number }
type Json = string
export type ConfigSettingValue = number | string  | Json
export type ConfigSetting = { [string] : ConfigSettingValue}

-- RbxConfig<T>: Init後のクライアント用型
export type RbxConfig<T = ConfigSetting> = {
	-- Internal state (cf. BetterConfig: _connections, _signals)
	_configSettings: T,
	_values: { [string]: any },
	_signals: { [string]: signal.Signal<any> },
	_initialized: boolean,

	-- Public API
	GetValue: (self: RbxConfig<T>, key: keyof<T>) -> index<T, keyof<T>>,
	GetValueChangedSignal: (self: RbxConfig<T>, key: keyof<T>) -> signal.Signal<index<T, keyof<T>>>,
}

-- ServerConfigClass<T>: Init後のサーバー用型
export type ServerConfigClass<T = { [string]: any }> = {
	-- Server-only internal state
	_testOverrides: { [string]: any },
	_observing: { [string]: boolean },
	_playerSnapshots: { [Player]: any },
	_remoteEvent: RemoteEvent?,
	_remoteFunction: RemoteFunction?,

	-- Server-only API
	SetTestingValue: (self: ServerConfigClass<T>, key: keyof<T>, value: index<T, keyof<T>>) -> (),
	ClearTestingValue: (self: ServerConfigClass<T>, key: keyof<T>) -> (),
	GetValueForPlayer: (self: ServerConfigClass<T>, key: keyof<T>, player: Player) -> index<T, keyof<T>>,
} & RbxConfig<T>

-- RbxConfigModule: require直後のモジュール型（InitServer/InitClientを持つ）
export type RbxConfigModule = {
	InitServer: <U>(self: RbxConfigModule, configSettings: U) -> ServerConfigClass<U>,
	InitClient: <U>(self: RbxConfigModule, configSettings: U) -> RbxConfig<U>,
}

return {}
