local ownsBasic = false 
local ownsAdvanced = false
script.Parent.Close.MouseButton1Down:Connect(function() -- Sets up an even listener for when the menu close button is clicked.
	script.Parent.Visible = false -- Closes the menu.
end)
wait(5)
local response, rate = game.ReplicatedStorage.Events.retreiveMinerData:InvokeServer() -- Gathers the data and rate of the miners.
print(response)
repeat
	wait(2)
until response ~= nil
print(typeof(response))
if typeof(response) == "table" then
	print("YES")
	if response["Basic Miner"]["Owned"] == true then
		script.Parent.BasicMiner.Text = "Basic Miner | Owned" -- Tells the user that they own the miner
		ownsBasic = true
		game.Workspace.GrimCoin["Token Miner"].soundPart.Attachment["Server Room"].Playing = true -- Plays a nice server room sound around the miner.
		script.Parent.Parent.Parent.counter.Frame["Mine Rate"].Text = "Rate: "..rate.."/minute" -- Displays the mine rate on a frame.
		script.Parent.Parent.upgrades.Frame.rate.Text = "Rate: "..rate.."/minute" -- Displays the mine rate on another frame.
	end
	if response["Advanced Miner"]["Owned"] == true then
		script.Parent.AdvancedMiner.Text = "Advanced Miner | Owned" -- Tells the user that they own the miner.
		ownsAdvanced = true
	end
else
	warn("Error getting miner data")
end
game.Workspace.GrimCoin["Miner Seller"].HumanoidRootPart.ProximityPrompt.Triggered:Connect(function() -- Shows the shop UI when they interact with the miner seller.
	script.Parent.Visible = true
end)
script.Parent.BasicMiner.MouseButton1Down:Connect(function() -- Adds an event listener for when the basic miner is clicked to be purchased.
	if game.Players.LocalPlayer.leaderstats.Cash.Value >= 250000 then -- Checks if they have enough money. - This is also done on the server of course.
		game.ReplicatedStorage.Events.purchaseMiner:FireServer("Basic Miner") -- Tells the server they want to purchase a Basic Miner.
		script.Parent.BasicMiner.Text = "Basic Miner | Owned" -- Sets the miner on the UI to owned.
	end
end)
game.ReplicatedStorage.Events.minerRateUpdate.OnClientEvent:Connect(function(rate) -- HOoks up an event listener for when their mine rate is update.
	script.Parent.Parent.Parent.counter.Frame["Mine Rate"].Text = "Rate: "..rate.."/minute" -- Updates their mine rate on a UI.
	script.Parent.Parent.upgrades.Frame.rate.Text = "Rate: "..rate.."/minute" -- Updates their mine rate on a UI.
end)