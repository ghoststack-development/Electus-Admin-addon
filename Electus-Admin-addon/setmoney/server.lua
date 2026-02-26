lib.addCommand('setmoney', {
    help = locale('command.setmoney.help'),
    params = {
        { name = locale('command.setmoney.params.id.name'), help = locale('command.setmoney.params.id.help'), type = 'playerId' },
        { name = locale('command.setmoney.params.moneytype.name'), help = locale('command.setmoney.params.moneytype.help'), type = 'string' },
        { name = locale('command.setmoney.params.amount.name'), help = locale('command.setmoney.params.amount.help'), type = 'number' }
    }
}, function(source, args)

    -- Fetch the webhook URL for the setmoney command from apikeys.lua
    local WEBHOOK = ApiKeys.Webhooks.SetMoney

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
        TriggerClientEvent('ox_lib:notify', source, {
            title = "Set Money",
            description = "Could not retrieve player license.",
            type = "error"
        })
        return
    end

    -- ==============================
    -- PERMISSION CHECK (FROM config.lua)
    -- ==============================
    local hasPerm, role = HasCommandPermission(source, "setmoney")

    if not hasPerm then
        TriggerClientEvent('ox_lib:notify', source, {
            title = "Set Money",
            description = "You are not authorised to use this command.",
            type = "error"
        })
        return
    end

    -- ==============================
    -- TARGET PLAYER
    -- ==============================
    local targetId = tonumber(args[locale('command.setmoney.params.id.name')])
    local moneyType = args[locale('command.setmoney.params.moneytype.name')]
    local amount = tonumber(args[locale('command.setmoney.params.amount.name')])

    if not targetId or not moneyType or not amount then
        TriggerClientEvent('ox_lib:notify', source, {
            title = "Set Money",
            description = "Invalid arguments.",
            type = "error"
        })
        return
    end

    local player = exports.qbx_core:GetPlayer(targetId)

    if not player then
        TriggerClientEvent('ox_lib:notify', source, {
            title = "Set Money",
            description = locale('error.not_online'),
            type = "error"
        })
        return
    end

    -- ==============================
    -- GET TARGET AND ADMIN CHARACTER DATA
    -- ==============================
    local adminCharInfo = source ~= 0 and exports.qbx_core:GetPlayer(source).PlayerData.charinfo or {}
    local targetCharInfo = player.PlayerData.charinfo or {}

    local adminCharacterName = (adminCharInfo.firstname or "Unknown") .. " " .. (adminCharInfo.lastname or "Unknown")
    local targetCharacterName = (targetCharInfo.firstname or "Unknown") .. " " .. (targetCharInfo.lastname or "Unknown")
    local targetCitizenId = player.PlayerData.citizenid or "Unknown"
    local adminCitizenId = source ~= 0 and exports.qbx_core:GetPlayer(source).PlayerData.citizenid or "Console"

    -- ==============================
    -- SET MONEY
    -- ==============================
    player.Functions.SetMoney(moneyType, amount)

    TriggerClientEvent('ox_lib:notify', source, {
        title = "Set Money",
        description = "Money updated successfully.",
        type = "success"
    })

    TriggerClientEvent('ox_lib:notify', targetId, {
        title = "Money Updated",
        description = "Your " .. moneyType .. " balance has been set to $" .. amount,
        type = "inform"
    })

    -- ==============================
    -- DISCORD LOG
    -- ==============================
    if WEBHOOK and WEBHOOK ~= "" then
        local embed = {
            {
                title = "💰 SetMoney Log",
                color = 15844367,
                fields = {
                    {
                        name = "**👮 Admin Info**",
                        value =
                            "**Name:** `" .. GetPlayerName(source) .. "`\n" ..
                            "**Character Name:** `" .. adminCharacterName .. "`\n" ..
                            "**Server ID:** `" .. source .. "`\n" ..
                            "**Citizen ID:** `" .. adminCitizenId .. "`\n" ..
                            "**Role:** `" .. role .. "`\n" ..
                            "**License:** `" .. pureLicense .. "`"
                    },
                    {
                        name = "**🎯 Target Info**",
                        value =
                            "**Character Name:** `" .. targetCharacterName .. "`\n" ..
                            "**OOC Name:** `" .. GetPlayerName(targetId) .. "`\n" ..
                            "**Server ID:** `" .. targetId .. "`\n" ..
                            "**Citizen ID:** `" .. targetCitizenId .. "`"
                    },
                    {
                        name = "**💰 Money Info**",
                        value =
                            "Type: `" .. moneyType .. "`\n" ..
                            "Amount Set: `$" .. amount
                    }
                },
                footer = {
                    text = "Electus Money System • " .. os.date("%Y-%m-%d %H:%M:%S")
                }
            }
        }

        PerformHttpRequest(WEBHOOK, function(statusCode)
            print("[SETMONEY LOG STATUS]:", statusCode)
        end, 'POST', json.encode({
            username = "Electus Logs",
            embeds = embed
        }), {
            ['Content-Type'] = 'application/json'
        })
    else
        print("[SETMONEY] Webhook not configured.")
    end

end)