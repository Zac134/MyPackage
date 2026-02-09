--!strict
--[[
	RbxConfig Client Example
	クライアント側での RbxConfig の使用例を示すスクリプト

	機能:
	- InitClient: クライアント用コンフィグ設定の初期化（戻り値でキー自動補完が有効）
	- GetValue: 現在の値の取得
	- GetValueChangedSignal: 値変更の監視（サーバーからのプッシュを受信）
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RbxConfigModule = require(ReplicatedStorage.Modules.RbxConfig)

-- サーバーと同じコンフィグ設定とデフォルト値を定義
-- InitClient 時にサーバーから最新の値を RemoteFunction 経由で取得する
-- サーバーとの通信に失敗した場合は、ここで指定したデフォルト値が使われる
local configSettings = require(ReplicatedStorage.shared.RbxConfigSetting)

-- RbxConfig をクライアント側で初期化（戻り値をキャプチャすることでキー自動補完が有効になる）
local RbxConfig = RbxConfigModule:InitClient(configSettings)
print("[Client] RbxConfig initialized!")

---------------------------------------------------------
-- 例1: 現在の値を取得（サーバーから受信した値）
---------------------------------------------------------
print("[Client] === Current Values ===")
print("[Client] max_players_per_team =", RbxConfig:GetValue("max_players_per_team"))

---------------------------------------------------------
-- 例2: 値の変更を監視
-- サーバーから RemoteEvent 経由でプッシュされた変更を受信する
-- ConfigService の値変更やテストオーバーライドの反映を検知できる
---------------------------------------------------------
RbxConfig:GetValueChangedSignal("max_players_per_team"):Connect(function(newValue)
	print(`[Client] max_players_per_team changed to: {newValue}`)

	-- 例: チーム選択UIの最大人数表示を更新する
	-- teamSelectUI.MaxLabel.Text = `Max: {newValue}`
end)

---------------------------------------------------------
-- 例3: 値の変更に応じたUI制御の実践的な例
---------------------------------------------------------
local function setupConfigDrivenUI()
	-- 初期値に基づいてUIを設定
	local maxTeamSize = RbxConfig:GetValue("max_players_per_team")
	print(`[Client] Initial max team size: {maxTeamSize}`)
end

setupConfigDrivenUI()
