ESX = exports['es_extended']:getSharedObject()
local IsPlayerSammeln = {}

RegisterNetEvent('startProcessingOrFarmItem')
AddEventHandler('startProcessingOrFarmItem', function(selectedItem, bool, receiveItem, requestItem, receiveCount, amount, delay, notify)
    local xPlayer = ESX.GetPlayerFromId(source)

    if bool then
        -- Farming logic
        IsPlayerSammeln[source] = true
        startSammeln(source, receiveItem, requestItem, receiveCount, amount, delay, notify)
    else
        -- Processing logic
        for _, itemInfo in ipairs(Config.ProcessingItems) do
            if selectedItem == itemInfo.itemName then
                local item = xPlayer.getInventoryItem(itemInfo.itemName)
                
                if item and item.count <= 0 then
                    xPlayer.showNotification("Du hast nicht alle erforderlichen Items.")
                    return
                end

                Citizen.Wait(itemInfo.delay)
                xPlayer.removeInventoryItem(itemInfo.itemName, 1)
                Citizen.Wait(itemInfo.delay)
                xPlayer.addInventoryItem(itemInfo.newItem, 1)
                TriggerClientEvent('updateProcessingMenu', source)
                return
            end
        end
    end
end)

function startSammeln(source, receiveItem, requestItem, receiveCount, amount, delay, notify)
    local xPlayer = ESX.GetPlayerFromId(source)
    if IsPlayerSammeln[source] then
        Wait(delay)
        xPlayer.showNotification((notify):format(amount, requestItem, receiveItem, receiveCount))
        xPlayer.addInventoryItem(receiveItem, receiveCount)
        xPlayer.removeInventoryItem(requestItem, amount)
        startSammeln(source, receiveItem, requestItem, receiveCount, amount, delay, notify) -- infinite farm
    end
end
