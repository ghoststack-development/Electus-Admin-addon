local function HasCommandPermission(source, commandName)

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

lib.addCommand('setjob', {
    help = locale('command.setjob.help'),
    params = {
        { name = locale('command.setjob.params.id.name'), help = locale('command.setjob.params.id.help'), type = 'playerId' },
        { name = locale('command.setjob.params.job.name'), help = locale('command.setjob.params.job.help'), type = 'string' },
        { name = locale('command.setjob.params.grade.name'), help = locale('command.setjob.params.grade.help'), type = 'number', optional = true }
    }
}, function(source, args)

    local WEBHOOK = ApiKeys?.Webhooks?.SetJob

    local function notify(player, msg, type)
        if player == 0 then
            print("[SETJOB]", msg)
            return
        end

        TriggerClientEvent('ox_lib:notify', player, {
            title = "Set Job",
            description = msg,
            type = type or "info",
            duration = 5000
        })
    end


    local hasPerm, role = HasCommandPermission(source, "setjob")

    if not hasPerm then
        notify(source, "You are not authorised to use this command.", "error")
        return
    end


    local targetId = tonumber(args[locale('command.setjob.params.id.name')])
    local jobName = args[locale('command.setjob.params.job.name')]
    local grade = tonumber(args[locale('command.setjob.params.grade.name')]) or 0

    if not targetId or not jobName then
        notify(source, "Invalid arguments.", "error")
        return
    end

    local player = exports.qbx_core:GetPlayer(targetId)

    if not player then
        notify(source, "Target player not online.", "error")
        return
    end


    local jobData = exports.qbx_core:GetJobs()[jobName]

    if not jobData then
        notify(source, "Job does not exist.", "error")
        return
    end

if not jobData.grades[grade] then
    notify(source, "Invalid job grade.", "error")
    return
end

    local pureLicense = "Console"

    if source ~= 0 then
        for _, id in pairs(GetPlayerIdentifiers(source)) do
            if id:find("license:") then
                pureLicense = id:gsub("license:", "")
                break
            end
        end
    end

    local charInfo = player.PlayerData.charinfo or {}
    local characterName = (charInfo.firstname or "Unknown") .. " " .. (charInfo.lastname or "")
    local citizenId = player.PlayerData.citizenid or "Unknown"
    local oocName = GetPlayerName(targetId) or "Unknown"

    player.Functions.SetJob(jobName, grade)

    notify(source, "Job set successfully.", "success")

    TriggerClientEvent('ox_lib:notify', targetId, {
        title = "Job Updated",
        description = "Your job has been set to " .. jobName .. " (Grade " .. grade .. ")",
        type = "inform"
    })

    if WEBHOOK and WEBHOOK ~= "" then

        local embed = {
            {
                title = "💼 Job Assignment Executed",
                color = 3066993,
                fields = {
                    {
                        name = "👮 Staff",
                        value =
                            "Name: `" .. (source == 0 and "Console" or GetPlayerName(source)) .. "`\n" ..
                            "ID: `" .. source .. "`\n" ..
                            "Role: `" .. (role or "Unknown") .. "`\n" ..
                            "License: `" .. pureLicense .. "`"
                    },
                    {
                        name = "🎯 Target",
                        value =
                            "Character: `" .. characterName .. "`\n" ..
                            "OOC: `" .. oocName .. "`\n" ..
                            "ID: `" .. targetId .. "`\n" ..
                            "Citizen ID: `" .. citizenId .. "`"
                    },
                    {
                        name = "💼 Job Details",
                        value =
                            "Job: `" .. jobName .. "`\n" ..
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
        print("[SETJOB] Webhook not configured.")
    end

end)