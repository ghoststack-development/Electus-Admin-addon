fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'Ghoststack Development | Developed by spixy__'
description 'Admin Command System for Electus_admin menu https://www.electus-scripts.com/packages/admin'
version '1.1.0'

-- Shared Scripts
shared_script '@ox_lib/init.lua'
client_scripts {
    'car/client.lua',
    'god/client.lua',
}

-- Server Scripts
server_scripts {
    -- Core Dependencies
    '@oxmysql/lib/MySQL.lua',  -- MySQL Dependency
    'apikeys.lua',
    'config.lua',                   
    'permissions.lua',         

    'setbucket/server.lua',    -- Set Player Buckets
    'setmoney/server.lua',     -- Set Player Money
    'dv/server.lua',           -- Vehicle Delete Command
    'tp/server.lua',           -- Teleport Command
    'tpm/server.lua',          -- Teleport to Marker Command
    'car/server.lua',          -- Car-related Server Commands
    'setjob/server.lua',       -- Set Player Job
    'setgang/server.lua',      -- Set Player Gang
    'deletechar/server.lua',   -- Delete Character Command
    'removejob/server.lua',    -- Remove Player Job
    'addjob/server.lua',       -- Add Player Job Command
    'changejob/server.lua',    -- Change Player Job Command
    'givemoney/server.lua',    -- Give Money Command
}


dependencies {
    'ox_lib',    
    'oxmysql',  
    'qbx_core',  
}

ox_lib {
    locale = 'en',
}