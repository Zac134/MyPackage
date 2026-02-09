--!strict
--[[
	RbxConfig - Singleton wrapper for Roblox ConfigService

	Usage (Server):
		local RbxConfigModule = require(path.to.RbxConfig)
		local RbxConfig = RbxConfigModule:InitServer({
			wave_ui_functionality = false,
			wave_interval_time = 0,
		})

		local value = RbxConfig:GetValue("wave_ui_functionality")
		RbxConfig:GetValueChangedSignal("wave_ui_functionality"):Connect(function(newValue)
			print("Changed to", newValue)
		end)
		local playerValue = RbxConfig:GetValueForPlayer("wave_ui_functionality", player)
		RbxConfig:SetTestingValue("wave_ui_functionality", true)
		RbxConfig:ClearTestingValue("wave_ui_functionality")

	Usage (Client):
		local RbxConfigModule = require(path.to.RbxConfig)
		local RbxConfig = RbxConfigModule:InitClient({
			wave_ui_functionality = false,
			wave_interval_time = 0,
		})

		local value = RbxConfig:GetValue("wave_ui_functionality")
		RbxConfig:GetValueChangedSignal("wave_ui_functionality"):Connect(function(newValue)
			print("Changed to", newValue)
		end)
]]

local RunService = game:GetService("RunService")

local Types = require(script.RbxConfigTypes)
local signal = require(script.Packages.signal)
local Server_RbxConfig = require(script.Server_RbxConfig)
local Client_RbxConfig = require(script.Client_RbxConfig)

export type ServerConfigClass<T = { [string]: any }> = Types.ServerConfigClass<T>
export type RbxConfig<T = { [string]: any }> = Types.RbxConfig<T>
export type RbxConfigModule = Types.RbxConfigModule
export type ConfigSetting = Types.ConfigSetting

local isServer = RunService:IsServer()

local RbxConfig = {}

-- Internal state
RbxConfig._configSettings = {} :: { [string]: any }
RbxConfig._values = {} :: { [string]: any }
RbxConfig._signals = {} :: { [string]: signal.Signal<any> }
RbxConfig._initialized = false

--- Internal initialization logic.
--- Sets up config values and delegates to server/client handler.
function RbxConfig._init(self: typeof(RbxConfig), configSettings: ConfigSetting)
	if self._initialized then
		warn("[RbxConfig] Already initialized")
		return
	end
	self._initialized = true
	self._configSettings = configSettings

	-- Set defaults as initial values
	for key, defaultValue in configSettings do
		self._values[key] = defaultValue
	end

	if isServer then
		Server_RbxConfig.init(self, configSettings)
	else
		Client_RbxConfig.init(self, configSettings)
	end
end

--- Initialize RbxConfig for server use.
--- Returns ServerConfigClass<T> with full key autocomplete for all methods
--- including GetValue, SetTestingValue, GetValueForPlayer, etc.
function RbxConfig.InitServer(self: typeof(RbxConfig), configSettings: ConfigSetting)
	self:_init(configSettings)
	return self :: any
end

--- Initialize RbxConfig for client use.
--- Returns RbxConfig<T> with key autocomplete for GetValue, GetValueChangedSignal.
function RbxConfig.InitClient(self: typeof(RbxConfig), configSettings: ConfigSetting)
	self:_init(configSettings)
	return self :: any
end

--- Get the current value for a config key.
--- Returns the test override if set, otherwise the live value, otherwise the default.
function RbxConfig.GetValue(self: typeof(RbxConfig), key: string)
	-- Server: check test overrides first
	if isServer and self._testOverrides and self._testOverrides[key] ~= nil then
		return self._testOverrides[key]
	end

	local value = self._values[key]
	if value ~= nil then
		return value
	end

	return self._configSettings[key]
end

--- Get a signal that fires when a config value changes.
--- On the server, this lazily starts observing the ConfigSnapshot for that key.
--- On the client, the signal fires when the server pushes a value update.
function RbxConfig.GetValueChangedSignal(self: typeof(RbxConfig), key: string)
	if self._signals[key] then
		return self._signals[key]
	end

	local sig = signal.new()
	self._signals[key] = sig

	-- Server: start lazy observation for this key
	if isServer then
		Server_RbxConfig.startObserving(self, key)
	end

	return sig
end

--- [Server Only] Get the config value for a specific player.
--- Uses ConfigService:GetConfigForPlayerAsync with snapshot caching.
function RbxConfig.GetValueForPlayer(self: typeof(RbxConfig), key: string, player: Player)
	if not isServer then
		warn("[RbxConfig] GetValueForPlayer is only available on the server")
		return nil
	end

	return Server_RbxConfig.getValueForPlayer(self, key, player)
end

--- [Server Only] Set a testing override value for a config key.
--- Overrides GetValue results and pushes the override to all clients.
function RbxConfig.SetTestingValue(self: typeof(RbxConfig), key: string, value: any)
	if not isServer then
		warn("[RbxConfig] SetTestingValue is only available on the server")
		return
	end

	Server_RbxConfig.setTestingValue(self, key, value)
end

--- [Server Only] Clear a testing override, restoring the real ConfigService value.
--- Also pushes the restored value to all clients.
function RbxConfig.ClearTestingValue(self: typeof(RbxConfig), key: string)
	if not isServer then
		warn("[RbxConfig] ClearTestingValue is only available on the server")
		return
	end

	Server_RbxConfig.clearTestingValue(self, key)
end

return RbxConfig :: RbxConfigModule
