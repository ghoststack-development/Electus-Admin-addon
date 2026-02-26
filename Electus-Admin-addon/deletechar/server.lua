-- =====================================================
-- ELECTUS ADMIN SYSTEM - DELETECHAR
-- =====================================================

lib.addCommand('deletechar', {
    help = locale('info.deletechar_command_help'),
    params = {
        { name = 'id', help = locale('info.deletechar_command_arg_player_id'), type = 'number' },
    }
}, function(source, args)

    local WEBHOOK = ApiKeys.Webhooks.DeleteChar

    local function notify(player, msg, type)
        if player == 0 then
            print("[DELETECHAR]", msg)
            return
        end

        TriggerClientEvent('ox_lib:notify', player, {
            title = locale("Delete Character"),
            description = msg,
            type = type or "info",
            duration = 5000
        })
    end

    if not WEBHOOK or WEBHOOK == "" then
        print("[DELETECHAR] Webhook not configured in apikeys.lua")
        return
    end

    -- =============================
    -- PERMISSION CHECK (CONFIG BASED)
    -- =============================

    local hasPerm, role = HasCommandPermission(source, "deletechar")

    if not hasPerm then
        notify(source, locale("error.no_permission"), "error")
        return
    end

    -- =============================
    -- TARGET PLAYER
    -- =============================

    local targetId = tonumber(args.id)
    if not targetId then
        notify(source, locale("error.invalid_player_id"), "error")
        return
    end

    local player = exports.qbx_core:GetPlayer(targetId)
    if not player then
        notify(source, locale('error.not_online'), "error")
        return
    end

    -- =============================
    -- GET STAFF LICENSE
    -- =============================

    local staffPureLicense
    for _, id in pairs(GetPlayerIdentifiers(source)) do
        if id:find("license:") then
            staffPureLicense = id:gsub("license:", "")
            break
        end
    end

    -- =============================
    -- GET TARGET DATA
    -- =============================

    local citizenId = player.PlayerData.citizenid
    local charInfo = player.PlayerData.charinfo or {}
    local characterName = (charInfo.firstname or "Unknown") .. " " .. (charInfo.lastname or "")
    local oocName = GetPlayerName(targetId)

    local targetPureLicense
    for _, id in pairs(GetPlayerIdentifiers(targetId)) do
        if id:find("license:") then
            targetPureLicense = id:gsub("license:", "")
            break
        end
    end

    -- =============================
    -- KICK PLAYER FIRST
    -- =============================

    DropPlayer(targetId, locale("kick.default_reason"))

    Wait(1000)

    -- =============================
    -- DELETE FROM DATABASE
    -- =============================

    local deleted = MySQL.update.await(
        "DELETE FROM players WHERE citizenid = ?",
        { citizenId }
    )

    MySQL.update.await("DELETE FROM properties WHERE owner_citizenid = ?", { citizenId })
    MySQL.update.await("DELETE FROM phone_phones WHERE owner_id = ?", { citizenId })

    if not deleted or deleted < 1 then
        notify(source, locale("error.character_not_deleted"), "error")
        print("[DELETECHAR] Failed to delete:", citizenId)
        return
    end

    notify(source, locale("success.character_deleted"), "success")
    print("[DELETECHAR] Deleted:", citizenId)

    -- =============================
    -- DISCORD LOG
    -- =============================

    local embed = {
        {
            title = locale("log.deletechar_title"),
            color = 15158332,
            fields = {
                {
                    name = locale("log.founder_info"),
                    value =
                        locale("log.name") .. ": `" .. GetPlayerName(source) .. "`\n" ..
                        locale("log.server_id") .. ": `" .. source .. "`\n" ..
                        locale("log.role") .. ": `" .. (role or "Unknown") .. "`\n" ..
                        locale("log.license") .. ": `" .. (staffPureLicense or "Unknown") .. "`"
                },
                {
                    name = locale("log.deleted_character"),
                    value =
                        locale("log.character_name") .. ": `" .. characterName .. "`\n" ..
                        locale("log.ooc_name") .. ": `" .. oocName .. "`\n" ..
                        locale("log.server_id") .. ": `" .. targetId .. "`\n" ..
                        locale("log.citizen_id") .. ": `" .. citizenId .. "`\n" ..
                        locale("log.license") .. ": `" .. (targetPureLicense or "Unknown") .. "`"
                }
            },
            footer = {
                text = locale("log.footer") .. " • " .. os.date("%Y-%m-%d %H:%M:%S")
            }
        }
    }

    PerformHttpRequest(WEBHOOK, function(statusCode)
        print("[DELETECHAR LOG STATUS]:", statusCode)
    end, 'POST', json.encode({
        username = "Electus Logs",
        embeds = embed
    }), {
        ['Content-Type'] = 'application/json'
    })

end)