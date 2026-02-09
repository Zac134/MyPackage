--!strict
--[[
	Server_RbxConfig - Server-side ConfigService wrapper

	Handles:
	- Fetching ConfigSnapshots from ConfigService
	- Lazy observation of value changes (UpdateAvailable → Refresh → signal)
	- Replication to clients via RemoteFunction (initial) + RemoteEvent (updates)
	- Per-player config (GetValueForPlayer)
	- Testing value overrides (SetTestingValue / ClearTestingValue)
]]

local ConfigService = game:GetService("ConfigService")
local Players = game:GetService("Players")

local Server_RbxConfig = {}

--[[ Internal state stored on rbxConfig singleton ]]
-- rbxConfig._values: { [string]: any }
-- rbxConfig._configSettings: { [string]: any } (defaults)
-- rbxConfig._snapshot: ConfigSnapshot?                  (single global snapshot)
-- rbxConfig._snapshotRefreshConnected: boolean           (UpdateAvailable connected flag)
-- rbxConfig._signals: { [string]: Signal }
-- rbxConfig._observing: { [string]: boolean }
-- rbxConfig._testOverrides: { [string]: any }
-- rbxConfig._playerSnapshots: { [Player]: ConfigSnapshot }
-- rbxConfig._remoteEvent: RemoteEvent
-- rbxConfig._remoteFunction: RemoteFunction

--- Initialize the server-side RbxConfig.
--- Fetches a single ConfigSnapshot containing all keys, creates remotes for client replication.
function Server_RbxConfig.init(rbxConfig: any, configSettings: { [string]: any })
	rbxConfig._snapshot = nil
	rbxConfig._snapshotRefreshConnected = false
	rbxConfig._observing = {}
	rbxConfig._testOverrides = {}
	rbxConfig._playerSnapshots = {}

	-- Fetch a single global snapshot (contains all config keys)
	local success, snapshot = pcall(function()
		return ConfigService:GetConfigAsync()
	end)

	if success and snapshot then
		rbxConfig._snapshot = snapshot
		for key in configSettings do
			rbxConfig._values[key] = snapshot:GetValue(key)
		end
	else
		warn(`[RbxConfig] Failed to fetch config snapshot: {snapshot}`)
	end

	-- Create RemoteEvent for pushing value changes to clients
	local remoteEvent = Instance.new("RemoteEvent")
	remoteEvent.Name = "RbxConfigRemoteEvent"
	remoteEvent.Parent = script.Parent

	-- Create RemoteFunction for initial client value requests
	local remoteFunction = Instance.new("RemoteFunction")
	remoteFunction.Name = "RbxConfigRemoteFunction"
	remoteFunction.Parent = script.Parent

	rbxConfig._remoteEvent = remoteEvent
	rbxConfig._remoteFunction = remoteFunction

	-- Handle client initial value request
	remoteFunction.OnServerInvoke = function(_player: Player)
		return rbxConfig._values
	end

	-- Clean up player snapshots on leave
	Players.PlayerRemoving:Connect(function(player: Player)
		rbxConfig._playerSnapshots[player] = nil
	end)
end

--- Start observing a specific config key for value changes (lazy initialization).
--- Called when GetValueChangedSignal(key) is invoked for the first time.
function Server_RbxConfig.startObserving(rbxConfig: any, key: string)
	if rbxConfig._observing[key] then
		return
	end
	rbxConfig._observing[key] = true

	local snapshot = rbxConfig._snapshot
	if not snapshot then
		return
	end

	-- Connect UpdateAvailable → Refresh once for the single snapshot
	if not rbxConfig._snapshotRefreshConnected then
		rbxConfig._snapshotRefreshConnected = true
		snapshot.UpdateAvailable:Connect(function()
			snapshot:Refresh()
		end)
	end

	-- Per-key: when the value changes after refresh, update and notify
	snapshot:GetValueChangedSignal(key):Connect(function(newValue)
		-- Do not override if a test value is set
		if rbxConfig._testOverrides[key] ~= nil then
			return
		end

		rbxConfig._values[key] = newValue

		-- Fire the external signal
		local sig = rbxConfig._signals[key]
		if sig then
			sig:Fire(newValue)
		end

		-- Push to all clients
		rbxConfig._remoteEvent:FireAllClients(key, newValue)
	end)
end

--- Get the config value for a specific player using ConfigService:GetConfigForPlayerAsync.
--- Caches the player snapshot for subsequent calls.
function Server_RbxConfig.getValueForPlayer(rbxConfig: any, key: string, player: Player): any
	-- Check test overrides first
	if rbxConfig._testOverrides[key] ~= nil then
		return rbxConfig._testOverrides[key]
	end

	local playerSnapshot = rbxConfig._playerSnapshots[player]

	if not playerSnapshot then
		local success, result = pcall(function()
			return ConfigService:GetConfigForPlayerAsync(player)
		end)

		if success and result then
			rbxConfig._playerSnapshots[player] = result
			playerSnapshot = result
		else
			warn(`[RbxConfig] Failed to fetch config for player "{player.Name}": {result}`)
			-- Fall back to global value
			return rbxConfig._values[key] or rbxConfig._configSettings[key]
		end
	end

	return playerSnapshot:GetValue(key)
end

--- Set a testing override value for a config key.
--- Overrides GetValue and GetValueForPlayer results.
--- Also pushes the override to all clients.
function Server_RbxConfig.setTestingValue(rbxConfig: any, key: string, value: any)
	rbxConfig._testOverrides[key] = value

	-- Fire signal with override value
	local sig = rbxConfig._signals[key]
	if sig then
		sig:Fire(value)
	end

	-- Push to clients
	if rbxConfig._remoteEvent then
		rbxConfig._remoteEvent:FireAllClients(key, value)
	end
end

--- Clear a testing override value, restoring the real ConfigService value.
--- Also pushes the restored value to all clients.
function Server_RbxConfig.clearTestingValue(rbxConfig: any, key: string)
	rbxConfig._testOverrides[key] = nil

	-- Restore from snapshot or default
	local snapshot = rbxConfig._snapshot
	local restoredValue
	if snapshot then
		restoredValue = snapshot:GetValue(key)
	else
		restoredValue = rbxConfig._configSettings[key]
	end

	rbxConfig._values[key] = restoredValue

	-- Fire signal with restored value
	local sig = rbxConfig._signals[key]
	if sig then
		sig:Fire(restoredValue)
	end

	-- Push to clients
	if rbxConfig._remoteEvent then
		rbxConfig._remoteEvent:FireAllClients(key, restoredValue)
	end
end

return Server_RbxConfig
