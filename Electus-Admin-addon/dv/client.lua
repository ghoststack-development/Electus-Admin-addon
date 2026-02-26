RegisterNetEvent('electus:forceDeleteVehicle', function(netId)

    local entity = NetworkGetEntityFromNetworkId(netId)

    if entity and DoesEntityExist(entity) then
        SetEntityAsMissionEntity(entity, true, true)
        DeleteEntity(entity)
    end

end)