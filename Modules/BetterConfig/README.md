# BetterConfig

Unified configuration management for Roblox using the Strategy Pattern.

## Overview

BetterConfig provides a single, consistent API for managing configuration data from multiple sources in Roblox. Whether your config comes from Configuration instances with ValueBase children, Instance Attributes, or plain Lua tables, BetterConfig abstracts the differences and gives you the same intuitive interface with full type safety and reactive change observation.

**Problem**: Different config sources in Roblox have different APIs (Configuration→ValueBase, Instance→Attributes, plain tables), making code inconsistent and harder to maintain.

**Solution**: BetterConfig automatically detects the source type and returns the appropriate implementation, giving you one unified interface with type-safe autocomplete.

## Features

- **Three config source strategies** with automatic detection
- **Type-safe API** with Luau generics and `keyof<T>` for autocomplete
- **Reactive value change observation** with Signal support
- **Zero boilerplate** factory pattern
- **Resource management** with `Destroy()` method

## Installation

### Via Wally

```toml
[dependencies]
BetterConfig = "zac134/better-config@2.0.0"
```

### Manual Installation

Copy the `Modules/BetterConfig/` directory to your project's ReplicatedStorage or ServerStorage.

## Quick Start

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BetterConfig = require(ReplicatedStorage.Modules.BetterConfig)

-- Factory automatically detects the config source type
local config = BetterConfig.new(workspace.GameConfig)

-- Get values
local value = config:Get("max_players")

-- Set values
config:Set("max_players", 10)

-- Observe changes
config:GetValueChangedSignal("max_players"):Connect(function(newValue)
    print("max_players changed to:", newValue)
end)
```

## Configuration Sources

### 1. Instance Attributes

Use Attributes when you need simple key-value config on existing Instances.

```lua
local part = workspace.ConfigPart
part:SetAttribute("max_items", 10)
part:SetAttribute("show_ui", true)

local config = BetterConfig.fromAttribute(part)
local maxItems = config:Get("max_items")
config:Set("show_ui", false)
```

**Benefits:**
- Flexible types supported by Roblox Attributes
- Easy to inspect and modify in Studio Properties panel
- Lightweight (no child instances required)

### 2. Configuration/ValueBase

Use Configuration instances when you need specific ValueBase types or want visual Studio editing.

```lua
local configInstance = workspace.GameConfig  -- Configuration instance with ValueBase children
local config = BetterConfig.fromConfiguration(configInstance)

local maxPlayers = config:Get("max_players")  -- Reads from IntValue child
config:Set("max_players", 8)  -- Updates IntValue.Value
```

**Benefits:**
- Type-specific ValueBase children (IntValue, StringValue, BoolValue, etc.)
- Visual hierarchy in Studio Explorer
- Direct access to ValueBase properties

**Supported ValueBase types:** `ObjectValue`, `IntValue`, `BoolValue`, `StringValue`, `NumberValue`, `Color3Value`, `CFrameValue`, `Vector3Value`, `BrickColorValue`, `RayValue`

### 3. Dictionary/Table

Use Dictionary config when you need runtime config generation, testing, or programmatic configs.

```lua
local config = BetterConfig.fromDict({
    round_time = 120,
    team_size = 4,
    map_name = "Grasslands",
})

local roundTime = config:Get("round_time")
config:Set("round_time", 180)
```

**Benefits:**
- No Instance required, pure Lua
- Perfect for testing and runtime configuration
- Automatic type mapping (string→StringValue, number→NumberValue, etc.)
- Creates internal Configuration instance with appropriate ValueBase children

## Factory vs Explicit Methods

### Auto-Detection (Recommended)

```lua
local config1 = BetterConfig.new(workspace.GameConfig)  -- Configuration detected
local config2 = BetterConfig.new(workspace.Part)         -- Attribute detected
local config3 = BetterConfig.new({key = "value"})        -- Dictionary detected
```

Use `BetterConfig.new()` when you want automatic source detection.

### Explicit Methods

```lua
local config1 = BetterConfig.fromAttribute(instance)      -- Explicit Attribute config
local config2 = BetterConfig.fromConfiguration(config)    -- Explicit Configuration config
local config3 = BetterConfig.fromDict(table)               -- Explicit Dictionary config
```

Use explicit methods when:
- You want to be explicit about the config type
- You need better type inference
- You're building a library and want clear contracts

## Type-Safe Autocomplete

Define your config shape as a type for autocomplete support:

```lua
type MyConfig = {
    show_ui: boolean,
    max_items: number,
    welcome_message: string,
}

