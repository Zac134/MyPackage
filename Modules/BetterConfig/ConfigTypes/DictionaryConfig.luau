--!strict
--[[
	DictionaryConfig - Config implementation using a Lua dictionary

	A strategy that accepts a {[string]: any} table, creates a Configuration
	instance with appropriate ValueBase children under this script,
	and delegates all operations to an internal ConfigInstance.
]]

local BetterConfigTypes = require(script.Parent.Parent.BetterConfigTypes)
local ConfigInstance = require(script.Parent.ConfigInstance)

local DictionaryConfig = {}
DictionaryConfig.__index = DictionaryConfig

export type DictionaryConfig<T> = BetterConfigTypes.BaseConfigClass<T> & {
	_configInstance: ConfigInstance.ConfigInstance<T>,
	_configuration: Configuration,
}

local VALUE_TYPE_MAP: { [string]: string } = {
	string = "StringValue",
	number = "NumberValue",
	boolean = "BoolValue",
	Color3 = "Color3Value",
	Vector3 = "Vector3Value",
	CFrame = "CFrameValue",
	BrickColor = "BrickColorValue",
	Ray = "RayValue",
}

local function resolveValueBaseClassName(value: any): string?
	local valueType = typeof(value)

	local className = VALUE_TYPE_MAP[valueType]
	if className then
		return className
	end

	if typeof(value) == "Instance" then
		return "ObjectValue"
	end

	return nil
end

local function createValueBase(key: string, value: any, parent: Instance): Instance?
	local className = resolveValueBaseClassName(value)
	if not className then
		warn(`[DictionaryConfig] Unsupported value type "{typeof(value)}" for key "{key}", skipping`)
		return nil
	end

	local valueBase = Instance.new(className)
	valueBase.Name = key;
	(valueBase :: any).Value = value
	valueBase.Parent = parent

	return valueBase
end

-- Creates a new DictionaryConfig from a {[string]: any} table
function DictionaryConfig.new<T>(src: { [string]: any }): DictionaryConfig<T>
	local self = setmetatable({}, DictionaryConfig)

	local configuration = Instance.new("Configuration")
	configuration.Name = "DictConfig"
	configuration.Parent = script

	for key, value in src do
		createValueBase(key, value, configuration)
	end

	local configInstance = ConfigInstance.new(configuration)

	self.ConfigSrc = src :: BetterConfigTypes.ConfigSrc
	self.ConfigType = "Dict" :: BetterConfigTypes.ConfigSrcType
	self._connections = {}
	self._signals = {}
	self._configInstance = configInstance
	self._configuration = configuration

	return self :: any
end

-- Gets the value for the specified key
function DictionaryConfig:Get(key: string): any
	return self._configInstance:Get(key)
end

-- Sets the value for the specified key
function DictionaryConfig:Set(key: string, value: any)
	self._configInstance:Set(key, value)
end

-- Gets the value changed signal for the specified key
function DictionaryConfig:GetValueChangedSignal(key: string)
	return self._configInstance:GetValueChangedSignal(key)
end

-- Destroys and cleans up all resources
function DictionaryConfig:Destroy()
	if self._configInstance then
		self._configInstance:Destroy()
	end

	if self._configuration then
		self._configuration:Destroy()
	end

	table.clear(self)
end

return DictionaryConfig
