local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RbxConfig = require(ReplicatedStorage.Modules.RbxConfig)

export type ConfigSetting = {
	max_players_per_team: number,
}

local configSettings = {
	max_players_per_team = 4,
} :: ConfigSetting

return configSettings :: ConfigSetting