-- Type hint enables autocomplete for all methods
local config = BetterConfig.fromAttribute(configPart)

-- Get with autocomplete - valid keys suggested automatically
local showUi = config:Get("show_ui")        -- ✓ Autocomplete works
local maxItems = config:Get("max_items")    -- ✓ Autocomplete works
-- config:Get("invalid_key")                -- ✗ Type error if strict mode enabled
```

The type definition enables your IDE/editor to suggest valid keys when calling `Get`, `Set`, and `GetValueChangedSignal`.

## Observing Value Changes

`GetValueChangedSignal` returns a [Signal](https://github.com/sleitnick/rbx-util/tree/main/modules/signal) that fires when a value changes:

```lua
local signal = config:GetValueChangedSignal("max_items")

-- Connect to listen for changes
signal:Connect(function(newValue)
    print("max_items changed to:", newValue)
end)

-- Fire once and disconnect
signal:Once(function(newValue)
    print("First change detected:", newValue)
end)

-- Wait for next change
task.spawn(function()
    local newValue = signal:Wait()
    print("Got new value:", newValue)
end)
```

### When Signals Fire

- **AttributeConfig**: Fires when `Instance:SetAttribute()` is called or Attribute changes in Studio
- **ConfigInstance**: Fires when the ValueBase child's `.Value` property changes
- **DictionaryConfig**: Fires when `Set()` is called on the config

## Resource Cleanup

Always call `Destroy()` when you're done with a config to clean up connections and signals:

```lua
local config = BetterConfig.new(workspace.GameConfig)

-- Use the config...
config:GetValueChangedSignal("max_items"):Connect(handler)

-- Clean up when done (important!)
config:Destroy()
```

**Why it matters:** `GetValueChangedSignal` creates `RBXScriptConnection` objects and Signal instances. Calling `Destroy()` disconnects all connections and destroys all signals, preventing memory leaks.

**When to call Destroy():**
- When the config is no longer needed
- Before removing the source Instance
- In cleanup functions (e.g., `Maid:DoCleaning()`)

## API Reference

### Factory Methods

#### `BetterConfig.new<T>(src: ConfigSrc): BaseConfigClass<T>`
Auto-detects the config source type and returns the appropriate implementation.

**Parameters:**
- `src`: Configuration instance, Instance (uses Attributes), or Lua table

**Returns:** Config object with `Get`, `Set`, `GetValueChangedSignal`, and `Destroy` methods

---

#### `BetterConfig.fromAttribute<T>(src: Instance): AttributeConfig<T>`
Creates an Attribute-based config explicitly.

**Parameters:**
- `src`: Any Instance with Attributes

**Returns:** AttributeConfig implementation

---

#### `BetterConfig.fromConfiguration<T>(src: Configuration): ConfigInstance<T>`
Creates a Configuration/ValueBase-based config explicitly.

**Parameters:**
- `src`: Configuration instance with ValueBase children

**Returns:** ConfigInstance implementation

---

#### `BetterConfig.fromDict<T>(src: {[string]: any}): DictionaryConfig<T>`
Creates a Dictionary-based config explicitly. Internally creates a Configuration instance with appropriate ValueBase children.

**Parameters:**
- `src`: Lua table with string keys and number/string/boolean values

**Returns:** DictionaryConfig implementation

---

### Instance Methods

All config implementations expose the same interface:

#### `Get<T>(key: keyof<T>): index<T, keyof<T>>`
Retrieves the current value for the specified key.

**Parameters:**
- `key`: Configuration key (autocomplete enabled with type hints)

**Returns:** Current value

---

#### `Set<T>(key: keyof<T>, value: index<T, keyof<T>>): ()`
Sets a new value for the specified key.

**Parameters:**
- `key`: Configuration key (autocomplete enabled with type hints)
- `value`: New value to set

---

#### `GetValueChangedSignal<T>(key: keyof<T>): Signal<index<T, keyof<T>>>`
Returns a Signal that fires when the specified key's value changes.

**Parameters:**
- `key`: Configuration key (autocomplete enabled with type hints)

**Returns:** Signal object with `Connect`, `Once`, `Wait` methods

---

#### `Destroy(): ()`
Cleans up all connections and signals. Call this when done with the config.

---

### Types

```lua
export type BaseConfigClass<T = { [string]: any }> = {
    ConfigSrc: ConfigSrc,
    ConfigType: ConfigSrcType,

    Get: (self: BaseConfigClass<T>, key: keyof<T>) -> index<T, keyof<T>>,
    Set: (self: BaseConfigClass<T>, key: keyof<T>, value: index<T, keyof<T>>) -> (),
    GetValueChangedSignal: (self: BaseConfigClass<T>, key: keyof<T>) -> Signal,
    Destroy: (self: BaseConfigClass<T>) -> (),
}

