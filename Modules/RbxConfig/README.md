# RbxConfig

Singleton wrapper for Roblox ConfigService with automatic server-client synchronization.

## Overview

RbxConfig is a singleton module that wraps Roblox's ConfigService, providing automatic server-client synchronization, player-specific configuration targeting, and a type-safe API for managing cloud-based configuration values. Update your config remotely without restarting servers, run A/B tests with player-specific configs, and test configuration changes with temporary overrides.

**Problem**: Accessing Roblox ConfigService requires complex snapshot management, manual client synchronization, and lacks type safety. Changes require careful observation setup and error-prone replication logic.

**Solution**: RbxConfig handles all the complexity automatically - lazy observation, RemoteEvent/RemoteFunction setup, player snapshot caching, and type-safe key autocomplete.

## Features

- **Cloud-based configuration** via Roblox ConfigService
- **Automatic server-client synchronization** using RemoteFunction (initial) and RemoteEvent (updates)
- **Player-specific configuration targeting** for A/B testing and personalization
- **Test override system** for QA and debugging
- **Type-safe API** with key autocomplete
- **Lazy observation** for performance (only observes keys with listeners)
- **Singleton pattern** with `InitServer` and `InitClient`

## Prerequisites

This module requires Roblox ConfigService to be set up in your experience:

