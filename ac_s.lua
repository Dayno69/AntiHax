Components = {
	Teleport = true,
	GodMode = true,
	Speedhack = true,
	WeaponBlacklist = true,
	CustomFlag = true,
	Explosions = true,
}

Users = {}
violations = {}


recentExplosions = {}



RegisterServerEvent("AntiHax:timer")
AddEventHandler("AntiHax:timer", function()
	if Users[source] then
		if (os.time() - Users[source]) < 15 and Components.Speedhack then -- prevent the player from doing a good old cheat engine speedhack
			DropPlayer(source, "Speedhacking")
		else
			Users[source] = os.time()
		end
	else
		Users[source] = os.time()
	end
end)

AddEventHandler('playerDropped', function()
	if(Users[source])then
		Users[source] = nil
	end
end)

RegisterServerEvent("AntiHax:kick")
AddEventHandler("AntiHax:kick", function(reason)
	DropPlayer(source, reason)
end)

AddEventHandler("AntiHax:SetComponentStatus", function(component, state)
	if type(component) == "string" and type(state) == "boolean" then
		Components[component] = state -- changes the component to the wished status
	end
end)

AddEventHandler("AntiHax:ToggleComponent", function(component)
	if type(component) == "string" then
		Components[component] = not Components[component]
	end
end)

AddEventHandler("AntiHax:SetAllComponents", function(state)
	if type(state) == "boolean" then
		for i,theComponent in pairs(Components) do
			Components[i] = state
		end
	end
end)

Citizen.CreateThread(function()
	while true do 
		Wait(2000)
		clientExplosionCount = {}
		for i, expl in ipairs(recentExplosions) do 
			if not clientExplosionCount[expl.sender] then clientExplosionCount[expl.sender] = 0 end
			clientExplosionCount[expl.sender] = clientExplosionCount[expl.sender]+1
			table.remove(recentExplosions,i)
		end 
		recentExplosions = {}
		for c, count in pairs(clientExplosionCount) do 
			if count > 20 then
				local license, steam = GetPlayerNeededIdentifiers(c)
				local name = GetPlayerName(c)

				local isKnown, isKnownCount, isKnownExtraText = WarnPlayer(name,"Explosion Spawning", true, c)

				SendWebhookMessage(webhook, "**Explosion Spawner!** \n```\nUser:"..name.."\n"..license.."\n"..steam.."\nSpawned "..count.." Explosions in <2s. \nAntiHax Flags:"..isKnownCount..""..isKnownExtraText.." ```")
			end
		end
	end
end)