export type ConfigSrc = Configuration | Instance | { [string]: any }
export type ConfigSrcType = "Configuration" | "Attribute" | "Dict"
```

## Examples

Full examples are available at:
- [`/Examples/client/BetterConfig.client.luau`](../../Examples/client/BetterConfig.client.luau) - Comprehensive examples with Attributes and Dictionary configs

### Example 1: Attribute Config with Change Observation

```lua
local BetterConfig = require(ReplicatedStorage.Modules.BetterConfig)

-- Create a part with attributes
local configPart = Instance.new("Part")
configPart:SetAttribute("show_ui", true)
configPart:SetAttribute("max_items", 10)

-- Create config
local config = BetterConfig.fromAttribute(configPart)

-- Get values
print(config:Get("show_ui"))      -- true
print(config:Get("max_items"))    -- 10

-- Observe changes
config:GetValueChangedSignal("max_items"):Connect(function(newValue)
    print("max_items changed to:", newValue)
end)

-- Update value (fires the signal)
config:Set("max_items", 20)  -- Prints: "max_items changed to: 20"
```

### Example 2: Dictionary Config

```lua
local BetterConfig = require(ReplicatedStorage.Modules.BetterConfig)

-- Create config from table
local config = BetterConfig.fromDict({
    round_time = 120,
    team_size = 4,
    map_name = "Grasslands",
})

-- Use like any other config
print(config:Get("round_time"))  -- 120

-- Observe and update
config:GetValueChangedSignal("round_time"):Connect(function(newValue)
    print("Round time changed to:", newValue)
end)

