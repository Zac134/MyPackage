--!strict
--[[
	BetterConfig - Config Factory Module

	A factory that returns the appropriate Config implementation based on the ConfigSrc type.
	Uses the Strategy Pattern to support both Configuration (ValueBase) and
	Instance (Attribute) sources.

	Example:
		local config = BetterConfig.new(someConfiguration)
		local value = config:Get("Health")
		config:Set("Health", 100)

		local signal = config:GetValueChangedSignal("Health")
		signal:Connect(function(newValue)
			print("Health changed to", newValue)
		end)
]]

local BetterConfigTypes = require(script.BetterConfigTypes)
local ConfigInstance = require(script.ConfigTypes.ConfigInstance)
local AttributeConfig = require(script.ConfigTypes.AttributeConfig)

local BetterConfig = {}

-- Type exports
export type BaseConfigClass<T = { [string]: any }> = BetterConfigTypes.BaseConfigClass<T>
export type ConfigSrc = BetterConfigTypes.ConfigSrc
export type ConfigSrcType = BetterConfigTypes.ConfigSrcType

--[[
	Creates a new Config instance.

	@param src Configuration | Instance - The config source
	@return BaseConfigClass - The appropriate Config implementation

	Example:
		-- Using Configuration (ValueBase)
		local configInstance = BetterConfig.new(workspace.GameConfig)

		-- Using Instance Attributes
		local attributeConfig = BetterConfig.new(workspace.Player)
]]
function BetterConfig.new<T>(src: ConfigSrc): BaseConfigClass<T>
	if typeof(src) == "Instance" then
		if src:IsA("Configuration") then
			return ConfigInstance.new(src :: Configuration)
		else
			return AttributeConfig.new(src)
		end
	elseif typeof(src) == "table" then
		-- Future extension: TableConfig
		error("[BetterConfig] Table config is not yet implemented")
	end

	error("[BetterConfig] Invalid ConfigSrc type: " .. typeof(src))
end

--[[
	Determines the type of ConfigSrc.

	@param src ConfigSrc - The source to check
	@return ConfigSrcType - The type of the source
]]
function BetterConfig._getConfigType(src: ConfigSrc): ConfigSrcType
	if typeof(src) == "Instance" then
		if src:IsA("Configuration") then
			return "Configuration"
		else
			return "Attribute"
		end
	elseif typeof(src) == "table" then
		return "Table"
	end

	error("[BetterConfig] Invalid ConfigSrc type: " .. typeof(src))
end

-- Export individual Config implementations (can be used directly if needed)
BetterConfig.ConfigInstance = ConfigInstance
BetterConfig.AttributeConfig = AttributeConfig

return BetterConfig
