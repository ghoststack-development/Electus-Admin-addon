RegisterNetEvent('electus:spawnCar', function(modelName, keepCurrentVehicle, plate)

    local function notify(msg, type)
        lib.notify({
            title = "Vehicle",
            description = msg,
            type = type,
            duration = 5000
        })
    end

    local modelHash = joaat(modelName)

    if not IsModelInCdimage(modelHash) or not IsModelAVehicle(modelHash) then
        notify("Invalid vehicle model.", "error")
        return
    end

    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)

    if not keepCurrentVehicle then
        local currentVehicle = GetVehiclePedIsIn(ped, false)
        if currentVehicle ~= 0 then
            DeleteEntity(currentVehicle)
        end
    end

    RequestModel(modelHash)
    while not HasModelLoaded(modelHash) do
        Wait(10)
    end

    local vehicle = CreateVehicle(modelHash, coords.x, coords.y, coords.z, heading, true, true)

    if not vehicle or vehicle == 0 then
        notify("Vehicle spawn failed.", "error")
        return
    end

    SetPedIntoVehicle(ped, vehicle, -1)

    local netId = NetworkGetNetworkIdFromEntity(vehicle)

    SetNetworkIdExistsOnAllMachines(netId, true)
    SetNetworkIdCanMigrate(netId, true)

    SetModelAsNoLongerNeeded(modelHash)

    notify("Vehicle spawned: "..modelName, "success")

    TriggerServerEvent('electus:carSpawned', modelName, netId, coords)
end)