-- [ OPTIONS ] Configuration panel for Elite Target Frame.

local ADDON_NAME = "Elite Target Frame"
local ADDON_LOADED_NAME = "EliteTargetFrame"
local L = ETF_L or {}

local PAD = 16
local GROUP_SPACING = 20
local SECTION_PADDING = 10

local panel = CreateFrame("Frame", "EliteTargetFrameOptionsPanel", UIParent)
panel.name = ADDON_NAME
panel:Hide()

local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
title:SetPoint("TOPLEFT", 16, -16)
title:SetText(ADDON_NAME)

local function getBaseAddon()
    return ElitePlayerFrame_Enhanced
end

local function getTargetSettings()
    if type(EliteTargetFrame_GetSettings) == "function" then
        return EliteTargetFrame_GetSettings()
    end
    return _G.EliteTargetFrame_Settings
end

local function getFrameModes(addon)
    if not addon then return nil end
    if type(addon.GetFrameModes) == "function" then
        local ok, modes = pcall(function() return addon:GetFrameModes() end)
        if ok and type(modes) == "table" then return modes end
    end
    return addon.FRAME_MODES
end

local function requestTargetUpdate()
    if type(EliteTargetFrame_RequestUpdate) == "function" then
        pcall(function() EliteTargetFrame_RequestUpdate() end)
    end
end

local function setTargetSetting(setting, value)
    if type(EliteTargetFrame_SetSetting) == "function" then
        EliteTargetFrame_SetSetting(setting, value)
        return true
    end
    local targetSettings = getTargetSettings()
    if targetSettings then
        targetSettings[setting] = value
        requestTargetUpdate()
        return true
    end
    return false
end

--[[
 * Tooltips in Esc -> AddOns use SettingsTooltip, not GameTooltip (see DefaultTooltipMixin).
--]]
local function bindOptionTooltip(targets, titleText, descText, anchorFrame)
    if not titleText then
        return
    end

    local targetList = type(targets) == "table" and targets or { targets }
    local tooltipAnchor = anchorFrame or targetList[1]

    local function populateTooltip()
        local settingsTooltip = _G.SettingsTooltip
        if Settings and Settings.InitTooltip and settingsTooltip then
            if GameTooltip_ClearLines then
                GameTooltip_ClearLines(settingsTooltip)
            end
            Settings.InitTooltip(titleText, descText)
            return
        end

        local tooltip = GameTooltip
        if not tooltip then
            return
        end
        tooltip:SetOwner(targetList[1], "ANCHOR_RIGHT")
        if GameTooltip_ClearLines then
            GameTooltip_ClearLines(tooltip)
        end
        if GameTooltip_SetTitle then
            GameTooltip_SetTitle(tooltip, titleText)
        else
            tooltip:SetText(titleText, 1, 1, 1)
        end
        if descText and descText ~= "" then
            if GameTooltip_AddNormalLine then
                GameTooltip_AddNormalLine(tooltip, descText, true)
            else
                tooltip:AddLine(descText, 1, 0.82, 0, true)
            end
        end
        tooltip:Show()
    end

    if DefaultTooltipMixin and Settings and Settings.InitTooltip and _G.SettingsTooltip then
        for _, frame in ipairs(targetList) do
            if frame then
                Mixin(frame, DefaultTooltipMixin)
                DefaultTooltipMixin.OnLoad(frame)
                frame:SetTooltipFunc(populateTooltip)
                if frame ~= tooltipAnchor and frame.SetCustomTooltipAnchoring then
                    frame:SetCustomTooltipAnchoring(tooltipAnchor, "ANCHOR_RIGHT", -10, 0)
                end
            end
        end
        return
    end

    local function showTooltip(self)
        populateTooltip()
        local settingsTooltip = _G.SettingsTooltip
        if settingsTooltip and settingsTooltip.SetOwner then
            settingsTooltip:SetOwner(tooltipAnchor, "ANCHOR_RIGHT", -10, 0)
            settingsTooltip:Show()
        end
    end

    local function hideTooltip()
        local settingsTooltip = _G.SettingsTooltip
        if settingsTooltip then
            settingsTooltip:Hide()
        elseif GameTooltip then
            GameTooltip:Hide()
        end
    end

    for _, frame in ipairs(targetList) do
        if frame then
            frame:EnableMouse(true)
            frame:SetScript("OnEnter", showTooltip)
            frame:SetScript("OnLeave", hideTooltip)
        end
    end