Citizen.CreateThread(function()

	function SendWebhookMessage(wh,message)
		webhook = GetConvar("ac_webhook", "none")
		if wh ~= "none" then
			PerformHttpRequest(wh, function(err, text, headers) end, 'POST', json.encode({content = message}), { ['Content-Type'] = 'application/json' })
		end
	end
	
	function WarnPlayer(playername, reason,banInstantly,pid)
		local isKnown = false
		local isKnownCount = 1
		local isKnownExtraText = ""
		for i,thePlayer in ipairs(violations) do
			if thePlayer.name == playername then
				isKnown = true
				if banInstantly then
					TriggerEvent("banCheater", pid or source,"Cheating")
					isKnownCount = violations[i].count
					table.remove(violations,i)
					isKnownExtraText = ", was banned instantly."
				else
					if violations[i].count == 1 then
						TriggerEvent("EasyAdmin:TakeScreenshot", source)
					end
					if violations[i].count == 3 then
						TriggerEvent("banCheater", pid or source,"Cheating")
						isKnownCount = violations[i].count
						table.remove(violations,i)
						isKnownExtraText = ", was banned."
					else
						violations[i].count = violations[i].count+1
						isKnownCount = violations[i].count
					end
				end
			end
		end

		if not isKnown then
			if banInstantly then
				TriggerEvent("banCheater", pid or source,"Cheating")
				isKnownExtraText = ", was banned instantly."
			else
				table.insert(violations, { name = playername, count = 1 })
			end
		end

		return isKnown, isKnownCount,isKnownExtraText
	end

	function GetPlayerNeededIdentifiers(player)
		local ids = GetPlayerIdentifiers(player)
		for i,theIdentifier in ipairs(ids) do
			if string.find(theIdentifier,"license:") or -1 > -1 then
				license = theIdentifier
			elseif string.find(theIdentifier,"steam:") or -1 > -1 then
				steam = theIdentifier
			end
		end
		if not steam then
			steam = "steam: missing"
		end
		return license, steam
	end

	RegisterServerEvent('AntiHax:SpeedFlag')
	AddEventHandler('AntiHax:SpeedFlag', function(rounds, roundm)
		if Components.Speedhack and not IsPlayerAceAllowed(source,"AntiHax.bypass") then
			local license, steam = GetPlayerNeededIdentifiers(source)
			local name = GetPlayerName(source)

			local isKnown, isKnownCount, isKnownExtraText = WarnPlayer(name,"Speed Hacking")

			SendWebhookMessage(webhook, "**Speed Hacker!** \n```\nUser:"..name.."\n"..license.."\n"..steam.."\nWas travelling "..rounds.. " units. That's "..roundm.." more than normal!"..isKnownCount..""..isKnownExtraText.." ```")
		end
	end)



	RegisterServerEvent('AntiHax:NoclipFlag')
	AddEventHandler('AntiHax:NoclipFlag', function(distance)
		if Components.Speedhack and not IsPlayerAceAllowed(source,"AntiHax.bypass") then
			local license, steam = GetPlayerNeededIdentifiers(source)
			local name = GetPlayerName(source)

			local isKnown, isKnownCount, isKnownExtraText = WarnPlayer(name,"Noclip/Teleport Hacking")


			SendWebhookMessage(webhook,"**Noclip/Teleport!** \n```\nUser:"..name.."\n"..license.."\n"..steam.."\nCaught with "..distance.." units between last checked location\nAntiHax Flags:"..isKnownCount..""..isKnownExtraText.." ```")
		end
	end)

	
	
	RegisterServerEvent('AntiHax:CustomFlag')
	AddEventHandler('AntiHax:CustomFlag', function(reason,extrainfo)
		if Components.CustomFlag and not IsPlayerAceAllowed(source,"AntiHax.bypass") then
			local license, steam = GetPlayerNeededIdentifiers(source)
			local name = GetPlayerName(source)
			if not extrainfo then extrainfo = "no extra informations provided" end
			local isKnown, isKnownCount, isKnownExtraText = WarnPlayer(name,reason)


			SendWebhookMessage(webhook,"**"..reason.."** \n```\nUser:"..name.."\n"..license.."\n"..steam.."\n"..extrainfo.."..isKnownCount.")
		end
	end)

	RegisterServerEvent('AntiHax:HealthFlag')
	AddEventHandler('AntiHax:HealthFlag', function(invincible,oldHealth, newHealth, curWait)
		if Components.GodMode and not IsPlayerAceAllowed(source,"AntiHax.bypass") then
			local license, steam = GetPlayerNeededIdentifiers(source)
			local name = GetPlayerName(source)

			local isKnown, isKnownCount, isKnownExtraText = WarnPlayer(name,"Health Hacking")

			if invincible then
				SendWebhookMessage(webhook,"**Health Hack!** \n```\nUser:"..name.."\n"..license.."\n"..steam.."\nRegenerated "..newHealth-oldHealth.."hp ( to reach "..newHealth.."hp ) in "..curWait.."ms! ( PlayerPed was invincible )\nAntiHax Flags:"..isKnownCount..""..isKnownExtraText.." ```")
			else
				SendWebhookMessage(webhook,"**Health Hack!** \n```\nUser:"..name.."\n"..license.."\n"..steam.."\nRegenerated "..newHealth-oldHealth.."hp ( to reach "..newHealth.."hp ) in "..curWait.."ms! ( Health was Forced )\nAntiHax Flags:"..isKnownCount..""..isKnownExtraText.." ```")
			end
		end
	end)

	RegisterServerEvent('AntiHax:WeaponFlag')
	AddEventHandler('AntiHax:WeaponFlag', function(weapon)
		if Components.WeaponBlacklist and not IsPlayerAceAllowed(source,"AntiHax.bypass") then
			local license, steam = GetPlayerNeededIdentifiers(source)
			local name = GetPlayerName(source)

			local isKnown, isKnownCount, isKnownExtraText = WarnPlayer(name,"Inventory Cheating")

			SendWebhookMessage(webhook,"**Inventory Hack!** \n```\nUser:"..name.."\n"..license.."\n"..steam.."\nGot Weapon: "..weapon.."( Blacklisted )\nGodzilla Flags:"..isKnownCount..""..isKnownExtraText.." ```")
			TriggerClientEvent("AntiHax:RemoveInventoryWeapons", source) 
		end
	end)

	AddEventHandler('explosionEvent', function(sender, ev)
		if Components.Explosions and ev.damageScale ~= 0.0 and ev.ownerNetId == 0 then -- make sure component is enabled, damage isnt 0 and owner is the sender
			ev.time = os.time()
			table.insert(recentExplosions, {sender = sender, data=ev})
		end
	end)
end)