local State = {}
State.__index = State

export type StateType = {
	Action: (() -> ())?,
	Start: (() -> ())?,
	End: (() -> ())?,
	AddActions: (StateType, any) -> (),
}

function State.new(state: string, actions): StateType
	local self = setmetatable({}, State)
	self.Action = function() end
	self.Start = function() end
	self.End = function() end
	return self
end

function State:AddActions(actions)
	self.Action = actions.Action or function() end
	self.Start = actions.Start or function() end
	self.End = actions.End or function() end
end

return State
