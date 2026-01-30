export type ConfigSetting<T> = {
	configKey: string,
	defaultValue: T,
	shouldObserve: boolean,
	experimentOption: {
		targetPlayerType: "All" | "Initial" | "Manual",
		useExperiment: boolean,
	},
}

export type ConfigClass<T> = {
	ConfigSetting: ConfigSetting<T>,
	Value: T,
	Key: string,
	GlobalSnapShot: ConfigSnapshot,
	GetValueForPlayer: (self: ConfigClass<T>, player: Player) -> T,
	IsExperimentEnabled: (self: ConfigClass<T>) -> boolean,
	ValueChangedSignal: RBXScriptSignal,
	PlayerSnapShotLoaded: RBXScriptSignal,

	_valueChangedSignal: BindableEvent,
	_connections: { RBXScriptConnection? },
	_playerSnapShots: { [Player]: ConfigSnapshot },
	_playerSnapShotLoaded: BindableEvent,
}

return {}
