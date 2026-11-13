fx_version 'cerulean'
game 'gta5'
lua54 'yes'
use_experimental_fxv2_oal 'yes'

name 'cobalt_garages'
author 'Project Cobalt'
description 'Garages, impound and the in-game garage creator'
version '1.0.0'

dependencies {
    'cobalt_mysql',
    'ox_lib',
    'cobalt_core',
}

shared_script '@ox_lib/init.lua'

server_scripts {
    '@cobalt_mysql/lib/MySQL.lua',
    '@cobalt_core/server/migrationgate.lua',
    'server/init.lua',
}

client_script 'client/init.lua'

ui_page '_nui/build/index.html'

files {
    'config.lua',
    'client/*.lua',
    'shared/*.lua',
    '_nui/build/index.html',
    '_nui/build/assets/*',
}
