local CoolDownsTable = {
    ['BARD'] = {
        ['Резонансный барьер'] = true,
        ['Марш'] = true,
        ['Соната'] = true,
        ['Щит теней'] = true,
        ['Мелодии войны'] = true,
    },
    ['NECROMANCER'] = {
        ['Щит крови'] = true,
        ['Тёмная мощь'] = true,
    },
    ['STALKER'] = {
        ['Маятник'] = true,
        ['Дымное облако'] = true,
        ['Дымное облако'] = true,
        ['Отскок'] = true,
        ['Камуфляж'] = true,
    }
}

local wtChat
local valuedText = common.CreateValuedText()
local addonName = common.GetAddonName()

local OpenConfigButton
local CommonPanel
local Row
local RowDesc
local Item
local ItemDesc

--local PanelItem = ItemsRow:GetChildUnchecked("PanelItem", false)
--local wtTimer = mainForm:CreateWidgetByDesc(wtTimerTemplate:GetWidgetDesc())

local spaceBtwRows = 5

local enemiesBuffs = {
    rowsCount = 0;
    users = {};
}

--local friendsBuffs = {}

local dndOn = false

function LogToChat(text)
    if not wtChat then
        wtChat = stateMainForm:GetChildUnchecked("ChatLog", false)
        wtChat = wtChat:GetChildUnchecked("Container", true)
        local formatVT = "<html fontname='AllodsFantasy' fontsize='14' shadow='1'><rs class='color'><r name='addonName'/><r name='text'/></rs></html>"
        valuedText:SetFormat(userMods.ToWString(formatVT))
    end

    if wtChat and wtChat.PushFrontValuedText then
        if not common.IsWString(text) then
            text = userMods.ToWString(text)
        end

        valuedText:ClearValues()
        valuedText:SetClassVal("color", "LogColorYellow")
        valuedText:SetVal("text", text)
        valuedText:SetVal("addonName", userMods.ToWString("CD: "))
        wtChat:PushFrontValuedText(valuedText)
    end
end

function ToHex(str)
    return (str:gsub('.', function (c)
        return string.format('%02X', string.byte(c))
    end))
end

function CreateConfigButton()
    OpenConfigButton = mainForm:GetChildUnchecked("OpenConfigButton", false)
    OpenConfigButton:Show(true)

    DnD.Init(OpenConfigButton, nil, true)

    common.RegisterReactionHandler(OnClickButton, 'EVENT_ON_CONFIG_BUTTON_CLICK')
    common.RegisterReactionHandler(OnRightClickButton, 'EVENT_ON_CONFIG_BUTTON_RIGHT_CLICK')

    common.RegisterEventHandler(OnAoPanelStart, 'AOPANEL_START')
end

function GetDefaultStruct()
    return {
        --rowWidget = CommonPanel:CreateWidgetByDesc(RowDesc);
        rowWidget = mainForm:CreateWidgetByDesc(RowDesc);
        cooldowns = {
            count = 1; -- панель создается для нового кд, оно будет первым
            items = {}; -- { spellNAme = {  } }
        };
    }
end

function AddSpellToTable(params)
    if enemiesBuffs.rowsCount == 6 then
        return
    end

    local spellValues = spellLib.GetCurrentValues(params.spellId)

    -- такого юзера еще нет
    if enemiesBuffs.users[params.casterId] == nil then
        enemiesBuffs.users[params.casterId] = GetDefaultStruct()
        enemiesBuffs.rowsCount = enemiesBuffs.rowsCount + 1

        local placementPlain = enemiesBuffs.users[params.casterId].rowWidget:GetPlacementPlain()
        placementPlain.posY = (enemiesBuffs.rowsCount - 1) * placementPlain.sizeY
        if placementPlain.posY ~= 0 then
            placementPlain.posY = placementPlain.posY + spaceBtwRows
        end

        enemiesBuffs.users[params.casterId].rowWidget:SetPlacementPlain(placementPlain)
        enemiesBuffs.users[params.casterId].cooldowns.items[params.spellName] = {
            widget = enemiesBuffs.users[params.casterId].rowWidget:GetChildUnchecked('PanelItem', false);
            cooldown = spellValues.predictedCooldown / 1000;
        }

        enemiesBuffs.users[params.casterId].cooldowns.items[params.spellName].widget
                :GetChildUnchecked('ImageItem', false)
                :SetBackgroundTexture(spellLib.GetIcon(params.spellId))

        enemiesBuffs.users[params.casterId].rowWidget
                :AddChild(enemiesBuffs.users[params.casterId].cooldowns.items[params.spellName].widget)

        CommonPanel:AddChild(enemiesBuffs.users[params.casterId].rowWidget)

        return -- строка откатов создана, первое умение отрисовали, здесь больше делать нечего
    end

    -- это умение уже в списке, просто обновим ему кд
    if enemiesBuffs.users[params.casterId].cooldowns.items[params.spellName] ~= nil then
        enemiesBuffs.users[params.casterId].cooldowns.items[params.spellName].cooldown = spellValues.predictedCooldown / 1000
        return
    end

    -- добавляем новую запись
    enemiesBuffs.users[params.casterId].cooldowns.count = enemiesBuffs.users[params.casterId].cooldowns.count + 1

    local newItemWidget = mainForm:CreateWidgetByDesc(ItemDesc)
    newItemWidget:GetChildUnchecked('ImageItem', false):SetBackgroundTexture(spellLib.GetIcon(params.spellId))

    local placementPlain = newItemWidget:GetPlacementPlain()
    placementPlain.posX = (enemiesBuffs.users[params.casterId].cooldowns.count - 1) * placementPlain.sizeX
    newItemWidget:SetPlacementPlain(placementPlain)

    enemiesBuffs.users[params.casterId].rowWidget:AddChild(newItemWidget)
    enemiesBuffs.users[params.casterId].cooldowns.items[params.spellName] = {
        widget = newItemWidget;
        cooldown = spellValues.predictedCooldown / 1000;
    }