end

local ROW_HEIGHT = 26
local ROW_WIDTH = 300

local function createCheckboxRow(parent, anchor, yOffset, labelText)
    local row = CreateFrame("Frame", nil, parent)
    row:SetSize(ROW_WIDTH, ROW_HEIGHT)
    row:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, yOffset)

    local check = CreateFrame("CheckButton", nil, row, "InterfaceOptionsCheckButtonTemplate")
    check:SetPoint("LEFT", row, "LEFT", 0, 0)

    local label = row:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    label:SetPoint("LEFT", check, "RIGHT", 4, 0)
    label:SetPoint("RIGHT", row, "RIGHT", -4, 0)
    label:SetJustifyH("LEFT")
    label:SetText(labelText)

    -- Narrow hit area over the label; tooltip anchors to the checkbox (not the wide row).
    local labelHit = CreateFrame("Frame", nil, row)
    labelHit:SetPoint("TOPLEFT", check, "TOPRIGHT", 0, 0)
    labelHit:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", -4, 0)
    labelHit:EnableMouse(true)

    return row, check, labelHit, label
end

local CONTAINER_BACKDROP = {
    bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true,
    tileSize = 16,
    edgeSize = 16,
    insets = { left = 3, right = 3, top = 3, bottom = 3 },
}

local function setSectionBackdrop(frame)
    if not frame.SetBackdrop and BackdropTemplateMixin then
        Mixin(frame, BackdropTemplateMixin)
    end
    if frame.SetBackdrop then
        frame:SetBackdrop(CONTAINER_BACKDROP)
        frame:SetBackdropColor(0.2, 0.2, 0.2, 0.5)
        if frame.SetBackdropBorderColor then
            frame:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
        end
    end
end

local BackdropTemplate = "BackdropTemplate"

local group1 = CreateFrame("Frame", nil, panel, BackdropTemplate)
group1:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -PAD, 0)
group1:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -PAD, 24)
setSectionBackdrop(group1)

local sectionMain = group1:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
sectionMain:SetPoint("TOPLEFT", SECTION_PADDING, -SECTION_PADDING)
sectionMain:SetText(L.SectionTarget or "Target frame")

local ROW_SPACING = -2

local rowDisplay, checkDisplay, labelHitDisplay, checkDisplayLabel = createCheckboxRow(group1, sectionMain, -6, L.Display or "Display")
local rowSync, checkSync, labelHitSync, checkSyncLabel = createCheckboxRow(group1, rowDisplay, ROW_SPACING, L.SyncFrameMode or "Sync with player frame")
local rowHideInInstance, checkHideInInstance, labelHitHideInInstance, checkHideInInstanceLabel = createCheckboxRow(group1, rowSync, ROW_SPACING, L.HideInInstance or "Display in instances")
local rowPlayersOnly, checkPlayersOnly, labelHitPlayersOnly, checkPlayersOnlyLabel = createCheckboxRow(group1, rowHideInInstance, ROW_SPACING, L.PlayersOnly or "Players only")

bindOptionTooltip({ checkDisplay, labelHitDisplay }, L.Display or "Display", L.DisplayDesc, checkDisplay)
bindOptionTooltip({ checkSync, labelHitSync }, L.SyncFrameMode or "Sync with player frame", L.SyncFrameModeDesc, checkSync)
bindOptionTooltip({ checkHideInInstance, labelHitHideInInstance }, L.HideInInstance or "Display in instances", L.HideInInstanceDesc, checkHideInInstance)
bindOptionTooltip({ checkPlayersOnly, labelHitPlayersOnly }, L.PlayersOnly or "Players only", L.PlayersOnlyDesc, checkPlayersOnly)

