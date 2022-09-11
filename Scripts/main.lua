local wtChat
local valuedText = common.CreateValuedText()
local addonName = common.GetAddonName()

local OpenConfigButton = mainForm:GetChildUnchecked("OpenConfigButton", false)
local ItemsPanel = mainForm:GetChildUnchecked("ItemsPanel", false)
local ItemsRow = ItemsPanel:GetChildUnchecked("ItemsRow", false)
local PanelItem = ItemsRow:GetChildUnchecked("PanelItem", false)

local enemiesBuffs = {}
local friendsBuffs = {}

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
    OpenConfigButton:Show(true)

    DnD.Init(OpenConfigButton, nil, true)

    common.RegisterReactionHandler(OnClickButton, 'EVENT_ON_CONFIG_BUTTON_CLICK')
    common.RegisterReactionHandler(OnRightClickButton, 'EVENT_ON_CONFIG_BUTTON_RIGHT_CLICK')

    common.RegisterEventHandler(OnAoPanelStart, 'AOPANEL_START')
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
    if true then
        return
    end

    if not (userMods.FromWString(params.buffName) == 'Защита') then
        return
    end

    local buffInfo = object.GetBuffInfo(params.buffId)
    if buffInfo.producer.casterId == nil then
        return
    end

    local class = unit.GetClass(buffInfo.producer.casterId)
    --LogToChat(class.className)

    local spellId = buffInfo.producer.spellId
    if spellId ~= nil then
        local icon = spellLib.GetIcon(spellId)
        PanelItem:GetChildUnchecked('ImageItem', false):SetBackgroundTexture(icon)
        local spellDescription = spellLib.GetDescription(spellId)
        local spellValues = spellLib.GetCurrentValues(spellId)
        local spellInfo = spellLib.GetProperties(spellId)
        local string = 'Spell: ' .. userMods.FromWString(spellDescription.name) .. ' ('.. spellInfo.rank ..'), CD: ' .. tostring(spellValues.predictedCooldown / 1000 ..'s')
        LogToChat(string)
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
        ItemsPanel:SetBackgroundColor({ r = 1; g = 1; b = 1; a = 0 })
        DnD.Remove(ItemsPanel)
        LogToChat('DnD off')
    else
        DnD.Init(ItemsPanel, nil, true)
        ItemsPanel:SetBackgroundColor({ r = 1; g = 1; b = 1; a = 0.4 })
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
    if not IsAvatarCanUseAddon() then
        OpenConfigButton:Show(false)
        LogToChat('Аддон только для ги "Рыцари Крови" [МГ]')
        return
    end

    ItemsPanel:Show(false)
    ItemsPanel:SetBackgroundColor( { a = 0.0 } )
    DnD.Init(ItemsPanel, nil, true)
    DnD.Remove(ItemsPanel)

    PanelItem:Show(true)

    CreateConfigButton()

    common.RegisterEventHandler(OnZoneChanged, 'EVENT_AVATAR_CLIENT_ZONE_CHANGED');
    common.RegisterEventHandler(OnEventBuffAdded, 'EVENT_OBJECT_BUFF_ADDED')
end

function Init()
    if avatar and avatar.IsExist() then
        OnEventAvatarCreated()
    else
        common.RegisterEventHandler(OnEventAvatarCreated, "EVENT_AVATAR_CREATED")
    end
end

Init()
