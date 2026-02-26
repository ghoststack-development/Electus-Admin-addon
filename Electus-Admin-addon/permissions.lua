function HasCommandPermission(source, commandName)

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