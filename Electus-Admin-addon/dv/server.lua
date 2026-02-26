lib.addCommand('dv', {
    help = locale('command.dv.help'),
    params = {
        {
            name = locale('command.dv.params.radius.name'),
            type = 'number',
            optional = true
        }
    }
}, function(source, args)

    -- Fetch the webhook URL for the DV command from apikeys.lua
    local WEBHOOK = ApiKeys.Webhooks.dv

    -- Helper function to notify players
    local function notify(player, msg, type)
        TriggerClientEvent('ox_lib:notify', player, {
            title = "Vehicle Delete",
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
    -- PERMISSION CHECK (FROM config.lua)
    -- ==============================
    local hasPerm, role = HasCommandPermission(source, "dv")

    if not hasPerm then
        notify(source, "You are not authorised to use this command.", "error")
        return
    end

    -- ==============================
    -- FETCH ADMIN CHARACTER DATA
    -- ==============================
    local adminName = "Unknown"
    local adminCitizenId = "Unknown"

    local adminData = MySQL.query.await([[ 
        SELECT 
            citizenid,
            JSON_UNQUOTE(JSON_EXTRACT(charinfo, '$.firstname')) AS firstname,
            JSON_UNQUOTE(JSON_EXTRACT(charinfo, '$.lastname')) AS lastname
        FROM players
        WHERE license = ?
        LIMIT 1
    ]], { license })

    if adminData and adminData[1] then
        local row = adminData[1]
        adminCitizenId = row.citizenid or "Unknown"

        if row.firstname and row.lastname then
            adminName = row.firstname .. " " .. row.lastname
        end
    end

    -- ==============================
    -- DELETE VEHICLES
    -- ==============================
    local ped = GetPlayerPed(source)
    if not ped then return end

    local coords = GetEntityCoords(ped)
    local radius = tonumber(args.radius) or 5.0

    local deletedVehicles = {}
    local plates = {}

    for _, veh in pairs(GetAllVehicles()) do
        local vehCoords = GetEntityCoords(veh)

        if #(coords - vehCoords) <= radius then
            local plate = (GetVehicleNumberPlateText(veh) or "N/A"):gsub("%s+","")
            local modelHash = GetEntityModel(veh)

            table.insert(deletedVehicles, {
                model = modelHash,
                plate = plate,
                coords = vehCoords
            })

            if plate ~= "N/A" then
                table.insert(plates, plate)
            end

            DeleteEntity(veh)
        end
    end

    if #deletedVehicles == 0 then
        TriggerClientEvent('ox_lib:notify', source, {
            title = "Vehicle Delete",
            description = "No vehicles found",
            type = "error"
        })
        return
    end

    TriggerClientEvent('ox_lib:notify', source, {
        title = "Vehicle Delete",
        description = "Deleted " .. #deletedVehicles .. " vehicles",
        type = "success"
    })

    -- ==============================
    -- FETCH OWNERS FROM DATABASE
    -- ==============================
    local owners = {}

    if #plates > 0 then
        local placeholders = string.rep("?,", #plates):sub(1, -2)

        local result = MySQL.query.await([[ 
            SELECT 
                pv.plate,
                pv.citizenid,
                JSON_UNQUOTE(JSON_EXTRACT(p.charinfo, '$.firstname')) AS firstname,
                JSON_UNQUOTE(JSON_EXTRACT(p.charinfo, '$.lastname')) AS lastname
            FROM player_vehicles pv
            LEFT JOIN players p ON pv.citizenid = p.citizenid
            WHERE REPLACE(pv.plate,' ','') IN (]] .. placeholders .. [[)
        ]], plates)

        if result then
            for _, row in pairs(result) do
                local cleanedPlate = row.plate:gsub("%s+","")
                local ownerName = "Unknown"

                if row.firstname and row.lastname then
                    ownerName = row.firstname .. " " .. row.lastname
                end

                owners[cleanedPlate] = {
                    citizenid = row.citizenid,
                    name = ownerName
                }
            end
        end
    end

    -- ==============================
    -- BUILD VEHICLE LOG TEXT
    -- ==============================
    local vehicleText = {}

    for i, v in ipairs(deletedVehicles) do
        local ownerData = owners[v.plate]
        local ownerText = "Not Stored"

        if ownerData then
            ownerText = ownerData.name ..
                        "\nCitizenID: " .. ownerData.citizenid
        end

        table.insert(vehicleText,
            "**Vehicle #" .. i .. "**\n" ..
            "Model Hash: `" .. v.model .. "`\n" ..
            "Plate: `" .. v.plate .. "`\n" ..
            "Owner:\n`" .. ownerText .. "`\n" ..
            "Coords: `" ..
            math.floor(v.coords.x) .. ", " ..
            math.floor(v.coords.y) .. ", " ..
            math.floor(v.coords.z) .. "`"
        )
    end

    -- ==============================
    -- DISCORD LOG
    -- ==============================
    if WEBHOOK and WEBHOOK ~= "" then
        local embed = {
            title = "🚗 Vehicle Deletion Log",
            color = 3447003,
            fields = {
                {
                    name = "👮 Admin",
                    value = "Character: " .. adminName ..
                            "\nCitizenID: " .. adminCitizenId ..
                            "\nPlayer Name: " .. GetPlayerName(source) ..
                            "\nServer ID: " .. source ..
                            "\nLicense: " .. pureLicense
                },
                {
                    name = "📊 Summary",
                    value = "Radius: " .. radius ..
                            "\nTotal Deleted: " .. #deletedVehicles,
                    inline = true
                },
                {
                    name = "🚘 Vehicles",
                    value = table.concat(vehicleText, "\n\n-----------------\n\n")
                }
            },
            footer = {
                text = "Electus DV System • " .. os.date("%Y-%m-%d %H:%M:%S")
            }
        }

        PerformHttpRequest(WEBHOOK, function() end, 'POST', json.encode({
            embeds = { embed }
        }), { ['Content-Type'] = 'application/json' })

    else
        print("[DV] Webhook not configured.")
    end

end)