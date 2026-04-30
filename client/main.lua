local isOpen = false
local view = 'categories'
local selectedCategory = 1
local selectedItem = 1
local playerPoints = 0

local function t(key, ...)
  local locale = Locales[Config.Locale] or Locales.fr or {}
  local value = locale[key] or key
  if select('#', ...) > 0 then
    return value:format(...)
  end
  return value
end

local function notify(message)
  if Config.Messages.useChat then
    TriggerEvent('chat:addMessage', {
      args = { Config.Messages.prefix, message }
    })
  else
    BeginTextCommandThefeedPost('STRING')
    AddTextComponentSubstringPlayerName(message)
    EndTextCommandThefeedPostTicker(false, false)
  end
end

local function drawText(x, y, scale, text, r, g, b, a, align)
  SetTextFont(4)
  SetTextScale(scale, scale)
  SetTextColour(r or 255, g or 255, b or 255, a or 255)
  SetTextCentre(align == 'center')
  SetTextRightJustify(align == 'right')
  BeginTextCommandDisplayText('STRING')
  AddTextComponentSubstringPlayerName(text)
  EndTextCommandDisplayText(x, y)
end

local function drawPanel(x, y, w, h, color)
  DrawRect(x + w / 2, y + h / 2, w, h, color.r, color.g, color.b, color.a)
end

local function categories()
  return Config.Shop or {}
end

local function currentCategory()
  return categories()[selectedCategory]
end

local function currentItems()
  local category = currentCategory()
  return category and category.items or {}
end

local function currentItem()
  return currentItems()[selectedItem]
end

local function clampSelection()
  local categoryCount = #categories()
  if categoryCount < 1 then
    selectedCategory = 1
    selectedItem = 1
    return
  end

  if selectedCategory < 1 then selectedCategory = categoryCount end
  if selectedCategory > categoryCount then selectedCategory = 1 end

  local itemCount = #currentItems()
  if itemCount < 1 then
    selectedItem = 1
    return
  end

  if selectedItem < 1 then selectedItem = itemCount end
  if selectedItem > itemCount then selectedItem = 1 end
end

local function closeMenu()
  isOpen = false
  view = 'categories'
end

local function openMenu()
  isOpen = true
  view = 'categories'
  selectedCategory = 1
  selectedItem = 1
  TriggerServerEvent('topserveur_boutique:server:requestBalance')
end

local function toggleMenu()
  if isOpen then
    closeMenu()
  else
    openMenu()
  end
end

RegisterCommand(Config.Command, function()
  toggleMenu()
end, false)

if Config.KeyMapping.enabled then
  RegisterKeyMapping(Config.Command, Config.KeyMapping.description or t('open_hint'), 'keyboard', Config.KeyMapping.key or 'F7')
end

RegisterNetEvent('topserveur_boutique:client:setBalance', function(points)
  playerPoints = tonumber(points) or 0
end)

RegisterNetEvent('topserveur_boutique:client:notify', function(message)
  notify(message)
end)

local function buySelectedItem()
  local category = currentCategory()
  local item = currentItem()
  if not category or not item then
    notify(t('invalid_item'))
    return
  end

  TriggerServerEvent('topserveur_boutique:server:purchaseItem', category.id, item.id)
  notify(t('purchase_sent'))
end

local function handleControls()
  if IsControlJustPressed(0, 172) then -- arrow up
    if view == 'categories' then
      selectedCategory = selectedCategory - 1
    else
      selectedItem = selectedItem - 1
    end
  elseif IsControlJustPressed(0, 173) then -- arrow down
    if view == 'categories' then
      selectedCategory = selectedCategory + 1
    else
      selectedItem = selectedItem + 1
    end
  elseif IsControlJustPressed(0, 191) then -- enter
    if view == 'categories' then
      view = 'items'
      selectedItem = 1
    else
      buySelectedItem()
    end
  elseif IsControlJustPressed(0, 177) then -- backspace
    if view == 'items' then
      view = 'categories'
    else
      closeMenu()
    end
  end
  clampSelection()
end

local function drawMenu()
  local x, y = 0.075, 0.16
  local w = 0.32
  local headerH = 0.075
  local rowH = 0.045
  local maxRows = Config.Menu.maxVisibleItems or 7
  local bg = Config.Menu.background or { r = 8, g = 13, b = 24, a = 220 }
  local accent = Config.Menu.accent or { r = 139, g = 44, b = 255, a = 220 }
  local rows = view == 'categories' and categories() or currentItems()

  drawPanel(x, y, w, headerH, accent)
  drawText(x + 0.015, y + 0.012, 0.46, Config.Menu.title or t('menu_title'), 255, 255, 255, 255)
  drawText(x + 0.015, y + 0.044, 0.28, Config.Menu.subtitle or 'TopServeur.fr', 220, 210, 255, 255)
  drawText(x + w - 0.015, y + 0.044, 0.25, t('points_balance', playerPoints, Config.Currency.label), 220, 210, 255, 255, 'right')

  local startY = y + headerH
  drawPanel(x, startY, w, rowH * (maxRows + 1.5), bg)

  if #rows < 1 then
    drawText(x + 0.015, startY + 0.014, 0.32, t('no_items'), 210, 210, 220, 255)
    return
  end

  local selectedIndex = view == 'categories' and selectedCategory or selectedItem
  local first = math.max(1, selectedIndex - maxRows + 1)
  local last = math.min(#rows, first + maxRows - 1)

  for i = first, last do
    local row = rows[i]
    local rowY = startY + ((i - first) * rowH)
    local selected = i == selectedIndex
    if selected then
      drawPanel(x + 0.004, rowY + 0.002, w - 0.008, rowH - 0.004, accent)
    end

    local label = row.label or row.id or 'Item'
    if view == 'items' then
      label = ('%s %s'):format(row.icon or Config.Currency.icon or '', label)
    end

    drawText(x + 0.015, rowY + 0.011, 0.32, label, 255, 255, 255, 255)

    if view == 'items' then
      drawText(x + w - 0.015, rowY + 0.011, 0.3, ('%s %s'):format(row.price or 0, Config.Currency.label), 220, 210, 255, 255, 'right')
    end
  end

  local footerY = startY + (maxRows * rowH) + 0.008
  local help = view == 'items' and (currentItem() and currentItem().description or '') or t('menu_help')
  drawText(x + 0.015, footerY, 0.25, help, 180, 190, 210, 255)
  drawText(x + 0.015, footerY + 0.025, 0.22, t('controls'), 140, 150, 175, 255)
end

CreateThread(function()
  while true do
    if isOpen then
      Wait(0)
      DisableControlAction(0, 1, true)
      DisableControlAction(0, 2, true)
      handleControls()
      drawMenu()
    else
      Wait(250)
    end
  end
end)
