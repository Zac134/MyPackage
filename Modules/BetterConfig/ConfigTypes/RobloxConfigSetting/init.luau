local RunService = game:GetService("RunService")
local Types = require(script.RobloxConfigTypes)
local ConfigRemote = script.ConfigRemote

export type ConfigClass<T> = Types.ConfigClass<T>
export type ServerConfigSetting = {
	wave_ui_functionality: ConfigClass<boolean>,
	wave_interval_time: ConfigClass<number>,
}

--To Adjust Roblox Config, add here by referencing type.
local ConfigSettings = {
	wave_ui_functionality = {
		configKey = "wave_ui_functionality",
		defaultValue = false,
		shouldObserve = false,
		experimentOption = {
			targetPlayerType = "All",
			useExperiment = true,
		},
	} :: Types.ConfigSetting<boolean>,
	wave_interval_time = {
		configKey = "wave_interval_time",
		defaultValue = 0,
		shouldObserve = false,
		experimentOption = {
			useExperiment = false,
		},
	} :: Types.ConfigSetting<number>,
}

if RunService:IsClient() then
	local clientValues = {}
	ConfigRemote:FireServer()
	ConfigRemote.OnClientEvent:Connect(function(allValue: { [string]: any })
		for key, value in allValue do
			clientValues[key] = value
		end
	end)
	clientValues = ConfigRemote.OnClientEvent:Wait()

	--Add typecasting for intellisense
	return clientValues :: {
		wave_ui_functionality: boolean,
		wave_interval_time: number,
	}
elseif RunService:IsServer() then
	local RobloxConfig = require(script.RobloxConfig)

	local allValue = {}

	for configKey, configSetting in ConfigSettings do
		local configClass = RobloxConfig.new(configSetting)
		allValue[configKey] = configClass
	end

	local clientReplicationValues = {
		[allValue.wave_interval_time.Key] = allValue.wave_interval_time.Value,
		[allValue.wave_ui_functionality.Key] = allValue.wave_ui_functionality.Value,
	}

	for configKey, configClass in allValue do
		configClass.ValueChangedSignal:Connect(function(newValue: any)
			clientReplicationValues[configClass.Key] = newValue
			ConfigRemote:FireAllClients(clientReplicationValues)
		end)
	end

	ConfigRemote.OnServerEvent:Connect(function(player: Player)
		local clientValue = table.clone(clientReplicationValues)
		for configKey, configClass in allValue do
			clientValue[configKey] = configClass:GetValueForPlayer(player)
		end
		ConfigRemote:FireClient(player, clientValue)
	end)

	--Add typecasting for intellisense
	return allValue :: ServerConfigSetting
end

return ConfigSettings
