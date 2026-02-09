--!strict
--[[
	AttributeConfig - Config implementation using Instance Attributes

	A strategy that manages Config values using
	Instance:GetAttribute() / Instance:SetAttribute().
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Signal = require(script.Parent.Parent.Parent.signal)
local BetterConfigTypes = require(script.Parent.Parent.BetterConfigTypes)

local AttributeConfig = {}
AttributeConfig.__index = AttributeConfig

export type AttributeConfig<T> = BetterConfigTypes.BaseConfigClass<T>

-- Creates a new AttributeConfig
function AttributeConfig.new<T>(src: Instance): AttributeConfig<T>
	local self = setmetatable({}, AttributeConfig)

	self.ConfigSrc = src
	self.ConfigType = "Attribute" :: BetterConfigTypes.ConfigSrcType
	self._connections = {}
	self._signals = {}
	self._attributeConnection = nil :: RBXScriptConnection?

	return self :: any
end

-- Gets the value for the specified key
function AttributeConfig:Get(key: string): any
	return self.ConfigSrc:GetAttribute(key)
end

-- Sets the value for the specified key
function AttributeConfig:Set(key: string, value: any)
	self.ConfigSrc:SetAttribute(key, value)
end

-- Ensures the shared AttributeChanged connection is set up (lazy initialization)
function AttributeConfig:_ensureAttributeConnection()
	if self._attributeConnection then
		return
	end

	self._attributeConnection = self.ConfigSrc.AttributeChanged:Connect(function(attributeName: string)
		local signal = self._signals[attributeName]
		if signal then
			local newValue = self.ConfigSrc:GetAttribute(attributeName)
			signal:Fire(newValue)
		end
	end)

	-- Also store in _connections for batch cleanup in Destroy
	self._connections["_attributeConnection"] = self._attributeConnection
end

-- Gets the value changed signal for the specified key
function AttributeConfig:GetValueChangedSignal(key: string)
	-- Return existing signal if it exists
	if self._signals[key] then
		return self._signals[key]
	end

	local signal = Signal.new()
	self._signals[key] = signal

	-- Ensure shared attribute connection (lazy initialization)
	self:_ensureAttributeConnection()

	return signal
end

-- Destroys and cleans up resources
function AttributeConfig:Destroy()
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

	self._attributeConnection = nil

	table.clear(self)
end

return AttributeConfig
