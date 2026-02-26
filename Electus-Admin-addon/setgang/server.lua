lib.addCommand('setgang', {
    help = locale('command.setgang.help'),
    params = {
        { name = locale('command.setgang.params.id.name'), help = locale('command.setgang.params.id.help'), type = 'playerId' },
        { name = locale('command.setgang.params.gang.name'), help = locale('command.setgang.params.gang.help'), type = 'string' },
        { name = locale('command.setgang.params.grade.name'), help = locale('command.setgang.params.grade.help'), type = 'number', optional = true }
    }
}, function(source, args)

    local WEBHOOK = ApiKeys.Webhooks.SetGang

    -- =============================
    -- GET LICENSE
    -- =============================

    local license, pureLicense
    for _, id in pairs(GetPlayerIdentifiers(source)) do
        if id:find("license:") then
            license = id
            pureLicense = id:gsub("license:", "")
            break
        end
    end

    if not license then
        TriggerClientEvent('ox_lib:notify', source, {
            title = "Set Gang",
            description = "Could not retrieve player license.",
            type = "error"
        })
        return
    end

    -- =============================
    -- PERMISSION CHECK
    -- =============================

    local hasPerm, role = HasCommandPermission(source, "setgang")

    if not hasPerm then
        TriggerClientEvent('ox_lib:notify', source, {
            title = "Set Gang",
            description = "You are not authorised to use this command.",
            type = "error"
        })
        return
    end

    -- =============================
    -- TARGET PLAYER
    -- =============================

    local targetId = tonumber(args[locale('command.setgang.params.id.name')])
    local gangName = args[locale('command.setgang.params.gang.name')]
    local grade = tonumber(args[locale('command.setgang.params.grade.name')]) or 0

    if not targetId or not gangName then
        TriggerClientEvent('ox_lib:notify', source, {
            title = "Set Gang",
            description = "Invalid arguments.",
            type = "error"
        })
        return
    end

    local player = exports.qbx_core:GetPlayer(targetId)

    if not player then
        TriggerClientEvent('ox_lib:notify', source, {
            title = "Set Gang",
            description = "Target player not online.",
            type = "error"
        })
        return
    end

    -- =============================
    -- SET GANG
    -- =============================

    player.Functions.SetGang(gangName, grade)

    TriggerClientEvent('ox_lib:notify', source, {
        title = "Set Gang",
        description = "Gang set successfully.",
        type = "success"
    })

    TriggerClientEvent('ox_lib:notify', targetId, {
        title = "Gang Updated",
        description = "Your gang has been set to " .. gangName .. " (Grade " .. grade .. ")",
        type = "inform"
    })

    -- =============================
    -- DISCORD LOG
    -- =============================

    if WEBHOOK and WEBHOOK ~= "" then
        local embed = {
            {
                title = "🔫 **SetGang Executed**",
                color = 3066993,
                fields = {
                    {
                        name = "**👮 Admin Info**",
                        value =
                            "**Name:** `" .. GetPlayerName(source) .. "`\n" ..
                            "**Server ID:** `" .. source .. "`\n" ..
                            "**Role:** `" .. (role or "Unknown") .. "`\n" ..
                            "**License:** `" .. pureLicense .. "`"
                    },
                    {
                        name = "**🎯 Target Info**",
                        value =
                            "**Character Name:** `" .. (player.PlayerData.charinfo.firstname or "Unknown") .. " " .. (player.PlayerData.charinfo.lastname or "Unknown") .. "`\n" ..
                            "**OOC Name:** `" .. GetPlayerName(targetId) .. "`\n" ..
                            "**Server ID:** `" .. targetId .. "`\n" ..
                            "**Citizen ID:** `" .. player.PlayerData.citizenid .. "`"
                    },
                    {
                        name = "**💼 Gang Details**",
                        value =
                            "**Gang:** `" .. gangName .. "`\n" ..
                            "**Grade:** `" .. grade .. "`"
                    }
                },
                footer = {
                    text = "Electus Admin System • " .. os.date("%Y-%m-%d %H:%M:%S")
                }
            }
        }

        PerformHttpRequest(WEBHOOK, function(statusCode)
            print("[SETGANG LOG STATUS]:", statusCode)
        end, 'POST', json.encode({
            username = "Electus Logs",
            embeds = embed
        }), {
            ['Content-Type'] = 'application/json'
        })

    else
        print("[SETGANG] Webhook not configured.")
    end

end)