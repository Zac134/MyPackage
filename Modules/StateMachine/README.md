# StateMachine Module / ステートマシンモジュール

## English

### Overview

A lightweight state machine implementation for Roblox that provides state management with Start/End lifecycle methods and Action handlers. Each state can have its own behaviors that are automatically managed during state transitions.

### Features

-   State lifecycle management (Start/End methods)
-   Action handlers for state-specific behavior
-   Event-driven state change notifications
-   Thread-safe state transitions
-   Automatic cleanup on destroy
-   Dynamic state addition

### Basic Usage

```lua
local StateMachine = require(script.StateMachine)

-- Create a state machine with initial states
local stateMachine = StateMachine.new({
    "Idle",
    "Walking",
    "Running"
}, "Idle", function()
    -- Optional initial actions
    print("StateMachine initialized")
end)

-- Get a state and add actions to it
local idleState = stateMachine:GetStateClass("Idle")
idleState:AddActions({
    Start = function()
        print("Entering Idle state")
    end,
    End = function()
        print("Leaving Idle state")
    end,
    Action = function()
        -- Main behavior for this state
        print("Idling...")
    end
})

-- Listen for state changes
stateMachine.OnChange:Connect(function(oldState, newState)
    print("State changed from", oldState, "to", newState)
end)

-- Change state
stateMachine:ChangeState("Walking")

-- Add a new state dynamically
local jumpingState = stateMachine:AddState("Jumping")
jumpingState:AddActions({
    Start = function()
        print("Jump started!")
    end,
    End = function()
        print("Jump ended!")
    end
})

-- Clean up when done
stateMachine:Destroy()
```

### API Reference

#### `StateMachine.new(stateList: {string}, initialState: string, initialActions?: () -> ())`

Creates a new state machine instance.

-   `stateList`: Array of state names to initialize
-   `initialState`: The starting state
-   `initialActions`: Optional function to run on initialization

#### `stateMachine:ChangeState(nextState: string)`

Transitions to a new state. This will:

1. Call the `End` method of the current state
2. Fire the `OnChange` event
3. Update the current state
4. Call the `Start` method of the new state

Returns the State object if successful, nil if the state doesn't exist or is already active.

#### `stateMachine:AddState(state: string)`

Dynamically adds a new state to the state machine.
Returns the newly created State object, or nil if the state already exists.

#### `stateMachine:GetStateClass(state: string)`

Returns the State object for the given state name.

#### `stateMachine:GetCurrentState()`

Returns the name of the current active state.

#### `stateMachine.OnChange`

Signal that fires when the state changes.
Callback signature: `(oldState: string, newState: string)`

#### `stateMachine:Destroy()`

Cleans up the state machine, cancelling all running threads and destroying events. Also calls the `Destroying` callback if set.

#### `stateMachine.Destroying`

A callback function that is invoked before the state machine is destroyed. Can be set to perform custom cleanup.

### Internal Implementation Details

- State Start/End methods are executed in separate threads using `task.spawn` for non-blocking execution
- Each state's thread is tracked and properly cancelled on state change or destruction
- The state machine prevents transitions to non-existent states or the current state

### State Class API

#### `state:AddActions(actions: {Action?: () -> (), Start?: () -> (), End?: () -> ()})`

Sets the behavior functions for a state:

-   `Action`: Main behavior function for the state
-   `Start`: Called when entering this state
-   `End`: Called when leaving this state

### Type Definitions

```lua
export type StateMachine = {
    States: { State.StateType? },
    currentState: string?,
    ChangeState: (StateMachine, string) -> State.StateType,
    AddState: (StateMachine, string) -> State.StateType,
    GetStateClass: (StateMachine, string) -> State.StateType,
    GetCurrentState: (StateMachine) -> string,
    threads: { thread? },
    Destroying: () -> (),
    Destroy: (StateMachine) -> (),
    OnChange: Signal.Signal<string, string>,
}

export type StateType = {
    Action: (() -> ())?,
    Start: (() -> ())?,
    End: (() -> ())?,
    AddActions: (StateType, any) -> (),
}
```

---

## 日本語

### 概要

Roblox のための Start/End ライフサイクルメソッドとアクションハンドラーを提供する軽量なステートマシン実装です。各状態は、状態遷移時に自動的に管理される独自の動作を持つことができます。

### 機能

-   状態のライフサイクル管理（Start/End メソッド）
-   状態固有の動作のためのアクションハンドラー
-   イベント駆動の状態変更通知
-   スレッドセーフな状態遷移
-   破棄時の自動クリーンアップ
-   動的な状態の追加

