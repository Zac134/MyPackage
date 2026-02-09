--!strict
--[[
	BetterConfig Client Example
	クライアント側での BetterConfig の使用例を示すスクリプト

	機能:
	- BetterConfig.fromAttribute: Instance Attribute ベースのコンフィグを生成
	- BetterConfig.fromConfiguration: Configuration/ValueBase ベースのコンフィグを生成
	- BetterConfig.fromDict: テーブルからコンフィグを生成（型は自動推論）
	- Get: 現在の値の取得（キー自動補完あり）
	- Set: 値の更新
	- GetValueChangedSignal: 値変更の監視
	- Destroy: リソースのクリーンアップ
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BetterConfig = require(ReplicatedStorage.Modules.BetterConfig)

---------------------------------------------------------
-- コンフィグの型定義
-- キーと値の型を明示することで Get/Set 等のキー自動補完が有効になる
---------------------------------------------------------
type MyConfig = {
	show_ui: boolean,
	max_items: number,
	welcome_message: string,
}

---------------------------------------------------------
-- 例1: Attribute ベースの Config
-- Instance の Attribute を使って値を管理する
-- workspace にあらかじめ Attribute が設定されている想定
---------------------------------------------------------
print("[Client] === BetterConfig Attribute Example ===")

-- Attribute の初期値を設定
local configPart = Instance.new("Part")
configPart.Name = "ConfigHolder"
configPart.Parent = workspace
configPart:SetAttribute("show_ui", true)
configPart:SetAttribute("max_items", 10)
configPart:SetAttribute("welcome_message", "Hello!")

-- fromAttribute にファントム型ヒントを渡すことで T が推論される
-- キャスト不要でキー自動補完が有効になる
local config = BetterConfig.fromAttribute(configPart)

-- 値の取得（キー自動補完が効く）
local showUi = config:Get("show_ui")
local maxItems = config:Get("max_items")
local message = config:Get("welcome_message")
print(`[Client] show_ui = {showUi}`)
print(`[Client] max_items = {maxItems}`)
print(`[Client] welcome_message = {message}`)

---------------------------------------------------------
-- 例2: 値の変更を監視
-- Attribute の値が変更されるとシグナルが発火する
---------------------------------------------------------
config:GetValueChangedSignal("max_items"):Connect(function(newValue)
	print(`[Client] max_items changed to: {newValue}`)
end)

config:GetValueChangedSignal("show_ui"):Connect(function(newValue)
	print(`[Client] show_ui changed to: {newValue}`)
end)

---------------------------------------------------------
-- 例3: 値の更新
-- Set で Attribute の値を更新する
-- GetValueChangedSignal で接続済みのシグナルが発火する
---------------------------------------------------------
task.delay(3, function()
	print("[Client] === Updating values ===")
	config:Set("max_items", 20)
	config:Set("show_ui", false)
	print(`[Client] max_items after Set = {config:Get("max_items")}`)
	print(`[Client] show_ui after Set = {config:Get("show_ui")}`)
end)

---------------------------------------------------------
-- 例4: Dictionary ベースの Config
-- テーブルから Config を生成する（内部で Configuration + ValueBase に変換される）
-- fromDict はテーブルの形状から T を自動推論するため、型ヒントもキャストも不要
---------------------------------------------------------
print("[Client] === BetterConfig Dictionary Example ===")

local dictConfig = BetterConfig.fromDict({
	round_time = 120,
	team_size = 4,
	map_name = "Grasslands",
})

print(`[Client] round_time = {dictConfig:Get("round_time")}`)
print(`[Client] team_size = {dictConfig:Get("team_size")}`)
print(`[Client] map_name = {dictConfig:Get("map_name")}`)

-- 値変更の監視
dictConfig:GetValueChangedSignal("round_time"):Connect(function(newValue)
	print(`[Client] round_time changed to: {newValue}`)
end)

-- 値の更新
task.delay(5, function()
	dictConfig:Set("round_time", 180)
	print(`[Client] round_time after Set = {dictConfig:Get("round_time")}`)
end)
