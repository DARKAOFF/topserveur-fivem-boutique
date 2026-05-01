local locale = Config.Locale or "fr"

local function t(key, fallback)
  return (Config.LocaleText and Config.LocaleText[locale] and Config.LocaleText[locale][key]) or fallback
end

local LocaleText = {
  fr = {
    loading = "Chargement...",
    noItems = "Aucun article disponible.",
    openBoutique = "Ouvrir la boutique",
    closeBoutique = "Fermer la boutique",
    purchaseTitle = "Confirmer l’achat",
    purchaseHint = "Confirme la quantité et valide.",
    quantity = "Quantité",
    validate = "Valider",
    cancel = "Annuler",
    purchaseSuccess = "Achat effectué, récompense en cours d’attribution.",
    notFound = "Article introuvable.",
    purchaseError = "Impossible de terminer l’achat.",
  },
  en = {
    loading = "Loading...",
    noItems = "No items available.",
    openBoutique = "Open shop",
    closeBoutique = "Close shop",
    purchaseTitle = "Confirm purchase",
    purchaseHint = "Choose quantity and validate.",
    quantity = "Quantity",
    validate = "Confirm",
    cancel = "Cancel",
    purchaseSuccess = "Purchase sent, reward is being granted.",
    notFound = "Item not found.",
    purchaseError = "Unable to complete purchase.",
  },
}

Config.LocaleText = LocaleText

if not lib then
  print("[TopServeur Boutique] ox_lib introuvable. Installe le resource ox_lib et recommence.")
  return
end

local function notify(level, message)
  local title = t("openBoutique", "TopServeur Boutique")
  if lib and lib.notify then
    lib.notify({
      title = title,
      description = message,
      type = level,
      duration = Config.Notification.duration,
    })
    return
  end
  print(("[%s] %s"):format(title, message))
end

local function getCategoryIcon(iconName)
  return iconName or "box"
end

local function buildItemsContext(category)
  local contextId = ("tsb:category:%s"):format(category.id)
  local menuItems = {}

  for _, item in ipairs(category.items or {}) do
    local desc = (item.description and (item.description[locale] or item.description.en)) or ""
    local price = (item.price or 0)
    local itemTitle = item.label and (item.label[locale] or item.label.en) or item.id

    table.insert(menuItems, {
      title = itemTitle,
      description = ("%s | %s$"):format(desc, price),
      icon = item.icon or "tag",
      onSelect = function()
        if lib and lib.inputDialog then
          local confirm = lib.inputDialog(
            t("purchaseTitle", "Confirmer l’achat"),
            {
              {
                type = "number",
                label = t("quantity", "Quantité"),
                default = 1,
                min = 1,
                max = Config.Menus.maxQuantityPerPurchase,
              },
            }
          )
          if type(confirm) ~= "table" then
            return
          end

          local quantity = tonumber(confirm[1]) or 1
          TriggerServerEvent("topserveur_boutique:server:purchase", category.id, item.id, quantity)
          return
        end

        TriggerServerEvent("topserveur_boutique:server:purchase", category.id, item.id, 1)
      end,
    })
  end

  if #menuItems == 0 then
    table.insert(menuItems, {
      title = t("noItems", "Aucun article disponible."),
      disabled = true,
      icon = "ban",
    })
  end

  lib.registerContext({
    id = contextId,
    title = (category.label and (category.label[locale] or category.label.en)) or category.id,
    options = menuItems,
  })
end

local function buildRootContext()
  local menuItems = {}

  for _, category in ipairs(Config.ShopCatalog or {}) do
    local categoryTitle = category.label and (category.label[locale] or category.label.en) or category.id
    local categoryDesc = category.description and (category.description[locale] or category.description.en) or ""
    local categoryId = ("tsb:category:%s"):format(category.id)

    buildItemsContext(category)

    table.insert(menuItems, {
      title = categoryTitle,
      description = categoryDesc,
      icon = getCategoryIcon(category.icon),
      onSelect = function()
        lib.showContext(categoryId)
      end,
    })
  end

  if #menuItems == 0 then
    table.insert(menuItems, {
      title = t("noItems", "Aucun article disponible."),
      disabled = true,
      icon = "ban",
    })
  end

  lib.registerContext({
    id = "tsb:main",
    title = "TopServeur Boutique",
    options = menuItems,
  })
end

local function openShop()
  if not lib or not lib.showContext then
    notify("error", "ox_lib indisponible.")
    return
  end

  lib.closeInputDialog()
  locale = Config.Locale or "fr"
  buildRootContext()
  lib.showContext("tsb:main")
end

RegisterCommand(Config.Command, function()
  openShop()
end, false)

if Config.KeyMapping and Config.KeyMapping.enabled then
  RegisterKeyMapping(
    Config.Command,
    Config.KeyMapping.description or t("openBoutique", "Ouvrir la boutique"),
    "keyboard",
    Config.KeyMapping.key or "F7"
  )
end

RegisterNetEvent("topserveur_boutique:client:purchaseResult", function(success, message)
  if success then
    notify("success", message or t("purchaseSuccess", "Achat effectué, récompense en cours d’attribution."))
    if Config.Menus.autoCloseSeconds and Config.Menus.autoCloseSeconds > 0 then
      SetTimeout(Config.Menus.autoCloseSeconds * 1000, function()
        lib.hideContext()
      end)
    end
  else
    notify("error", message or t("purchaseError", "Impossible de terminer l’achat."))
  end
end)

