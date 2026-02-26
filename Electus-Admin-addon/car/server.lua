local WEBHOOK = ApiKeys.Webhooks.Car  -- Fetch the webhook URL for car spawn from apikeys.lua

local function notify(player, msg, type)
    TriggerClientEvent('ox_lib:notify', player, {
        title = "Vehicle",
        description = msg,
        type = type,
        duration = 5000
    })
end

-- ==============================
-- GET ADMIN DATA (FROM config.lua)
-- ==============================
local function GetAdminData(source)
    local license

    for _, id in ipairs(GetPlayerIdentifiers(source)) do
        if id:sub(1,8) == "license:" then
            license = id:gsub("license:", "")
            break
        end
    end

    if not license then return nil end

    -- Query the database for admin role info (using config-based permission system)
    local result = MySQL.single.await(
        "SELECT role FROM electus_admin_staffs WHERE license = ?",
        { license }
    )

    if not result then return nil end

    return {
        role = result.role,
        license = license
    }
end

-- ==============================
-- COMMAND
-- ==============================
lib.addCommand('car', {
    help = 'Spawn a vehicle',
    params = {
        { name = 'model', type = 'string', help = 'Vehicle model name' },
        { name = 'keep', type = 'boolean', help = 'Keep current vehicle', optional = true }
    }
}, function(source, args)

    -- Fetch admin data from the database
    local admin = GetAdminData(source)

    -- Check if the player is an admin
    if not admin then
        notify(source, "You are not staff.", "error")
        LogUnauthorized(source, "Not Staff", args.model)
        return
    end

    -- Fetch permissions from the config (Car permission)
    local hasPerm = false
    if Config.CommandPermissions.Car then
        -- Check if the player's role is in the allowed roles from Config.CommandPermissions.Car
        for _, role in ipairs(Config.CommandPermissions.Car) do
            if admin.role == role then
                hasPerm = true
                break
            end
        end
    else
        notify(source, "Error: No roles configured for car command in config.lua", "error")
        return
    end

    -- Check for required admin role permission
    if not hasPerm then
        notify(source, "No permission.", "error")
        LogUnauthorized(source, "Insufficient Role: "..admin.role, args.model)
        return
    end

    -- Ensure vehicle model is provided
    if not args.model or args.model == "" then
        notify(source, "You must specify a vehicle model.", "error")
        return
    end

    local Player = exports.qbx_core:GetPlayer(source)
    if not Player then return end

    local charName = Player.PlayerData.charinfo.firstname .. Player.PlayerData.charinfo.lastname
    charName = string.upper(string.sub(charName, 1, 8))

    -- Trigger client-side event to spawn the vehicle
    TriggerClientEvent('electus:spawnCar', source, args.model, args.keep, charName)
end)

-- ==============================
-- VEHICLE CALLBACK
-- ==============================
RegisterNetEvent('electus:carSpawned', function(model, netId, coords)
    local source = source

    local admin = GetAdminData(source)

    if not admin then
        LogUnauthorized(source, "Triggered event without permission", model)
        return
    end

    local hasPerm = false
    if Config.CommandPermissions.Car then
        for _, role in ipairs(Config.CommandPermissions.Car) do
            if admin.role == role then
                hasPerm = true
                break
            end
        end
    else
        print("Error: No roles configured for car command in config.lua")
        return
    end

    if not hasPerm then
        LogUnauthorized(source, "Event bypass attempt", model)
        return
    end

    local vehicle
    local attempts = 0

    while attempts < 50 do
        vehicle = NetworkGetEntityFromNetworkId(netId)
        if vehicle and vehicle ~= 0 then break end
        Wait(100)
        attempts = attempts + 1
    end

    if not vehicle or vehicle == 0 then
        print('[Electus] Vehicle entity not found.')
        return
    end

    exports.qbx_vehiclekeys:GiveKeys(source, vehicle)

    local Player = exports.qbx_core:GetPlayer(source)
    if not Player then return end

    local charName = Player.PlayerData.charinfo.firstname .. " " .. Player.PlayerData.charinfo.lastname

    -- Log vehicle spawn to Discord Webhook
    PerformHttpRequest(WEBHOOK, function() end, 'POST', json.encode({
        embeds = { {
            title = "Staff Vehicle Spawned",
            color = 3066993,
            fields = {
                { name = "Character", value = charName, inline = true },
                { name = "License", value = admin.license, inline = true },
                { name = "Vehicle", value = model, inline = true },
                {
                    name = "Coords",
                    value = string.format("X: %.2f Y: %.2f Z: %.2f", coords.x, coords.y, coords.z)
                }
            },
            timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
        }}
    }), {
        ['Content-Type'] = 'application/json'
    })
end)

-- Cleanup on disconnect
AddEventHandler('playerDropped', function()
    failedAttempts[source] = nil
end)