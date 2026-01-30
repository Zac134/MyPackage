local ConfigService = game:GetService("ConfigService")
local Players = game:GetService("Players")
local Types = require(script.Parent.RobloxConfigTypes)

local RobloxConfig = {}

export type ConfigSetting<T> = Types.ConfigSetting<T>
export type ConfigClass<T> = Types.ConfigClass<T>

function RobloxConfig.new<T>(configInfo: ConfigSetting<T>): ConfigClass<T>
	local self = {}
	self.ConfigSetting = configInfo
	self._connections = {}
	self.Value = configInfo.defaultValue
	self.GetValueForPlayer = RobloxConfig.GetValueForPlayer
	self.IsExperimentEnabled = RobloxConfig.IsExperimentEnabled
	self._playerSnapShotLoaded = Instance.new("BindableEvent")
	self.PlayerSnapShotLoaded = self._playerSnapShotLoaded.Event

	self.Key = configInfo.configKey
	self.GlobalSnapShot = nil
	self._playerSnapShots = {}
	self._valueChangedSignal = Instance.new("BindableEvent")
	self.ValueChangedSignal = self._valueChangedSignal.Event

	RobloxConfig._init(self)

	return self
end

function RobloxConfig.IsExperimentEnabled<T>(self: ConfigClass<T>): boolean
	return self.ConfigSetting.experimentOption.useExperiment == true
end

function RobloxConfig._init<T>(self: ConfigClass<T>)
	if self.ConfigSetting.experimentOption.useExperiment ~= true then
		RobloxConfig._fetchSnapShot(self)
		if self.ConfigSetting.shouldObserve == true then
			RobloxConfig._observeValueChanged(self)
		end
		return
	end

	local targetPlayerType = self.ConfigSetting.experimentOption.targetPlayerType

	if targetPlayerType == "All" or targetPlayerType == "Manual" then
		Players.PlayerAdded:Connect(function(player: Player)
			RobloxConfig._fetchSnapShotForPlayer(self, player)
		end)
		for _, player in Players:GetPlayers() do
			RobloxConfig._fetchSnapShotForPlayer(self, player)
		end
	elseif targetPlayerType == "Initial" then
		local initialPlayer = Players:GetPlayers()[1] or Players.PlayerAdded:Wait()
		RobloxConfig._fetchSnapShotForPlayer(self, initialPlayer)
	end

	if self.ConfigSetting.shouldObserve == true then
		RobloxConfig._observeValueChanged(self)
	end

	Players.PlayerRemoving:Connect(function(player: Player)
		if self._playerSnapShots[player] then
			self._playerSnapShots[player] = nil
		end
	end)
end

function RobloxConfig._fetchSnapShot<T>(self: ConfigClass<T>)
	local success, result = pcall(function(...)
		return ConfigService:GetConfigAsync(self.ConfigSetting.configKey)
	end)
	if not success then
		warn(result)
		return
	end
	self.GlobalSnapShot = result
	self.Value = self.GlobalSnapShot:GetValue(self.ConfigSetting.configKey)
end

--Only call COnfigService:GetValueForPlayerAsync when experiment is enabled.
function RobloxConfig.GetValueForPlayer<T>(self: ConfigClass<T>, player: Player): T
	local playerSnapShot = self._playerSnapShots[player]

	if not playerSnapShot and self.ConfigSetting.experimentOption.useExperiment ~= true then
		return self.Value
	elseif not playerSnapShot then
		repeat
			local snapShotLoadedPlayer = self.PlayerSnapShotLoaded:Wait()
		until snapShotLoadedPlayer == player
		playerSnapShot = self._playerSnapShots[player]
	end
	local experimentValueForPlayer = playerSnapShot:GetValue(self.ConfigSetting.configKey)
	print("experimentValueForPlayer", player.Name, self.ConfigSetting.configKey, experimentValueForPlayer)
	return experimentValueForPlayer
end

function RobloxConfig._fetchSnapShotForPlayer<T>(self: ConfigClass<T>, player: Player)
	local success, result = pcall(function(...)
		return ConfigService:GetConfigForPlayerAsync(player)
	end)
	if not success then
		warn("failed to fetch snap shot for player", self.ConfigSetting.configKey, result)
		result = self.GlobalSnapShot
	end
	self._playerSnapShots[player] = result
	self._playerSnapShotLoaded:Fire(player)
end

function RobloxConfig._observeValueChanged<T>(self: ConfigClass<T>)
	if not self.GlobalSnapShot then
		return
	end
	self.GlobalSnapShot.UpdateAvailable:Connect(function(...)
		self.GlobalSnapShot:Refresh()
	end)
	self.GlobalSnapShot:GetValueChangedSignal(self.ConfigSetting.configKey):Connect(function(newValue: T)
		self.Value = newValue
		self._valueChangedSignal:Fire(newValue)
	end)
end

return RobloxConfig
