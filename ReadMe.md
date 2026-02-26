# GhostStack Admin Webhook Addon

![GitHub last commit](https://img.shields.io/github/last-commit/ghoststack-dev/fivem-admin-webhooksstyle=flat-square)
![Discord](https://img.shields.io/discord/000000000000000000label=Support&style=flat-square)
![License](https://img.shields.io/badge/license-MIT-greenstyle=flat-square)

> Advanced **Discord webhook logging addon** for the Electus Admin Script ([Electus Admin](https://store.electus-scripts.com/packages/admin)), developed by **GhostStack Development**.

---

##  Table of Contents

- [File Overview](#file-overview)  
- [Config Setup](#config-setup)  
- [Webhook Setup](#webhook-setup-apikeyslua)  
- [Commands & Permissions](#commands--permissions)  
- [Example Discord Embed](#example-discord-embed)  
- [Developed By](#developed-by)

---

##  File Overview

| File | Description |
|------|-------------|
| `config.lua` | Manages command permissions and role access |
| `apikeys.lua` | Stores all Discord webhook URLs |
| Other Lua files | Handle command logic, logging, and integration with Electus Admin |

---

##  Config Setup

Configure which roles can execute each admin command by editing `config.lua`:

```lua
Config = {}

Config.CommandPermissions = {
    setjob = {
        "founder",
        "admin",
        "management"
    },

    deletechar = {
        "founder"
    },

    removejob = {
        "founder",
        "admin"
    },
    
    setgang = {
        "founder",
        "admin",
        "management",
        "moderator"
    },
    
    setmoney = {
       "founder",
       "management",
    },
    
    tp = {
        "founder",
        "admin",
        "management",
        "moderator",
        "supporter"
    },
    
    tpm = {
        "founder",
        "admin",
        "management",
        "moderator",
        "supporter"
    },
    
    dv = {
        "founder",
        "management",
        "admin",
        "moderator",
        "supporter"
    },
    
    setbucket = {
        "founder",
        "admin",
        "management"
    },
    
    Car = {
        "Founder",
        "admin",
        "management"
    },
    
    addjob = {
        "founder",
        "admin",
        "management"
    },

    changejob = {
        "founder",
        "admin",
        "management",
        "Legal Team"
    },

    givemoney = {
        "founder",
        "admin",
        "management"
    },

    god = {
        "founder",
        "admin",
        "management",
        "moderator",
        "supporter"
    },
}

 Role names must exactly match your server groups.

 Webhook Setup (apikeys.lua)

Update with your Discord webhook URLs to enable logging of all events.

ApiKeys = {}

ApiKeys.Webhooks = {
    DeleteChar = "change to your webhook",
    RemoveJob  = "change to your webhook",
    AdminLog   = "change to your webhook",
    SetJob     = "change to your webhook",
    SetGang    = "change to your webhook",
    SetMoney   = "change to your webhook",
    tp         = "change to your webhook",
    tpm        = "change to your webhook",
    dv         = "change to your webhook",
    SetBucket  = "change to your webhook",
    Car        = "change to your webhook",
    addjob     = "change to your webhook",
    changejob  = "change to your webhook",
    givemoney  = "change to your webhook",
    god        = "change to your webhook",
}

Ensure all webhooks are active and correspond to the correct actions.


Commands & Permissions
Admin Commands
Command	Allowed Roles
setjob	founder, admin, management
deletechar	founder
removejob	founder, admin
setgang	founder, admin, management, moderator
setmoney	founder, management
tp	founder, admin, management, moderator, supporter
tpm	founder, admin, management, moderator, supporter
dv	founder, admin, management, moderator, supporter
setbucket	founder, admin, management
Car	Founder, admin, management
addjob	founder, admin, management
changejob	founder, admin, management, Legal Team
givemoney	founder, admin, management
god	founder, admin, management, moderator, supporter


Role Groups Explanation

Founder – Full control of all admin commands.

Admin – High-level server control and job management.

Management – Can handle jobs, gangs, and money management.

Moderator – Limited admin powers like teleporting, deleting chars.

Supporter – Viewer-level commands, teleport, and minor admin actions.

Legal Team – Special access for changejob command.



Developed By

GhostStack Development – enhancing FiveM server admin control with clean, reliable webhook logging.

Ready to drop into your server and extend Electus Admin with professional logging!
