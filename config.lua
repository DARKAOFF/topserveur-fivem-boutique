Config = Config or {}

Config.Locale = GetConvar("topserveur_boutique_locale", "fr")

Config.Command = GetConvar("topserveur_boutique_command", "boutique")
Config.KeyMapping = {
  enabled = GetConvar("topserveur_boutique_keymap", "1") == "1",
  key = GetConvar("topserveur_boutique_key", "F7"),
  description = "Ouvrir la boutique TopServeur",
}

Config.Notification = {
  duration = tonumber(GetConvar("topserveur_boutique_notify_duration", "4500")) or 4500,
}

Config.Api = {
  enabled = GetConvar("topserveur_boutique_api", "false") == "true",
  baseUrl = GetConvar("topserveur_boutique_api_url", "https://topserveur.fr/api/public/v1"),
  serverToken = GetConvar("topserveur_boutique_server_token", ""),
  checkVoteBeforePurchase = GetConvar("topserveur_boutique_check_vote", "false") == "true",
}

Config.ShopCatalog = {
  {
    id = "packs",
    label = {
      fr = "Packs",
      en = "Packs",
    },
    description = {
      fr = "Packs de lancement, boosts et récompenses VIP",
      en = "Starter packs, boosts and VIP rewards",
    },
    icon = "package",
    items = {
      {
        id = "pack_start",
        label = {
          fr = "Pack de démarrage",
          en = "Starter Pack",
        },
        description = {
          fr = "Cash + voiture + kit de base",
          en = "Cash + vehicle + starter kit",
        },
        price = 9,
        icon = "coins",
        command = "give_money {player} 50000",
        rewards = {
          { type = "money", amount = 50000, currency = "USD" },
          { type = "command", command = "give_vehicle {player} comet2" },
        },
      },
      {
        id = "pack_vip",
        label = {
          fr = "Pack VIP",
          en = "VIP Pack",
        },
        description = {
          fr = "Doublement d’expérience et accès salon privé (exemple)",
          en = "XP boost and private lounge access (example)",
        },
        price = 15,
        icon = "star",
        command = "setVip {player} 24h",
        rewards = {
          { type = "command", command = "add_ace {player} topserveur.vip allow" },
        },
      },
    },
  },
  {
    id = "vehicules",
    label = {
      fr = "Véhicules",
      en = "Vehicles",
    },
    description = {
      fr = "Garages et véhicules légers/rapides",
      en = "Vehicle garage and quick rides",
    },
    icon = "car",
    items = {
      {
        id = "veh_sultan",
        label = {
          fr = "Sultan RS",
          en = "Sultan RS",
        },
        description = {
          fr = "Ajoute un véhicule prêt-à-ranger en garage",
          en = "Add vehicle directly in garage",
        },
        price = 19,
        icon = "car-front",
        command = "vehicle add {player} sultanrs",
        rewards = {
          { type = "command", command = "vehicle add {player} sultanrs" },
        },
      },
    },
  },
}

function Config.OnPurchase(source, item, category)
  local playerId = tostring(source or -1)

  print(("TopServeur Boutique purchase: player=%s item=%s category=%s"):format(
    playerId,
    item and item.id or "unknown",
    category and category.id or "unknown"
  ))
  for _, reward in ipairs(item and item.rewards or {}) do
    if reward.type == "command" and type(reward.command) == "string" then
      ExecuteCommand(reward.command:gsub("{player}", playerId))
    end
  end
end

Config.Menus = {
  maxQuantityPerPurchase = tonumber(GetConvar("topserveur_boutique_max_qty", "20")) or 20,
  autoCloseSeconds = tonumber(GetConvar("topserveur_boutique_autoclose", "3")) or 3,
}