end

function RenderNewItem(params)

end

function IsAvatarCanUseAddon()
    local serverName = userMods.FromWString(mission.GetShardName());
    if ToHex(serverName) ~= 'CCEEEBEEE4E0FF20C3E2E0F0E4E8FF' then
        return false
    end

    local guildInfo = unit.GetGuildInfo(avatar.GetId())
    if guildInfo == nil then
        return false
    end

    local guildName = userMods.FromWString(guildInfo.name);

    return not (guildName == nil or guildName == '' or ToHex(guildName) ~= 'D0FBF6E0F0E820CAF0EEE2E8')
end

function OnEventBuffAdded(params)
    local buffInfo = object.GetBuffInfo(params.buffId)
    if buffInfo.producer.casterId == nil then
        return
    end

    local class = unit.GetClass(buffInfo.producer.casterId)
    if CoolDownsTable[class.className] == nil then
        LogToChat('Нет правил для класса ' .. class.className)
        return
    end

    local spellId = buffInfo.producer.spellId
    if spellId ~= nil then
        local spellDescription = spellLib.GetDescription(spellId)
        local spellNameString = userMods.FromWString(spellDescription.name);
        if CoolDownsTable[class.className][spellNameString] == nil then
            return
        end

        AddSpellToTable({ spellId = spellId; casterId = buffInfo.producer.casterId; spellName = spellNameString })
        return
    end

    local abilityId = buffInfo.producer.abilityId
    if abilityId ~= nil then
       local abilityInfo = avatar.GetAbilityInfo(abilityId)
        if abilityInfo ~= nil then
            LogToChat(abilityInfo.name)
        end

        return
    end
end

function OnSecondTimer()
    local localMarginTop = 0;
    for k, v in pairs(enemiesBuffs) do

    end
end

function OnAoPanelStart()
    local SetVal = { val = userMods.ToWString("CD") }
    local params = { header = SetVal, ptype = "button", size = 60 }
    userMods.SendEvent("AOPANEL_SEND_ADDON", {
        name = addonName, sysName = addonName, param = params
    })

    common.RegisterEventHandler(OnAoPanelClickButton, 'AOPANEL_BUTTON_LEFT_CLICK')
    common.RegisterEventHandler(OnAoPanelRightClickButton, 'AOPANEL_BUTTON_RIGHT_CLICK')

    OpenConfigButton:Show(false)
end

function OnZoneChanged()

end

function OnAoPanelClickButton(params)
    if params.sender ~= nil and params.sender ~= addonName then
        return
    end

    OnClickButton()
end

function OnAoPanelRightClickButton(params)
    if params.sender ~= nil and params.sender ~= addonName then
        return
    end

    OnRightClickButton()
end

function OnClickButton()
    if DnD:IsDragging() then
        return
    end

    if dndOn then
        CommonPanel:SetBackgroundColor({ r = 1; g = 1; b = 1; a = 0 })
        DnD.Remove(CommonPanel)
        LogToChat('DnD off')
    else
        DnD.Init(CommonPanel, nil, true)
        CommonPanel:SetBackgroundColor({ r = 1; g = 1; b = 1; a = 0.4 })
        LogToChat('DnD on')
    end

    dndOn = not dndOn
end

function OnRightClickButton()
    if DnD:IsDragging() then
        return
    end

    local location = cartographer.GetCurrentMapInfo()

    LogToChat(location.name)
end

function OnEventAvatarCreated()
    mainForm:Show(false)

    if not IsAvatarCanUseAddon() then
        LogToChat('Аддон только для ги "Рыцари Крови" [МГ]')
        return
    end

    CommonPanel = mainForm:GetChildUnchecked("ItemsPanel", false)
    CommonPanel:SetBackgroundColor({ a = 0.0 })

    Row = CommonPanel:GetChildUnchecked("ItemsRow", false)
    Item = Row:GetChildUnchecked("PanelItem", false)

    ItemDesc = Item:GetWidgetDesc()
    RowDesc = Row:GetWidgetDesc()

    Row:DestroyWidget()

    --ItemsRowDesc = mainForm:CreateWidgetByDesc(ItemsRow:GetWidgetDesc())
    --ItemsPanel:Show(true)

    -- загрузить сохраненное расположение панели
    DnD.Init(CommonPanel, nil, true)
    DnD.Remove(CommonPanel)

    --PanelItem:Show(true)

    CreateConfigButton()

    common.RegisterEventHandler(OnZoneChanged, 'EVENT_AVATAR_CLIENT_ZONE_CHANGED');
    common.RegisterEventHandler(OnEventBuffAdded, 'EVENT_OBJECT_BUFF_ADDED')
    common.RegisterEventHandler(OnSecondTimer, 'EVENT_SECOND_TIMER')

    mainForm:Show(true)
end

function Init()
    if avatar and avatar.IsExist() then
        OnEventAvatarCreated()
    else
        common.RegisterEventHandler(OnEventAvatarCreated, "EVENT_AVATAR_CREATED")
    end
end

Init()