local function setCheckFromSetting(btn, value)
    local checked = (value == true or value == 1)
    btn:SetChecked(checked)
    if InterfaceOptionsPanel_CheckButton_Update then
        InterfaceOptionsPanel_CheckButton_Update(btn)
    end
end

local function refreshTargetChecks()
    local targetSettings = getTargetSettings()
    if targetSettings then
        setCheckFromSetting(checkDisplay, targetSettings.display)
        setCheckFromSetting(checkSync, targetSettings.syncFrameMode)
        setCheckFromSetting(checkHideInInstance, targetSettings.instances)
        setCheckFromSetting(checkPlayersOnly, targetSettings.playerTargetsOnly)
    end
end

local btnReset = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
btnReset:SetSize(100, 22)
btnReset:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -24, -16)
btnReset:SetText(L.Reset or "Reset")
bindOptionTooltip({ btnReset }, L.Reset or "Reset", L.ResetDesc)
btnReset:SetScript("OnClick", function()
    setTargetSetting("display", true)
    setTargetSetting("syncFrameMode", false)
    setTargetSetting("frameMode", 1)
    setTargetSetting("instances", true)
    setTargetSetting("playerTargetsOnly", true)
    if C_Timer and C_Timer.After then
        C_Timer.After(0, function()
            refreshTargetChecks()
            updateFrameModeList()
        end)
    end
end)

checkDisplay:SetScript("OnClick", function(self)
    setTargetSetting("display", self:GetChecked() and true or false)
end)
checkSync:SetScript("OnClick", function(self)
    setTargetSetting("syncFrameMode", self:GetChecked() and true or false)
    requestTargetUpdate()
end)
checkHideInInstance:SetScript("OnClick", function(self)
    setTargetSetting("instances", self:GetChecked() and true or false)
end)
checkPlayersOnly:SetScript("OnClick", function(self)
    setTargetSetting("playerTargetsOnly", self:GetChecked() and true or false)
    requestTargetUpdate()
end)

local group3 = CreateFrame("Frame", nil, panel, BackdropTemplate)
group3:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -12)
group3:SetPoint("BOTTOMLEFT", panel, "BOTTOMLEFT", PAD, 24)
setSectionBackdrop(group3)

local listLabel = group3:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
listLabel:SetPoint("TOPLEFT", SECTION_PADDING, -SECTION_PADDING)
listLabel:SetText(L.SectionTextures or "Available textures")

local updateFrameModeList = function() end

local hasScrollBoxAPI = (CreateScrollBoxListLinearView or CreateScrollBoxListGridView)
    and ScrollUtil and ScrollUtil.InitScrollBoxListWithScrollBar and CreateDataProvider

