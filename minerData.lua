local dataStoreService = game:GetService("DataStoreService")
local minerDataStore = dataStoreService:GetDataStore("playerdata-miners")
local minerData = {}
local minerThread = {}
local plrRate = {}
local marketPlaceService = game:GetService("MarketplaceService")
local zetaPass = 87439164
local upgradePrices = {
	["GPU"] = 150;
	["Fast"] = 200;
	["Moderate"] = 350;
	["Power Bank"] = 500;
	["GPU OverClock"] = 750;
	["CPU Mining"] = 1100;
	["CPU OverClock"] = 3100;
	["Software Update"] = 10000;

}
game.ReplicatedStorage.Events.upgradeMiner.OnServerEvent:Connect(function(plr, miner)    -- Adds an event listener for the client to request a miner upgrade using a remote event.
	if upgradePrices[miner] ~= nil and plr.plrData.Tokens.Value >= upgradePrices[miner] then -- If the selected miner upgrade does not equal nil and the player has enough money, it continues. -- Tokens is a value created inside of every plrData folder on every player by another script.
		if minerData[plr.UserId]["Basic Miner"]["Upgrades"] == nil or minerData[plr.UserId]["Basic Miner"]["Upgrades"][miner] == nil then -- This checks if they have any upgrades or if they have the specified upgrade.
			plrRate[plr.UserId] += 0.75 -- This adds 0.75 to a saved rate. -- The rate is set so that it works with other miners and other thing in the game.
			plr.plrData.Tokens.Value -= upgradePrices[miner] -- The cost of the upgrade is taken away from the player.
			game.ReplicatedStorage.Events.minerRateUpdate:FireClient(plr, plrRate[plr.UserId])
			-- The code below saves their upgrade in the server memory.
			if minerData[plr.UserId]["Basic Miner"]["Upgrades"] == nil then
				minerData[plr.UserId]["Basic Miner"]["Upgrades"] = {
					[miner] = true;
				}
			else
				minerData[plr.UserId]["Basic Miner"]["Upgrades"][miner] = true
			end
		end
	end
end)

--[[
Miner format:
{
	["Basic Miner"] = {
		["Owned"] = true;
		["Upgrades"] = {
			["Faster Production"] = true
		
		};
	};


};


]]
game.Players.PlayerAdded:Connect(function(plr) -- Called when a player joins.
	local success, data = pcall(function() -- The pcall catches errors if they are to occur with the request.
		return minerDataStore:GetAsync(plr.UserId) -- Gathers the miner data.
	end)
	if success then -- If there are no errors, then continue.
		print("SUCCESS")
		if data ~= nil then -- If there is data, then continue
			minerData[plr.UserId] = data -- Store the data on the servery memory.
			plrRate[plr.UserId] = 1 -- Store the data on the server memory.
			data = data["Basic Miner"] -- Reassign the data value to its child, Basic Miner. Really just an item in the dictionary.
			if data["Upgrades"] ~= nil then -- Checks if there is any upgrade data.
				print(data["Upgrades"])
				for k,v in pairs(data["Upgrades"]) do -- Loops through the upgrades.
					plrRate[plr.UserId] += 1 -- Adds 1 to the mine rate for each upgrade they have.
				end
			end
		else
			minerData[plr.UserId] = { -- Sets up their data is they do not have any.
				["Basic Miner"] = {
					["Owned"] = false;
					
				};
				["Advanced Miner"] = {
					["Owned"] = false;
				};
			};
		end
	else
		warn(data)
	end
	print(minerData[plr.UserId])
	if minerData[plr.UserId]["Basic Miner"] ~= nil then
		if minerData[plr.UserId]["Basic Miner"]["Owned"] == true then
			local thread = coroutine.create(function()
				while true do
					wait(60)
					if plr:FindFirstChild("plrData") then
						plr.plrData.Tokens.Value += plrRate[plr.UserId] -- This checks their data and hooks up a thread to give them tokens every 60 seconds if they are meant to get them. (all of the surrounding code does that)
						print(plrRate[plr.UserId])
					end
				end
			end)
			minerThread[plr.UserId] = thread
			coroutine.resume(thread)
		end
	end
	if marketPlaceService:UserOwnsGamePassAsync(plr.UserId, zetaPass) then -- Checks if they own a certain gamepass that boosts their minerate.
		Instance.new("BoolValue", game.ReplicatedStorage.SharedData.zetaOwners).Name = plr.UserId
		if minerThread[plr.UserId] ~= nil then
			plrRate[plr.UserId] += 25 -- Adds 25 to their rate for owning the gamepass.
		else
			plrRate[plr.UserId] = 25 -- Sets their rate and makes a new thread to give them tokens if need be.
			local thread = coroutine.create(function()
				while true do
					wait(60)
					if plr:FindFirstChild("plrData") then
						plr.plrData.Tokens.Value += plrRate[plr.UserId]
						print(plrRate[plr.UserId])
					end
				end
			end)
			game.ReplicatedStorage.Events.minerRateUpdate:FireClient(plr, plrRate[plr.UserId]) -- Fires an event to the client to update a GUI that tells them their mine rate.
			minerThread[plr.UserId] = thread
			coroutine.resume(thread)
		end
	end
end)
marketPlaceService.PromptGamePassPurchaseFinished:Connect(function(plr, pass, purchased) -- Hooks up an event to check if they have purchased a gamepass. If they have purchased the same gamepass as above, it does the same thing. This event is fried when they purchase the gamepass, not if they have done it.
	if purchased == true and pass == zetaPass then
		Instance.new("BoolValue", game.ReplicatedStorage.SharedData.zetaOwners).Name = plr.UserId
		if minerThread[plr.UserId] ~= nil then
			plrRate[plr.UserId] += 25
		else
			plrRate[plr.UserId] = 25
			local thread = coroutine.create(function()
				while true do
					wait(60)
					if plr:FindFirstChild("plrData") then
						plr.plrData.Tokens.Value += plrRate[plr.UserId]
						print(plrRate[plr.UserId])
					end
				end
			end)
			game.ReplicatedStorage.Events.minerRateUpdate:FireClient(plr, plrRate[plr.UserId])
			minerThread[plr.UserId] = thread
			coroutine.resume(thread)
		end
	end
end)
game.ReplicatedStorage.Events.retreiveMinerData.OnServerInvoke = function(plr) -- This remote function sends the client their mining data that was earlier gathered from the datastore.
	if minerData[plr.UserId] ~= nil then
		return minerData[plr.UserId], plrRate[plr.UserId]
	else
		print("Miner data below:")
		print(minerData[plr.UserId])
		minerData[plr.UserId] = {
			["Basic Miner"] = {
				["Owned"] = false;
				["Upgrades"] = {
					
				};
			};
			["Advanced Miner"] = {
				["Owned"] = false;
			}
		}
		return minerData[plr.UserId]
	end
