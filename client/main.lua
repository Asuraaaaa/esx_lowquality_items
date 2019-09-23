ESX              	= nil
local PlayerData	= {}
local callback		= nil

Citizen.CreateThread(function()
	while ESX == nil do
		TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
		Citizen.Wait(0)
	end
end)

RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(xPlayer)
  PlayerData = xPlayer   
end)

RegisterNetEvent('esx:setJob')
AddEventHandler('esx:setJob', function(job)
  PlayerData.job = job
end)
------------------------------- Tire
RegisterNetEvent('lq_items:Tire')
AddEventHandler('lq_items:Tire', function()
	local ped = GetPlayerPed(-1)
	local veh = ESX.Game.GetClosestVehicle(GetEntityCoords(GetPlayerPed(-1), true))--ESX.Game.GetVehicleInDirection()
	local closestTire = GetClosestVehicleTire(veh)
	if not closestTire then
		Citizen.Trace('Nao está proximo o suficiente de um pneu.')
	elseif IsVehicleTyreBurst(veh, closestTire.tireIndex , false) and not IsPedInVehicle(ped, veh, false)then
		ResetPedMovementClipset( ped, 0 )
		Notify(_U('tire_fixing'))
		-- iniciar progressbar (caso esteja ativa)
		if Config.progressbar then
			TriggerEvent('lq_progressbar:start', Config.timeTire, 'Consertando o veículo...')
		end
		-- iniciar animação
		ResetPedMovementClipset( ped, 0 )
		ESX.Streaming.RequestAnimSet('move_ped_crouched', function()
			SetPedMovementClipset( ped, "move_ped_crouched", 0.25 )
		end)
		ClearPedTasksImmediately(ped)
		local animDict = 'mini@safe_cracking'
		local anime = 'dial_turn_anti_fast'
		SetPedCurrentWeaponVisible(ped, 0, 1, 1, 1)
		ESX.Streaming.RequestAnimDict(animDict, function()
			TaskPlayAnim(PlayerPedId(), animDict, anime, 2.0, -2.0, -1, 63, 0, true, true, true)
		end)
		
		-- esperar o tempo
		Citizen.Wait((Config.timeTire * 1.3) * 1000)
		TriggerEvent('lq_progressbar:cancel')
		-- Se o player ainda tiver perto do carro...
		if GetDistanceBetweenCoords(GetEntityCoords(ped, false), GetEntityCoords(veh, false)) and not IsPedDeadOrDying(ped, true) then
		-- consertar o pneu do veículo.
			if Check('tire', true) then
				SetVehicleTyreFixed(veh, closestTire.tireIndex)
				Notify(_U('tire_fixed'))
				FreezeEntityPosition(ped, true)
				ClearPedTasksImmediately(ped)
				ResetPedMovementClipset( ped, 0 )
				FreezeEntityPosition(ped, false)
			else
				Notify(_U('no_item'))
			end
		else
			Notify(_U('tire_canceled'))
			FreezeEntityPosition(ped, true)
			ClearPedTasksImmediately(ped)
			ResetPedMovementClipset( ped, 0 )
			FreezeEntityPosition(ped, false)
		end
		
	else
		Notify(_U('tire_notBurst'))
		-- este pneu nao esta furado
	end
end)




