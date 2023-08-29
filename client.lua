local menuLocation = vector3(292.9995, -569.6815, 43.1401)
local maxDistanceFromMenu = 3.0

local processingInProgress = false
local currentSelectedItem = nil

CreateThread(function()
    while true do
        Wait(0)

        local playerCoords = GetEntityCoords(PlayerPedId())

        if Vdist(playerCoords, menuLocation.x, menuLocation.y, menuLocation.z) < 2.0 then
            ESX.ShowHelpNotification("~INPUT_CONTEXT~ Verarbeiten")
            if IsControlJustReleased(0, 54) then
                OpenItemMenu()
            end
        end


        if currentSelectedItem and Vdist(playerCoords, menuLocation.x, menuLocation.y, menuLocation.z) > maxDistanceFromMenu then
            processingInProgress = false
            currentSelectedItem = nil
        end
    end
end)

function OpenItemMenu()
    local elements = {}
    local playerItems = ESX.GetPlayerData().inventory
    
    for _, item in pairs(playerItems) do
        if item.count > 0 and IsItemProcessable(item.name) then
            table.insert(elements, {
                label = item.label .. " (" .. item.count .. "x)",
                value = item.name
            })
        end
    end
    
    ESX.UI.Menu.CloseAll()

    ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'item_menu',
        {
            title    = 'Deine Gegenstände',
            align    = 'right',
            elements = elements
        },
        function(data, menu)
            local selectedItem = data.current.value
            currentSelectedItem = selectedItem
            ProcessSelectedItem(selectedItem)
        end,
        function(data, menu)
            menu.close()
        end
    )
end

function ProcessSelectedItem(itemName)
    if not processingInProgress then
        processingInProgress = true
        local progressBarStatus = false  -- Wird verwendet, um den Fortschrittsbalkenstatus zu überwachen
        Citizen.CreateThread(function()
            while currentSelectedItem == itemName do
                Citizen.Wait(0)
                local playerItems = ESX.GetPlayerData().inventory
                local itemCount = GetItemCount(playerItems, itemName)
                
                if itemCount > 0 then
                    if not progressBarStatus then
                        progressBarStatus = true
                        TriggerEvent("mythic_progbar:client:progress", {
                            name = "processing_item",
                            duration = 1000,  -- Beispiel: 1 Sekunde
                            label = "Verarbeiten...",
                            useWhileDead = false,
                            canCancel = true,
                            controlDisables = {
                                disableMovement = true,
                                disableCarMovement = true,
                                disableMouse = false,
                                disableCombat = true,
                            },
                            animation = {
                                animDict = "anim@heists@ornate_bank@grab_cash_heels",
                                anim = "grab",
                            },
                        }, function(status)
                            if not status then
                                TriggerServerEvent('startProcessing', itemName)
                            end
                            progressBarStatus = false
                        end)
                    end
                else
                    processingInProgress = false
                    currentSelectedItem = nil
                end
                
                -- Überprüfe, ob der Spieler die Abbruchtaste gedrückt hat
                if IsControlJustReleased(0, 73) then
                    processingInProgress = false
                    currentSelectedItem = nil
                    break
                end
            end
        end)
    end
end

function GetItemCount(playerItems, itemName)
    for _, item in pairs(playerItems) do
        if item.name == itemName then
            return item.count
        end
    end
    return 0
end

function IsItemProcessable(itemName)
    for _, processableItem in ipairs(Config.ProcessingItems) do
        if processableItem.itemName == itemName then
            return true
        end
    end
    return false
end
