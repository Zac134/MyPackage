# BetterConfig

[English](#english) | [日本語](#japanese)

---

<a name="english"></a>

## English

### Overview

BetterConfig is a Roblox Luau module that provides unified configuration management using the Strategy Pattern. It automatically selects the appropriate implementation based on the source type — `Configuration` instances (ValueBase children) or Instance Attributes — and exposes a consistent API for getting, setting, and observing value changes via Signals.

### Features

- Support for `Configuration` instances with ValueBase objects (IntValue, StringValue, NumberValue, etc.)
- Support for Instance Attributes
- Unified API (`Get` / `Set` / `GetValueChangedSignal`) regardless of source type
- Reactive change observation using [sleitnick/signal](https://github.com/Sleitnick/RbxUtil/tree/main/modules/signal)
- Automatic resource cleanup with `Destroy()`
- Factory pattern with automatic source type detection
- Type-safe with Luau generics and type annotations

### Installation

#### Using Wally

Add the following to your `wally.toml`:

```toml
[dependencies]
BetterConfig = "zac134/better-config@2.0.0"
```

### Usage

#### Basic Usage — Get / Set

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BetterConfig = require(ReplicatedStorage.Packages.BetterConfig)

-- With a Configuration instance (ValueBase children)
local configInstance = workspace.GameConfig -- Configuration with IntValue, StringValue, etc.
local config = BetterConfig.new(configInstance)

print(config:Get("MaxPlayers"))  -- Gets the Value of the IntValue named "MaxPlayers"
config:Set("MaxPlayers", 20)     -- Sets the Value of the IntValue named "MaxPlayers"

-- With Instance Attributes
local settingsInstance = workspace.Settings
local settings = BetterConfig.new(settingsInstance)

print(settings:Get("Volume"))    -- Gets the attribute "Volume"
settings:Set("Volume", 0.8)     -- Sets the attribute "Volume"
```

The factory `BetterConfig.new()` automatically detects the source type:

- If the source is a `Configuration` instance, it creates a **ConfigInstance** (uses ValueBase children).
- Otherwise, it creates an **AttributeConfig** (uses Instance Attributes).

#### Observing Value Changes

Use `GetValueChangedSignal(key)` to get a Signal that fires whenever the specified value changes.

```lua
local signal = config:GetValueChangedSignal("MaxPlayers")

signal:Connect(function(newValue)
    print("MaxPlayers changed to:", newValue)
end)
```

The returned Signal is a [sleitnick/signal](https://github.com/Sleitnick/RbxUtil/tree/main/modules/signal) instance, supporting `Connect`, `Once`, `Wait`, and other standard Signal methods.

#### Using Individual Implementations Directly

If you know the source type in advance, you can use the implementations directly:

```lua
-- ConfigInstance (for Configuration with ValueBase children)
local ConfigInstance = BetterConfig.ConfigInstance
local config = ConfigInstance.new(workspace.GameConfig)

-- AttributeConfig (for Instance Attributes)
local AttributeConfig = BetterConfig.AttributeConfig
local settings = AttributeConfig.new(workspace.Settings)
```

#### Cleanup

```lua
-- Clean up all connections and signals when no longer needed
config:Destroy()
```

### API Reference

#### `BetterConfig.new(src: Configuration | Instance): BaseConfigClass`

Creates a new Config instance. Automatically selects the implementation based on the source type.

**Parameters:**

- `src`: A `Configuration` instance (uses ValueBase children) or any other `Instance` (uses Attributes)

**Returns:**

- `BaseConfigClass`: The appropriate Config implementation

**Errors:**

- Throws if `src` is a table (not yet implemented)
- Throws if `src` is not a valid type

---

#### `BetterConfig.ConfigInstance`

Direct reference to the ConfigInstance class. Can be used to create ConfigInstance objects directly via `ConfigInstance.new(src: Configuration)`.

#### `BetterConfig.AttributeConfig`

Direct reference to the AttributeConfig class. Can be used to create AttributeConfig objects directly via `AttributeConfig.new(src: Instance)`.

---

#### `Config:Get(key: string): any`

Gets the current value for the specified key.

- **ConfigInstance**: Finds the ValueBase child with the given name and returns its `.Value` property. Returns `nil` if not found.
- **AttributeConfig**: Returns `Instance:GetAttribute(key)`.

**Parameters:**

- `key`: The name of the configuration value to retrieve

**Returns:**

- The current value, or `nil` if the key does not exist

---

#### `Config:Set(key: string, value: any): ()`

Sets the value for the specified key.

- **ConfigInstance**: Finds the ValueBase child with the given name and sets its `.Value` property. Warns if not found.
- **AttributeConfig**: Calls `Instance:SetAttribute(key, value)`.

**Parameters:**

- `key`: The name of the configuration value to set
- `value`: The new value

---

#### `Config:GetValueChangedSignal(key: string): Signal`

Returns a Signal that fires whenever the specified key's value changes. If the Signal for the key already exists, returns the existing one.

- **ConfigInstance**: Connects to the ValueBase's `GetPropertyChangedSignal("Value")`. Each key gets its own RBXScriptConnection.
- **AttributeConfig**: Uses a single shared `AttributeChanged` connection (lazy-initialized on first call) that dispatches to per-key Signals.

**Parameters:**

- `key`: The name of the configuration value to observe

**Returns:**

- `Signal<any>`: A Signal that fires with the new value when the specified key changes

---

#### `Config:Destroy()`

Disconnects all RBXScriptConnections and destroys all Signals. Should be called when the Config instance is no longer needed to prevent memory leaks.

---

### Type Definitions

```lua
-- Config source type discriminator
export type ConfigSrcType = "Configuration" | "Attribute" | "Dict"

-- Config source types
export type ConfigSrc = Configuration | Instance | { [string]: any }

-- Supported ValueBase types
export type HasValuePropertyObject =
    ObjectValue | IntValue | BoolValue | StringValue
    | NumberValue | Color3Value | CFrameValue | Vector3Value
    | BrickColorValue | RayValue

-- Base config class interface
export type BaseConfigClass<T = { [string]: any }> = {
    ConfigSrc: ConfigSrc,
    ConfigType: ConfigSrcType,

    Get: <K>(self: BaseConfigClass<T>, key: keyof<T>) -> index<T, K>,
    Set: <K>(self: BaseConfigClass<T>, key: keyof<T>, value: any) -> (),
    GetValueChangedSignal: <K>(self: BaseConfigClass<T>, key: keyof<T>) -> Signal<index<T, K>>,
    Destroy: (self: BaseConfigClass<T>) -> (),
}
```

### Example: Game Settings Manager

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BetterConfig = require(ReplicatedStorage.Packages.BetterConfig)

-- Create a config from a Configuration instance
local gameConfig = BetterConfig.new(workspace.GameConfig)

-- Read initial values
local maxPlayers = gameConfig:Get("MaxPlayers")
local difficulty = gameConfig:Get("Difficulty")
print("Max Players:", maxPlayers, "Difficulty:", difficulty)

-- Update a value
gameConfig:Set("MaxPlayers", 16)

-- Listen for difficulty changes
gameConfig:GetValueChangedSignal("Difficulty"):Connect(function(newDifficulty)
    print("Difficulty changed to:", newDifficulty)
    -- Update game mechanics based on difficulty
end)

-- Listen for max players changes
gameConfig:GetValueChangedSignal("MaxPlayers"):Connect(function(newMax)
    print("Max players changed to:", newMax)
end)

-- Clean up when done
gameConfig:Destroy()
```

### Dependencies

- [sleitnick/signal@^2.0](https://github.com/Sleitnick/RbxUtil/tree/main/modules/signal) — Signal implementation for reactive change observation

### License

MIT

---

<a name="japanese"></a>

## 日本語

### 概要

BetterConfig は、Strategy Pattern を用いて統一的な設定管理を提供する Roblox Luau モジュールです。ソースの型に応じて適切な実装を自動選択し — `Configuration` インスタンス（ValueBase 子要素）またはインスタンスの Attribute — 値の取得・設定・変更監視のための一貫した API を提供します。

### 特徴

- ValueBase オブジェクト（IntValue、StringValue、NumberValue など）を持つ `Configuration` インスタンスのサポート
- インスタンス Attribute のサポート
- ソースの種類に関わらず統一された API（`Get` / `Set` / `GetValueChangedSignal`）
- [sleitnick/signal](https://github.com/Sleitnick/RbxUtil/tree/main/modules/signal) を使用したリアクティブな変更監視
- `Destroy()` による自動リソースクリーンアップ
- ファクトリーパターンによるソースタイプの自動判定
- Luau ジェネリクスと型注釈による型安全性

### インストール

#### Wally を使用する場合

`wally.toml` に以下を追加してください：

```toml
[dependencies]
BetterConfig = "zac134/better-config@2.0.0"
```

### 使用方法

#### 基本的な使い方 — Get / Set

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BetterConfig = require(ReplicatedStorage.Packages.BetterConfig)

-- Configuration インスタンスを使用（ValueBase 子要素）
local configInstance = workspace.GameConfig -- IntValue, StringValue 等を持つ Configuration
local config = BetterConfig.new(configInstance)

print(config:Get("MaxPlayers"))  -- "MaxPlayers" という名前の IntValue の Value を取得
config:Set("MaxPlayers", 20)     -- "MaxPlayers" という名前の IntValue の Value を設定

-- インスタンスの Attribute を使用
local settingsInstance = workspace.Settings
local settings = BetterConfig.new(settingsInstance)

print(settings:Get("Volume"))    -- Attribute "Volume" を取得
settings:Set("Volume", 0.8)     -- Attribute "Volume" を設定
```

ファクトリー `BetterConfig.new()` はソースの型を自動判定します：

- ソースが `Configuration` インスタンスの場合、**ConfigInstance**（ValueBase 子要素を使用）を作成します。
- それ以外の場合、**AttributeConfig**（インスタンスの Attribute を使用）を作成します。

#### 値の変更を監視

`GetValueChangedSignal(key)` を使用して、指定した値が変更されたときに発火する Signal を取得します。

```lua
local signal = config:GetValueChangedSignal("MaxPlayers")

signal:Connect(function(newValue)
    print("MaxPlayers が変更されました:", newValue)
end)
```

返される Signal は [sleitnick/signal](https://github.com/Sleitnick/RbxUtil/tree/main/modules/signal) のインスタンスで、`Connect`、`Once`、`Wait` などの標準的な Signal メソッドをサポートしています。

#### 個別の実装を直接使用

ソースの型が事前にわかっている場合、実装クラスを直接使用できます：

```lua
-- ConfigInstance（ValueBase 子要素を持つ Configuration 用）
local ConfigInstance = BetterConfig.ConfigInstance
local config = ConfigInstance.new(workspace.GameConfig)

-- AttributeConfig（インスタンスの Attribute 用）
local AttributeConfig = BetterConfig.AttributeConfig
local settings = AttributeConfig.new(workspace.Settings)
```

#### クリーンアップ

```lua
-- 不要になったら全ての接続と Signal をクリーンアップ
config:Destroy()
```

### API リファレンス

#### `BetterConfig.new(src: Configuration | Instance): BaseConfigClass`

新しい Config インスタンスを作成します。ソースの型に応じて実装を自動選択します。

**パラメータ:**

- `src`: `Configuration` インスタンス（ValueBase 子要素を使用）、またはその他の `Instance`（Attribute を使用）

**戻り値:**

- `BaseConfigClass`: 適切な Config 実装

**エラー:**

- `src` がテーブルの場合はエラー（未実装）
- `src` が無効な型の場合はエラー

---

#### `BetterConfig.ConfigInstance`

ConfigInstance クラスへの直接参照。`ConfigInstance.new(src: Configuration)` で直接オブジェクトを作成できます。

#### `BetterConfig.AttributeConfig`

AttributeConfig クラスへの直接参照。`AttributeConfig.new(src: Instance)` で直接オブジェクトを作成できます。

---

#### `Config:Get(key: string): any`

指定されたキーの現在の値を取得します。

- **ConfigInstance**: 指定された名前の ValueBase 子要素を見つけ、その `.Value` プロパティを返します。見つからない場合は `nil` を返します。
- **AttributeConfig**: `Instance:GetAttribute(key)` を返します。

**パラメータ:**

- `key`: 取得する設定値の名前

**戻り値:**

- 現在の値。キーが存在しない場合は `nil`

---

#### `Config:Set(key: string, value: any): ()`

指定されたキーに値を設定します。

- **ConfigInstance**: 指定された名前の ValueBase 子要素を見つけ、その `.Value` プロパティを設定します。見つからない場合は警告を出力します。
- **AttributeConfig**: `Instance:SetAttribute(key, value)` を呼び出します。

**パラメータ:**

- `key`: 設定する値の名前
- `value`: 新しい値

---

#### `Config:GetValueChangedSignal(key: string): Signal`

指定されたキーの値が変更されたときに発火する Signal を返します。既にそのキーの Signal が存在する場合は、既存のものを返します。

- **ConfigInstance**: ValueBase の `GetPropertyChangedSignal("Value")` に接続します。各キーごとに個別の RBXScriptConnection を作成します。
- **AttributeConfig**: 共有の `AttributeChanged` 接続を1つだけ使用し（初回呼び出し時に遅延初期化）、キーごとの Signal にディスパッチします。

**パラメータ:**

- `key`: 監視する設定値の名前

**戻り値:**

- `Signal<any>`: 指定されたキーが変更されたときに新しい値で発火する Signal

---

#### `Config:Destroy()`

全ての RBXScriptConnection を切断し、全ての Signal を破棄します。メモリリークを防ぐため、Config インスタンスが不要になったときに呼び出してください。

---

### 型定義

```lua
-- コンフィグソースの種別判別型
export type ConfigSrcType = "Configuration" | "Attribute" | "Dict"

-- コンフィグソースの型
export type ConfigSrc = Configuration | Instance | { [string]: any }

-- サポートされる ValueBase 型
export type HasValuePropertyObject =
    ObjectValue | IntValue | BoolValue | StringValue
    | NumberValue | Color3Value | CFrameValue | Vector3Value
    | BrickColorValue | RayValue

-- 基本コンフィグクラスのインターフェース
export type BaseConfigClass<T = { [string]: any }> = {
    ConfigSrc: ConfigSrc,
    ConfigType: ConfigSrcType,

    Get: <K>(self: BaseConfigClass<T>, key: keyof<T>) -> index<T, K>,
    Set: <K>(self: BaseConfigClass<T>, key: keyof<T>, value: any) -> (),
    GetValueChangedSignal: <K>(self: BaseConfigClass<T>, key: keyof<T>) -> Signal<index<T, K>>,
    Destroy: (self: BaseConfigClass<T>) -> (),
}
```

### 使用例：ゲーム設定マネージャー

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BetterConfig = require(ReplicatedStorage.Packages.BetterConfig)

-- Configuration インスタンスからコンフィグを作成
local gameConfig = BetterConfig.new(workspace.GameConfig)

-- 初期値を読み取り
local maxPlayers = gameConfig:Get("MaxPlayers")
local difficulty = gameConfig:Get("Difficulty")
print("最大プレイヤー数:", maxPlayers, "難易度:", difficulty)

-- 値を更新
gameConfig:Set("MaxPlayers", 16)

-- 難易度の変更をリッスン
gameConfig:GetValueChangedSignal("Difficulty"):Connect(function(newDifficulty)
    print("難易度が変更されました:", newDifficulty)
    -- 難易度に基づいてゲームメカニクスを更新
end)

-- 最大プレイヤー数の変更をリッスン
gameConfig:GetValueChangedSignal("MaxPlayers"):Connect(function(newMax)
    print("最大プレイヤー数が変更されました:", newMax)
end)

-- 使い終わったらクリーンアップ
gameConfig:Destroy()
```

### 依存関係

- [sleitnick/signal@^2.0](https://github.com/Sleitnick/RbxUtil/tree/main/modules/signal) — リアクティブな変更監視のための Signal 実装

### ライセンス

MIT
