--!strict
--[[
	BetterConfig - Config Factory Module

	A factory that returns the appropriate Config implementation based on the ConfigSrc type.
	Supports Configuration (ValueBase), Instance (Attribute), and Dictionary (table) sources.
]]

local BetterConfigTypes = require(script.BetterConfigTypes)
local ConfigInstance = require(script.ConfigTypes.ConfigInstance)
local AttributeConfig = require(script.ConfigTypes.AttributeConfig)
local DictionaryConfig = require(script.ConfigTypes.DictionaryConfig)

local BetterConfig = {}

export type BaseConfigClass<T = { [string]: any }> = BetterConfigTypes.BaseConfigClass<T>
export type ConfigSrc = BetterConfigTypes.ConfigSrc
export type ConfigSrcType = BetterConfigTypes.ConfigSrcType

function BetterConfig.new<T>(src: ConfigSrc): BaseConfigClass<T>
	if typeof(src) == "Instance" then
		if src:IsA("Configuration") then
			return ConfigInstance.new(src :: Configuration)
		else
			return AttributeConfig.new(src :: Instance)
		end
	elseif typeof(src) == "table" then
		return DictionaryConfig.new(src)
	end

	error("[BetterConfig] Invalid ConfigSrc type: " .. typeof(src))
end

function BetterConfig.fromAttributes<T>(src: Instance): AttributeConfig.AttributeConfig<T>
	return AttributeConfig.new(src)
end

function BetterConfig.fromConfiguration<T>(src: Configuration): ConfigInstance.ConfigInstance<T>
	return ConfigInstance.new(src)
end

function BetterConfig.fromDict<T>(src: { [string]: any }): DictionaryConfig.DictionaryConfig<T>
	return DictionaryConfig.new(src)
end

function BetterConfig._getConfigType(src: ConfigSrc): ConfigSrcType
	if typeof(src) == "Instance" then
		if src:IsA("Configuration") then
			return "Configuration"
		else
			return "Attribute"
		end
	elseif typeof(src) == "table" then
		return "Dict"
	end

	error("[BetterConfig] Invalid ConfigSrc type: " .. typeof(src))
end

return BetterConfig
