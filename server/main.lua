ESX = nil


TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

ESX.RegisterUsableItem('medikit', function(source)
	-- local _source = source
	-- local xPlayer = ESX.GetPlayerFromId(_source)
	-- xPlayer.removeInventoryItem('medikit', 1)

	-- TriggerClientEvent('esx_ambulancejob:heal', _source, 'big')
	-- TriggerClientEvent('esx:showNotification', _source, _U('used_medikit'))
	TriggerClientEvent('lq_items:medkit', source)
end)

ESX.RegisterUsableItem('bandage', function(source)
	-- local _source = source
	-- local xPlayer = ESX.GetPlayerFromId(_source)
	-- xPlayer.removeInventoryItem('bandage', 1)

	-- TriggerClientEvent('esx_ambulancejob:heal', _source, 'small')
	-- TriggerClientEvent('esx:showNotification', _source, _U('used_bandage'))
	TriggerClientEvent('lq_items:bandage', source)
end)


-- Lockpick (Usable)
-- Advanced Lockpick (Usable)
-- Toolbox (Usable)
-- Advanced toolbox (Usable)
-- Pneu (Usable)
-- Licenças (Usable)
-- Licenças falsas (Usable)
-- Rolex
-- Joias
-- Cordao

ESX.RegisterUsableItem('license_weapon', function(source)
	--
end)

ESX.RegisterUsableItem('license_weapon_fake', function(source)
	--
end)

ESX.RegisterUsableItem('license_driver', function(source)
	--
end)

ESX.RegisterUsableItem('license_driver_fake', function(source)
	--
end)


ESX.RegisterUsableItem('advanced_toolbox', function(source)
	TriggerClientEvent('lq_items:advTool', source)
end)

ESX.RegisterUsableItem('toolbox', function(source)
	TriggerClientEvent('lq_items:tool', source)
end)

ESX.RegisterUsableItem('advanced_lockpick', function(source)
	TriggerClientEvent('lq_items:advLockpick', source)
end)

-- local unlockedVehicles = {}
-- RegisterServerEvent('unlockedVehicles')
-- AddEventHandler('unlockedVehicles', function(source, vehicle)
-- 	table.insert(unlockedVehicles, vehicle)
-- end)
ESX.RegisterUsableItem('lockpick', function(source)
	TriggerClientEvent('lq_items:Lockpick', source)
end)

ESX.RegisterUsableItem('tire', function(source)
	TriggerClientEvent('lq_items:Tire', source)
end)


--- Create function to remove item used
RegisterServerEvent("lq_items:Remove")
AddEventHandler("lq_items:Remove", function(item, count)
	if not count then
		count = 1
	end
	local _source = source
	local xPlayer = ESX.GetPlayerFromId(_source)
	xPlayer.removeInventoryItem(item, count)
end)

function Notify(id, text)
	TriggerClientEvent('esx:showNotification', id, text)
end

ESX.RegisterServerCallback('lq_items:checkCount', function(source, cb, itemName, quantity)
	local xPlayer = ESX.GetPlayerFromId(source)
	local item = xPlayer.getInventoryItem(itemName)
	if not quantity then
		quantity = 1
	end
	if(item.count >= quantity) then
		cb(true)
	else
		print('O jogador: ' ..xPlayer.getName().. ' Tentou dropar um '..itemName.. ' enquanto usava. Identifier: ' ..xPlayer.getIdentifier())
		cb(false)
	end
end)


RegisterServerEvent('esx_lowqualityitems_sv:JobBuyItem')
AddEventHandler('esx_lowqualityitems_sv:JobBuyItem', function(itemName, amount, price, itemLabel)
	if not itemLabel then
		itemLabel = itemName
	end
	local _source = source
	local xPlayer = ESX.GetPlayerFromId(_source)
	local sourceItem = xPlayer.getInventoryItem(itemName)

	if amount < 0 then
		print('O jogador '..xPlayer.identifier.. ' tentou exploitar o shop. Item: '..itemName..' quantidade: '..amount)
		return
	end

	if xPlayer.getMoney() >= price then
		-- can the player carry the said amount of x item?
		if sourceItem.limit ~= -1 and (sourceItem.count + amount) > sourceItem.limit then
			TriggerClientEvent('esx:showNotification', _source, "Voce atingiu o limite!")
		else
			xPlayer.removeMoney(price*amount)
			xPlayer.addInventoryItem(itemName, amount)
			TriggerClientEvent('esx:showNotification', _source, string.format('Comprou %s ~r~%s ~w~por ~g~$%s', tonumber(amount), itemLabel, tonumber(price * amount)))
		end
	else
		local missingMoney = price - xPlayer.getMoney()
		TriggerClientEvent('esx:showNotification', _source, string.format('Lhe falta ~r~$%s',ESX.Math.GroupDigits(missingMoney)))
	end
end)