-- xander1998 https://github.com/xander1998/slashtires/blob/master/client.lua
function GetClosestVehicleTire(vehicle)
	local tireBones = {"wheel_lf", "wheel_rf", "wheel_lm1", "wheel_rm1", "wheel_lm2", "wheel_rm2", "wheel_lm3", "wheel_rm3", "wheel_lr", "wheel_rr"}
	local tireIndex = {
		["wheel_lf"] = 0,
		["wheel_rf"] = 1,
		["wheel_lm1"] = 2,
		["wheel_rm1"] = 3,
		["wheel_lm2"] = 45,
		["wheel_rm2"] = 47,
		["wheel_lm3"] = 46,
		["wheel_rm3"] = 48,
		["wheel_lr"] = 4,
		["wheel_rr"] = 5,
	}
	local player = PlayerId()
	local plyPed = GetPlayerPed(player)
	local plyPos = GetEntityCoords(plyPed, false)
	local minDistance = 1.5
	local closestTire = nil
	
	for a = 1, #tireBones do
		local bonePos = GetWorldPositionOfEntityBone(vehicle, GetEntityBoneIndexByName(vehicle, tireBones[a]))
		local distance = Vdist(plyPos.x, plyPos.y, plyPos.z, bonePos.x, bonePos.y, bonePos.z)

		if closestTire == nil then
			if distance <= minDistance then
				closestTire = {bone = tireBones[a], boneDist = distance, bonePos = bonePos, tireIndex = tireIndex[tireBones[a]]}
			end
		else
			if distance < closestTire.boneDist then
				closestTire = {bone = tireBones[a], boneDist = distance, bonePos = bonePos, tireIndex = tireIndex[tireBones[a]]}
			end
		end
	end
	return closestTire
end



function Notify(text)
	TriggerEvent('esx:showNotification', text)
end



--------------------- Lockpick
RegisterNetEvent('lq_items:Lockpick')
AddEventHandler('lq_items:Lockpick', function()
	lockpick(Config.lockpickTime, Config.lockpickBreakChance, Config.unlockChance, 'lockpick')
end)

function vehicleUnlock(vehicle)
	SetVehicleDoorsLocked(vehicle , true)
	SetVehicleDoorsLockedForAllPlayers(vehicle , false)
	SetVehicleNeedsToBeHotwired(vehicle, true)
end

RegisterNetEvent('lq_items:advLockpick')
AddEventHandler('lq_items:advLockpick', function()
	lockpick(Config.advLockpickTime, Config.advBreakChance, Config.advunlockChance, 'advanced_lockpick')
end)

function lockpick(time, breakChance, unlockChance, itemName)
	local ped = GetPlayerPed(-1)
	local vehicle = ESX.Game.GetClosestVehicle(GetEntityCoords(ped, true))
	local isLocked = GetVehicleDoorLockStatus(vehicle)
	local remove = false
	if(GetDistanceBetweenCoords(GetEntityCoords(ped, true), GetEntityCoords(vehicle, false)) <= 2) then
		if GetVehicleDoorLockStatus(vehicle) == 1 then
			Notify(_U('Vehicle_not_locked'))
			return
		end
		--- start animation of unlocking vehicle
		if (Config.progressbar) then
			--- start progressbar of unlocking vehicle
			TriggerEvent('lq_progressbar:start', time, 'Usando lockpick...')
		end
		Citizen.Wait((time * 1300))
		TriggerEvent('lq_progressbar:cancel')
		if not (GetDistanceBetweenCoords(GetEntityCoords(ped, true), GetEntityCoords(vehicle, false)) <= 2) then
			Notify(_U('Vehicle_not_near'))
			return
		end
		local chance = math.random(0,100)
		if(chance <= unlockChance) then
			chance = Chance()
			if(chance <= breakChance) then
				remove = true
			end
			if(Check(itemName, remove)) then
				vehicleUnlock(vehicle)
				Notify(_U('Lockpick_Success'))
				if(remove) then
					Notify(_U('Lockpick_Broke'))
				end
			else
				Notify(_U('no_item'))
			end

		else
			-- alert?
			chance = Chance()
			if(chance <= breakChance) then
				remove = true
			end
			StartVehicleAlarm(vehicle)
			if(Check(itemName, remove)) then
				Notify(_U('Lockpick_Failed'))
				if(remove) then
					Notify(_U('Lockpick_Broke'))
				end
			else
				Notify(_U('no_item'))
			end
		end
	else
		--- send notification too far from the vehicle
	end

end




