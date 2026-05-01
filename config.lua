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

-- Détection automatique du framework pour un hook multi-framework.
local function getFramework()
  if GetResourceState("es_extended") == "started" then
    return "esx"
  end
  if GetResourceState("qb-core") == "started" then
    return "qbcore"
  end
  if GetResourceState("ox_core") == "started" then
    return "oxcore"
  end
  return "standalone"
end

local function getPlayerObject(source, framework)
  local playerId = tonumber(source or -1)
  if not playerId or playerId <= 0 then
    return nil
  end

  if framework == "esx" and GetResourceState("es_extended") == "started" then
    local ok, result = pcall(function()
      if exports["es_extended"] and exports["es_extended"].getSharedObject then
        return exports["es_extended"].getSharedObject()
      end
      if _G.ESX then
        return _G.ESX
      end
      return nil
    end)
    if ok and result then
      local getPlayer = result.GetPlayerFromId
      if type(getPlayer) == "function" then
        return getPlayer(result, playerId)
      end
    end
  end

  if framework == "qbcore" and GetResourceState("qb-core") == "started" then
    local ok, core = pcall(function()
      if exports["qb-core"] and exports["qb-core"].GetCoreObject then
        return exports["qb-core"].GetCoreObject()
      end
      return nil
    end)
    if ok and core and core.Functions then
      return core.Functions.GetPlayer(playerId)
    end
  end

  if framework == "oxcore" and GetResourceState("ox_core") == "started" then
    local player = nil
    local ok = pcall(function()
      if exports["ox_core"] and exports["ox_core"].getPlayer then
        player = exports["ox_core"].getPlayer(playerId)
      elseif exports["ox_core"] and exports["ox_core"].GetPlayer then
        player = exports["ox_core"].GetPlayer(playerId)
      end
    end)
    if ok then
      return player
    end
  end

  return nil
end

local function executeCommandTemplate(command, playerId)
  if type(command) ~= "string" then
    return
  end
  local safeId = tostring(playerId or -1)
  local safeCommand = command:gsub("{player}", safeId)
  safeCommand = safeCommand:gsub("{source}", safeId)
  if safeCommand == "" then
    return
  end
  ExecuteCommand(safeCommand)
end

local function grantMoney(playerObj, framework, playerId, reward)
  if type(reward.amount) ~= "number" then
    return
  end
  local amount = reward.amount
  if framework == "esx" and playerObj and playerObj.addMoney then
    playerObj.addMoney(amount)
    return
  end
  if framework == "esx" and playerObj.addAccountMoney then
    playerObj.addAccountMoney(reward.currency or "money", amount)
    return
  end
  if framework == "qbcore" and playerObj and playerObj.Functions then
    local account = reward.account or "cash"
    playerObj.Functions.AddMoney(account, amount, "topserveur_boutique")
    return
  end
  if framework == "oxcore" and playerObj and playerObj.addMoney then
    pcall(function()
      playerObj.addMoney(amount)
    end)
    return
  end

  executeCommandTemplate(
    ("add_money {player} %s"):format(amount),
    playerId
  )
end

local function grantItem(playerObj, framework, playerId, reward)
  local itemName = tostring(reward.item or "")
  local amount = tonumber(reward.amount) or 1
  if itemName == "" or amount <= 0 then
    return
  end

  if framework == "esx" and playerObj and playerObj.addInventoryItem then
    playerObj.addInventoryItem(itemName, amount)
    return
  end
  if framework == "qbcore" and playerObj and playerObj.Functions then
    playerObj.Functions.AddItem(itemName, amount)
    return
  end
  if framework == "oxcore" then
    local ok = pcall(function()
      if exports["ox_inventory"] and exports["ox_inventory"].AddItem then
        exports["ox_inventory"]:AddItem(playerId, itemName, amount)
        return
      end
    end)
    if ok then
      return
    end
  end

  executeCommandTemplate(
    ("item add {player} %s %s"):format(itemName, amount),
    playerId
  )
end

function Config.OnPurchase(source, item, category, quantity)
  local playerId = tostring(source or -1)
  local framework = getFramework()
  local playerObj = getPlayerObject(source, framework)
  quantity = quantity or 1

  print(("TopServeur Boutique purchase: player=%s item=%s category=%s"):format(
    playerId,
    item and item.id or "unknown",
    category and category.id or "unknown"
  ))

  if playerObj then
    print(("[TopServeur Boutique] Framework détecté: %s"):format(framework))
  else
    print("[TopServeur Boutique] Aucun objet joueur framework détecté; fallback commandes.")
  end

  for _, reward in ipairs(item and item.rewards or {}) do
    local rewardType = tostring(reward.type or "command")
    if rewardType == "money" or rewardType == "cash" then
      grantMoney(playerObj, framework, source, reward)
    elseif rewardType == "command" then
      executeCommandTemplate(reward.command, source)
    elseif rewardType == "item" then
      grantItem(playerObj, framework, source, reward)
    else
      executeCommandTemplate(reward.command, source)
    end
  end
end

Config.Menus = {
  maxQuantityPerPurchase = tonumber(GetConvar("topserveur_boutique_max_qty", "20")) or 20,
  autoCloseSeconds = tonumber(GetConvar("topserveur_boutique_autoclose", "3")) or 3,
}