### 基本的な使い方

```lua
local StateMachine = require(script.StateMachine)

-- 初期状態を持つステートマシンを作成
local stateMachine = StateMachine.new({
    "Idle",
    "Walking",
    "Running"
}, "Idle", function()
    -- オプションの初期アクション
    print("ステートマシンが初期化されました")
end)

-- 状態を取得してアクションを追加
local idleState = stateMachine:GetStateClass("Idle")
idleState:AddActions({
    Start = function()
        print("アイドル状態に入ります")
    end,
    End = function()
        print("アイドル状態から出ます")
    end,
    Action = function()
        -- この状態のメイン動作
        print("待機中...")
    end
})

-- 状態変更をリッスン
stateMachine.OnChange:Connect(function(oldState, newState)
    print("状態が", oldState, "から", newState, "に変更されました")
end)

-- 状態を変更
stateMachine:ChangeState("Walking")

-- 新しい状態を動的に追加
local jumpingState = stateMachine:AddState("Jumping")
jumpingState:AddActions({
    Start = function()
        print("ジャンプ開始！")
    end,
    End = function()
        print("ジャンプ終了！")
    end
})

-- 完了したらクリーンアップ
stateMachine:Destroy()
```

### API リファレンス

#### `StateMachine.new(stateList: {string}, initialState: string, initialActions?: () -> ())`

新しいステートマシンインスタンスを作成します。

-   `stateList`: 初期化する状態名の配列
-   `initialState`: 開始状態
-   `initialActions`: 初期化時に実行するオプションの関数

#### `stateMachine:ChangeState(nextState: string)`

新しい状態に遷移します。これは以下を行います：

1. 現在の状態の`End`メソッドを呼び出す
2. `OnChange`イベントを発火する
3. 現在の状態を更新する
4. 新しい状態の`Start`メソッドを呼び出す

成功した場合は State オブジェクトを返し、状態が存在しないか既にアクティブな場合は nil を返します。

#### `stateMachine:AddState(state: string)`

ステートマシンに新しい状態を動的に追加します。
新しく作成された State オブジェクトを返し、状態が既に存在する場合は nil を返します。

#### `stateMachine:GetStateClass(state: string)`

指定された状態名の State オブジェクトを返します。

#### `stateMachine:GetCurrentState()`

現在アクティブな状態の名前を返します。

#### `stateMachine.OnChange`

状態が変更されたときに発火する Signal。
コールバックシグネチャ：`(oldState: string, newState: string)`

#### `stateMachine:Destroy()`

ステートマシンをクリーンアップし、実行中のすべてのスレッドをキャンセルし、イベントを破棄します。また、設定されている場合は`Destroying`コールバックを呼び出します。

#### `stateMachine.Destroying`

ステートマシンが破棄される前に呼び出されるコールバック関数。カスタムクリーンアップを実行するために設定できます。

### 内部実装の詳細

- State の Start/End メソッドは、ノンブロッキング実行のために `task.spawn` を使用して別スレッドで実行されます
- 各状態のスレッドは追跡され、状態変更または破棄時に適切にキャンセルされます
- ステートマシンは存在しない状態や現在の状態への遷移を防ぎます

### State クラス API

#### `state:AddActions(actions: {Action?: () -> (), Start?: () -> (), End?: () -> ()})`

状態の動作関数を設定します：

-   `Action`: 状態のメイン動作関数
-   `Start`: この状態に入るときに呼ばれる
-   `End`: この状態から出るときに呼ばれる

### 型定義

```lua
export type StateMachine = {
    States: { State.StateType? },
    currentState: string?,
    ChangeState: (StateMachine, string) -> State.StateType,
    AddState: (StateMachine, string) -> State.StateType,
    GetStateClass: (StateMachine, string) -> State.StateType,
    GetCurrentState: (StateMachine) -> string,
    threads: { thread? },
    Destroying: () -> (),
    Destroy: (StateMachine) -> (),
    OnChange: Signal.Signal<string, string>,
}

export type StateType = {
    Action: (() -> ())?,
    Start: (() -> ())?,
    End: (() -> ())?,
    AddActions: (StateType, any) -> (),
}
```

---

## License / ライセンス

MIT License

## Contributing / 貢献

Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.

プルリクエストを歓迎します。大きな変更については、まず issue を開いて変更内容について議論してください。
