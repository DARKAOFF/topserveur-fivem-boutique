fx_version 'cerulean'
game 'gta5'

name 'topserveur-fivem-boutique'
author 'TopServeur.fr'
description 'Boutique FiveM configurable avec menu client, keymap, locales FR/EN et hooks serveur.'
version '1.0.0'

lua54 'yes'

shared_scripts {
  'config.lua',
  'locales/*.lua'
}

client_scripts {
  'client/main.lua'
}

server_scripts {
  'server/main.lua'
}
