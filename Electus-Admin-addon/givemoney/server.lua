lib.addCommand('god', {
    help = locale('command.god.help'),
    params = {
        { name = locale('command.god.params.location.name'), help = locale('command.god.params.location.help'), type = 'string' }
    }
}, function(source, args)

    -- Fetch the webhook URL for god command actions from apikeys.lua
    local WEBHOOK = ApiKeys.Webhooks.god

    local function notify(player, msg, type)
        if player == 0 then
            print("[GOD]", msg)
            return
        end
        TriggerClientEvent('ox_lib:notify', player, {
            title = "God Command",
            description = msg,
            type = type or "info",
            duration = 5000
        })
    end

    -- Check command permission
    local hasPerm, role = HasCommandPermission(source, "god")
    if not hasPerm then
        notify(source, locale('error.no_permission'), "error")
        return
    end

    -- Get the location name from args
    local locationName = args[locale('command.god.params.location.name')]

    -- Check if the location is valid
    local coords = locations[locationName]
    if not coords then
        notify(source, locale('error.invalid_location', {location = locationName}), "error")
        return
    end

    -- Teleport the player
    local ped = PlayerPedId()
    SetEntityCoords(ped, coords.x, coords.y, coords.z, false, false, false, false)

    -- Optional: flash effect for teleportation
    TriggerEvent("qbox-god:flash")

    -- Auto-revive the player
    TriggerEvent("qbx_medical:client:playerRevived")

    -- Notify the player
    notify(source, string.format(locale('success.teleport'), locationName), "success")

    -- Log the action to the webhook
    if WEBHOOK and WEBHOOK ~= "" then
        local embed = {
            {
                title = "🚀 God Command Teleportation",
                color = 3066993,
                fields = {
                    {
                        name = "👮 Staff",
                        value = "Name: `" .. (source == 0 and "Console" or GetPlayerName(source)) .. "`\n" ..
                                "ID: `" .. source .. "`\n" ..
                                "Role: `" .. (role or "Unknown") .. "`\n" ..
                                "License: `" .. (GetPlayerIdentifiers(source)[1] or "Unknown") .. "`"
                    },
                    {
                        name = "🎯 Target Location",
                        value = "Location: `" .. locationName .. "`\n" ..
                                "Coordinates: `X: " .. coords.x .. " Y: " .. coords.y .. " Z: " .. coords.z .. "`"
                    }
                },
                footer = {
                    text = "Electus Admin System • " .. os.date("%Y-%m-%d %H:%M:%S")
                }
            }
        }

        PerformHttpRequest(WEBHOOK, function() end, 'POST', json.encode({
            username = "Electus Logs",
            embeds = embed
        }), {
            ['Content-Type'] = 'application/json'
        })
    else
        print("[GOD] Webhook not configured.")
    end
end)