config:Set("round_time", 180)  -- Prints: "Round time changed to: 180"
```

## Comparison with RbxConfig

| Feature | BetterConfig | RbxConfig |
|---------|--------------|-----------|
| **Config Source** | Local (Configuration/Attributes/Tables) | Cloud (Roblox ConfigService) |
| **Setup Complexity** | Simple (no external setup) | Requires ConfigService setup in Creator Dashboard |
| **Server Required** | No | Yes |
| **Remote Updates** | No (local only) | Yes (update without restart) |
| **Player Targeting** | No | Yes (per-player configs) |
| **Use Cases** | Local game config, flexible sources | A/B testing, remote config, feature flags |
| **Update Speed** | Immediate (local) | Network dependent |

**Use BetterConfig when:**
- You need local configuration storage
- You want flexible config sources (Attributes, Configuration, tables)
- You don't need remote config updates
- Setup simplicity is important

**Use RbxConfig when:**
- You need cloud-based configuration
- You want to update config without restarting servers
- You need player-specific targeting for A/B testing
- You want feature flags controlled remotely

## Migration from v1.x to v2.0

### Breaking Changes

1. **Complete refactor using Strategy Pattern**: The internal implementation was split into three separate strategy classes (ConfigInstance, AttributeConfig, DictionaryConfig)
2. **Method renamed**: `getConfigType()` became `_getConfigType()` (now private/internal)
3. **API now strongly typed**: All methods use Luau generics with `keyof<T>` and `index<T, K>`
4. **New DictionaryConfig support**: v2.0 adds support for plain Lua tables as config sources

### Migration Steps

1. **Update Wally dependency** to version 2.0.0:
   ```toml
   [dependencies]
   BetterConfig = "zac134/better-config@2.0.0"
   ```

2. **Add type definitions** for autocomplete (optional but recommended):
   ```lua
   type MyConfig = {
       max_players: number,
       show_ui: boolean,
   }
   ```

3. **Update internal API usage** (if you used private methods):
   - `config:getConfigType()` → Not available (use `config.ConfigType` property instead)
   - If you relied on internal implementation details, review the new Strategy Pattern architecture

### Benefits of Upgrading

- Better type inference and autocomplete
- Support for Dictionary configs
- Cleaner internal architecture (easier to extend)
- Better performance (lazy observation in AttributeConfig)

## Dependencies

- **[sleitnick/signal@^2.0](https://github.com/sleitnick/rbx-util/tree/main/modules/signal)** - Signal implementation for reactive change observation

## License

MIT License

---

# BetterConfig (日本語)

Roblox用の統合設定管理ライブラリ。ストラテジーパターンを使用しています。

## 概要

BetterConfigは、Robloxの複数のソースからの設定データを管理するための、単一で一貫したAPIを提供します。設定がValueBase子要素を持つConfigurationインスタンス、インスタンス属性、または純粋なLuaテーブルのいずれから来ても、BetterConfigは違いを抽象化し、完全な型安全性とリアクティブな変更監視を備えた同じ直感的なインターフェースを提供します。

**問題**: Robloxの異なる設定ソースは異なるAPI(Configuration→ValueBase、Instance→Attributes、プレーンテーブル)を持っており、コードが一貫性を欠き、保守が困難になります。

**解決策**: BetterConfigはソースタイプを自動的に検出し、適切な実装を返すことで、型安全な自動補完を備えた統一されたインターフェースを提供します。

## 機能

- **3つの設定ソースストラテジー**と自動検出
- **型安全なAPI**: Luauジェネリクスと`keyof<T>`による自動補完
- **リアクティブな値変更監視**: Signalサポート
- **ゼロボイラープレート**: ファクトリーパターン
- **リソース管理**: `Destroy()`メソッド

## インストール

### Wally経由

```toml
[dependencies]
BetterConfig = "zac134/better-config@2.0.0"
```

### 手動インストール

`Modules/BetterConfig/`ディレクトリをプロジェクトのReplicatedStorageまたはServerStorageにコピーしてください。

## クイックスタート

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BetterConfig = require(ReplicatedStorage.Modules.BetterConfig)

-- ファクトリーが設定ソースタイプを自動検出
local config = BetterConfig.new(workspace.GameConfig)

-- 値を取得
local value = config:Get("max_players")

-- 値を設定
config:Set("max_players", 10)

-- 変更を監視
config:GetValueChangedSignal("max_players"):Connect(function(newValue)
    print("max_playersが変更されました:", newValue)
end)
```

## 設定ソース

### 1. インスタンス属性

既存のインスタンスにシンプルなキーバリュー設定が必要な場合は、属性を使用します。

```lua
local part = workspace.ConfigPart
part:SetAttribute("max_items", 10)
part:SetAttribute("show_ui", true)

local config = BetterConfig.fromAttribute(part)
local maxItems = config:Get("max_items")
config:Set("show_ui", false)
```

**利点:**
- Roblox属性がサポートする柔軟な型
- Studioのプロパティパネルで簡単に検査・変更可能
- 軽量(子インスタンス不要)

### 2. Configuration/ValueBase

特定のValueBaseタイプが必要な場合、またはStudioでのビジュアル編集が必要な場合は、Configurationインスタンスを使用します。

```lua
local configInstance = workspace.GameConfig  -- ValueBase子要素を持つConfigurationインスタンス
local config = BetterConfig.fromConfiguration(configInstance)

local maxPlayers = config:Get("max_players")  -- IntValue子要素から読み取り
config:Set("max_players", 8)  -- IntValue.Valueを更新
```

