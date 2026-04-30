local balances = {}

local function t(key, ...)
  local locale = Locales[Config.Locale] or Locales.fr or {}
  local value = locale[key] or key
  if select('#', ...) > 0 then
    return value:format(...)
  end
  return value
end

local function debugPrint(message)
  if Config.Debug then
    print(('[TopServeur Boutique] %s'):format(message))
  end
end

local function getIdentifier(source)
  local wanted = Config.Api.playerIdentifierType or 'license'
  if wanted == 'name' then
    return GetPlayerName(source)
  end

  for _, identifier in ipairs(GetPlayerIdentifiers(source)) do
    if identifier:find(wanted .. ':', 1, true) == 1 then
      return identifier
    end
  end

  return GetPlayerIdentifier(source, 0)
end

local function findCategory(categoryId)
  for _, category in ipairs(Config.Shop or {}) do
    if category.id == categoryId then
      return category
    end
  end
  return nil
end

local function findItem(category, itemId)
  if not category then return nil end
  for _, item in ipairs(category.items or {}) do
    if item.id == itemId then
      return item
    end
  end
  return nil
end

local function notify(source, message)
  TriggerClientEvent('topserveur_boutique:client:notify', source, message)
end

local function getBalance(source)
  local identifier = getIdentifier(source) or tostring(source)
  balances[identifier] = balances[identifier] or 0
  return balances[identifier], identifier
end

local function setBalance(identifier, amount)
  balances[identifier] = math.max(0, tonumber(amount) or 0)
end

local function hasEnoughPoints(source, price)
  local balance = getBalance(source)
  return balance >= (tonumber(price) or 0)
end

local function removePoints(source, price)
  local balance, identifier = getBalance(source)
  local nextBalance = math.max(0, balance - (tonumber(price) or 0))
  setBalance(identifier, nextBalance)
  TriggerClientEvent('topserveur_boutique:client:setBalance', source, nextBalance)
end

local function checkVoteRequirement(source)
  if not Config.Api.enabled or not Config.Api.checkVoteBeforePurchase then
    return true, t('api_disabled')
  end

  -- Placeholder volontairement serveur-only.
  -- Branche ici ton appel HTTP vers https://topserveur.fr/api/public/v1/votes/check
  -- avec Config.Api.serverToken et getIdentifier(source) si tu veux bloquer l'achat sans vote.
  return true, 'ok'
end

RegisterNetEvent('topserveur_boutique:server:requestBalance', function()
  local source = source
  local balance = getBalance(source)
  TriggerClientEvent('topserveur_boutique:client:setBalance', source, balance)
end)

RegisterNetEvent('topserveur_boutique:server:purchaseItem', function(categoryId, itemId)
  local source = source
  local category = findCategory(categoryId)
  local item = findItem(category, itemId)

  if not item then
    notify(source, t('purchase_refused', t('invalid_item')))
    return
  end

  local voteAllowed, voteMessage = checkVoteRequirement(source)
  if not voteAllowed then
    notify(source, t('purchase_refused', voteMessage or t('vote_required')))
    return
  end

  if not hasEnoughPoints(source, item.price or 0) then
    notify(source, t('purchase_refused', t('not_enough_points')))
    return
  end

  removePoints(source, item.price or 0)
  Config.OnPurchase(source, item, category)
  notify(source, t('purchase_success', item.label or item.id))
  debugPrint(('purchase source=%s category=%s item=%s'):format(source, categoryId, itemId))
end)

RegisterCommand('tsboutique_addpoints', function(source, args)
  if source ~= 0 and not IsPlayerAceAllowed(source, Config.Permissions.aceAdmin) then
    return
  end

  local target = tonumber(args[1] or '')
  local amount = tonumber(args[2] or '')
  if not target or not amount or not GetPlayerName(target) then
    if source == 0 then
      print('Usage: tsboutique_addpoints <playerId> <amount>')
    end
    return
  end

  local balance, identifier = getBalance(target)
  setBalance(identifier, balance + amount)
  TriggerClientEvent('topserveur_boutique:client:setBalance', target, balance + amount)
  notify(target, ('+%s %s'):format(amount, Config.Currency.label))
end, true)

exports('GetPlayerBoutiquePoints', function(source)
  return getBalance(source)
end)

exports('SetPlayerBoutiquePoints', function(source, amount)
  local _, identifier = getBalance(source)
  setBalance(identifier, amount)
  TriggerClientEvent('topserveur_boutique:client:setBalance', source, balances[identifier])
end)
