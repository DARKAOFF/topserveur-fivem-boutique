local function normalizeId(value)
  if type(value) ~= "string" then
    return ""
  end
  return value:gsub("^%s+", ""):gsub("%s+$", "")
end

local function toNumber(value, fallback)
  local numberValue = tonumber(value)
  if numberValue == nil then
    return fallback
  end
  return numberValue
end

local function getCategoryById(id)
  for _, category in ipairs(Config.ShopCatalog or {}) do
    if category.id == id then
      return category
    end
  end
  return nil
end

local function getItemById(category, itemId)
  if type(category) ~= "table" or type(category.items) ~= "table" then
    return nil
  end

  for _, item in ipairs(category.items) do
    if item.id == itemId then
      return item
    end
  end

  return nil
end

RegisterNetEvent("topserveur_boutique:server:purchase")
AddEventHandler("topserveur_boutique:server:purchase", function(categoryId, itemId, quantity)
  local sourcePlayer = source
  local normalizedCategory = normalizeId(categoryId)
  local normalizedItem = normalizeId(itemId)
  local normalizedQuantity = toNumber(quantity, 1)

  if normalizedCategory == "" or normalizedItem == "" then
    TriggerClientEvent("topserveur_boutique:client:purchaseResult", sourcePlayer, false, "catégorie/article invalide.")
    return
  end

  if normalizedQuantity < 1 then
    TriggerClientEvent("topserveur_boutique:client:purchaseResult", sourcePlayer, false, "Quantité invalide.")
    return
  end

  local maxQuantity = tonumber(Config.Menus.maxQuantityPerPurchase) or 20
  if normalizedQuantity > maxQuantity then
    TriggerClientEvent(
      "topserveur_boutique:client:purchaseResult",
      sourcePlayer,
      false,
      ("Quantité max autorisée : %s"):format(maxQuantity)
    )
    return
  end

  local category = getCategoryById(normalizedCategory)
  if not category then
    TriggerClientEvent("topserveur_boutique:client:purchaseResult", sourcePlayer, false, "Catégorie introuvable.")
    return
  end

  local item = getItemById(category, normalizedItem)
  if not item then
    TriggerClientEvent("topserveur_boutique:client:purchaseResult", sourcePlayer, false, "Article introuvable.")
    return
  end

  local playerName = GetPlayerName(sourcePlayer)
  local line = ("[TopServeur Boutique] %s achète %sx%s (%s)"):format(
    playerName or ("player:" .. tostring(sourcePlayer)),
    normalizedQuantity,
    item.id,
    category.id
  )
  print(line)

  local ok, err = pcall(function()
    if type(Config.OnPurchase) == "function" then
      Config.OnPurchase(sourcePlayer, item, category, normalizedQuantity)
    else
      print("[TopServeur Boutique] Config.OnPurchase non configuré : aucune récompense personnalisée.")
    end
  end)

  if not ok then
    local errorText = ("Erreur lors du traitement de la récompense : %s"):format(tostring(err))
    print(("[TopServeur Boutique] %s"):format(errorText))
    TriggerClientEvent("topserveur_boutique:client:purchaseResult", sourcePlayer, false, errorText)
    return
  end

  -- Envoie éventuel de l’événement d’achat vers TopServeur via une API optionnelle.
  if Config.Api.enabled and Config.Api.baseUrl and Config.Api.baseUrl ~= "" then
    local payload = json.encode({
      playerId = tostring(sourcePlayer),
      playerName = playerName,
      categoryId = category.id,
      itemId = item.id,
      quantity = normalizedQuantity,
      serverToken = Config.Api.serverToken,
      source = "topserveur_boutique",
    })

    PerformHttpRequest(
      ("%s/boutique/purchase"):format(Config.Api.baseUrl),
      function(statusCode, body)
        if statusCode and statusCode >= 200 and statusCode < 300 then
          print(("[TopServeur Boutique] Sync OK status=%s"):format(statusCode))
        else
          print(("[TopServeur Boutique] Sync KO status=%s body=%s"):format(tostring(statusCode), tostring(body)))
        end
      end,
      "POST",
      payload,
      { ["Content-Type"] = "application/json" }
    )
  end

  TriggerClientEvent("topserveur_boutique:client:purchaseResult", sourcePlayer, true, "Achat validé.")
end)
