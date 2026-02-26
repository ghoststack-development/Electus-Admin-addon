lib.addCommand('removejob', {
    help = locale('command.removejob.help'),
    params = {
        { name = locale('command.removejob.params.id.name'), help = locale('command.removejob.params.id.help'), type = 'playerId' },
        { name = locale('command.removejob.params.job.name'), help = locale('command.removejob.params.job.help'), type = 'string' }
    }
}, function(source, args)

    local WEBHOOK = "https://discord.com/api/webhooks/1474293990592483391/tFpwFDEBP_4Rn59bn-a2b9IbRN3ZrLB3iRp3tbFkzISzYqcspZc78i5SenoOFwS4a6Wq"

    local function notify(player, msg, type)
        TriggerClientEvent('ox_lib:notify', player, {
            title = "Job",
            description = msg,
            type = type or "info",
            duration = 5000
        })
    end

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

    if not license then return end

    -- =============================
    -- ROLE CHECK
    -- =============================

    local adminCheck = MySQL.query.await(
        "SELECT role FROM electus_admin_staffs WHERE license = ? LIMIT 1",
        { pureLicense }
    )

    if not adminCheck or not adminCheck[1] then
        notify(source, "You are not authorised to use this command.", "error")
        return
    end

    local role = string.lower(adminCheck[1].role)

    local allowedRoles = {
        moderator = true,
        admin = true,
        management = true,
        founder = true
    }

    if not allowedRoles[role] then
        notify(source, "Your staff role does not allow this command.", "error")
        return
    end

    -- =============================
    -- TARGET PLAYER
    -- =============================

    local targetId = tonumber(args[locale('command.removejob.params.id.name')])
    local jobName = string.lower(args[locale('command.removejob.params.job.name')] or "")

    if not targetId or jobName == "" then
        notify(source, "Invalid arguments.", "error")
        return
    end

    local player = exports.qbx_core:GetPlayer(targetId)

    if not player then
        notify(source, locale('error.not_online'), "error")
        return
    end

    local currentJob = string.lower(player.PlayerData.job.name)

    if currentJob ~= jobName then
        notify(source, "Player does not currently have that job.", "error")
        return
    end

    -- =============================
    -- CHARACTER NAME
    -- =============================

    local charInfo = player.PlayerData.charinfo
    local characterName = (charInfo.firstname or "Unknown") .. " " .. (charInfo.lastname or "")

    -- =============================
    -- REMOVE JOB
    -- =============================

    player.Functions.SetJob("unemployed", 0)

    notify(source, "Job removed successfully.", "success")

    -- =============================
    -- DISCORD LOG
    -- =============================

    PerformHttpRequest(WEBHOOK, function() end, 'POST', json.encode({
        embeds = {{
            title = "🛠️ **Job Removal Executed**",
            color = 15105570,
            description = "**A staff member has removed a job from a player.**",
            fields = {
                {
                    name = "👮 **Staff Information**",
                    value =
                        "**Name:** `" .. GetPlayerName(source) .. "`\n" ..
                        "**Server ID:** `" .. source .. "`\n" ..
                        "**Role:** `" .. role .. "`\n" ..
                        "**License:** `" .. pureLicense .. "`"
                },
                {
                    name = "🎯 **Target Information**",
                    value =
                        "**Character Name:** `" .. characterName .. "`\n" ..
                        "**OOC Name:** `" .. GetPlayerName(targetId) .. "`\n" ..
                        "**Server ID:** `" .. targetId .. "`\n" ..
                        "**Citizen ID:** `" .. player.PlayerData.citizenid .. "`"
                },
                {
                    name = "💼 **Job Removed**",
                    value = "```" .. jobName .. "```"
                }
            },
            footer = {
                text = "Electus Admin System • " .. os.date("%Y-%m-%d %H:%M:%S")
            }
        }}
    }), { ['Content-Type'] = 'application/json' })

end)