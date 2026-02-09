--!strict
--[[
	RbxConfig Server Example
	サーバー側での RbxConfig の使用例を示すスクリプト

	機能:
	- InitServer: サーバー用コンフィグ設定の初期化（戻り値でキー自動補完が有効）
	- GetValue: 現在の値の取得
	- GetValueChangedSignal: 値変更の監視
	- GetValueForPlayer: プレイヤーごとの値取得
	- SetTestingValue / ClearTestingValue: テスト用オーバーライド
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local RbxConfigModule = require(ReplicatedStorage.Modules.RbxConfig)

-- コンフィグ設定とデフォルト値を定義
-- キーは Roblox ConfigService で設定したものと一致させる
local configSettings = require(ReplicatedStorage.shared.RbxConfigSetting)

-- RbxConfig をサーバー用に初期化（戻り値をキャプチャすることでキー自動補完が有効になる）
local RbxConfig = RbxConfigModule:InitServer(configSettings)
local value = RbxConfig:GetValue("max_players_per_team")
print(value)

---------------------------------------------------------
-- 例1: 現在の値を取得
---------------------------------------------------------
print("[Server] === Current Values ===")
print("[Server] max_players_per_team =", RbxConfig:GetValue("max_players_per_team"))

---------------------------------------------------------
-- 例2: 値の変更を監視
-- ConfigService 上で値が変更されると自動的に発火する
---------------------------------------------------------
RbxConfig:GetValueChangedSignal("max_players_per_team"):Connect(function(newValue)
	print(`[Server] max_players_per_team changed to: {newValue}`)
end)

---------------------------------------------------------
-- 例3: プレイヤーごとのコンフィグ値を取得
-- ConfigService のターゲティング機能を利用して
-- プレイヤーに応じた値を返す
---------------------------------------------------------
Players.PlayerAdded:Connect(function(player: Player)
	-- プレイヤーの ConfigSnapshot を取得して値を読み取る
	local maxPlayers = RbxConfig:GetValueForPlayer("max_players_per_team", player)

	print(`[Server] Config for {player.Name}:`)
	print(`  max_players_per_team = {maxPlayers}`)
end)

---------------------------------------------------------
-- 例4: テスト用オーバーライド（デバッグ/QA用）
-- SetTestingValue で一時的に値を上書きし、
-- ClearTestingValue で本来の ConfigService の値に戻す
-- ※ オーバーライドはすべてのクライアントにも即座に反映される
---------------------------------------------------------
task.delay(10, function()
	print("[Server] === Testing Override Demo ===")

	-- テスト値を設定
	print("[Server] Setting test override: max_players_per_team = 8")
	RbxConfig:SetTestingValue("max_players_per_team", 8)
	print("[Server] GetValue after override:", RbxConfig:GetValue("max_players_per_team"))

	-- 5秒後にテスト値をクリアして元の値に戻す
	task.delay(5, function()
		print("[Server] Clearing test override for max_players_per_team")
		RbxConfig:ClearTestingValue("max_players_per_team")
		print("[Server] GetValue after clearing:", RbxConfig:GetValue("max_players_per_team"))
	end)
end)
