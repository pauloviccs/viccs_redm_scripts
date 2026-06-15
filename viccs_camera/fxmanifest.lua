fx_version 'cerulean'
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'
game 'rdr3'
lua54 'yes'

name 'viccs_camera'
author 'VICCS'
description 'Placeable photography camera with photo mode for VORP Framework'
version '1.0.0'

shared_scripts {
    'config.lua'
}

client_scripts {
    'client/placement.lua',
    'client/photomode.lua',
    'client/main.lua',
}

server_script 'server/main.lua'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js',
}

ui_page 'html/index.html'

dependencies {
    'vorp_core',
    'vorp_inventory',
    'screenshot-basic'
}
