local wtChat
local valuedText = common.CreateValuedText()
local addonName = common.GetAddonName()

local OpenConfigButton
local CommonPanel
local RowDesc
local ItemDesc

local enemiesBuffs = {
    rowsCount = 0;
    users = {};
}

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
        valuedText:SetVal("addonName", userMods.ToWString("CT: "))
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
        rowWidget = mainForm:CreateWidgetByDesc(RowDesc);
        cooldowns = {
            count = 0;
            items = {}; -- { spellNAme = {  } }
        };
    }
end

function CreateItem(params, wItem)
    wItem = wItem or mainForm:CreateWidgetByDesc(ItemDesc)
    local cooldownMs = GetCooldownMsForSpell(params.className, params.spellId, params.spellName)
    local wCooldownText = wItem:GetChildChecked('Cooldown', false)

    wItem:GetChildUnchecked('ImageItem', false):SetBackgroundTexture(spellLib.GetIcon(params.spellId))
    local str = '<body color="0xFFFFFFFF" fontsize="' .. config['COOLDOWN_TEXT_FONTSIZE'] .. '" alignx="right" aligny="bottom" outline="1"><rs class="class"><r name="text"/></rs></body>'
    wCooldownText:SetFormat(userMods.ToWString(str))
    wCooldownText:SetVal('text', GetCooldownReadableString(cooldownMs))

    local placementPlain = wItem:GetPlacementPlain()
    placementPlain.posX = (enemiesBuffs.users[params.casterId].cooldowns.count - 1) * config['ICON_SIZE']
    placementPlain.sizeX = config['ICON_SIZE']
    placementPlain.sizeY = config['ICON_SIZE']
    wItem:SetPlacementPlain(placementPlain)

    return {
        widget = wItem;
        cooldown = cooldownMs;
        wCooldownText = wCooldownText;
        spellId = params.spellId;
        used = params.usedAt;
    }
end

function GetCooldownReadableString(timerInMs)
    if timerInMs >= 86400000 then
        return tostring(math.floor(timerInMs / 86400000)) .. 'd'
    end

    if timerInMs >= 3600000 then
        return tostring(math.floor(timerInMs / 3600000)) .. 'h'
    end

    if timerInMs >= 60000 then
        return tostring(math.floor(timerInMs / 60000)) .. 'm'
    end

    return tostring(math.floor(timerInMs / 1000)) .. 's'
end

function GetCooldownMsForSpell(className, spellId, spellName)
    local cooldown = cooldowns[spellName] or cooldowns[className][spellName]
    local cooldownType = type(cooldown)

    -- boolean - ищем в spellLib
    if cooldownType == 'table' then
        local spellRank = spellLib.GetProperties(spellId).rank

        -- TODO
        return spellLib.GetCurrentValues(spellId).predictedCooldown
    end

    if cooldownType == 'number' then
        return cooldown * 1000
    end

    return spellLib.GetCurrentValues(spellId).predictedCooldown
end

function AddSpellToTable(params)
    if enemiesBuffs.rowsCount == config['MAX_ROWS_COUNT'] then
        return
    end

    local wItem

    -- такого юзера еще нет
    if enemiesBuffs.users[params.casterId] == nil then
        enemiesBuffs.users[params.casterId] = GetDefaultStruct()
        enemiesBuffs.rowsCount = enemiesBuffs.rowsCount + 1

        local placementPlain = enemiesBuffs.users[params.casterId].rowWidget:GetPlacementPlain()
        placementPlain.posY = (enemiesBuffs.rowsCount - 1) * (config['ICON_SIZE'] + config['SPACE_BETWEEN_ROWS'])
        enemiesBuffs.users[params.casterId].rowWidget:SetPlacementPlain(placementPlain)

        CommonPanel:AddChild(enemiesBuffs.users[params.casterId].rowWidget)
        wItem = enemiesBuffs.users[params.casterId].rowWidget:GetChildUnchecked('PanelItem', false)
    end

    -- это умение еще не в списке, добавим
    if enemiesBuffs.users[params.casterId].cooldowns.items[params.spellName] == nil then
        -- панель забита
        if enemiesBuffs.users[params.casterId].cooldowns.count == config['MAX_ITEMS_COUNT'] then
            return
        end

        enemiesBuffs.users[params.casterId].cooldowns.count = enemiesBuffs.users[params.casterId].cooldowns.count + 1
        enemiesBuffs.users[params.casterId].cooldowns.items[params.spellName] = CreateItem(params, wItem)
        enemiesBuffs.users[params.casterId].rowWidget:AddChild(enemiesBuffs.users[params.casterId].cooldowns.items[params.spellName].widget)
        return
    end

    if (params.usedAt - enemiesBuffs.users[params.casterId].cooldowns.items[params.spellName].usedAt) > 8000 then
        enemiesBuffs.users[params.casterId].cooldowns.items[params.spellName].cooldown = GetCooldownMsForSpell(params.className, params.spellId, params.spellName)
        enemiesBuffs.users[params.casterId].cooldowns.items[params.spellName].usedAt = params.usedAt
    end
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
    LogToChat(tostring(buffInfo.buffId))
    if buffInfo.producer.casterId == nil then
        return
    end

    local spellId = buffInfo.producer.spellId
    if spellId ~= nil then
        local spellDescription = spellLib.GetDescription(spellId)
        local spellNameString = userMods.FromWString(spellDescription.name);
        local class = unit.GetClass(buffInfo.producer.casterId)
        if cooldowns[class.className][spellNameString] == nil and cooldowns[spellNameString] == nil then
            return
        end

        AddSpellToTable({
            spellId = spellId;
            casterId = buffInfo.producer.casterId;
            spellName = spellNameString;
            className = class.className;
            usedAt = common.GetMsFromDateTime(common.GetLocalDateTime());
        })
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
    for casterId, v in pairs(enemiesBuffs.users) do
        if v.cooldowns.count ~= 0 then
            for spellName, item in pairs(v.cooldowns.items) do

            end
        end
        --v.cooldowns.items;
    end
end

function OnAoPanelStart()
    local SetVal = { val = userMods.ToWString("CT") }
    local params = { header = SetVal, ptype = "button", size = 30 }
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
        CommonPanel:SetTransparentInput(true)
        DnD.Remove(CommonPanel)
        LogToChat('DnD off')
    else
        DnD.Init(CommonPanel, nil, true)
        CommonPanel:SetBackgroundColor({ r = 1; g = 1; b = 1; a = 0.4 })
        CommonPanel:SetTransparentInput(false)
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
        return
    end

    CommonPanel = mainForm:GetChildUnchecked("ItemsPanel", false)
    CommonPanel:SetBackgroundColor({ a = 0.0 })

    local PanelWeight = config['MAX_ITEMS_COUNT'] * config['ICON_SIZE']
    local CommonPanelPlacement = CommonPanel:GetPlacementPlain();
    CommonPanelPlacement.sizeY = (config['ICON_SIZE'] + config['SPACE_BETWEEN_ROWS']) * (config['MAX_ROWS_COUNT'] - 1) + config['ICON_SIZE']
    CommonPanelPlacement.sizeX = PanelWeight
    CommonPanel:SetPlacementPlain(CommonPanelPlacement)

    local Row = CommonPanel:GetChildUnchecked("ItemsRow", false)
    local Item = Row:GetChildUnchecked("PanelItem", false)

    ItemDesc = Item:GetWidgetDesc()
    RowDesc = Row:GetWidgetDesc()

    Row:DestroyWidget()

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
