--!strict
--[[
	ConfigInstance - Config implementation using Configuration/ValueBase

	A strategy that manages Config values using ValueBase children
	(IntValue, StringValue, etc.) of a Configuration instance.
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BetterConfigTypes = require(script.Parent.Parent.BetterConfigTypes)
local Signal = require(script.Parent.Parent.Parent.signal)

local ConfigInstance = {}
ConfigInstance.__index = ConfigInstance

export type ConfigInstance<T> = typeof(setmetatable({} :: BetterConfigTypes.BaseConfigClass<T>, ConfigInstance))

-- Checks if a ValueBase has a Value property
local function hasValueProperty(object: any): boolean
	local success, _ = pcall(function()
		return object.Value
	end)
	return success
end

-- Creates a new ConfigInstance
function ConfigInstance.new<T>(src: Configuration): ConfigInstance<T>
	local self = setmetatable({}, ConfigInstance)

	self.ConfigSrc = src
	self.ConfigType = "Configuration" :: BetterConfigTypes.ConfigSrcType
	self._connections = {}
	self._signals = {}

	return self
end

-- Gets the value for the specified key
function ConfigInstance.Get<T>(self: ConfigInstance<T>, key: string): T
	local valueBase = self.ConfigSrc:FindFirstChild(key)
	if valueBase and valueBase:IsA("ValueBase") and hasValueProperty(valueBase) then
		return (valueBase :: any).Value
	end
	return nil
end

-- Sets the value for the specified key
function ConfigInstance.Set<T>(self: ConfigInstance<T>, key: keyof<T>, value: T)
	local valueBase = self.ConfigSrc:FindFirstChild(key)
	if valueBase and valueBase:IsA("ValueBase") and hasValueProperty(valueBase) then
		(valueBase :: any).Value = value
	else
		warn(`[ConfigInstance] ValueBase "{key}" not found in Configuration`)
	end
end

-- Gets the value changed signal for the specified key
function ConfigInstance:GetValueChangedSignal(key)
	-- Return existing signal if it exists
	if self._signals[key] then
		return self._signals[key]
	end

	local signal = Signal.new()
	self._signals[key] = signal

	-- Find the specific ValueBase
	local valueBase = self.ConfigSrc:FindFirstChild(key) :: BetterConfigTypes.HasValuePropertyObject?

	if valueBase and valueBase:IsA("ValueBase") and hasValueProperty(valueBase) then
		-- Only create connection if it doesn't exist
		if not self._connections[key] then
			self._connections[key] = (valueBase :: BetterConfigTypes.HasValuePropertyObject)
				:GetPropertyChangedSignal("Value")
				:Connect(function()
					local newValue = (valueBase :: any).Value
					-- Fire the signal
					if self._signals[key] then
						self._signals[key]:Fire(newValue)
					end
				end)
		end
	else
		warn(`[ConfigInstance] ValueBase "{key}" not found in Configuration`)
	end

	return signal
end

-- Destroys and cleans up resources
function ConfigInstance:Destroy()
	-- Disconnect all connections
	if self._connections then
		for key, connection: RBXScriptConnection in self._connections do
			connection:Disconnect()
			self._connections[key] = nil
		end
		table.clear(self._connections)
	end

	-- Destroy all signals
	if self._signals then
		for key, signal in self._signals do
			signal:Destroy()
			self._signals[key] = nil
		end
		table.clear(self._signals)
	end

	table.clear(self)
end

return ConfigInstance
