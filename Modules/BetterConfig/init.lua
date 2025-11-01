local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Signal = require(ReplicatedStorage.Packages.signal)

local Config = {}

type hasValuePropertyObject =
	ObjectValue
	| IntValue
	| BoolValue
	| StringValue
	| NumberValue
	| Color3Value
	| CFrameValue
	| Vector3Value
	| BrickColorValue
	| RayValue

export type Config = {
	BaseInstance: Configuration | Instance,
	Observe: (self: Config, key: string) -> Signal.Signal<any>,
	ObserveAll: (self: Config) -> Signal.Signal<string, any>,
	Destroy: (self: Config) -> (),
	_type: "Config" | "Attribute",

	_connections: { [string]: RBXScriptConnection },
	_signals: { [string]: Signal.Signal<any> },
	_allObserver: Signal.Signal<string, any>?,
}

local function hasProperty(object: any, property: string): boolean
	local hasValue, _ = pcall(function()
		return object[property]
	end)
	return hasValue
end

function Config.new(src: Configuration | Instance): Config
	local self = setmetatable({}, Config)
	self.BaseInstance = src

	local isConfiguration = src:IsA("Configuration")

	self._type = isConfiguration == true and "Config" or "Attribute"
	self._connections = {}
	self._signals = {}
	self._allObserver = nil

	self.Observe = Config.Observe
	self.ObserveAll = Config.ObserveAll
	self.Destroy = Config.Destroy

	Config._setValues(self)
	return self
end

function Config:_setValues()
	if self._type == "Config" then
		for _, valueBase: ValueBase in pairs(self.BaseInstance:GetChildren()) do
			if not valueBase:IsA("ValueBase") then
				continue
			end
			if not hasProperty(valueBase, "Value") then
				continue
			end

			if self[valueBase.Name] then
				warn(`Name {valueBase.Name} is reserved or already set. Please use a different name.`)
				continue
			end

			self[valueBase.Name] = valueBase.Value
		end
	else
		for name, value in pairs(self.BaseInstance:GetAttributes()) do
			if self[name] then
				warn(`Name {name} is reserved or already set. Please use a different name.`)
				continue
			end
			self[name] = value
		end
	end
end

function Config:Observe(key: string)
	-- 既にSignalが存在する場合はそれを返す
	if self._signals[key] then
		return self._signals[key]
	end

	local signal = Signal.new()
	self._signals[key] = signal

	if self._type == "Config" then
		-- 特定のValueBaseを探す
		local valueBase = self.BaseInstance:FindFirstChild(key)
		if valueBase and valueBase:IsA("ValueBase") and hasProperty(valueBase, "Value") then
			-- 既にConnectionが存在しない場合のみ作成
			if not self._connections[key] then
				self._connections[key] = valueBase:GetPropertyChangedSignal("Value"):Connect(function()
					local value = valueBase.Value
					-- ObserveまたはObserveAllが呼ばれている場合のみ値を更新
					if self._allObserver or self._signals[valueBase.Name] then
						self[valueBase.Name] = value
					end
					-- ObserverにFire（存在する場合）
					if self._allObserver then
						self._allObserver:Fire(valueBase.Name, value)
					end
					-- 特定のキーのSignalにFire
					if self._signals[valueBase.Name] then
						self._signals[valueBase.Name]:Fire(value)
					end
				end)
			end
		end
	else
		-- Attributeの場合、共通の接続を作成（まだ存在しない場合）
		if not self._connections.attributeChangedConnection then
			self._connections.attributeChangedConnection = self.BaseInstance.AttributeChanged:Connect(function(name)
				local value = self.BaseInstance:GetAttribute(name)
				-- ObserveまたはObserveAllが呼ばれている場合のみ値を更新
				if self._allObserver or self._signals[name] then
					self[name] = value
				end
				-- ObserveAllのObserverにFire
				if self._allObserver then
					self._allObserver:Fire(name, value)
				end
				-- 特定のキーのSignalにFire
				if self._signals[name] then
					self._signals[name]:Fire(value)
				end
			end)
		end
	end

	return signal
end

function Config:ObserveAll()
	-- 既にObserverが存在する場合はそれを返す
	if self._allObserver then
		return self._allObserver
	end

	self._allObserver = Signal.new()

	if self._type == "Config" then
		for _, valueBase: ValueBase in pairs(self.BaseInstance:GetChildren()) do
			if not valueBase:IsA("ValueBase") then
				continue
			end
			if not hasProperty(valueBase, "Value") then
				continue
			end

			-- 既にConnectionが存在する場合はスキップ（Observeで作成済み）
			if not self._connections[valueBase.Name] then
				self._connections[valueBase.Name] = valueBase:GetPropertyChangedSignal("Value"):Connect(function()
					local value = valueBase.Value
					-- ObserveまたはObserveAllが呼ばれている場合のみ値を更新
					if self._allObserver or self._signals[valueBase.Name] then
						self[valueBase.Name] = value
					end
					-- ObserverにFire
					if self._allObserver then
						self._allObserver:Fire(valueBase.Name, value)
					end
					-- 特定のキーのSignalにFire（存在する場合）
					if self._signals[valueBase.Name] then
						self._signals[valueBase.Name]:Fire(value)
					end
				end)
			end
		end
	else
		-- Attributeの場合、共通の接続を作成（まだ存在しない場合）
		if not self._connections.attributeChangedConnection then
			self._connections.attributeChangedConnection = self.BaseInstance.AttributeChanged:Connect(function(name)
				local value = self.BaseInstance:GetAttribute(name)
				-- ObserveまたはObserveAllが呼ばれている場合のみ値を更新
				if self._allObserver or self._signals[name] then
					self[name] = value
				end
				-- ObserveAllのObserverにFire
				if self._allObserver then
					self._allObserver:Fire(name, value)
				end
				-- 特定のキーのSignalにFire
				if self._signals[name] then
					self._signals[name]:Fire(value)
				end
			end)
		end
	end

	return self._allObserver
end

function Config:Destroy()
	-- Connectionsの破棄
	if self._connections and next(self._connections) ~= nil then
		for index, connection: RBXScriptConnection in self._connections do
			connection:Disconnect()
			self._connections[index] = nil
		end
	end

	-- Signalsの破棄
	if self._signals then
		for key, signal in self._signals do
			signal:Destroy()
			self._signals[key] = nil
		end
	end

	-- Observerの破棄
	if self._allObserver then
		self._allObserver:Destroy()
		self._allObserver = nil
	end

	table.clear(self)
end

return Config
