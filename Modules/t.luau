local BetterConfig = require(script.Parent.BetterConfig)

local Configuration = Instance.new("Configuration")
local config: BetterConfig.BaseConfigClass<{ a: number }> = BetterConfig.new(Configuration)