--------------- Toolbox 
RegisterNetEvent('lq_items:tool')
AddEventHandler('lq_items:tool', function()
	toolbox(Config.toolTime, Config.toolFixValue, Config.toolBreakChance, 'toolbox')
end)
RegisterNetEvent('lq_items:advTool')
AddEventHandler('lq_items:advTool', function()
	toolbox(Config.advToolTime, Config.advToolFixValue, Config.advToolBreakChance, 'advanced_toolbox')
end)

function toolbox(time, fixValue, breakChance, itemName)
	local ped = GetPlayerPed(-1)
	local vehicle = ESX.Game.GetClosestVehicle(GetEntityCoords(ped, true))
	local engineHealth = GetVehicleEngineHealth(vehicle)
	local remove = false
	if(engineHealth < fixValue) then
		if (Config.progressbar) then
			TriggerEvent('lq_progressbar:start', time, 'Consertando Veículo...')
		end
		-- wait the time
		Citizen.Wait(time * 1200)
		TriggerEvent('lq_progressbar:cancel')
		if not (GetDistanceBetweenCoords(GetEntityCoords(ped, true), GetEntityCoords(vehicle, false)) <= 2) then
			Notify(_U('Vehicle_not_near'))
			return
		end
		if(Chance() <= breakChance) then
			remove = true
			Notify(_U('tool_broke'))
		end
		if (Check(itemName, remove)) then
			SetVehicleEngineHealth(vehicle, fixValue)
			Citizen.Trace(tostring(GetVehicleEngineHealth(vehicle)))
			-- set the car engine to the fixValue 
			Notify(_U('Vehicle_Fixed'))
		else
			Notify(_U('no_item'))
		end
		-- calculate the break chance and cosume the item (itemName)
	else
		Notify(_U('Cant_Fix'))
	end
end


function Chance()
	return math.random(0,100)
end




----- Use it to remove any item
function Check(itemName, remove, quantity)
	if not quantity then
		quantity = 1
	end
	TriggerEvent('inventoryhud_close') -- this prevents players from duping items
	ESX.TriggerServerCallback('lq_items:checkCount', function(cb)
		TriggerEvent('lq_items_callback:set', cb)
	end, itemName, quantity)
	while callback == nil do
		Citizen.Wait(1)
	end
	if (callback) then
		if remove then
			TriggerServerEvent('lq_items:Remove', itemName, quantity)
		end
		callback = nil
		return true
	else
		return false
	end
end


----- Bandage

RegisterNetEvent('lq_items:bandage')
AddEventHandler('lq_items:bandage', function()
	if (Config.progressbar) then
		-- trigger
		TriggerEvent('lq_progressbar:start', Config.bandageTime, _U('Using_Bandage'))
		Citizen.Wait(Config.bandageTime * 1200)
		TriggerEvent('lq_progressbar:cancel')
		-- cancel progressbar
	else
		Citizen.Wait(Config.bandageTime * 1200)
	end
	if (Check('bandage', true, 2)) then
		TriggerEvent('esx_ambulancejob:heal', 'small')
		TriggerEvent('esx_showNotification', _U('used_bandage'))
	else
		Notify(_U('no_item'))
	end
end)




----- Medkit

RegisterNetEvent('lq_items:medkit')
AddEventHandler('lq_items:medkit', function()
	if (Config.progressbar) then
		-- trigger
		TriggerEvent('lq_progressbar:start', Config.medkitTime, _U('Using_Medkit'))
		Citizen.Wait(Config.medkitTime * 1200)
		TriggerEvent('lq_progressbar:cancel')
		-- cancel progressbar
	else
		Citizen.Wait(Config.medkitTime * 1200)
	end
	if (Check('medikit', true, 1)) then
		TriggerEvent('esx_ambulancejob:heal', 'big')
		TriggerEvent('esx_showNotification', _U('used_medikit'))
	else
		Notify(_U('no_item'))
	end
end)

-------
RegisterNetEvent('lq_items_callback:set')
AddEventHandler('lq_items_callback:set', function(value)
	callback = value
end)