end
game.ReplicatedStorage.Events.purchaseMiner.OnServerEvent:Connect(function(plr, miner) -- This is fired upon the player clicking a UI button to purchase a miner. The code checks if they have enough money to purchase it and do not already own it.
	if miner == "Basic Miner" then
		if plr.leaderstats.Cash.Value >= 250000 and minerData[plr.UserId]["Basic Miner"]["Owned"] == false then
			plr.leaderstats.Cash.Value -= 250000 -- Removes the cost of the miner from their Cash.
			minerData[plr.UserId]["Basic Miner"]["Owned"] = true -- Stores data stating that it is owned.
			plr.PlayerGui.Minerstore.Frame.BasicMiner.Text = "Basic Miner | Owned" -- Lets the client know that they have purchased it on a UI object.
			local thread = coroutine.create(function() -- Sets up a new thread as they would not yet have one.
				while true do
					wait(60)
					if plr:FindFirstChild("plrData") then
						plr.plrData.Tokens.Value += 1
					end
				end
			end)
			minerThread[plr.UserId] = thread
			coroutine.resume(thread)
		end
	end
end)
game.Players.PlayerRemoving:Connect(function(plr) -- Hooks up an event for when the player leaves.
	if game.ReplicatedStorage.SharedData.carPlantOwner.Value == plr then -- If they own the car plant, set the value to nil so other people can own it.
		game.ReplicatedStorage.SharedData.carPlantOwner.Value = nil
	end
	local success, err = pcall(function() -- Attempt to save their data and yield the coroutine so it stops using resources.
		minerDataStore:SetAsync(plr.UserId, minerData[plr.UserId])
		if minerThread[plr.UserId] ~= nil then
			coroutine.yield(minerThread[plr.UserId])
			minerThread[plr.UserId] = nil
		end
	end)
	if not success then
		print(err)
	end
end)
game.ReplicatedStorage.Events.loadUpgradeClient.OnServerInvoke = function(plr) -- Sends the client data so that it can tell them what upgrades they currently own.
	return minerData[plr.UserId]["Basic Miner"]["Upgrades"]
end
game.ReplicatedStorage.Events.purchaseCarPlant.OnServerInvoke = function(plr) -- Allows the user to purchase the car plant. - A way to gain more tokens.
	if game.ReplicatedStorage.SharedData.carPlantOwner.Value == nil and plr.plrData.Tokens.Value >= 5000 then -- Checks if they have enough tokens to purchase it.
		plr.plrData.Tokens.Value -= 5000 -- Takes the price of the tokens away from them.
		game.ReplicatedStorage.SharedData.carPlantOwner.Value = plr -- Marks the car plant as theirs on all clients and server so nobody else can purchase it.
		game.Workspace.plantUIPromptPart["Pen Write Cu Scribble On Paper 1 (SFX)"]:Play() -- Plays a nice pen sound to those nearby.
		if minerThread[plr.UserId] ~= nil then -- Adds their thread if they do not have one so that they can gain tokens.
			plrRate[plr.UserId] += 50
			game.ReplicatedStorage.Events.minerRateUpdate:FireClient(plr, plrRate[plr.UserId])
			return true
		else
			plrRate[plr.UserId] += 50
			local thread = coroutine.create(function()
				while true do
					wait(60)
					if plr:FindFirstChild("plrData") then
						plr.plrData.Tokens.Value += plrRate[plr.UserId]
						print(plrRate[plr.UserId])
					end
				end
			end)
			minerThread[plr.UserId] = thread
			coroutine.resume(thread)
			return true
		end
	else
		return false
	end
end