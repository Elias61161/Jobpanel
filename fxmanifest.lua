fx_version 'cerulean'
game 'gta5'

author 'Elias Developments'
description 'Ultimate Boss Panel - Professional Management System'
version '5.0.0'

ui_page 'html/index.html'

shared_scripts {
    '@es_extended/imports.lua',
    'config.lua'
}

client_scripts {
    'client/client.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/server.lua'
}

files {
    'html/index.html',
    'html/style.css',
    'html/script.js'
}

lua54 'yes'