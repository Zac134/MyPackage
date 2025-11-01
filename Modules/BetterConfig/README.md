# BetterConfig

[English](#english) | [日本語](#japanese)

---

<a name="english"></a>

## English

### Overview

BetterConfig is a Roblox Luau module that provides reactive configuration management using Signals. It supports both Configuration instances with ValueBase children and Attributes, allowing you to observe and react to changes in real-time.

### Features

-   ✅ Support for Configuration instances with ValueBase objects (IntValue, StringValue, etc.)
-   ✅ Support for Instance Attributes
-   ✅ Reactive change observation using Signals
-   ✅ Observe specific key changes or all changes
-   ✅ Automatic resource cleanup
-   ✅ Type-safe with Luau type annotations

### Installation

#### Using Wally

Add the following to your `wally.toml`:

```toml
[dependencies]
BetterConfig = "your-username/betterconfig@version"
```

### Important Behavior

**Value Update Policy:**

-   Initial values are loaded when `BetterConfig.new()` is called
-   **Values are only updated automatically when you observe them** using `Observe(key)` or `ObserveAll()`
-   If you don't observe a value, it will remain at its initial state even if the source changes
-   This design allows for selective observation and better performance

```lua
local config = BetterConfig.new(instance)
print(config.SomeValue) -- 10 (initial value)

-- Without observation, the value won't update
instance:SetAttribute("SomeValue", 20)
print(config.SomeValue) -- Still 10 (not updated)

-- Start observing
config:Observe("SomeValue")
instance:SetAttribute("SomeValue", 30)
print(config.SomeValue) -- 30 (now updates automatically)
```

### Usage

#### Basic Usage

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BetterConfig = require(ReplicatedStorage.Packages.BetterConfig)

-- With Configuration instance
local configInstance = workspace.GameConfig -- Configuration with ValueBase children
local config = BetterConfig.new(configInstance)

-- Access initial values directly
print(config.MaxPlayers) -- Assuming there's an IntValue named "MaxPlayers"
print(config.GameMode)   -- Assuming there's a StringValue named "GameMode"

-- With Attributes
local settingsInstance = workspace.Settings
local settings = BetterConfig.new(settingsInstance)

-- Access initial attribute values
print(settings.Volume)
print(settings.Brightness)
```

#### Observing Specific Changes

```lua
-- Observe a specific key
local maxPlayersObserver = config:Observe("MaxPlayers")

maxPlayersObserver:Connect(function(newValue)
    print("MaxPlayers changed to:", newValue)
end)
```

#### Observing All Changes

```lua
-- Observe all changes
local allChangesObserver = config:ObserveAll()

allChangesObserver:Connect(function(key, newValue)
    print(string.format("%s changed to: %s", key, tostring(newValue)))
end)
```

#### Cleanup

```lua
-- When you're done with the config, clean up resources
config:Destroy()
```

### API Reference

#### `BetterConfig.new(src: Configuration | Instance): Config`

Creates a new Config instance from either a Configuration object or an Instance with Attributes.

**Parameters:**

-   `src`: A Configuration instance (uses ValueBase children) or any Instance (uses Attributes)

**Returns:**

-   `Config`: A new Config object

#### `Config:Observe(key: string): Signal<any>`

Creates or returns a Signal that fires when a specific configuration value changes.

**Important:** Once you call this method, the specified key's value will automatically update in the Config object whenever the source changes.

**Parameters:**

-   `key`: The name of the configuration value to observe

**Returns:**

-   `Signal<any>`: A Signal that fires with the new value when the specified key changes

#### `Config:ObserveAll(): Signal<string, any>`

Creates or returns a Signal that fires when any configuration value changes.

**Important:** Once you call this method, all values in the Config object will automatically update whenever the source changes.

**Returns:**

-   `Signal<string, any>`: A Signal that fires with (key, value) when any value changes

#### `Config:Destroy()`

Cleans up all connections and signals. Should be called when the Config instance is no longer needed.

### Type Definitions

```lua
export type Config = {
    BaseInstance: Configuration | Instance,
    ObserveChange: boolean,
    Observe: (self: Config, key: string) -> Signal<any>,
    ObserveAll: (self: Config) -> Signal<string, any>,
    Destroy: (self: Config) -> (),
    Type: "Config" | "Attribute",
}
```

### Example: Game Settings Manager

```lua
local BetterConfig = require(ReplicatedStorage.Packages.BetterConfig)

-- Create settings manager
local gameSettings = BetterConfig.new(workspace.GameSettings)

-- Listen for difficulty changes
gameSettings:Observe("Difficulty"):Connect(function(difficulty)
    print("Game difficulty set to:", difficulty)
    -- Update game mechanics based on difficulty
end)

-- Listen for all settings changes
gameSettings:ObserveAll():Connect(function(key, value)
    print("Setting updated:", key, value)
    -- Log or sync to server
end)
```

### Dependencies

-   [sleitnick_signal](https://github.com/Sleitnick/RbxUtil/tree/main/modules/signal) - Signal implementation for reactive updates

### License

MIT

---

<a name="japanese"></a>

## 日本語

### 概要

BetterConfig は、Signal を使用してリアクティブな設定管理を提供する Roblox Luau モジュールです。ValueBase 子要素を持つ Configuration インスタンスと Attributes の両方をサポートし、リアルタイムで変更を監視して反応できます。

### 特徴

-   ✅ ValueBase オブジェクト（IntValue、StringValue など）を持つ Configuration インスタンスのサポート
-   ✅ インスタンス Attributes のサポート
-   ✅ Signal を使用したリアクティブな変更監視
-   ✅ 特定のキーまたはすべての変更を監視可能
-   ✅ 自動リソースクリーンアップ
-   ✅ Luau 型注釈による型安全性

### インストール

#### Wally を使用する場合

`wally.toml`に以下を追加してください：

```toml
[dependencies]
BetterConfig = "your-username/betterconfig@version"
```

### 重要な動作

**値の更新ポリシー:**

-   初期値は `BetterConfig.new()` を呼び出したときに読み込まれます
-   **値は `Observe(key)` または `ObserveAll()` を使用して監視している場合のみ自動的に更新されます**
-   監視していない値は、ソースが変更されても初期状態のままです
-   この設計により、選択的な監視とパフォーマンスの向上が可能になります

```lua
local config = BetterConfig.new(instance)
print(config.SomeValue) -- 10 (初期値)

-- 監視していない場合、値は更新されません
instance:SetAttribute("SomeValue", 20)
print(config.SomeValue) -- まだ10のまま（更新されていない）

-- 監視を開始
config:Observe("SomeValue")
instance:SetAttribute("SomeValue", 30)
print(config.SomeValue) -- 30 (これで自動的に更新される)
```

### 使用方法

#### 基本的な使い方

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BetterConfig = require(ReplicatedStorage.Packages.BetterConfig)

-- Configurationインスタンスを使用
local configInstance = workspace.GameConfig -- ValueBase子要素を持つConfiguration
local config = BetterConfig.new(configInstance)

-- 初期値に直接アクセス
print(config.MaxPlayers) -- "MaxPlayers"という名前のIntValueがあると仮定
print(config.GameMode)   -- "GameMode"という名前のStringValueがあると仮定

-- Attributesを使用
local settingsInstance = workspace.Settings
local settings = BetterConfig.new(settingsInstance)

-- 初期Attribute値にアクセス
print(settings.Volume)
print(settings.Brightness)
```

#### 特定の変更を監視

```lua
-- 特定のキーを監視
local maxPlayersObserver = config:Observe("MaxPlayers")

maxPlayersObserver:Connect(function(newValue)
    print("MaxPlayersが変更されました:", newValue)
end)
```

#### すべての変更を監視

```lua
-- すべての変更を監視
local allChangesObserver = config:ObserveAll()

allChangesObserver:Connect(function(key, newValue)
    print(string.format("%sが%sに変更されました", key, tostring(newValue)))
end)
```

#### クリーンアップ

```lua
-- configが不要になったら、リソースをクリーンアップ
config:Destroy()
```

### API リファレンス

#### `BetterConfig.new(src: Configuration | Instance): Config`

Configuration オブジェクトまたは Attributes を持つインスタンスから新しい Config インスタンスを作成します。

**パラメータ:**

-   `src`: Configuration インスタンス（ValueBase 子要素を使用）または任意のインスタンス（Attributes を使用）

**戻り値:**

-   `Config`: 新しい Config オブジェクト

#### `Config:Observe(key: string): Signal<any>`

特定の設定値が変更されたときに発火する Signal を作成または返します。

**重要:** このメソッドを呼び出すと、指定されたキーの値はソースが変更されるたびに Config オブジェクト内で自動的に更新されるようになります。

**パラメータ:**

-   `key`: 監視する設定値の名前

**戻り値:**

-   `Signal<any>`: 指定されたキーが変更されたときに新しい値で発火する Signal

#### `Config:ObserveAll(): Signal<string, any>`

任意の設定値が変更されたときに発火する Signal を作成または返します。

**重要:** このメソッドを呼び出すと、Config オブジェクト内のすべての値はソースが変更されるたびに自動的に更新されるようになります。

**戻り値:**

-   `Signal<string, any>`: 任意の値が変更されたときに(key, value)で発火する Signal

#### `Config:Destroy()`

すべての接続とシグナルをクリーンアップします。Config インスタンスが不要になったときに呼び出す必要があります。

### 型定義

```lua
export type Config = {
    BaseInstance: Configuration | Instance,
    ObserveChange: boolean,
    Observe: (self: Config, key: string) -> Signal<any>,
    ObserveAll: (self: Config) -> Signal<string, any>,
    Destroy: (self: Config) -> (),
    Type: "Config" | "Attribute",
}
```

### 例：ゲーム設定マネージャー

```lua
local BetterConfig = require(ReplicatedStorage.Packages.BetterConfig)

-- 設定マネージャーを作成
local gameSettings = BetterConfig.new(workspace.GameSettings)

-- 難易度の変更をリッスン
gameSettings:Observe("Difficulty"):Connect(function(difficulty)
    print("ゲーム難易度が設定されました:", difficulty)
    -- 難易度に基づいてゲームメカニクスを更新
end)

-- すべての設定変更をリッスン
gameSettings:ObserveAll():Connect(function(key, value)
    print("設定が更新されました:", key, value)
    -- ログを記録またはサーバーに同期
end)
```

### 依存関係

-   [sleitnick_signal](https://github.com/Sleitnick/RbxUtil/tree/main/modules/signal) - リアクティブ更新のための Signal 実装

### ライセンス

MIT
