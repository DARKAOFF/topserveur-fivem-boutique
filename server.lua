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

local function handlePurchase(categoryId, itemId, quantity)
  local sourcePlayer = source
  local normalizedCategory = normalizeId(categoryId)
  local normalizedItem = normalizeId(itemId)
  local normalizedQuantity = toNumber(quantity, 1)

  if normalizedCategory == "" or normalizedItem == "" then
    TriggerClientEvent("upserveur_boutique:client:purchaseResult", sourcePlayer, false, "categorie/article invalide.")
    return
  end

  if normalizedQuantity < 1 then
    TriggerClientEvent("upserveur_boutique:client:purchaseResult", sourcePlayer, false, "Quantite invalide.")
    return
  end

  local maxQuantity = tonumber(Config.Menus.maxQuantityPerPurchase) or 20
  if normalizedQuantity > maxQuantity then
    TriggerClientEvent(
      "upserveur_boutique:client:purchaseResult",
      sourcePlayer,
      false,
      ("Quantite max autorisee : %s"):format(maxQuantity)
    )
    return
  end

  local category = getCategoryById(normalizedCategory)
  if not category then
    TriggerClientEvent("upserveur_boutique:client:purchaseResult", sourcePlayer, false, "Categorie introuvable.")
    return
  end

  local item = getItemById(category, normalizedItem)
  if not item then
    TriggerClientEvent("upserveur_boutique:client:purchaseResult", sourcePlayer, false, "Article introuvable.")
    return
  end

  local playerName = GetPlayerName(sourcePlayer)
  local line = ("[UpServeur Boutique] %s achete %sx%s (%s)"):format(
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
      print("[UpServeur Boutique] Config.OnPurchase non configure : aucune recompense personnalisee.")
    end
  end)

  if not ok then
    local errorText = ("Erreur lors du traitement de la recompense : %s"):format(tostring(err))
    print(("[UpServeur Boutique] %s"):format(errorText))
    TriggerClientEvent("upserveur_boutique:client:purchaseResult", sourcePlayer, false, errorText)
    return
  end

  if Config.Api.enabled and Config.Api.baseUrl and Config.Api.baseUrl ~= "" then
    local payload = json.encode({
      playerId = tostring(sourcePlayer),
      playerName = playerName,
      categoryId = category.id,
      itemId = item.id,
      quantity = normalizedQuantity,
      serverToken = Config.Api.serverToken,
      source = "upserveur_boutique",
    })

    PerformHttpRequest(
      ("%s/boutique/purchase"):format(Config.Api.baseUrl),
      function(statusCode, body)
        if statusCode and statusCode >= 200 and statusCode < 300 then
          print(("[UpServeur Boutique] Sync OK status=%s"):format(statusCode))
        else
          print(("[UpServeur Boutique] Sync KO status=%s body=%s"):format(tostring(statusCode), tostring(body)))
        end
      end,
      "POST",
      payload,
      { ["Content-Type"] = "application/json" }
    )
  end

  TriggerClientEvent("upserveur_boutique:client:purchaseResult", sourcePlayer, true, "Achat valide.")
end

RegisterNetEvent("upserveur_boutique:server:purchase")
AddEventHandler("upserveur_boutique:server:purchase", handlePurchase)

RegisterNetEvent("topserveur_boutique:server:purchase")
AddEventHandler("topserveur_boutique:server:purchase", handlePurchase)
