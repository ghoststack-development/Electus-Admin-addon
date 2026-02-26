lib.addCommand('addjob', {
    help = locale('command.addjob.help'),
    params = {
        { name = locale('command.addjob.params.id.name'), help = locale('command.addjob.params.id.help'), type = 'playerId' },
        { name = locale('command.addjob.params.job.name'), help = locale('command.addjob.params.job.help'), type = 'string' },
        { name = locale('command.addjob.params.grade.name'), help = locale('command.addjob.params.grade.help'), type = 'number', optional = true }
    },
    restricted = 'group.admin'
}, function(source, args)

    -- Fetch the webhook URL for job actions from apikeys.lua
    local WEBHOOK = ApiKeys.Webhooks.addjob

    local function notify(player, msg, type)
        if player == 0 then
            print("[ADDJOB]", msg)
            return
        end
        TriggerClientEvent('ox_lib:notify', player, {
            title = "Job",
            description = msg,
            type = type or "info",
            duration = 5000
        })
    end

    -- Check command permission
    local hasPerm, role = HasCommandPermission(source, "addjob")
    if not hasPerm then
        notify(source, "You are not authorized to use this command.", "error")
        return
    end

    -- Get the player and job details
    local targetId = tonumber(args[locale('command.addjob.params.id.name')])
    local jobName = args[locale('command.addjob.params.job.name')]
    local grade = tonumber(args[locale('command.addjob.params.grade.name')]) or 0

    if not targetId or not jobName then
        notify(source, "Invalid arguments.", "error")
        return
    end

    local player = exports.qbx_core:GetPlayer(targetId)
    if not player then
        notify(source, "Target player not online.", "error")
        return
    end

    -- Ensure the job exists
    local jobData = exports.qbx_core:GetJobs()[jobName]
    if not jobData then
        notify(source, "Job does not exist.", "error")
        return
    end

    if not jobData.grades[grade] then
        notify(source, "Invalid job grade.", "error")
        return
    end

    -- Get the player's character information
    local charInfo = player.PlayerData.charinfo or {}
    local characterName = (charInfo.firstname or "Unknown") .. " " .. (charInfo.lastname or "")
    local citizenId = player.PlayerData.citizenid or "Unknown"
    local oocName = GetPlayerName(targetId) or "Unknown"

    -- Add the job to the player
    player.Functions.SetJob(jobName, grade)
    notify(source, "Job added successfully", "success")

    -- Notify the player about the job change
    TriggerClientEvent('ox_lib:notify', targetId, {
        title = "Job Updated",
        description = "Your job has been set to " .. jobName .. " (Grade " .. grade .. ")",
        type = "inform"
    })

    -- Log the action to the webhook
    if WEBHOOK and WEBHOOK ~= "" then
        local embed = {
            {
                title = "💼 Job Added",
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
                        name = "🎯 Target",
                        value = "Character: `" .. characterName .. "`\n" ..
                                "OOC: `" .. oocName .. "`\n" ..
                                "ID: `" .. targetId .. "`\n" ..
                                "Citizen ID: `" .. citizenId .. "`"
                    },
                    {
                        name = "💼 Job Details",
                        value = "Job: `" .. jobName .. "`\n" ..
                                "Grade: `" .. grade .. "`"
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
        print("[ADDJOB] Webhook not configured.")
    end
end)