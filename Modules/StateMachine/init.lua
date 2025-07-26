local StateMachine = {}
StateMachine.__index = StateMachine

local State = require(script.State)
local Signal = require(script.Parent.signal)

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

function StateMachine:defer(state: string, func: () -> ())
	self.threads[state] = task.spawn(func)
end

function StateMachine.new(stateList: { string }, initialState: string, initialActions: (() -> ())?)
	local self = setmetatable({}, StateMachine)
	self.States = {}
	for _, stateName in pairs(stateList) do
		self.States[stateName] = State.new(stateName)
	end
	self.OnChange = Signal.new()
	self.currentState = initialState
	self.threads = {}
	self.Destroying = function() end
	if initialActions then
		initialActions()
	end
	return self
end

function StateMachine:ChangeState(nextState: string): State.StateType?
	if not self.States[nextState] then
		warn("can not change state to", nextState)
		return
	end
	if self.currentState == nextState then
		return
	end
	if self.currentState then
		self:defer(self.currentState, self.States[self.currentState].End)
	end
	self.OnChange:Fire(self.currentState, nextState)
	self.currentState = nextState
	self:defer(nextState, self.States[nextState].Start)
	return self.States[nextState]
end

function StateMachine:AddState(state: string): State.StateType?
	if self.States[state] then
		warn("already added", state)
		return
	end
	self.States[state] = State.new(state)
	return self.States[state]
end

function StateMachine:GetStateClass(state: string): State.StateType?
	return self.States[state]
end

function StateMachine:GetCurrentState()
	return self.currentState
end

function StateMachine:Destroy()
	self.Destroying()
	for index, thread: thread in self.threads do
		if coroutine.status(thread) ~= "dead" then
			task.cancel(thread)
		end
		self.threads[index] = nil
	end
	self.OnChange:Destroy()
	table.clear(self)
end

return StateMachine
