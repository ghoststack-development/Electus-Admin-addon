-- server.lua

lib.addCommand('tpm', {
    help = locale('command.tpm.help')
}, function(source, args)

    -- Fetch the webhook for the TPM command from the config file
    local WEBHOOK = ApiKeys.Webhooks.tpm

    local function notify(player, msg, type)
        TriggerClientEvent('ox_lib:notify', player, {
            title = "Teleport",
            description = msg,
            type = type,
            duration = 5000
        })
    end

    -- ==============================
    -- GET LICENSE
    -- ==============================
    local license, pureLicense
    for _, id in pairs(GetPlayerIdentifiers(source)) do
        if id:find("license:") then
            license = id
            pureLicense = id:gsub("license:", "")
            break
        end
    end

    if not license then
        notify(source, "Could not retrieve player license.", "error")
        return
    end

    -- ==============================
    -- PERMISSION CHECK
    -- ==============================
    local hasPerm, role = HasCommandPermission(source, "tpm")

    if not hasPerm then
        notify(source, "You are not authorised to use this command.", "error")
        return
    end

    -- ==============================
    -- FETCH ADMIN CHARACTER DATA
    -- ==============================
    local adminCharInfo = source ~= 0 and exports.qbx_core:GetPlayer(source).PlayerData.charinfo or {}
    local adminName = (adminCharInfo.firstname or "Unknown") .. " " .. (adminCharInfo.lastname or "Unknown")
    local adminCitizenId = source ~= 0 and exports.qbx_core:GetPlayer(source).PlayerData.citizenid or "Console"

    -- ==============================
    -- GET FROM COORDS
    -- ==============================
    local ped = GetPlayerPed(source)
    if not ped then return end

    local fromCoords = GetEntityCoords(ped)

    -- ==============================
    -- EXECUTE TELEPORT
    -- ==============================
    TriggerClientEvent('QBCore:Command:GoToMarker', source)

    notify(source, "Teleported to waypoint.", "success")

    -- ==============================
    -- SUCCESS LOG
    -- ==============================
    if WEBHOOK and WEBHOOK ~= "" then
        local embed = {
            title = "Admin Teleport To Marker",
            color = 3447003,
            fields = {
                {
                    name = "**Admin Info**",
                    value =
                        "**Name:** `" .. adminName .. "`\n" ..
                        "**Citizen ID:** `" .. adminCitizenId .. "`\n" ..
                        "**Player Name:** `" .. GetPlayerName(source) .. "`\n" ..
                        "**Server ID:** `" .. source .. "`"
                },
                {
                    name = "**License**",
                    value = pureLicense,
                    inline = false
                },
                {
                    name = "**Origin Coordinates**",
                    value = string.format("```%.2f, %.2f, %.2f```", fromCoords.x, fromCoords.y, fromCoords.z),
                    inline = false
                }
            },
            footer = {
                text = "Electus Admin System • " .. os.date("%Y-%m-%d %H:%M:%S")
            },
            timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
        }

        PerformHttpRequest(WEBHOOK, function(statusCode)
            print("[TPM LOG STATUS]:", statusCode)
        end, 'POST', json.encode({
            username = "Electus Logs",
            embeds = { embed }
        }), {
            ['Content-Type'] = 'application/json'
        })
    else
        print("[TPM] Webhook not configured.")
    end
end)