1. Navigate to the [Creator Dashboard](https://create.roblox.com/)
2. Select your experience
3. Go to **Configure** → **Config Service**
4. Create configuration keys for your experience

For more information, see the [Roblox ConfigService documentation](https://create.roblox.com/docs/cloud/open-cloud/usage-configuration).

## Installation

### Via Wally

```toml
[dependencies]
signal = "sleitnick/signal@^2.0"
```

### Manual Installation

Copy the `Modules/RbxConfig/` directory to your project's ReplicatedStorage.

## Quick Start

### Server

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RbxConfig = require(ReplicatedStorage.Modules.RbxConfig):InitServer({
    max_players_per_team = 4,
})

local value = RbxConfig:GetValue("max_players_per_team")
print("Max players per team:", value)
```

### Client

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RbxConfig = require(ReplicatedStorage.Modules.RbxConfig):InitClient({
    max_players_per_team = 4,
})

local value = RbxConfig:GetValue("max_players_per_team")
print("Max players per team:", value)
```

## Configuration Settings Definition

Best practice: define your config settings in a shared module for use by both server and client.

```lua
-- ReplicatedStorage/shared/RbxConfigSetting.luau
export type ConfigSetting = {
    max_players_per_team: number,
}

local configSettings = {
    max_players_per_team = 4,
} :: ConfigSetting

return configSettings
```

Then use it in both server and client:

```lua
local configSettings = require(ReplicatedStorage.shared.RbxConfigSetting)
local RbxConfig = require(ReplicatedStorage.Modules.RbxConfig):InitServer(configSettings)
```

## Server-Side Usage

### Getting Values

```lua
local value = RbxConfig:GetValue("max_players_per_team")
```

**Value priority:**
1. Test overrides (if set via `SetTestingValue`)
2. ConfigService snapshot value
3. Default value from `configSettings`

### Observing Changes

```lua
RbxConfig:GetValueChangedSignal("max_players_per_team"):Connect(function(newValue)
    print("Max players per team changed to:", newValue)
    -- Update game logic based on new value
end)
```

**Lazy observation:** The ConfigService snapshot is only observed for keys that have listeners attached. This improves performance by avoiding unnecessary network calls.

**How it works:**
1. When `GetValueChangedSignal` is first called for a key, RbxConfig starts observing that key
2. The snapshot's `UpdateAvailable` event triggers a `Refresh()`
3. When the key's value changes, the signal fires and the update is pushed to all clients

### Player-Specific Configuration

Get configuration values targeted to specific players for A/B testing or personalization:

```lua
Players.PlayerAdded:Connect(function(player)
    local maxPlayers = RbxConfig:GetValueForPlayer("max_players_per_team", player)
    print(player.Name, "sees max_players_per_team as:", maxPlayers)

    -- Use player-specific config for features
    if maxPlayers > 4 then
        enableBetaFeatures(player)
    end
end)
```

**Use cases:**
- A/B testing: Show different configs to different player groups
- Regional configs: Different settings based on player location
- VIP features: Enable features for specific players
- Gradual rollouts: Incrementally enable features

**Player snapshot caching:** Player-specific snapshots are cached and cleaned up on `PlayerRemoving`.

### Test Overrides

Temporarily override config values for QA testing without touching live ConfigService values:

```lua
-- Override a value
RbxConfig:SetTestingValue("max_players_per_team", 8)
-- All clients immediately receive the override

-- Wait and then restore original value
task.delay(60, function()
    RbxConfig:ClearTestingValue("max_players_per_team")
    -- All clients immediately receive the original ConfigService value
end)
```

**QA workflow:**
1. QA team runs commands to set test overrides
2. Test the feature with overridden config
3. Clear overrides to restore production config
4. No ConfigService changes needed, no server restart required

**Important:** Test overrides are server-only and lost on server restart. Use for testing, not production logic.

## Client-Side Usage

### Getting Values

```lua
local value = RbxConfig:GetValue("max_players_per_team")
```

**Initial sync:** When the client calls `InitClient`, it invokes a RemoteFunction to fetch all current values from the server. If the network request fails, it falls back to the defaults provided in `configSettings`.

### Observing Changes

```lua
RbxConfig:GetValueChangedSignal("max_players_per_team"):Connect(function(newValue)
    print("Max players per team changed to:", newValue)

    -- Update UI based on new value
    updateTeamSelectUI(newValue)
end)
```

**UI update scenario:**
```lua
local teamUI = player.PlayerGui.TeamSelect

RbxConfig:GetValueChangedSignal("max_players_per_team"):Connect(function(newValue)
    teamUI.MaxLabel.Text = `Max: {newValue}`
    teamUI.TeamList:UpdateCapacity(newValue)
end)
```

### Automatic Synchronization

When the server updates a config value (via ConfigService or test override), it pushes the update to all clients via RemoteEvent. Clients automatically update their internal `_values` and fire any connected signals.

**No client restart needed:** Config changes take effect immediately on all clients.

## Architecture

### Server Architecture

- **ConfigSnapshot management**: Fetches a single global snapshot via `ConfigService:GetConfigAsync()`
- **Lazy observation**: Only observes keys that have listeners (`GetValueChangedSignal` called)
- **UpdateAvailable → Refresh**: When ConfigService pushes an update, calls `snapshot:Refresh()` to get new values
- **RemoteFunction**: Created as `"RbxConfigRemoteFunction"` for initial client value requests
- **RemoteEvent**: Created as `"RbxConfigRemoteEvent"` for pushing updates to clients
- **Player snapshot caching**: Caches per-player snapshots and cleans up on `PlayerRemoving`

### Client Architecture

- **Initial value fetch**: Invokes RemoteFunction to get all values from server on `InitClient`
- **RemoteEvent listener**: Listens for server-pushed updates (key, newValue)
- **Local signal management**: Maintains `_signals` table and fires signals when values update
- **Fallback to defaults**: Uses `configSettings` defaults if network request fails

### Replication Flow

1. **Server startup**: Server calls `InitServer`, fetches global ConfigSnapshot from ConfigService
2. **Client startup**: Client calls `InitClient`, invokes RemoteFunction to get initial values
3. **Lazy observation**: Server starts observing a key when `GetValueChangedSignal` is first called for that key
4. **ConfigService update**: When ConfigService pushes an update, server detects via `UpdateAvailable`, calls `Refresh()`, updates `_values[key]`, fires local signal, pushes to all clients via RemoteEvent
5. **Test override**: `SetTestingValue` immediately updates `_values`, fires signals, and pushes to clients (bypasses ConfigService)

## API Reference

### Module Methods

#### `InitServer<T>(configSettings: T): ServerConfigClass<T>`
Initializes RbxConfig for server use. Must be called once on the server.

**Parameters:**
- `configSettings`: Table defining config keys and their default values

**Returns:** Server-side RbxConfig instance with full API (GetValue, GetValueChangedSignal, GetValueForPlayer, SetTestingValue, ClearTestingValue)

---

#### `InitClient<T>(configSettings: T): RbxConfig<T>`
Initializes RbxConfig for client use. Must be called once on each client.

**Parameters:**
- `configSettings`: Table defining config keys and their default values (should match server)

**Returns:** Client-side RbxConfig instance with read-only API (GetValue, GetValueChangedSignal)

---

### Shared Methods (Server & Client)

#### `GetValue<T>(key: keyof<T>): index<T, keyof<T>>`
Gets the current value for the specified config key.

**Server behavior:**
- Checks test overrides first
- Falls back to ConfigService snapshot value
- Falls back to default from `configSettings`

**Client behavior:**
- Returns value from internal `_values` (synced from server)
- Falls back to default from `configSettings`

**Parameters:**
- `key`: Configuration key (autocomplete enabled with type hints)

**Returns:** Current value

---

#### `GetValueChangedSignal<T>(key: keyof<T>): Signal<index<T, keyof<T>>>`
Returns a Signal that fires when the specified key's value changes.

**Server behavior:**
- Lazily starts observing the ConfigService snapshot for this key
- Fires when ConfigService pushes an update or test override changes

**Client behavior:**
- Fires when server pushes an update via RemoteEvent

**Parameters:**
- `key`: Configuration key (autocomplete enabled with type hints)

**Returns:** Signal object with `Connect`, `Once`, `Wait` methods

---

### Server-Only Methods

#### `GetValueForPlayer<T>(key: keyof<T>, player: Player): index<T, keyof<T>>`
Gets the config value targeted to a specific player. Uses `ConfigService:GetConfigForPlayerAsync`.

**Parameters:**
- `key`: Configuration key (autocomplete enabled with type hints)
- `player`: Player instance to get config for

**Returns:** Player-specific config value

**Note:** Player snapshots are cached and cleaned up automatically on `PlayerRemoving`.

---

#### `SetTestingValue<T>(key: keyof<T>, value: index<T, keyof<T>>): ()`
Sets a temporary test override for the specified key. Immediately pushes to all clients.

**Parameters:**
- `key`: Configuration key (autocomplete enabled with type hints)
- `value`: Override value

**Use for:** QA testing, debugging, temporary feature flags

**Important:** Test overrides are lost on server restart. Do not use for production logic.

---

#### `ClearTestingValue<T>(key: keyof<T>): ()`
Clears a test override, restoring the original ConfigService value. Immediately pushes to all clients.

**Parameters:**
- `key`: Configuration key (autocomplete enabled with type hints)

---

### Types

```lua
-- Config value types (supported by ConfigService)
export type ConfigSettingValue = number | string | Json
export type ConfigSetting = { [string]: ConfigSettingValue }

-- Client interface
export type RbxConfig<T = ConfigSetting> = {
    GetValue: (self: RbxConfig<T>, key: keyof<T>) -> index<T, keyof<T>>,
    GetValueChangedSignal: (self: RbxConfig<T>, key: keyof<T>) -> Signal<index<T, keyof<T>>>,
}

-- Server interface (extends client interface)
export type ServerConfigClass<T = { [string]: any }> = RbxConfig<T> & {
    SetTestingValue: (self: ServerConfigClass<T>, key: keyof<T>, value: index<T, keyof<T>>) -> (),
    ClearTestingValue: (self: ServerConfigClass<T>, key: keyof<T>) -> (),
    GetValueForPlayer: (self: ServerConfigClass<T>, key: keyof<T>, player: Player) -> index<T, keyof<T>>,
}

-- Module interface
export type RbxConfigModule = {
    InitServer: <U>(self: RbxConfigModule, configSettings: U) -> ServerConfigClass<U>,
    InitClient: <U>(self: RbxConfigModule, configSettings: U) -> RbxConfig<U>,
}
```

## Examples

Full examples are available at:
- [`/Examples/server/RbxConfig.server.luau`](../../Examples/server/RbxConfig.server.luau) - Server initialization and test overrides
- [`/Examples/client/RbxConfig.client.luau`](../../Examples/client/RbxConfig.client.luau) - Client initialization and observation
- [`/Examples/shared/RbxConfigSetting.luau`](../../Examples/shared/RbxConfigSetting.luau) - Config settings definition

### Example 1: Basic Server Initialization

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RbxConfigModule = require(ReplicatedStorage.Modules.RbxConfig)
local configSettings = require(ReplicatedStorage.shared.RbxConfigSetting)

local RbxConfig = RbxConfigModule:InitServer(configSettings)

-- Get values
local maxPlayers = RbxConfig:GetValue("max_players_per_team")

-- Observe changes
RbxConfig:GetValueChangedSignal("max_players_per_team"):Connect(function(newValue)
    print("Config updated:", newValue)
end)
```

### Example 2: Player-Specific Config (A/B Testing)

```lua
local Players = game:GetService("Players")

Players.PlayerAdded:Connect(function(player)
    -- Get player-specific config
    local showNewUI = RbxConfig:GetValueForPlayer("show_new_ui", player)

    if showNewUI then
        -- Player is in A/B test group, show new UI
        player:SetAttribute("UIVersion", "new")
        print(player.Name, "is in the new UI test group")
    else
        -- Player sees old UI
        player:SetAttribute("UIVersion", "old")
    end
end)
```

### Example 3: Test Overrides for QA

```lua
-- QA command to test different team sizes
game:GetService("ReplicatedStorage").Events.QACommand.OnServerEvent:Connect(function(player, command, value)
    if not isQATester(player) then return end

    if command == "setTeamSize" then
        RbxConfig:SetTestingValue("max_players_per_team", value)
        print(`QA: Set team size to {value}`)

        -- Auto-clear after 5 minutes
        task.delay(300, function()
            RbxConfig:ClearTestingValue("max_players_per_team")
            print("QA: Cleared team size override")
        end)
    end
end)
```

## Best Practices

### 1. Shared Config Settings
Define config settings once in a shared module:

```lua
-- ✓ Good: Shared config settings
local configSettings = require(ReplicatedStorage.shared.RbxConfigSetting)
local serverConfig = RbxConfig:InitServer(configSettings)
local clientConfig = RbxConfig:InitClient(configSettings)
```

```lua
-- ✗ Bad: Duplicated config settings
local serverConfig = RbxConfig:InitServer({ max_players = 4 })
local clientConfig = RbxConfig:InitClient({ max_players = 4 })  -- Duplicate!
```

### 2. Fallback Values
Always provide sensible defaults:

```lua
-- ✓ Good: Sensible defaults
local configSettings = {
    max_players_per_team = 4,      -- Reasonable default
    round_time = 300,                -- 5 minutes default
}
```

### 3. Type Safety
Capture the return value with proper typing:

```lua
-- ✓ Good: Type-safe with autocomplete
type MyConfig = { max_players_per_team: number }
local RbxConfig = RbxConfigModule:InitServer(configSettings)
local maxPlayers = RbxConfig:GetValue("max_players_per_team")  -- Autocomplete works!
```

### 4. Lazy Observation
Only call `GetValueChangedSignal` when you need to observe changes:

```lua
-- ✓ Good: Only observe what you need
RbxConfig:GetValueChangedSignal("max_players_per_team"):Connect(handler)

-- ✗ Bad: Observing everything unnecessarily
for key in configSettings do
    RbxConfig:GetValueChangedSignal(key):Connect(function() end)
end
```

### 5. Test Overrides
Use test overrides for QA/debugging, not production logic:

```lua
-- ✓ Good: QA testing
if isQAMode then
    RbxConfig:SetTestingValue("max_players_per_team", 8)
end

-- ✗ Bad: Production logic depending on test overrides
RbxConfig:SetTestingValue("enable_feature", true)  -- Don't use for production!
```

### 6. Player Targeting
Leverage player-specific configs for controlled rollouts:

```lua
-- ✓ Good: Gradual feature rollout
local enableBeta = RbxConfig:GetValueForPlayer("beta_features", player)
if enableBeta then
    enableBetaFeatures(player)
end

-- A/B test: ConfigService can target specific player segments
```

## Comparison with BetterConfig

| Feature | RbxConfig | BetterConfig |
|---------|-----------|--------------|
| **Config Source** | Cloud (Roblox ConfigService) | Local (Configuration/Attributes/Tables) |
| **Setup Complexity** | Requires ConfigService setup in Creator Dashboard | Simple (no external setup) |
| **Server Required** | Yes | No |
| **Remote Updates** | Yes (update without restart) | No (local only) |
| **Player Targeting** | Yes (per-player configs) | No |
| **Use Cases** | A/B testing, remote config, feature flags | Local game config, flexible sources |
| **Update Speed** | Network dependent | Immediate (local) |
| **Cost** | ConfigService API calls | Free (local) |

**Use RbxConfig when:**
- You need cloud-based configuration
- You want to update config without restarting servers
- You need player-specific targeting for A/B testing
- You want feature flags controlled remotely
- You need to test config changes safely with overrides

**Use BetterConfig when:**
- You need local configuration storage
- You want flexible config sources (Attributes, Configuration, tables)
- You don't need remote config updates
- Setup simplicity is important
- You want to avoid ConfigService API costs

## Dependencies

- **[sleitnick/signal@^2.0](https://github.com/sleitnick/rbx-util/tree/main/modules/signal)** - Signal implementation for reactive change observation
- **Roblox ConfigService** (built-in) - Cloud-based configuration management

## License

MIT License

---

# RbxConfig (日本語)

Roblox ConfigServiceのシングルトンラッパー。サーバー・クライアント間の自動同期機能付き。

## 概要

RbxConfigは、RobloxのConfigServiceをラップするシングルトンモジュールで、サーバー・クライアント間の自動同期、プレイヤー固有の設定ターゲティング、クラウドベースの設定値を管理するための型安全なAPIを提供します。サーバーを再起動せずにリモートで設定を更新し、プレイヤー固有の設定でA/Bテストを実行し、一時的なオーバーライドで設定変更をテストできます。

**問題**: Roblox ConfigServiceへのアクセスには、複雑なスナップショット管理、手動のクライアント同期が必要で、型安全性が欠けています。変更には注意深い監視設定とエラーが発生しやすいレプリケーションロジックが必要です。

**解決策**: RbxConfigは、遅延監視、RemoteEvent/RemoteFunction設定、プレイヤースナップショットキャッシング、型安全なキー自動補完など、すべての複雑さを自動的に処理します。

## 機能

- **クラウドベースの設定**: Roblox ConfigService経由
- **サーバー・クライアント間の自動同期**: RemoteFunction(初期)とRemoteEvent(更新)を使用
- **プレイヤー固有の設定ターゲティング**: A/Bテストとパーソナライゼーション用
- **テストオーバーライドシステム**: QAとデバッグ用
- **型安全なAPI**: キー自動補完付き
- **遅延監視**: パフォーマンス向上(リスナーがあるキーのみ監視)
- **シングルトンパターン**: `InitServer`と`InitClient`

## 前提条件

このモジュールは、エクスペリエンスでRoblox ConfigServiceが設定されている必要があります:

1. [Creator Dashboard](https://create.roblox.com/)に移動
2. エクスペリエンスを選択
3. **設定** → **Config Service**に移動
4. エクスペリエンスの設定キーを作成

詳細については、[Roblox ConfigServiceドキュメント](https://create.roblox.com/docs/cloud/open-cloud/usage-configuration)を参照してください。

## インストール

### Wally経由

```toml
[dependencies]
signal = "sleitnick/signal@^2.0"
```

### 手動インストール

`Modules/RbxConfig/`ディレクトリをプロジェクトのReplicatedStorageにコピーしてください。

## クイックスタート

### サーバー

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RbxConfig = require(ReplicatedStorage.Modules.RbxConfig):InitServer({
    max_players_per_team = 4,
})

local value = RbxConfig:GetValue("max_players_per_team")
print("チームあたりの最大プレイヤー数:", value)
```

### クライアント

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RbxConfig = require(ReplicatedStorage.Modules.RbxConfig):InitClient({
    max_players_per_team = 4,
})

local value = RbxConfig:GetValue("max_players_per_team")
print("チームあたりの最大プレイヤー数:", value)
```

## 設定の定義

ベストプラクティス: サーバーとクライアントの両方で使用するために、共有モジュールで設定を定義します。

```lua
-- ReplicatedStorage/shared/RbxConfigSetting.luau
export type ConfigSetting = {
    max_players_per_team: number,
}

local configSettings = {
    max_players_per_team = 4,
} :: ConfigSetting

return configSettings
```

その後、サーバーとクライアントの両方で使用します:

```lua
local configSettings = require(ReplicatedStorage.shared.RbxConfigSetting)
local RbxConfig = require(ReplicatedStorage.Modules.RbxConfig):InitServer(configSettings)
```

## サーバーサイドの使用方法

### 値の取得

```lua
local value = RbxConfig:GetValue("max_players_per_team")
```

**値の優先順位:**
1. テストオーバーライド(`SetTestingValue`で設定された場合)
2. ConfigServiceスナップショットの値
3. `configSettings`のデフォルト値

### 変更の監視

```lua
RbxConfig:GetValueChangedSignal("max_players_per_team"):Connect(function(newValue)
    print("チームあたりの最大プレイヤー数が変更されました:", newValue)
    -- 新しい値に基づいてゲームロジックを更新
end)
```

**遅延監視:** ConfigServiceスナップショットは、リスナーがアタッチされているキーに対してのみ監視されます。これにより、不要なネットワーク呼び出しを回避してパフォーマンスが向上します。

**動作方法:**
1. キーに対して`GetValueChangedSignal`が初めて呼び出されると、RbxConfigはそのキーの監視を開始
2. スナップショットの`UpdateAvailable`イベントが`Refresh()`をトリガー
3. キーの値が変更されると、シグナルが発火し、更新がすべてのクライアントにプッシュされる

### プレイヤー固有の設定

A/Bテストやパーソナライゼーションのために、特定のプレイヤーをターゲットにした設定値を取得します:

```lua
Players.PlayerAdded:Connect(function(player)
    local maxPlayers = RbxConfig:GetValueForPlayer("max_players_per_team", player)
    print(player.Name, "はmax_players_per_teamを", maxPlayers, "として見ています")

    -- プレイヤー固有の設定を機能に使用
    if maxPlayers > 4 then
        enableBetaFeatures(player)
    end
end)
```

**ユースケース:**
- A/Bテスト: 異なるプレイヤーグループに異なる設定を表示
- 地域設定: プレイヤーの場所に基づく異なる設定
- VIP機能: 特定のプレイヤーの機能を有効化
- 段階的なロールアウト: 機能を段階的に有効化

**プレイヤースナップショットキャッシング:** プレイヤー固有のスナップショットはキャッシュされ、`PlayerRemoving`でクリーンアップされます。

### テストオーバーライド

ライブのConfigService値に触れることなく、QAテストのために設定値を一時的にオーバーライドします:

```lua
-- 値をオーバーライド
RbxConfig:SetTestingValue("max_players_per_team", 8)
-- すべてのクライアントが即座にオーバーライドを受信

-- 待機してから元の値を復元
task.delay(60, function()
    RbxConfig:ClearTestingValue("max_players_per_team")
    -- すべてのクライアントが即座に元のConfigService値を受信
end)
```

**QAワークフロー:**
1. QAチームがコマンドを実行してテストオーバーライドを設定
2. オーバーライドされた設定で機能をテスト
3. オーバーライドをクリアして本番設定を復元
4. ConfigServiceの変更は不要、サーバーの再起動も不要

**重要:** テストオーバーライドはサーバー専用で、サーバー再起動時に失われます。テスト用に使用し、本番ロジックには使用しないでください。

## クライアントサイドの使用方法

### 値の取得

```lua
local value = RbxConfig:GetValue("max_players_per_team")
```

**初期同期:** クライアントが`InitClient`を呼び出すと、サーバーからすべての現在の値を取得するためにRemoteFunctionを呼び出します。ネットワークリクエストが失敗した場合、`configSettings`で提供されたデフォルトにフォールバックします。

### 変更の監視

```lua
RbxConfig:GetValueChangedSignal("max_players_per_team"):Connect(function(newValue)
    print("チームあたりの最大プレイヤー数が変更されました:", newValue)

    -- 新しい値に基づいてUIを更新
    updateTeamSelectUI(newValue)
end)
```

**UI更新のシナリオ:**
```lua
local teamUI = player.PlayerGui.TeamSelect

RbxConfig:GetValueChangedSignal("max_players_per_team"):Connect(function(newValue)
    teamUI.MaxLabel.Text = `最大: {newValue}`
    teamUI.TeamList:UpdateCapacity(newValue)
end)
```

### 自動同期

サーバーが設定値を更新すると(ConfigServiceまたはテストオーバーライド経由)、RemoteEventを介してすべてのクライアントに更新をプッシュします。クライアントは自動的に内部の`_values`を更新し、接続されているシグナルを発火します。

**クライアントの再起動は不要:** 設定変更はすべてのクライアントで即座に有効になります。

## アーキテクチャ

### サーバーアーキテクチャ

- **ConfigSnapshot管理**: `ConfigService:GetConfigAsync()`を介して単一のグローバルスナップショットを取得
- **遅延監視**: リスナーがあるキーのみ監視(`GetValueChangedSignal`が呼び出された)
- **UpdateAvailable → Refresh**: ConfigServiceが更新をプッシュすると、`snapshot:Refresh()`を呼び出して新しい値を取得
- **RemoteFunction**: 初期クライアント値リクエスト用に`"RbxConfigRemoteFunction"`として作成
- **RemoteEvent**: クライアントへの更新プッシュ用に`"RbxConfigRemoteEvent"`として作成
- **プレイヤースナップショットキャッシング**: プレイヤーごとのスナップショットをキャッシュし、`PlayerRemoving`でクリーンアップ

### クライアントアーキテクチャ

- **初期値取得**: `InitClient`でサーバーからすべての値を取得するためにRemoteFunctionを呼び出す
- **RemoteEventリスナー**: サーバーからプッシュされた更新(key, newValue)をリッスン
- **ローカルシグナル管理**: `_signals`テーブルを維持し、値が更新されたときにシグナルを発火
- **デフォルトへのフォールバック**: ネットワークリクエストが失敗した場合、`configSettings`のデフォルトを使用

### レプリケーションフロー

1. **サーバー起動**: サーバーが`InitServer`を呼び出し、ConfigServiceからグローバルConfigSnapshotを取得
2. **クライアント起動**: クライアントが`InitClient`を呼び出し、初期値を取得するためにRemoteFunctionを呼び出す
3. **遅延監視**: そのキーに対して`GetValueChangedSignal`が初めて呼び出されたときにサーバーがキーの監視を開始
4. **ConfigService更新**: ConfigServiceが更新をプッシュすると、サーバーは`UpdateAvailable`を介して検出し、`Refresh()`を呼び出し、`_values[key]`を更新し、ローカルシグナルを発火し、RemoteEvent経由ですべてのクライアントにプッシュ
5. **テストオーバーライド**: `SetTestingValue`は即座に`_values`を更新し、シグナルを発火し、クライアントにプッシュ(ConfigServiceをバイパス)

## APIリファレンス

### モジュールメソッド

#### `InitServer<T>(configSettings: T): ServerConfigClass<T>`
サーバー用にRbxConfigを初期化します。サーバーで一度だけ呼び出す必要があります。

**パラメータ:**
- `configSettings`: 設定キーとそのデフォルト値を定義するテーブル

**戻り値:** 完全なAPI(GetValue、GetValueChangedSignal、GetValueForPlayer、SetTestingValue、ClearTestingValue)を持つサーバーサイドRbxConfigインスタンス

---

#### `InitClient<T>(configSettings: T): RbxConfig<T>`
クライアント用にRbxConfigを初期化します。各クライアントで一度だけ呼び出す必要があります。

**パラメータ:**
- `configSettings`: 設定キーとそのデフォルト値を定義するテーブル(サーバーと一致する必要があります)

**戻り値:** 読み取り専用API(GetValue、GetValueChangedSignal)を持つクライアントサイドRbxConfigインスタンス

---

### 共有メソッド(サーバーとクライアント)

#### `GetValue<T>(key: keyof<T>): index<T, keyof<T>>`
指定された設定キーの現在の値を取得します。

**サーバーの動作:**
- まずテストオーバーライドをチェック
- ConfigServiceスナップショット値にフォールバック
- `configSettings`のデフォルトにフォールバック

**クライアントの動作:**
- 内部`_values`から値を返す(サーバーから同期)
- `configSettings`のデフォルトにフォールバック

**パラメータ:**
- `key`: 設定キー(型ヒント付きで自動補完有効)

**戻り値:** 現在の値

---

#### `GetValueChangedSignal<T>(key: keyof<T>): Signal<index<T, keyof<T>>>`
指定されたキーの値が変更されたときに発火するSignalを返します。

**サーバーの動作:**
- このキーのConfigServiceスナップショットの監視を遅延開始
- ConfigServiceが更新をプッシュするか、テストオーバーライドが変更されたときに発火

**クライアントの動作:**
- サーバーがRemoteEvent経由で更新をプッシュしたときに発火

**パラメータ:**
- `key`: 設定キー(型ヒント付きで自動補完有効)

**戻り値:** `Connect`、`Once`、`Wait`メソッドを持つSignalオブジェクト

---

### サーバー専用メソッド

#### `GetValueForPlayer<T>(key: keyof<T>, player: Player): index<T, keyof<T>>`
特定のプレイヤーをターゲットにした設定値を取得します。`ConfigService:GetConfigForPlayerAsync`を使用します。

**パラメータ:**
- `key`: 設定キー(型ヒント付きで自動補完有効)
- `player`: 設定を取得するPlayerインスタンス

**戻り値:** プレイヤー固有の設定値

**注意:** プレイヤースナップショットはキャッシュされ、`PlayerRemoving`で自動的にクリーンアップされます。

---

#### `SetTestingValue<T>(key: keyof<T>, value: index<T, keyof<T>>): ()`
指定されたキーの一時的なテストオーバーライドを設定します。即座にすべてのクライアントにプッシュします。

**パラメータ:**
- `key`: 設定キー(型ヒント付きで自動補完有効)
- `value`: オーバーライド値

**使用目的:** QAテスト、デバッグ、一時的な機能フラグ

**重要:** テストオーバーライドはサーバー再起動時に失われます。本番ロジックには使用しないでください。

---

#### `ClearTestingValue<T>(key: keyof<T>): ()`
テストオーバーライドをクリアし、元のConfigService値を復元します。即座にすべてのクライアントにプッシュします。

**パラメータ:**
- `key`: 設定キー(型ヒント付きで自動補完有効)

---

### 型

```lua
-- 設定値の型(ConfigServiceがサポート)
export type ConfigSettingValue = number | string | Json
export type ConfigSetting = { [string]: ConfigSettingValue }

-- クライアントインターフェース
export type RbxConfig<T = ConfigSetting> = {
    GetValue: (self: RbxConfig<T>, key: keyof<T>) -> index<T, keyof<T>>,
    GetValueChangedSignal: (self: RbxConfig<T>, key: keyof<T>) -> Signal<index<T, keyof<T>>>,
}

-- サーバーインターフェース(クライアントインターフェースを拡張)
export type ServerConfigClass<T = { [string]: any }> = RbxConfig<T> & {
    SetTestingValue: (self: ServerConfigClass<T>, key: keyof<T>, value: index<T, keyof<T>>) -> (),
    ClearTestingValue: (self: ServerConfigClass<T>, key: keyof<T>) -> (),
    GetValueForPlayer: (self: ServerConfigClass<T>, key: keyof<T>, player: Player) -> index<T, keyof<T>>,
}

-- モジュールインターフェース
export type RbxConfigModule = {
    InitServer: <U>(self: RbxConfigModule, configSettings: U) -> ServerConfigClass<U>,
    InitClient: <U>(self: RbxConfigModule, configSettings: U) -> RbxConfig<U>,
}
```

## 例

完全な例は以下で利用可能です:
- [`/Examples/server/RbxConfig.server.luau`](../../Examples/server/RbxConfig.server.luau) - サーバー初期化とテストオーバーライド
- [`/Examples/client/RbxConfig.client.luau`](../../Examples/client/RbxConfig.client.luau) - クライアント初期化と監視
- [`/Examples/shared/RbxConfigSetting.luau`](../../Examples/shared/RbxConfigSetting.luau) - 設定定義

### 例1: 基本的なサーバー初期化

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RbxConfigModule = require(ReplicatedStorage.Modules.RbxConfig)
local configSettings = require(ReplicatedStorage.shared.RbxConfigSetting)

local RbxConfig = RbxConfigModule:InitServer(configSettings)

-- 値を取得
local maxPlayers = RbxConfig:GetValue("max_players_per_team")

-- 変更を監視
RbxConfig:GetValueChangedSignal("max_players_per_team"):Connect(function(newValue)
    print("設定が更新されました:", newValue)
end)
```

### 例2: プレイヤー固有の設定(A/Bテスト)

```lua
local Players = game:GetService("Players")

Players.PlayerAdded:Connect(function(player)
    -- プレイヤー固有の設定を取得
    local showNewUI = RbxConfig:GetValueForPlayer("show_new_ui", player)

    if showNewUI then
        -- プレイヤーはA/Bテストグループに参加、新しいUIを表示
        player:SetAttribute("UIVersion", "new")
        print(player.Name, "は新しいUIテストグループに参加しています")
    else
        -- プレイヤーは古いUIを見る
        player:SetAttribute("UIVersion", "old")
    end
end)
```

### 例3: QA用のテストオーバーライド

```lua
-- 異なるチームサイズをテストするQAコマンド
game:GetService("ReplicatedStorage").Events.QACommand.OnServerEvent:Connect(function(player, command, value)
    if not isQATester(player) then return end

    if command == "setTeamSize" then
        RbxConfig:SetTestingValue("max_players_per_team", value)
        print(`QA: チームサイズを{value}に設定`)

        -- 5分後に自動クリア
        task.delay(300, function()
            RbxConfig:ClearTestingValue("max_players_per_team")
            print("QA: チームサイズオーバーライドをクリア")
        end)
    end
end)
```

## ベストプラクティス

### 1. 共有設定
共有モジュールで設定を一度定義します:

```lua
-- ✓ 良い: 共有設定
local configSettings = require(ReplicatedStorage.shared.RbxConfigSetting)
local serverConfig = RbxConfig:InitServer(configSettings)
local clientConfig = RbxConfig:InitClient(configSettings)
```

```lua
-- ✗ 悪い: 重複した設定
local serverConfig = RbxConfig:InitServer({ max_players = 4 })
local clientConfig = RbxConfig:InitClient({ max_players = 4 })  -- 重複!
```

### 2. フォールバック値
常に適切なデフォルトを提供します:

```lua
-- ✓ 良い: 適切なデフォルト
local configSettings = {
    max_players_per_team = 4,      -- 合理的なデフォルト
    round_time = 300,                -- 5分のデフォルト
}
```

### 3. 型安全性
適切な型付けで戻り値をキャプチャします:

```lua
-- ✓ 良い: 自動補完付きで型安全
type MyConfig = { max_players_per_team: number }
local RbxConfig = RbxConfigModule:InitServer(configSettings)
local maxPlayers = RbxConfig:GetValue("max_players_per_team")  -- 自動補完が機能!
```

### 4. 遅延監視
変更を監視する必要がある場合のみ`GetValueChangedSignal`を呼び出します:

```lua
-- ✓ 良い: 必要なものだけ監視
RbxConfig:GetValueChangedSignal("max_players_per_team"):Connect(handler)

-- ✗ 悪い: すべてを不必要に監視
for key in configSettings do
    RbxConfig:GetValueChangedSignal(key):Connect(function() end)
end
```

### 5. テストオーバーライド
QA/デバッグにはテストオーバーライドを使用し、本番ロジックには使用しません:

```lua
-- ✓ 良い: QAテスト
if isQAMode then
    RbxConfig:SetTestingValue("max_players_per_team", 8)
end

-- ✗ 悪い: テストオーバーライドに依存する本番ロジック
RbxConfig:SetTestingValue("enable_feature", true)  -- 本番には使用しないでください!
```

### 6. プレイヤーターゲティング
制御されたロールアウトにはプレイヤー固有の設定を活用します:

```lua
-- ✓ 良い: 段階的な機能ロールアウト
local enableBeta = RbxConfig:GetValueForPlayer("beta_features", player)
if enableBeta then
    enableBetaFeatures(player)
end

-- A/Bテスト: ConfigServiceは特定のプレイヤーセグメントをターゲットにできます
```

## BetterConfigとの比較

| 機能 | RbxConfig | BetterConfig |
|------|-----------|--------------|
| **設定ソース** | クラウド(Roblox ConfigService) | ローカル(Configuration/Attributes/Tables) |
| **セットアップの複雑さ** | Creator DashboardでのConfigServiceセットアップが必要 | シンプル(外部セットアップ不要) |
| **サーバー必須** | はい | いいえ |
| **リモート更新** | はい(再起動なしで更新) | いいえ(ローカルのみ) |
| **プレイヤーターゲティング** | はい(プレイヤー別設定) | いいえ |
| **ユースケース** | A/Bテスト、リモート設定、機能フラグ | ローカルゲーム設定、柔軟なソース |
| **更新速度** | ネットワーク依存 | 即座(ローカル) |
| **コスト** | ConfigService API呼び出し | 無料(ローカル) |

**RbxConfigを使用する場合:**
- クラウドベースの設定が必要
- サーバー再起動なしで設定を更新したい
- A/Bテストのためのプレイヤー固有のターゲティングが必要
- リモートで制御される機能フラグが必要
- オーバーライドで設定変更を安全にテストしたい

**BetterConfigを使用する場合:**
- ローカル設定ストレージが必要
- 柔軟な設定ソース(Attributes、Configuration、tables)が必要
- リモート設定更新が不要
- セットアップのシンプルさが重要
- ConfigService APIコストを回避したい

## 依存関係

- **[sleitnick/signal@^2.0](https://github.com/sleitnick/rbx-util/tree/main/modules/signal)** - リアクティブな変更監視のためのSignal実装
- **Roblox ConfigService** (組み込み) - クラウドベースの設定管理

## ライセンス

MIT License