**利点:**
- 型固有のValueBase子要素(IntValue、StringValue、BoolValueなど)
- Studioエクスプローラーでのビジュアル階層
- ValueBaseプロパティへの直接アクセス

**サポートされているValueBaseタイプ:** `ObjectValue`、`IntValue`、`BoolValue`、`StringValue`、`NumberValue`、`Color3Value`、`CFrameValue`、`Vector3Value`、`BrickColorValue`、`RayValue`

### 3. Dictionary/Table

ランタイム設定生成、テスト、またはプログラマティック設定が必要な場合は、Dictionary設定を使用します。

```lua
local config = BetterConfig.fromDict({
    round_time = 120,
    team_size = 4,
    map_name = "Grasslands",
})

local roundTime = config:Get("round_time")
config:Set("round_time", 180)
```

**利点:**
- インスタンス不要、純粋なLua
- テストやランタイム設定に最適
- 自動型マッピング(string→StringValue、number→NumberValueなど)
- 適切なValueBase子要素を持つ内部Configurationインスタンスを作成

## ファクトリー vs 明示的メソッド

### 自動検出(推奨)

```lua
local config1 = BetterConfig.new(workspace.GameConfig)  -- Configuration検出
local config2 = BetterConfig.new(workspace.Part)         -- Attribute検出
local config3 = BetterConfig.new({key = "value"})        -- Dictionary検出
```

自動ソース検出が必要な場合は`BetterConfig.new()`を使用してください。

### 明示的メソッド

```lua
local config1 = BetterConfig.fromAttribute(instance)      -- 明示的なAttribute設定
local config2 = BetterConfig.fromConfiguration(config)    -- 明示的なConfiguration設定
local config3 = BetterConfig.fromDict(table)               -- 明示的なDictionary設定
```

明示的メソッドを使用する場合:
- 設定タイプについて明示的にしたい
- より良い型推論が必要
- ライブラリを構築していて明確な契約が必要

## 型安全な自動補完

自動補完サポートのために、設定の形状を型として定義します:

```lua
type MyConfig = {
    show_ui: boolean,
    max_items: number,
    welcome_message: string,
}

-- 型ヒントにより、すべてのメソッドで自動補完が有効化
local config = BetterConfig.fromAttribute(configPart)

-- 自動補完付きで取得 - 有効なキーが自動的に提案される
local showUi = config:Get("show_ui")        -- ✓ 自動補完が機能
local maxItems = config:Get("max_items")    -- ✓ 自動補完が機能
-- config:Get("invalid_key")                -- ✗ strictモード有効時は型エラー
```

型定義により、`Get`、`Set`、`GetValueChangedSignal`を呼び出す際に、IDE/エディタが有効なキーを提案できるようになります。

## 値変更の監視

