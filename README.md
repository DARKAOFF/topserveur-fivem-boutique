# UpServeur FiveM Shop

Plugin officiel UpServeur pour connecter un serveur de jeu au système de vote UpServeur.

`upserveur_boutique` est une boutique FiveM basée sur `ox_lib`, avec menu, commande, keymap et hooks serveur personnalisables.

## Installation

1. Place la ressource dans `resources/[upserveur]/upserveur_boutique`
2. Vérifie que `ox_lib` est démarré avant elle
3. Ajoute `ensure upserveur_boutique` dans `server.cfg`
4. Ajuste la configuration et les récompenses dans `config.lua`

## Configuration recommandée

```cfg
ensure ox_lib
ensure upserveur_boutique

set upserveur_boutique_command "boutique"
set upserveur_boutique_api "false"
set upserveur_boutique_api_url "https://upserveur.fr/api/public/v1"
set upserveur_boutique_server_token ""
```

## Compatibilité ancienne configuration

La ressource accepte encore les anciens convars `topserveur_boutique_*` et l’ancien namespace d’événements `topserveur_boutique:*`.

## Fonctionnalités

- menu client `ox_lib`
- catalogue configurable
- hooks commandes / argent / items
- support ESX, QBCore, ox_core et fallback commandes
- sync API optionnelle vers UpServeur

## Événements

- `upserveur_boutique:server:purchase`
- `upserveur_boutique:client:purchaseResult`

Compatibilité temporaire :

- `topserveur_boutique:server:purchase`
- `topserveur_boutique:client:purchaseResult`

## Notes

- adapte `Config.OnPurchase` à ton framework et ton économie
- la ressource ne change pas ta logique métier, elle rebrand simplement le socle
- pense à migrer progressivement les anciennes permissions comme `topserveur.vip` vers `upserveur.vip`
