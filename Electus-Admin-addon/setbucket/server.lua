lib.locale()

lib.addCommand('setbucket', {
    help = locale('command.setbucket.help'),
    params = {
        {
            name = locale('command.setbucket.params.id.name'),
            help = locale('command.setbucket.params.id.help'),
            type = 'playerId'
        },
        {
            name = locale('command.setbucket.params.bucket.name'),
            help = locale('command.setbucket.params.bucket.help'),
            type = 'number'
        }
    }
}, function(source, args)

    -- Fetch the webhook for setbucket from apikeys.lua
    local WEBHOOK = ApiKeys.Webhooks.SetBucket

    -- Helper function to notify players
    local function notify(player, msg, type)
        TriggerClientEvent('ox_lib:notify', player, {
            title = "Bucket",
            description = msg,
            type = type,
            duration = 5000
        })
    end

    -- Get target player ID and bucket ID from the command arguments
    local targetId = args[locale('command.setbucket.params.id.name')]
    local bucketId = args[locale('command.setbucket.params.bucket.name')]

    -- Ensure target player exists
    if not targetId or not GetPlayerName(targetId) then
        notify(source, locale('error.player_not_found'), 'error')
        return
    end

    -- Get the player's license identifier
    local license
    for _, id in pairs(GetPlayerIdentifiers(source)) do
        if id:find("license:") then
            license = id:gsub("license:", "")
            break
        end
    end

    if not license then
        notify(source, "License identifier not found.", 'error')
        return
    end

    -- Check if the admin has permission using the role-based permission system from config.lua
    local hasPerm, role = HasCommandPermission(source, "setbucket")

    if not hasPerm then
        notify(source, locale('error.no_permission'), 'error')
        return
    end

    -- Set the bucket for the target player
    local targetName = GetPlayerName(targetId)
    SetPlayerRoutingBucket(targetId, bucketId)

    -- Notify the source and target player
    notify(source, locale('success.bucket_set', targetName, bucketId), 'success')
    
    -- ==============================
    -- LOGGING (Discord Webhook)
    -- ==============================
    if WEBHOOK and WEBHOOK ~= "" then
        local embed = {
            title = "🔑 SetBucket Log",
            color = 3447003,
            fields = {
                {
                    name = "**Admin Info**",
                    value =
                        "**Name:** `" .. GetPlayerName(source) .. "`\n" ..
                        "**Role:** `" .. role .. "`\n" ..
                        "**License:** `" .. license .. "`"
                },
                {
                    name = "**Target Info**",
                    value =
                        "**Name:** `" .. targetName .. "`\n" ..
                        "**Server ID:** `" .. targetId .. "`"
                },
                {
                    name = "**Bucket Info**",
                    value =
                        "**Bucket ID:** `" .. bucketId .. "`"
                }
            },
            footer = {
                text = "Electus Admin System • " .. os.date("%Y-%m-%d %H:%M:%S")
            }
        }

        PerformHttpRequest(WEBHOOK, function(statusCode)
            print("[SETBUCKET LOG STATUS]:", statusCode)
        end, 'POST', json.encode({
            username = "Electus Logs",
            embeds = { embed }
        }), {
            ['Content-Type'] = 'application/json'
        })

    else
        print("[SETBUCKET] Webhook not configured.")
    end
end)