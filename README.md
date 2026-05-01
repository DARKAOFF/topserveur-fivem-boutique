# TopServeur Boutique (ox_lib)

Ressource **FiveM** séparée du plugin de votes.

Objectif :
- Afficher un menu boutique en jeu via `ox_lib`.
- Ajouter une commande et une `keymap` configurables (`/boutique` et `F7` par défaut).
- Gérer la logique d’articles/catégories côté `config.lua`.
- Déclencher un hook serveur `Config.OnPurchase(source, item, category, quantity)`.
- Supporter un appel API optionnel (`Config.Api`) pour tracer les achats.

## Dépendance

Cette ressource utilise **ox_lib** :

- `@ox_lib/init.lua`

Installe d’abord `ox_lib` sur ton serveur FiveM.

## Installation

1. Copie le dossier dans :

```txt
resources/topserveur_boutique
```

2. Ajoute dans ton `server.cfg` :

```cfg
ensure ox_lib
ensure topserveur_boutique
```

3. Configure `Config` dans `config.lua`.

## Configuration rapide

```lua
Config.Locale = 'fr'
Config.Command = 'boutique'
Config.KeyMapping = {
  enabled = true,
  key = 'F7',
  description = 'Ouvrir la boutique TopServeur'
}
```

Si tu changes la langue :

```lua
Config.Locale = 'en'
```

## Exemple : branchement récompense (server-side)

`config.lua` expose le hook :

```lua
function Config.OnPurchase(source, item, category, quantity)
  -- La version actuelle détecte automatiquement ESX / QBCore / ox_core.
  -- Tu peux aussi surcharger cette fonction pour personnaliser totalement la logique.
  local playerId = tostring(source or -1)
  local framework = getFramework()
  print(('[TopServeur] %s achète %sx%s'):format(playerId, tostring(quantity), item.id))
  print(('[TopServeur] Framework détecté: %s'):format(framework))
end
```

Par défaut le hook gère déjà :
- récompenses `money` (ESX/QB/ox_core + fallback commande)
- récompenses `item`
- récompenses `command`

Structure recommandée dans `Config.ShopCatalog` :

```lua
{
  id = "pack_start",
  label = {
    fr = "Pack de démarrage",
    en = "Starter Pack",
  },
  description = {
    fr = "Cash + voiture",
    en = "Cash + vehicle",
  },
  price = 9,
  rewards = {
    { type = "money", amount = 50000 },
    { type = "item", item = "water", amount = 10 },
    { type = "command", command = "add_ace {player} topserveur.vip allow" },
  },
},
```

Tu peux donc faire les rewards en multi-framework sans réécrire les couches d’intégration, uniquement via `Config.ShopCatalog`.

## API d'achat (optionnelle)

Tu peux activer la synchronisation de chaque achat via :

```lua
Config.Api.enabled = true
Config.Api.baseUrl = "https://topserveur.fr/api/public/v1"
Config.Api.serverToken = "TON_TOKEN_SERVEUR"
Config.Api.checkVoteBeforePurchase = false
```

Les appels se font vers :

- `POST /api/public/v1/boutique/purchase`

> Si le endpoint n’existe pas encore sur ton backend, laisse `Config.Api.enabled = false` (comportement par défaut).

## Articles personnalisés

`Config.ShopCatalog` supporte :

- catégories,
- articles,
- description par langue (`fr`, `en`),
- prix,
- commandes de récompense (`command`),
- prix max par commande.

Tu peux remplacer entièrement `Config.ShopCatalog` pour brancher tes données DB ou ton panneau d’admin.

## Events

- `topserveur_boutique:server:purchase` (serveur) : évènement interne appelé par le menu client.
- `topserveur_boutique:client:purchaseResult` (client) : retour succès/erreur.

## Notes

- `Config.Menus.maxQuantityPerPurchase` limite la quantité maximale.
- `Config.Menus.autoCloseSeconds` ferme automatiquement le menu après un achat réussi.
- `Config.Notification` ajuste la durée des notifs `ox_lib`.
