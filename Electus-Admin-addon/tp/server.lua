lib.addCommand('tp', {
    help = locale('command.tp.help'),
    params = {
        { name = locale('command.tp.params.x.name'), help = locale('command.tp.params.x.help'), optional = false },
        { name = locale('command.tp.params.y.name'), help = locale('command.tp.params.y.help'), optional = true },
        { name = locale('command.tp.params.z.name'), help = locale('command.tp.params.z.help'), optional = true }
    }
}, function(source, args)

    -- Fetch the webhook URL for the TP command from apikeys.lua
    local WEBHOOK = ApiKeys.Webhooks.tp

    -- Helper function to notify players
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
    -- PERMISSION CHECK (CONFIG BASED)
    -- ==============================
    local hasPerm, role = HasCommandPermission(source, "tp")

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
    -- TELEPORT TO PLAYER OR COORDINATES
    -- ==============================
    local xArg = args[locale('command.tp.params.x.name')]
    local yArg = args[locale('command.tp.params.y.name')]
    local zArg = args[locale('command.tp.params.z.name')]

    local tpType = "Unknown"
    local targetInfo = "N/A"
    local toCoords = nil

    if xArg and not yArg and not zArg then
        -- Teleport to player by ID
        local targetId = tonumber(xArg)
        if not targetId then
            notify(source, "Invalid player ID.", "error")
            return
        end

        local targetPed = GetPlayerPed(targetId)
        if not targetPed or targetPed == 0 then
            notify(source, "Player not online.", "error")
            return
        end

        local coords = GetEntityCoords(targetPed)
        TriggerClientEvent('QBCore:Command:TeleportToPlayer', source, coords)

        notify(source, "Teleported to ID "..targetId, "success")

        tpType = "Player Teleport"
        targetInfo = "ID: "..targetId
        toCoords = coords

    elseif xArg and yArg and zArg then
        -- Teleport to coordinates
        local x = tonumber(xArg)
        local y = tonumber(yArg)
        local z = tonumber(zArg)

        if not x or not y or not z then
            notify(source, "Invalid coordinates.", "error")
            return
        end

        TriggerClientEvent('QBCore:Command:TeleportToCoords', source, x + 0.0, y + 0.0, z + 0.0)

        notify(source, "Teleported to "..x..", "..y..", "..z, "success")

        tpType = "Coordinate Teleport"
        toCoords = vector3(x, y, z)
    else
        notify(source, "Missing arguments.", "error")
        return
    end

    -- ==============================
    -- GET ADMIN AND TARGET CHARACTER DATA (Even if teleporting to self)
    -- ==============================
    local targetId = source  -- Target will be the same if teleporting to yourself
    local targetCharInfo = exports.qbx_core:GetPlayer(targetId).PlayerData.charinfo or {}
    local targetName = (targetCharInfo.firstname or "Unknown") .. " " .. (targetCharInfo.lastname or "Unknown")
    local targetCitizenId = exports.qbx_core:GetPlayer(targetId).PlayerData.citizenid or "Unknown"
    local adminCitizenId = exports.qbx_core:GetPlayer(source).PlayerData.citizenid or "Console"

    -- ==============================
    -- LOG TELEPORT
    -- ==============================
    if WEBHOOK and WEBHOOK ~= "" then
        local embed = {
            title = "🛰️ Admin Teleport Log",
            color = 15105570,
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
                    name = "**Target Info**",
                    value =
                        "**Name:** `" .. targetName .. "`\n" ..
                        "**Citizen ID:** `" .. targetCitizenId .. "`\n" ..
                        "**Server ID:** `" .. targetId .. "`"
                },
                {
                    name = "**Teleport Info**",
                    value =
                        "Type: `" .. tpType .. "`\n" ..
                        "From: `" .. math.floor(fromCoords.x) .. ", " .. math.floor(fromCoords.y) .. ", " .. math.floor(fromCoords.z) .. "`\n" ..
                        "To: `" .. (toCoords and math.floor(toCoords.x) .. ", " .. math.floor(toCoords.y) .. ", " .. math.floor(toCoords.z) or "Unknown") .. "`"
                }
            },
            footer = {
                text = "Electus Admin System • " .. os.date("%Y-%m-%d %H:%M:%S")
            }
        }

        PerformHttpRequest(WEBHOOK, function(statusCode)
            print("[TP LOG STATUS]:", statusCode)
        end, 'POST', json.encode({
            username = "Electus Logs",
            embeds = { embed }
        }), {
            ['Content-Type'] = 'application/json'
        })
    else
        print("[TP] Webhook not configured.")
    end
end)