`GetValueChangedSignal`は、値が変更されたときに発火する[Signal](https://github.com/sleitnick/rbx-util/tree/main/modules/signal)を返します:

```lua
local signal = config:GetValueChangedSignal("max_items")

-- 変更を監視するために接続
signal:Connect(function(newValue)
    print("max_itemsが変更されました:", newValue)
end)

-- 一度発火して切断
signal:Once(function(newValue)
    print("最初の変更が検出されました:", newValue)
end)

-- 次の変更を待機
task.spawn(function()
    local newValue = signal:Wait()
    print("新しい値を取得しました:", newValue)
end)
```

### Signalが発火するタイミング

- **AttributeConfig**: `Instance:SetAttribute()`が呼び出されるか、Studioで属性が変更されたとき
- **ConfigInstance**: ValueBase子要素の`.Value`プロパティが変更されたとき
- **DictionaryConfig**: 設定で`Set()`が呼び出されたとき

## リソースのクリーンアップ

設定の使用が終了したら、接続とシグナルをクリーンアップするために必ず`Destroy()`を呼び出してください:

```lua
local config = BetterConfig.new(workspace.GameConfig)

-- 設定を使用...
config:GetValueChangedSignal("max_items"):Connect(handler)

-- 終了時にクリーンアップ(重要!)
config:Destroy()
```

**重要な理由:** `GetValueChangedSignal`は`RBXScriptConnection`オブジェクトとSignalインスタンスを作成します。`Destroy()`を呼び出すと、すべての接続が切断され、すべてのシグナルが破棄され、メモリリークを防ぎます。

**Destroy()を呼び出すタイミング:**
- 設定が不要になったとき
- ソースインスタンスを削除する前
- クリーンアップ関数内(例: `Maid:DoCleaning()`)

## APIリファレンス

### ファクトリーメソッド

#### `BetterConfig.new<T>(src: ConfigSrc): BaseConfigClass<T>`
設定ソースタイプを自動検出し、適切な実装を返します。

**パラメータ:**
- `src`: Configurationインスタンス、Instance(属性を使用)、またはLuaテーブル

**戻り値:** `Get`、`Set`、`GetValueChangedSignal`、`Destroy`メソッドを持つ設定オブジェクト

---

#### `BetterConfig.fromAttribute<T>(src: Instance): AttributeConfig<T>`
明示的に属性ベースの設定を作成します。

**パラメータ:**
- `src`: 属性を持つ任意のインスタンス

**戻り値:** AttributeConfig実装

---

#### `BetterConfig.fromConfiguration<T>(src: Configuration): ConfigInstance<T>`
明示的にConfiguration/ValueBaseベースの設定を作成します。

**パラメータ:**
- `src`: ValueBase子要素を持つConfigurationインスタンス

**戻り値:** ConfigInstance実装

---

#### `BetterConfig.fromDict<T>(src: {[string]: any}): DictionaryConfig<T>`
明示的にDictionaryベースの設定を作成します。内部的に適切なValueBase子要素を持つConfigurationインスタンスを作成します。

**パラメータ:**
- `src`: 文字列キーと数値/文字列/真偽値を持つLuaテーブル

**戻り値:** DictionaryConfig実装

---

### インスタンスメソッド

すべての設定実装は同じインターフェースを公開します:

#### `Get<T>(key: keyof<T>): index<T, keyof<T>>`
指定されたキーの現在の値を取得します。

**パラメータ:**
- `key`: 設定キー(型ヒント付きで自動補完有効)

**戻り値:** 現在の値

---

#### `Set<T>(key: keyof<T>, value: index<T, keyof<T>>): ()`
指定されたキーの新しい値を設定します。

**パラメータ:**
- `key`: 設定キー(型ヒント付きで自動補完有効)
- `value`: 設定する新しい値

---

#### `GetValueChangedSignal<T>(key: keyof<T>): Signal<index<T, keyof<T>>>`
指定されたキーの値が変更されたときに発火するSignalを返します。

**パラメータ:**
- `key`: 設定キー(型ヒント付きで自動補完有効)

**戻り値:** `Connect`、`Once`、`Wait`メソッドを持つSignalオブジェクト

---

#### `Destroy(): ()`
すべての接続とシグナルをクリーンアップします。設定の使用が終了したら呼び出してください。

---

### 型

```lua
export type BaseConfigClass<T = { [string]: any }> = {
    ConfigSrc: ConfigSrc,
    ConfigType: ConfigSrcType,

    Get: (self: BaseConfigClass<T>, key: keyof<T>) -> index<T, keyof<T>>,
    Set: (self: BaseConfigClass<T>, key: keyof<T>, value: index<T, keyof<T>>) -> (),
    GetValueChangedSignal: (self: BaseConfigClass<T>, key: keyof<T>) -> Signal,
    Destroy: (self: BaseConfigClass<T>) -> (),
}

export type ConfigSrc = Configuration | Instance | { [string]: any }
export type ConfigSrcType = "Configuration" | "Attribute" | "Dict"
```

## 例

完全な例は以下で利用可能です:
- [`/Examples/client/BetterConfig.client.luau`](../../Examples/client/BetterConfig.client.luau) - 属性とDictionary設定の包括的な例

### 例1: 変更監視付き属性設定

```lua
local BetterConfig = require(ReplicatedStorage.Modules.BetterConfig)

-- 属性を持つパーツを作成
local configPart = Instance.new("Part")
configPart:SetAttribute("show_ui", true)
configPart:SetAttribute("max_items", 10)

-- 設定を作成
local config = BetterConfig.fromAttribute(configPart)

-- 値を取得
print(config:Get("show_ui"))      -- true
print(config:Get("max_items"))    -- 10

-- 変更を監視
config:GetValueChangedSignal("max_items"):Connect(function(newValue)
    print("max_itemsが変更されました:", newValue)
end)

-- 値を更新(シグナルが発火)
config:Set("max_items", 20)  -- 出力: "max_itemsが変更されました: 20"
```

### 例2: Dictionary設定

```lua
local BetterConfig = require(ReplicatedStorage.Modules.BetterConfig)

-- テーブルから設定を作成
local config = BetterConfig.fromDict({
    round_time = 120,
    team_size = 4,
    map_name = "Grasslands",
})

-- 他の設定と同様に使用
print(config:Get("round_time"))  -- 120

-- 監視と更新
config:GetValueChangedSignal("round_time"):Connect(function(newValue)
    print("ラウンド時間が変更されました:", newValue)
end)

config:Set("round_time", 180)  -- 出力: "ラウンド時間が変更されました: 180"
```

## RbxConfigとの比較

| 機能 | BetterConfig | RbxConfig |
|------|--------------|-----------|
| **設定ソース** | ローカル(Configuration/Attributes/Tables) | クラウド(Roblox ConfigService) |
| **セットアップの複雑さ** | シンプル(外部セットアップ不要) | Creator DashboardでのConfigServiceセットアップが必要 |
| **サーバー必須** | いいえ | はい |
| **リモート更新** | いいえ(ローカルのみ) | はい(再起動なしで更新) |
| **プレイヤーターゲティング** | いいえ | はい(プレイヤー別設定) |
| **ユースケース** | ローカルゲーム設定、柔軟なソース | A/Bテスト、リモート設定、機能フラグ |
| **更新速度** | 即座(ローカル) | ネットワーク依存 |

**BetterConfigを使用する場合:**
- ローカル設定ストレージが必要
- 柔軟な設定ソース(Attributes、Configuration、tables)が必要
- リモート設定更新が不要
- セットアップのシンプルさが重要

**RbxConfigを使用する場合:**
- クラウドベースの設定が必要
- サーバー再起動なしで設定を更新したい
- A/Bテストのためのプレイヤー固有のターゲティングが必要
- リモートで制御される機能フラグが必要

## v1.xからv2.0への移行

### 破壊的変更

1. **ストラテジーパターンを使用した完全なリファクタリング**: 内部実装が3つの個別のストラテジークラス(ConfigInstance、AttributeConfig、DictionaryConfig)に分割されました
2. **メソッド名変更**: `getConfigType()`が`_getConfigType()`に(現在はプライベート/内部)
3. **APIが強く型付けされました**: すべてのメソッドが`keyof<T>`と`index<T, K>`を使用したLuauジェネリクスを使用
4. **新しいDictionaryConfigサポート**: v2.0では、設定ソースとして純粋なLuaテーブルのサポートが追加されました

### 移行手順

1. **Wally依存関係をバージョン2.0.0に更新**:
   ```toml
   [dependencies]
   BetterConfig = "zac134/better-config@2.0.0"
   ```

2. **自動補完のための型定義を追加**(オプションですが推奨):
   ```lua
   type MyConfig = {
       max_players: number,
       show_ui: boolean,
   }
   ```

3. **内部API使用を更新**(プライベートメソッドを使用していた場合):
   - `config:getConfigType()` → 利用不可(代わりに`config.ConfigType`プロパティを使用)
   - 内部実装の詳細に依存していた場合は、新しいストラテジーパターンアーキテクチャを確認してください

### アップグレードの利点

- より良い型推論と自動補完
- Dictionary設定のサポート
- よりクリーンな内部アーキテクチャ(拡張が容易)
- より良いパフォーマンス(AttributeConfigでの遅延監視)

## 依存関係

- **[sleitnick/signal@^2.0](https://github.com/sleitnick/rbx-util/tree/main/modules/signal)** - リアクティブな変更監視のためのSignal実装

## ライセンス

MIT License
