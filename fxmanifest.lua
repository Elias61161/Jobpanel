shared_script '@WaveShield/resource/include.lua'

shared_script '@ibrp_menu/shared_fg-obfuscated.lua'
shared_script '@ibrp_menu/ai_module_fg-obfuscated.lua'

fx_version 'cerulean'
game 'gta5'

name 'Elias Jobapenl'
author 'Elias'

lua54 'yes'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
}

client_scripts {
    'client/modules/utils.lua',
    'client/modules/callbacks.lua',
    'client/main.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/config.lua',
    'server/modules/utils.lua',
    'server/modules/permissions.lua',
    'server/modules/audit.lua',
    'server/modules/cache.lua',
    'server/modules/session.lua',
    'server/modules/employees.lua',
    'server/modules/finances.lua',
    'server/modules/shifts.lua',
    'server/modules/statistics.lua',
    'server/modules/discord.lua',
    'server/main.lua',
}

ui_page 'web/dist/index.html'

files {
    'web/dist/index.html',
    'web/dist/**/*',
}

dependencies {
    'es_extended',
    'ox_lib',
    'oxmysql',
}

escrow_ignore {
    'config.lua',
    'server/config.lua',
}

dependency '/assetpacks'