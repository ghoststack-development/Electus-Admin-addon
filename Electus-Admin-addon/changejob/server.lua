local QBCore = exports['qb-core']:GetCoreObject()

local DISCORD_WEBHOOK = ApiKeys.Webhooks.god  -- Fetch the webhook URL for god actions from apikeys.lua
local BOT_NAME = "GOD"
local BOT_AVATAR = "image_url_here"  -- Provide your bot avatar URL

local Teleports = {
    hp = vector3(1151.94, -1527.99, 34.93),  -- HP Square
    pd = vector3(431.87, -974.64, 30.71),  -- Police Department
    meh = vector3(-303.70, -1365.47, 31.44), -- Custom Location
    square = vector3(205.05, -919.90, 30.69),  -- Custom Square Location
    island = vector3(3272.60, -148.38, 17.55),  -- Island Location
    pvp = vector3(-1736.93, 5982.33, 209.37),  -- PvP Arena
    np = vector3(1409.83, 6695.19, 14.18), -- North Pier Location
}

-- Function to notify players
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

-- Function to send a log to Discord webhook with a polished embed
local function SendDiscordLog(title, message, color)
    local embed = {
        {
            ["title"] = title,
            ["description"] = message,
            ["color"] = color or 3066993, -- Green color for success
            ["timestamp"] = os.date("!%Y-%m-%dT%H:%M:%SZ"),  -- Timestamp for better tracking
            ["footer"] = {
                ["text"] = "Electus Admin System • " .. os.date("%Y-%m-%d %H:%M:%S")
            },
            ["author"] = {
                ["name"] = BOT_NAME,
                ["icon_url"] = BOT_AVATAR
            },
            ["fields"] = {
                {
                    ["name"] = "📌 **Action Taken**",
                    ["value"] = message,
                    ["inline"] = false
                },
            }
        }
    }

    PerformHttpRequest(DISCORD_WEBHOOK, function(err, text, headers) end, "POST", json.encode({
        username = BOT_NAME,
        avatar_url = BOT_AVATAR,
        embeds = embed
    }), { ["Content-Type"] = "application/json" })
end

-- Permission check for god command (same structure as the one in `changejob`)
local function HasGodPermission(source, commandName)
    if source == 0 then
        return true, "Console"
    end

    local pureLicense
    for _, id in pairs(GetPlayerIdentifiers(source)) do
        if id:find("license:") then
            pureLicense = id:gsub("license:", "")
            break
        end
    end

    if not pureLicense then
        return false
    end

    local result = MySQL.query.await(
        "SELECT role FROM electus_admin_staffs WHERE license = ? LIMIT 1",
        { pureLicense }
    )

    if not result or not result[1] then
        return false
    end

    local userRole = string.lower(result[1].role)
    local allowedRoles = Config.CommandPermissions[commandName]

    if not allowedRoles then
        return false
    end

    for _, role in ipairs(allowedRoles) do
        if string.lower(role) == userRole then
            return true, userRole
        end
    end

    return false
end

RegisterCommand("god", function(source, args)
    local src = source

    -- Check permissions for the command
    local hasPerm, role = HasGodPermission(src, "god")
    if not hasPerm then
        notify(src, locale('error.no_permission'), "error")  -- Notify if the player doesn't have permission
        return
    end

    -- Default target is the player executing the command
    local target = src
    if args[1] then
        target = tonumber(args[1])  -- If a player ID is provided, set the target to that ID
        if not target or not GetPlayerPed(target) then
            notify(src, locale('error.player_not_found'), "error")
            return
        end
    end

    -- Trigger the flash effect for teleportation
    TriggerClientEvent("qbox-god:flash", target)

    -- Set default teleport name
    local teleportName = "None"
    if args[2] and Teleports[args[2]] then  -- Check if location is valid
        TriggerClientEvent("qbox-god:teleport", target, Teleports[args[2]])  -- Teleport the player to the specified location
        teleportName = args[2]  -- Update teleport name with the selected location
    end

    -- Revive the player
    TriggerClientEvent("qbx_medical:client:playerRevived", target)

    -- Set player's hunger and thirst to 100 after revival
    TriggerClientEvent("QBCore:Client:SetPlayerData", target, {
        metadata = {
            hunger = 100,
            thirst = 100
        }
    })

    -- Notify the admin about the successful action
    if src ~= 0 then
        TriggerClientEvent('okokNotify:Alert', src, "GOD MODE", "You goded this ID: "..target, 5000, 'success')
    end

    -- Get player names for admin and target
    local adminName = src == 0 and "CONSOLE" or GetPlayerName(src)
    local targetName = GetPlayerName(target)

    -- Get the target player's character information
    local player = exports.qbx_core:GetPlayer(target)
    local charInfo = player.PlayerData.charinfo or {}
    local characterName = (charInfo.firstname or "Unknown") .. " " .. (charInfo.lastname or "Unknown")
    local citizenId = player.PlayerData.citizenid or "Unknown"
    local oocName = GetPlayerName(target) or "Unknown"

    -- Send the log to Discord with the improved embed
    local logMessage = "**Admin:** " .. adminName .. " (ID: " .. src .. ")\n" ..
                       "**Target:** " .. targetName .. " (ID: " .. target .. ")\n" ..
                       "**Teleport Location:** " .. teleportName .. "\n" ..
                       "**Character Name:** " .. characterName .. "\n" ..
                       "**Citizen ID:** " .. citizenId .. "\n" ..
                       "**OOC Name:** " .. oocName

    -- Webhook logging
    if DISCORD_WEBHOOK and DISCORD_WEBHOOK ~= "" then
        SendDiscordLog(
            "🛡️ **/god Command Used**",
            logMessage,
            3066993 -- Green color
        )
    else
        print("[GOD] Webhook not configured.")
    end
end, false)  -- This means the command is restricted to players with permissions defined by `HasGodPermission`