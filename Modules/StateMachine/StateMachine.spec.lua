return function()
	local StateMachine = require(script.Parent)
	local stateMachine = StateMachine.new({
		"Start",
		"Testing",
		"End",
	}, "Start")
	describe("State correctly changing", function()
		it("initial state set correctly", function()
			expect(stateMachine:GetCurrentState()).be.equal("Start")
		end)

		it("correctly change the state Start to Testing", function()
			stateMachine:ChangeState("Testing")
			expect(stateMachine:GetCurrentState()).be.equal("Testing")
		end)
	end)
end
