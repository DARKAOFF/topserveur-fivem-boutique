# TopServeur FiveM Boutique

Ressource FiveM officielle pour proposer une boutique en jeu configurable, liée à l'écosystème TopServeur.fr.

Cette ressource correspond au **type boutique** : elle ajoute un menu client, une commande, une keymap, une configuration Lua complète, une gestion du contenu boutique et des locales FR/EN.

## Fonctionnalités

- Menu boutique client standalone, sans dépendance obligatoire.
- Commande configurable, par défaut `/boutique`.
- Keymap configurable, par défaut `F7`.
- `config.lua` centralisé pour les paramètres, catégories, items, prix et récompenses.
- Locales françaises et anglaises.
- Events serveur pour brancher ESX, QBCore, ox_inventory, garage custom ou commandes.
- Exports serveur pour lire ou modifier les points boutique.
- Préparation API TopServeur côté serveur uniquement.

## Installation

1. Télécharge le repo en ZIP ou clone-le dans ton dossier `resources`.
2. Renomme le dossier en `topserveur_boutique`.
3. Ajoute dans ton `server.cfg` :

```cfg
ensure topserveur_boutique
```

4. Configure `config.lua` :

```lua
Config.Locale = 'fr'
Config.Command = 'boutique'
Config.KeyMapping.key = 'F7'
Config.Api.serverToken = 'TON_TOKEN_TOPSERVEUR'
```

## Configuration boutique

Les catégories et articles se configurent dans `Config.Shop`.

```lua
Config.Shop = {
  {
    id = 'packs',
    label = 'Packs',
    description = 'Packs de démarrage',
    items = {
      {
        id = 'starter_pack',
        label = 'Pack starter',
        description = 'Un pack idéal pour commencer.',
        price = 500,
        icon = '🎁',
        rewards = {
          { type = 'money', amount = 25000 },
          { type = 'item', name = 'bread', count = 5 }
        }
      }
    }
  }
}
```

## Brancher les récompenses

Par défaut, la ressource déclenche des events serveur pour te laisser connecter ton framework.

Dans `config.lua`, adapte :

```lua
function Config.OnPurchase(source, item, category)
  for _, reward in ipairs(item.rewards or {}) do
    if reward.type == 'money' then
      TriggerEvent('topserveur_boutique:rewardMoney', source, reward.amount or 0)
    elseif reward.type == 'item' then
      TriggerEvent('topserveur_boutique:rewardItem', source, reward.name, reward.count or 1)
    elseif reward.type == 'vehicle' then
      TriggerEvent('topserveur_boutique:rewardVehicle', source, reward.model)
    elseif reward.type == 'command' then
      ExecuteCommand(reward.command:gsub('{player}', tostring(source)))
    end
  end
end
```

Exemple ESX :

```lua
AddEventHandler('topserveur_boutique:rewardMoney', function(source, amount)
  local xPlayer = ESX.GetPlayerFromId(source)
  if xPlayer then
    xPlayer.addMoney(amount)
  end
end)

AddEventHandler('topserveur_boutique:rewardItem', function(source, itemName, count)
  local xPlayer = ESX.GetPlayerFromId(source)
  if xPlayer then
    xPlayer.addInventoryItem(itemName, count)
  end
end)
```

## Commandes

- `/boutique` : ouvre/ferme le menu boutique.
- `/tsboutique_addpoints <playerId> <amount>` : ajoute des points à un joueur, console ou ACE `topserveur.boutique.admin`.

## Keymap

La touche par défaut est `F7`.

Les joueurs peuvent la modifier dans les paramètres GTA/FiveM, section key bindings.

## Exports serveur

```lua
exports['topserveur_boutique']:GetPlayerBoutiquePoints(source)
exports['topserveur_boutique']:SetPlayerBoutiquePoints(source, amount)
```

## Locales

Fichiers disponibles :

- `locales/fr.lua`
- `locales/en.lua`

Change la langue avec :

```lua
Config.Locale = 'en'
```

## API TopServeur

La configuration API est volontairement côté serveur uniquement :

```lua
Config.Api = {
  enabled = false,
  baseUrl = 'https://topserveur.fr/api/public/v1',
  serverToken = 'CHANGE_ME',
  checkVoteBeforePurchase = false,
  playerIdentifierType = 'license'
}
```

Ne mets jamais de secret sensible côté client.

## Types de ressources

- `topserveur_vote` : plugin de vote simple pour recevoir les votes et déclencher des récompenses.
- `topserveur_boutique` : version boutique avec menu client, contenu configurable, points et hooks de récompenses.

## Sécurité

- La validation d'achat se fait côté serveur.
- Les points sont manipulés côté serveur.
- Le client ne peut pas déclencher directement une récompense sans passer par l'event serveur.
- Branche ta vraie base de points ou ton framework dans `Config.OnPurchase` pour une production complète.
