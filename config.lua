Config = {}

Config.Locale = 'fr'
Config.Debug = false

Config.Command = 'boutique'
Config.KeyMapping = {
  enabled = true,
  key = 'F7',
  description = 'Ouvrir la boutique TopServeur'
}

Config.Menu = {
  title = 'Boutique',
  subtitle = 'TopServeur.fr',
  maxVisibleItems = 7,
  accent = { r = 139, g = 44, b = 255, a = 220 },
  background = { r = 8, g = 13, b = 24, a = 220 }
}

Config.Currency = {
  label = 'points',
  icon = '⭐'
}

Config.Api = {
  enabled = false,
  baseUrl = 'https://topserveur.fr/api/public/v1',
  serverToken = 'CHANGE_ME',
  checkVoteBeforePurchase = false,
  playerIdentifierType = 'license' -- license, steam, discord, fivem, name
}

Config.Permissions = {
  aceAdmin = 'topserveur.boutique.admin'
}

Config.Messages = {
  useChat = true,
  prefix = '^5[TopServeur Boutique]^7'
}

Config.Shop = {
  {
    id = 'packs',
    label = 'Packs',
    description = 'Packs de démarrage et avantages serveur',
    items = {
      {
        id = 'starter_pack',
        label = 'Pack starter',
        description = 'Un pack idéal pour commencer sur le serveur.',
        price = 500,
        icon = '🎁',
        metadata = {
          image = '',
          rarity = 'standard'
        },
        rewards = {
          { type = 'money', amount = 25000 },
          { type = 'item', name = 'bread', count = 5 }
        }
      },
      {
        id = 'vip_week',
        label = 'VIP 7 jours',
        description = 'Accès VIP temporaire, à brancher sur ton système de permissions.',
        price = 1500,
        icon = '👑',
        rewards = {
          { type = 'command', command = 'addvip {player} 7' }
        }
      }
    }
  },
  {
    id = 'vehicles',
    label = 'Véhicules',
    description = 'Véhicules et avantages RP',
    items = {
      {
        id = 'sultan',
        label = 'Sultan RS',
        description = 'Exemple de véhicule boutique à adapter à ton garage.',
        price = 3000,
        icon = '🚗',
        rewards = {
          { type = 'vehicle', model = 'sultanrs' }
        }
      }
    }
  }
}

-- Hook serveur appelé après validation d'un achat.
-- Remplace ce contenu pour brancher ESX, QBCore, ox_inventory, ton garage, etc.
function Config.OnPurchase(source, item, category)
  if Config.Debug then
    print(('[TopServeur Boutique] Achat valide: source=%s category=%s item=%s'):format(source, category.id, item.id))
  end

  for _, reward in ipairs(item.rewards or {}) do
    if reward.type == 'command' and reward.command then
      local command = reward.command:gsub('{player}', tostring(source))
      ExecuteCommand(command)
    elseif reward.type == 'money' then
      TriggerEvent('topserveur_boutique:rewardMoney', source, reward.amount or 0)
    elseif reward.type == 'item' then
      TriggerEvent('topserveur_boutique:rewardItem', source, reward.name, reward.count or 1)
    elseif reward.type == 'vehicle' then
      TriggerEvent('topserveur_boutique:rewardVehicle', source, reward.model)
    end
  end
end
