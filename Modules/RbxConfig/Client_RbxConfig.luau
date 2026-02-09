--!strict
--[[
	Client_RbxConfig - Client-side config value store

	Handles:
	- Requesting initial values from server via RemoteFunction
	- Listening for value updates via RemoteEvent
	- Managing local signals for value change notifications
]]

local Client_RbxConfig = {}

--[[ Internal state stored on rbxConfig singleton ]]
-- rbxConfig._values: { [string]: any }
-- rbxConfig._configSettings: { [string]: any } (defaults)
-- rbxConfig._signals: { [string]: Signal }

--- Initialize the client-side RbxConfig.
--- Requests initial values from server and sets up change listener.
function Client_RbxConfig.init(rbxConfig: any, configSettings: { [string]: any })
	local rbxConfigModule = script.Parent

	-- Wait for remotes created by Server_RbxConfig
	local remoteFunction = rbxConfigModule:WaitForChild("RbxConfigRemoteFunction")
	local remoteEvent = rbxConfigModule:WaitForChild("RbxConfigRemoteEvent")

	-- Request initial values from server
	local success, serverValues = pcall(function()
		return (remoteFunction :: RemoteFunction):InvokeServer()
	end)

	if success and serverValues then
		for key, value in serverValues do
			rbxConfig._values[key] = value
		end
	else
		warn(`[RbxConfig] Failed to fetch initial values from server: {serverValues}`)
		-- Fall back to defaults
		for key, defaultValue in configSettings do
			rbxConfig._values[key] = defaultValue
		end
	end

	-- Listen for value changes pushed from server
	(remoteEvent :: RemoteEvent).OnClientEvent:Connect(function(key: string, newValue: any)
		rbxConfig._values[key] = newValue

		-- Fire local signal if one exists for this key
		local sig = rbxConfig._signals[key]
		if sig then
			sig:Fire(newValue)
		end
	end)
end

return Client_RbxConfig