if hasScrollBoxAPI then
    local searchBoxContainer = CreateFrame("Frame", nil, group3)
    searchBoxContainer:SetPoint("TOPLEFT", listLabel, "BOTTOMLEFT", 0, -6)
    searchBoxContainer:SetPoint("TOPRIGHT", group3, "TOPRIGHT", -SECTION_PADDING - 24, 0)
    searchBoxContainer:SetHeight(24)

    local searchEditBox
    local currentSearchFilter = ""
    local okTemplate = pcall(function()
        searchEditBox = CreateFrame("EditBox", nil, searchBoxContainer, "SearchBoxTemplate")
    end)
    if okTemplate and searchEditBox then
        searchEditBox:SetPoint("LEFT", 6, 0)
        searchEditBox:SetPoint("RIGHT", -6, 0)
        searchEditBox:SetPoint("TOP", 0, 0)
        searchEditBox:SetPoint("BOTTOM", 0, 0)
        searchEditBox:SetMaxLetters(80)
        if searchEditBox.Instructions then
            searchEditBox.Instructions:SetText(L.SearchFilter or "Filter...")
        end
        searchEditBox:SetScript("OnTextChanged", function(self)
            if SearchBoxTemplate_OnTextChanged then SearchBoxTemplate_OnTextChanged(self) end
            local text = self:GetText()
            if text and text:len() > 0 then
                currentSearchFilter = text:gsub("^%s+", ""):gsub("%s+$", ""):lower()
            else
                currentSearchFilter = ""
            end
            updateFrameModeList()
        end)
    end

    local listContainer = CreateFrame("Frame", nil, group3, BackdropTemplate)
    listContainer:SetPoint("TOPLEFT", searchBoxContainer, "BOTTOMLEFT", 0, -6)
    listContainer:SetPoint("BOTTOMRIGHT", group3, "BOTTOMRIGHT", -24, 6)
    if listContainer.SetBackdrop then
        listContainer:SetBackdrop(CONTAINER_BACKDROP)
        listContainer:SetBackdropColor(0.2, 0.2, 0.2, 0.5)
        if listContainer.SetBackdropBorderColor then
            listContainer:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
        end
    end

    local scrollBox = CreateFrame("Frame", nil, listContainer, "WowScrollBoxList")
    scrollBox:SetPoint("TOPLEFT", 8, -8)
    scrollBox:SetPoint("BOTTOMRIGHT", -8, 8)

    local scrollBar = CreateFrame("EventFrame", nil, group3, "MinimalScrollBar")
    scrollBar:SetPoint("TOPLEFT", listContainer, "TOPRIGHT", 6, 0)
    scrollBar:SetPoint("BOTTOMLEFT", listContainer, "BOTTOMRIGHT", 6, 0)

    local function applyFrameMode(index)
        if index == 1 then
            setTargetSetting("syncFrameMode", false)
        end
        setTargetSetting("frameMode", index)
        if scrollBox.GetDataProvider then
            scrollBox:ForEachFrame(function(button, elementData)
                local targetSettings = getTargetSettings()
                local selectedIndex = targetSettings and targetSettings.frameMode
                if button.SelectedTexture then
                    button.SelectedTexture:SetShown(selectedIndex == elementData.index)
                end
            end)
        end
    end

    local function getModeDisplayName(modes, i)
        local mode = modes[i]
        local displayName
        if i == 0 then
            displayName = L.DefaultNoTexture or "Default (no texture)"
        elseif mode and mode.name then
            displayName = tostring(mode.name)
        else
            displayName = (i == 1 and (L.Automatic or "Automatic")) or (L.Custom or "Custom")
        end
        if mode and mode.color and mode.color.GetRGB then
            local r, g, b = mode.color:GetRGB()
            return format("|cff%02x%02x%02x[%d] %s|r", r * 255, g * 255, b * 255, i, displayName)
        end
        return format("[%d] %s", i, displayName)
    end

    local function getModeDisplayNamePlain(modes, i)
        local raw = getModeDisplayName(modes, i)
        return raw:gsub("|c%x%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):lower()
    end

    local function InitButton(button, elementData)
        if not button.Text then
            button.Text = button:CreateFontString(nil, "ARTWORK", "GameFontWhite")
            button.Text:SetPoint("LEFT", 10, 0)
            button.Text:SetPoint("RIGHT", -10, 0)
            button.Text:SetJustifyH("LEFT")
            local highlight = button:CreateTexture(nil, "HIGHLIGHT")
            highlight:SetAllPoints()
            local ok = pcall(function() highlight:SetAtlas("Options_List_Hover") end)
            if not ok then highlight:SetColorTexture(1, 1, 1, 0.15) end
            button:SetHighlightTexture(highlight)
            local selected = button:CreateTexture(nil, "BACKGROUND")
            selected:SetAllPoints(button)
            pcall(function() selected:SetAtlas("Options_List_Active") end)
            button.SelectedTexture = selected
            selected:Hide()
        end
        button.Text:SetText(getModeDisplayName(elementData.allModes, elementData.index))
        button:SetScript("OnClick", function()
            applyFrameMode(elementData.index)
        end)
        local targetSettings = getTargetSettings()
        local selectedIndex = targetSettings and targetSettings.frameMode
        if button.SelectedTexture then
            button.SelectedTexture:SetShown(selectedIndex == elementData.index)
        end
    end

    updateFrameModeList = function()
        local addon = getBaseAddon()
        local modes = getFrameModes(addon)
        if not modes then return end
        local dataProvider = CreateDataProvider()
        local maxIndex = 0
        for k in pairs(modes) do
            if type(k) == "number" and k > maxIndex then maxIndex = k end
        end
        local filter = currentSearchFilter
        for i = 0, maxIndex do
            if filter == "" or getModeDisplayNamePlain(modes, i):find(filter, 1, true) then
                dataProvider:Insert({ index = i, allModes = modes })
            end
        end
        scrollBox:SetDataProvider(dataProvider)
    end

    local view = CreateScrollBoxListLinearView and CreateScrollBoxListLinearView() or CreateScrollBoxListGridView(1)
    view:SetElementExtent(20)
    view:SetElementInitializer("Button", InitButton)
    view:SetPadding(5, 5, 5, 5, 5)
    ScrollUtil.InitScrollBoxListWithScrollBar(scrollBox, scrollBar, view)
end

panel:SetScript("OnShow", function()
    local panelW = panel:GetWidth()
    if panelW and panelW > 0 then
        group3:SetWidth(panelW * 0.6)
        group1:SetWidth(panelW * 0.4)
        group3:ClearAllPoints()
        group3:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -12)
        group3:SetPoint("BOTTOMLEFT", panel, "BOTTOMLEFT", PAD, 24)
        group1:ClearAllPoints()
        group1:SetPoint("TOPLEFT", group3, "TOPRIGHT", GROUP_SPACING, 0)
        group1:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -PAD, 0)
        group1:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -PAD, 24)
    end
    title:SetText(ADDON_NAME)
    sectionMain:SetText(L.SectionTarget or "Target frame")
    checkDisplayLabel:SetText(L.Display or "Display")
    checkSyncLabel:SetText(L.SyncFrameMode or "Sync with player frame")
    checkHideInInstanceLabel:SetText(L.HideInInstance or "Display in instances")
    checkPlayersOnlyLabel:SetText(L.PlayersOnly or "Players only")
    listLabel:SetText(L.SectionTextures or "Available textures")
    refreshTargetChecks()
    updateFrameModeList()
end)

local function registerOptions()
    local ok, err = pcall(function()
        if InterfaceOptions_AddCategory then
            InterfaceOptions_AddCategory(panel)
        end
        if Settings and Settings.RegisterCanvasLayoutCategory and Settings.RegisterAddOnCategory then
            local category = Settings.RegisterCanvasLayoutCategory(panel, ADDON_NAME)
            Settings.RegisterAddOnCategory(category)
        end
    end)
    if not ok and DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage("|cffff0000Elite Target Frame:|r Options registration failed: " .. tostring(err))
    end
    local addon = getBaseAddon()
    if addon and type(addon.WhenInitialised) == "function" then
        addon:WhenInitialised(function()
            pcall(refreshTargetChecks)
            pcall(updateFrameModeList)
        end)
    end
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:SetScript("OnEvent", function(_, event, addonName)
    if event == "ADDON_LOADED" and addonName == ADDON_LOADED_NAME then
        eventFrame:UnregisterEvent("ADDON_LOADED")
        local ok, err = pcall(registerOptions)
        if not ok and DEFAULT_CHAT_FRAME then
            DEFAULT_CHAT_FRAME:AddMessage("|cffff0000Elite Target Frame:|r " .. tostring(err))
        end
    end
end)
