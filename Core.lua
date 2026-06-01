-- [ CORE ] Mirrors ElitePlayerFrame_Enhanced textures onto TargetFrame.

local ADDON_NAME = "EliteTargetFrame"

local TARGET_FRAME = "TargetFrame"
local TARGET_CONTAINER = "TargetFrameContainer"
local TARGET_TEXTURE_FRAME = "FrameTexture"
local TARGET_PORTRAIT = "Portrait"
local TARGET_BOSS_TEXTURE = "BossPortraitFrameTexture"

local FRAME_LAYERS = { "Frame", "Portrait" }
local SV_NAME = "EliteTargetFrame_Settings"
local MAX_LEVEL_TEXTURE_ID = 5
local INTRO_MAX_LEVEL = 10

local SETTINGS_DEFAULTS = {
    display = true,
    syncFrameMode = false,
    frameMode = 1,
    instances = true,
    playerTargetsOnly = true,
    layerOffsets = {
        Frame = { x = 0, y = 0 },
        Portrait = { x = 0, y = 0 },
    },
}

local settings
local overlayFrame
local bossDefaultAnchor

local function getBaseAddon()
    return ElitePlayerFrame_Enhanced
end

local function isBaseReady(base)
    return base and type(base.IsInitialised) == "function" and base:IsInitialised()
end

local function ensureSettings()
    local sv = _G[SV_NAME]
    if type(sv) ~= "table" then
        sv = {}
        _G[SV_NAME] = sv
    end
    for k, v in pairs(SETTINGS_DEFAULTS) do
        if sv[k] == nil then
            if k == "layerOffsets" then
                sv[k] = {
                    Frame = { x = 0, y = 0 },
                    Portrait = { x = 0, y = 0 },
                }
            else
                sv[k] = v
            end
        end
    end
    settings = sv
    return settings
end

local function ensureLayerOffsets()
    ensureSettings()
    if type(settings.layerOffsets) ~= "table" then
        settings.layerOffsets = {}
    end
    for _, layerName in ipairs(FRAME_LAYERS) do
        if type(settings.layerOffsets[layerName]) ~= "table" then
            settings.layerOffsets[layerName] = { x = 0, y = 0 }
        end
        if settings.layerOffsets[layerName].x == nil then
            settings.layerOffsets[layerName].x = 0
        end
        if settings.layerOffsets[layerName].y == nil then
            settings.layerOffsets[layerName].y = 0
        end
    end
    if type(settings.textureOffsetX) == "number" then
        settings.layerOffsets.Frame.x = (settings.layerOffsets.Frame.x or 0) + settings.textureOffsetX
        settings.textureOffsetX = nil
    end
    return settings.layerOffsets
end

local function getLayerAdjust(layerName)
    local offsets = ensureLayerOffsets()
    local layer = offsets[layerName]
    if not layer then return 0, 0 end
    return layer.x or 0, layer.y or 0
end

local function getTargetContainer()
    local target = _G[TARGET_FRAME]
    return target and target[TARGET_CONTAINER]
end

local function ensureOverlay()
    if overlayFrame and overlayFrame.Frame and overlayFrame.Portrait then
        return overlayFrame
    end

    local target = _G[TARGET_FRAME]
    local container = getTargetContainer()
    if not target or not container then
        return nil
    end

    local etf = target.ETF
    if not etf then
        etf = CreateFrame("Frame", "EliteTargetFrame_Overlay", target)
        target.ETF = etf
    end

    if not etf.Frame then
        local frameTex = etf:CreateTexture(nil, "BACKGROUND", nil, 3)
        frameTex:SetPoint("LEFT", container[TARGET_TEXTURE_FRAME], "LEFT", 0, 0)
        etf.Frame = frameTex
    end

    if not etf.Portrait then
        local portraitTex = etf:CreateTexture(nil, "ARTWORK", nil, 3)
        portraitTex:SetPoint("LEFT", container[TARGET_PORTRAIT], "LEFT", 0, 0)
        etf.Portrait = portraitTex
    end

    overlayFrame = etf
    return overlayFrame
end

local function getMirroredLayerPosition(layerName, sourceOffset)
    local adjustX, adjustY = getLayerAdjust(layerName)
    local sourceX = sourceOffset and sourceOffset.x or 0
    local sourceY = sourceOffset and sourceOffset.y or 0
    return -sourceX + adjustX, sourceY + adjustY
end

local function getTextureResolution(base)
    if base and type(base.GetTextureResolution) == "function" then
        return base:GetTextureResolution() or 1
    end
    return 1
end

local function getTextureResolutionValue(atlas, value, base)
    if not atlas or not value then return nil end
    local tr = getTextureResolution(base)
    local av = atlas[tr == 1 and value or format("%s-%sx", value, tr)]
        or atlas[format("%s-%sx", value, tr + 1)]
        or atlas[format("%s-%sx", value, tr - 1)]
    if av then return av end
    local min, max = 2, (tr * 2) - 1
    for delta = 2, math.max(tr - min, max - tr) do
        av = tr + delta
        if av <= max then
            av = atlas[format("%s-%dx", value, av)]
            if av then return av end
        end
        av = tr - delta
        if av >= min then
            av = atlas[format("%s-%dx", value, av)]
            if av then return av end
        end
    end
    return atlas[value]
end

local function applyLayerPosition(layerFrame, layerName, offsetX, offsetY)
    local container = getTargetContainer()
    if not container or not layerFrame then return false end

    layerFrame:ClearAllPoints()
    if layerName == "Frame" and container[TARGET_TEXTURE_FRAME] then
        layerFrame:SetPoint("LEFT", container[TARGET_TEXTURE_FRAME], "LEFT", offsetX or 0, offsetY or 0)
        return true
    end
    if layerName == "Portrait" and container[TARGET_PORTRAIT] then
        layerFrame:SetPoint("LEFT", container[TARGET_PORTRAIT], "LEFT", offsetX or 0, offsetY or 0)
        return true
    end
    return false
end

local function applyHorizontalFlipTexCoords(texture, atlas, base)
    local ltc = getTextureResolutionValue(atlas, "leftTexCoord", base) or 0
    local rtc = getTextureResolutionValue(atlas, "rightTexCoord", base) or 1
    local ttc = getTextureResolutionValue(atlas, "topTexCoord", base) or 0
    local btc = getTextureResolutionValue(atlas, "bottomTexCoord", base) or 1
    if atlas.flipHorizontally then
        texture:SetTexCoord(ltc, rtc, ttc, btc)
    else
        texture:SetTexCoord(rtc, ltc, ttc, btc)
    end
end

local function applyAtlasToTexture(texture, atlas, base)
    if not texture or not atlas or not base then return end
    if atlas.name then
        local atlasName = getTextureResolutionValue(atlas, "name", base)
        if atlasName then
            texture:SetAtlas(atlasName, not (atlas.width and atlas.height), atlas.filterMode)
            texture:SetTexCoord(
                atlas.flipHorizontally and 0 or 1,
                atlas.flipHorizontally and 1 or 0,
                atlas.flipVertically and 0 or 1,
                atlas.flipVertically and 1 or 0
            )
        end
    else
        local file = getTextureResolutionValue(atlas, "file", base)
        if file then
            texture:SetTexture(file, atlas.tilesHorizontally, atlas.tilesVertically, atlas.filterMode)
            applyHorizontalFlipTexCoords(texture, atlas, base)
        end
    end
    if atlas.width and atlas.height then
        texture:SetSize(atlas.width, atlas.height)
    elseif atlas.width then
        texture:SetWidth(atlas.width)
    elseif atlas.height then
        texture:SetHeight(atlas.height)
    end
end

local function setDefaultTargetFrameTextureVisible(show)
    local container = getTargetContainer()
    local tf = container and container[TARGET_TEXTURE_FRAME]
    if tf then
        if show then tf:Show() else tf:Hide() end
    end
end

local function captureBossDefaultAnchor()
    if bossDefaultAnchor then return end
    local container = getTargetContainer()
    local bossTex = container and container[TARGET_BOSS_TEXTURE]
    if not bossTex or bossTex:GetNumPoints() == 0 then return end
    local anchor, relativeFrame, relativeAnchor, x, y = bossTex:GetPoint(1)
    bossDefaultAnchor = {
        anchor = anchor,
        relativeFrame = relativeFrame,
        relativeAnchor = relativeAnchor,
        offsetX = x or 0,
        offsetY = y or 0,
    }
end

local function applyBossPortraitOffset(textureData)
    local container = getTargetContainer()
    local bossTex = container and container[TARGET_BOSS_TEXTURE]
    if not bossTex then return end

    captureBossDefaultAnchor()
    if not bossDefaultAnchor then return end

    local o = textureData and textureData.restIconOffsets
    local d = bossDefaultAnchor
    bossTex:ClearAllPoints()
    bossTex:SetPoint(
        d.anchor,
        d.relativeFrame,
        d.relativeAnchor,
        d.offsetX - (o and o.x or 0),
        d.offsetY + (o and o.y or 0)
    )
end

local function resolveClassId(base, classToken)
    if type(classToken) == "number" then
        return classToken
    end
    if type(classToken) == "string" and type(base.GetClass) == "function" then
        local classInfo = base:GetClass(classToken)
        if type(classInfo) == "table" and classInfo.id then
            return classInfo.id
        end
    end
end

local function resolveSpecId(base, specToken)
    if type(specToken) == "number" then
        return specToken
    end
    if type(specToken) == "string" and type(base.GetSpecialization) == "function" then
        local specInfo = base:GetSpecialization(specToken)
        if type(specInfo) == "table" and specInfo.id then
            return specInfo.id
        end
    end
end

local function resolveSexId(base, sexToken)
    if type(sexToken) == "number" then
        return sexToken
    end
    if type(sexToken) == "string" and type(base.GetSex) == "function" then
        local sexInfo = base:GetSex(sexToken)
        if type(sexInfo) == "table" and sexInfo.id then
            return sexInfo.id
        end
    end
end

local function getTargetUnitLevel()
    local level = UnitLevel("target")
    if level and level > 0 then
        return level
    end
    local effective = UnitEffectiveLevel and UnitEffectiveLevel("target")
    if effective and effective > 0 then
        return effective
    end
    return level
end

local function getTargetUnitInfo(base)
    if not UnitExists("target") then
        return nil
    end

    local info = {}
    info.name = UnitName("target")
    info.level = getTargetUnitLevel()
    info.faction = UnitFactionGroup("target")
    info.sex = UnitSex("target")
    info.race = select(3, UnitRace("target"))

    local _, classFile, classId = UnitClass("target")
    if classId then
        info.class = classId
    elseif classFile then
        info.class = resolveClassId(base, classFile)
    end

    if UnitIsPlayer("target") then
        if UnitIsUnit("target", "player") and PlayerUtil and PlayerUtil.GetCurrentSpecID then
            info.specialization = PlayerUtil.GetCurrentSpecID()
        elseif GetInspectSpecialization then
            info.specialization = GetInspectSpecialization("target")
        end
    end

    return info
end

local function tryInspectTarget()
    if not UnitExists("target") or not UnitIsPlayer("target") or UnitIsUnit("target", "player") then
        return
    end
    if CanInspect and CanInspect("target") and NotifyInspect then
        NotifyInspect("target")
    end
end

-- Custom Skins autoCondition closures use addon:CharacterIs* with player data baked in.
-- We match target unit info directly from skin definition entries (EPF_CustomSkins_Definitions when present).
local skinCriteriaByModeId = {}
local skinCriteriaMapReady = false
local CUSTOM_SKINS_PATH_MARKER = "ElitePlayerFrame_Enhanced_CustomSkins"
local savedFrameMethods = {}

local function targetMatchesClass(base, targetInfo, value)
    if not targetInfo or not targetInfo.class then
        return false
    end
    if type(value) == "table" and value.id then
        return targetInfo.class == value.id
    end
    local wantId = resolveClassId(base, value)
    return wantId ~= nil and targetInfo.class == wantId
end

local function targetMatchesSpec(base, targetInfo, value)
    if not targetInfo or not targetInfo.specialization then
        return false
    end
    local wantId = resolveSpecId(base, value)
    return wantId ~= nil and targetInfo.specialization == wantId
end

local function targetMatchesRace(base, targetInfo, value)
    if not targetInfo or not targetInfo.race then
        return false
    end
    if type(value) == "string" then
        return targetInfo.race == value
    end
    if type(value) == "number" and type(base.GetRace) == "function" then
        local raceInfo = base:GetRace(value)
        if type(raceInfo) == "table" and raceInfo.id then
            return targetInfo.race == raceInfo.id
        end
    end
    return false
end

local function targetMatchesFaction(targetInfo, value)
    if not targetInfo or not targetInfo.faction then
        return false
    end
    return targetInfo.faction == value
end

local function targetMatchesSex(base, targetInfo, value)
    if not targetInfo or not targetInfo.sex then
        return false
    end
    local wantId = resolveSexId(base, value)
    return wantId ~= nil and targetInfo.sex == wantId
end

local CRITERIA_ANY = ""

local RACE_FILE_ALIASES = {
    Earthen = "EarthenDwarf",
    Haranir = "Harronir",
}

local function normalizeRaceKey(race)
    if not race then return nil end
    return tostring(race):upper():gsub(" ", "")
end

local function targetRaceMatchesStoredCriteria(target_race_id, stored_race)
    if not stored_race or stored_race == CRITERIA_ANY then
        return true
    end
    if not target_race_id then
        return false
    end
    local numeric = tonumber(stored_race)
    if numeric then
        return target_race_id == numeric
    end
    if not C_CreatureInfo or not C_CreatureInfo.GetRaceInfo then
        return false
    end
    local ok, target_info = pcall(C_CreatureInfo.GetRaceInfo, target_race_id)
    if not ok or not target_info or not target_info.clientFileString then
        return false
    end
    local stored = RACE_FILE_ALIASES[stored_race] or stored_race
    local target_key = normalizeRaceKey(target_info.clientFileString)
    return target_key == normalizeRaceKey(stored) or target_key == normalizeRaceKey(stored_race)
end

--[[
 * Match EPF Custom Skins override rows against target unit info (no call into Custom Skins code).
 * Uses mode_to_override on the global table when that addon has registered modes.
--]]
local function overrideCriteriaMatchesTarget(base, targetInfo, override)
    if not override or override.enabled == false or not override.catalogId then
        return false
    end
    if override.class and override.class ~= CRITERIA_ANY and not targetMatchesClass(base, targetInfo, override.class) then
        return false
    end
    if override.spec and override.spec ~= CRITERIA_ANY then
        local spec_id = tonumber(override.spec) or override.spec
        if not targetInfo.specialization or targetInfo.specialization ~= spec_id then
            return false
        end
    end
    if override.race and override.race ~= CRITERIA_ANY and not targetRaceMatchesStoredCriteria(targetInfo.race, override.race) then
        return false
    end
    if override.faction and override.faction ~= CRITERIA_ANY and not targetMatchesFaction(targetInfo, override.faction) then
        return false
    end
    if override.sex and override.sex ~= CRITERIA_ANY and not targetMatchesSex(base, targetInfo, override.sex) then
        return false
    end
    return true
end

local function getRegisteredOverrideForMode(modeId)
    local module_table = _G.EPF_CustomSkins_Overrides
    if not module_table or type(module_table.mode_to_override) ~= "table" then
        return nil
    end
    return module_table.mode_to_override[modeId]
end

local function isRegisteredOverrideModeId(modeId)
    return getRegisteredOverrideForMode(modeId) ~= nil
end

local function targetMatchesOverrideMode(base, targetInfo, modeId)
    local override = getRegisteredOverrideForMode(modeId)
    if not override then
        return false
    end
    return overrideCriteriaMatchesTarget(base, targetInfo, override)
end

local function entryMatchesTarget(base, targetInfo, entry)
    if not entry or entry.class == "CUSTOM" then
        return false
    end
    if entry.class and not targetMatchesClass(base, targetInfo, entry.class) then
        return false
    end
    if entry.spec and not targetMatchesSpec(base, targetInfo, entry.spec) then
        return false
    end
    if entry.faction and not targetMatchesFaction(targetInfo, entry.faction) then
        return false
    end
    if entry.race and not targetMatchesRace(base, targetInfo, entry.race) then
        return false
    end
    return true
end

local function textureUsesCustomSkinsAsset(base, textureData)
    if not textureData then
        return false
    end
    for _, layerKey in ipairs(FRAME_LAYERS) do
        local layer = textureData[layerKey]
        local atlas = layer and layer.atlas
        if type(atlas) == "table" then
            local file = getTextureResolutionValue(atlas, "file", base) or atlas.file
            if type(file) == "string" and file:find(CUSTOM_SKINS_PATH_MARKER, 1, true) then
                return true
            end
        end
    end
    return false
end

local function getMergedSkinDefinitionEntries()
    local definitions = _G.EPF_CustomSkins_Definitions
    if not definitions then
        return nil
    end
    local merged = {}
    local specList = definitions.textureConfigSpec or definitions.textureConfig or {}
    for _, entry in ipairs(specList) do
        merged[#merged + 1] = entry
    end
    for _, entry in ipairs(definitions.textureConfigFallback or {}) do
        merged[#merged + 1] = entry
    end
    if #merged == 0 then
        return nil
    end
    return merged
end

local function collectCustomSkinsModeIdsByRegistration(base)
    local ids = {}
    local frameModes = base.FRAME_MODES
    if type(frameModes) ~= "table" then
        return ids
    end

    -- Custom Skins registers modes in definition order; ReorderCustomFrameModes only changes menu order.
    local maxStandard = base.MAX_LEVEL_TEXTURE_ID or 5
    for modeId = maxStandard + 1, #frameModes do
        local textureData = base:GetTexture(modeId)
        if textureUsesCustomSkinsAsset(base, textureData) then
            ids[#ids + 1] = modeId
        end
    end
    return ids
end

local function rebuildSkinCriteriaMap(base)
    skinCriteriaByModeId = {}
    local merged = getMergedSkinDefinitionEntries()
    if not merged then
        skinCriteriaMapReady = true
        return
    end

    local customModeIds = collectCustomSkinsModeIdsByRegistration(base)
    local pairCount = math.min(#merged, #customModeIds)
    for index = 1, pairCount do
        skinCriteriaByModeId[customModeIds[index]] = merged[index]
    end

    skinCriteriaMapReady = true
end

local function ensureSkinCriteriaMap(base)
    if not skinCriteriaMapReady then
        rebuildSkinCriteriaMap(base)
    end
end

local function applyTargetEvalFramePatches(base, targetInfo)
    local frames = {}
    if base then
        frames[#frames + 1] = base
    end
    if _G.EPF_CustomSkins_BaseAddon then
        frames[#frames + 1] = _G.EPF_CustomSkins_BaseAddon
    end

    for _, frame in ipairs(frames) do
        if frame and not savedFrameMethods[frame] then
            savedFrameMethods[frame] = {
                CharacterIsClass = frame.CharacterIsClass,
                CharacterIsSpecialization = frame.CharacterIsSpecialization,
                CharacterIsRace = frame.CharacterIsRace,
                CharacterIsFaction = frame.CharacterIsFaction,
                CharacterIsSex = frame.CharacterIsSex,
            }
        end
        frame.CharacterIsClass = function(_, value)
            return targetMatchesClass(base, targetInfo, value)
        end
        frame.CharacterIsSpecialization = function(_, value)
            return targetMatchesSpec(base, targetInfo, value)
        end
        frame.CharacterIsRace = function(_, value)
            return targetMatchesRace(base, targetInfo, value)
        end
        frame.CharacterIsFaction = function(_, value)
            return targetMatchesFaction(targetInfo, value)
        end
        frame.CharacterIsSex = function(_, value)
            return targetMatchesSex(base, targetInfo, value)
        end
    end
end

local function clearTargetEvalFramePatches()
    for frame, methods in pairs(savedFrameMethods) do
        for key, method in pairs(methods) do
            frame[key] = method
        end
    end
    savedFrameMethods = {}
end

local function resolveTargetLevelFallbackTexture(base, targetInfo)
    local maxLevel = base.GetMaxLevelInfo and base:GetMaxLevelInfo()
    local expansion = base.GetExpansionInfo and base:GetExpansionInfo()
    local level = targetInfo and targetInfo.level

    if not level or level < 0 then
        return base:GetTexture(1)
    end
    if maxLevel and level >= maxLevel then
        return base:GetTexture(MAX_LEVEL_TEXTURE_ID) or base:GetTexture(1)
    end
    if level >= INTRO_MAX_LEVEL then
        if expansion and level >= expansion.minLevel then
            return base:GetTexture(3) or base:GetTexture(1)
        end
        return base:GetTexture(2) or base:GetTexture(1)
    end
    return base:GetTexture(1)
end

local function resolveTargetAutoTexture(base)
    local targetInfo = getTargetUnitInfo(base)
    if not targetInfo then
        return base:GetTexture(1)
    end

    ensureSkinCriteriaMap(base)

    local order = base.GetCustomFrameModesOrder and base:GetCustomFrameModesOrder()
    if type(order) == "table" then
        for _, modeId in ipairs(order) do
            local entry = skinCriteriaByModeId[modeId]
            if entry and entryMatchesTarget(base, targetInfo, entry) then
                return base:GetTexture(modeId)
            end
            if targetMatchesOverrideMode(base, targetInfo, modeId) then
                return base:GetTexture(modeId)
            end
        end
    end

    applyTargetEvalFramePatches(base, targetInfo)
    local matchedTexture
    local ok, result = pcall(function()
        if type(order) ~= "table" then
            return nil
        end
        for _, modeId in ipairs(order) do
            if skinCriteriaByModeId[modeId] or isRegisteredOverrideModeId(modeId) then
                -- Handled above (definition entries and target-based overrides).
            else
                local textureData = base:GetTexture(modeId)
                if textureData and type(textureData.autoCondition) == "function" then
                    if textureData.autoCondition(base) then
                        return textureData
                    end
                end
            end
        end
        return nil
    end)
    clearTargetEvalFramePatches()
    if ok and result then
        matchedTexture = result
    end

    if matchedTexture then
        return matchedTexture
    end

    return resolveTargetLevelFallbackTexture(base, targetInfo)
end

local function shouldApplyToCurrentTarget()
    ensureSettings()
    if settings.playerTargetsOnly then
        if not UnitExists("target") or not UnitIsPlayer("target") then
            return false
        end
    end
    return true
end

local function getActiveTexture(base)
    ensureSettings()
    if not settings.display or not shouldApplyToCurrentTarget() or (not settings.instances and IsInInstance()) then
        return base:GetTexture(0)
    end
    if settings.syncFrameMode and type(base.GetCurrentTexture) == "function" then
        return base:GetCurrentTexture()
    end

    local mode = settings.frameMode or 1
    if mode == 0 then
        return base:GetTexture(1)
    end
    if mode == 1 then
        return resolveTargetAutoTexture(base)
    end
    return base:GetTexture(mode) or base:GetTexture(1)
end

local function layerHasCustomAtlas(layerTexture)
    return type(layerTexture) == "table" and type(layerTexture.atlas) == "table"
end

local function hideTargetOverlays()
    local overlay = ensureOverlay()
    if not overlay then return end
    for _, layerName in ipairs(FRAME_LAYERS) do
        local layerFrame = overlay[layerName]
        if layerFrame then layerFrame:Hide() end
    end
    setDefaultTargetFrameTextureVisible(true)
end

local function updateTargetTexture()
    local base = getBaseAddon()
    if not isBaseReady(base) then return false end
    ensureSettings()

    local overlay = ensureOverlay()
    if not overlay then return false end

    if not settings.display or not shouldApplyToCurrentTarget() then
        hideTargetOverlays()
        return true
    end

    local textureData = getActiveTexture(base)
    if not textureData then return false end

    local hasFrameSkin = false

    for _, layerName in ipairs(FRAME_LAYERS) do
        local layerFrame = overlay[layerName]
        if not layerFrame then return false end

        local layerTexture = textureData[layerName]
        local sourceOffset = layerTexture and layerTexture.offsets
        local atlas = layerTexture and layerTexture.atlas
        local posX, posY = getMirroredLayerPosition(layerName, sourceOffset)

        applyLayerPosition(layerFrame, layerName, posX, posY)

        if layerHasCustomAtlas(layerTexture) then
            local ok, err = pcall(applyAtlasToTexture, layerFrame, atlas, base)
            if not ok and geterrorhandler then
                geterrorhandler()(ADDON_NAME .. " applyAtlasToTexture: " .. tostring(err))
            end
            layerFrame:Show()
            if layerName == "Frame" then
                hasFrameSkin = true
            end
        else
            layerFrame:Hide()
        end
    end

    setDefaultTargetFrameTextureVisible(not hasFrameSkin)
    applyBossPortraitOffset(textureData)
    return true
end

local function requestUpdate()
    updateTargetTexture()
end

local function registerBaseCallbacks(base)
    if not base or type(base.RegisterCallback) ~= "function" then return end
    base:RegisterCallback("TEXTURE_UPDATED", function()
        requestUpdate()
    end, ADDON_NAME .. "_TextureUpdated")
    base:RegisterCallback("DISPLAY_UPDATED", function()
        requestUpdate()
    end, ADDON_NAME .. "_DisplayUpdated")
    base:RegisterCallback("TEXTURE_RESOLUTION_CHANGED", function()
        skinCriteriaMapReady = false
        requestUpdate()
    end, ADDON_NAME .. "_ResolutionChanged")
    base:RegisterCallback("CUSTOM_FRAME_MODE_ADDED", function()
        skinCriteriaMapReady = false
        requestUpdate()
    end, ADDON_NAME .. "_CustomFrameModeAdded")
    base:RegisterCallback("CUSTOM_FRAME_MODES_REORDERED", function()
        skinCriteriaMapReady = false
        requestUpdate()
    end, ADDON_NAME .. "_CustomFrameModesReordered")
    base:RegisterCallback("SETTING_CHANGED", function()
        if settings.syncFrameMode then
            requestUpdate()
        end
    end, ADDON_NAME .. "_SettingChanged")
    base:RegisterCallback("SETTINGS_RESET", function()
        requestUpdate()
    end, ADDON_NAME .. "_SettingsReset")
end

local function onTargetContextChanged()
    tryInspectTarget()
    requestUpdate()
end

local function registerHooks()
    if TargetFrame_Update then
        hooksecurefunc("TargetFrame_Update", function()
            requestUpdate()
        end)
    end
end

local bootstrap

local function registerTargetEvents()
    if not bootstrap then return end
    bootstrap:RegisterEvent("PLAYER_TARGET_CHANGED")
    bootstrap:RegisterEvent("INSPECT_READY")
    if bootstrap.RegisterUnitEvent then
        bootstrap:RegisterUnitEvent("UNIT_LEVEL", "target")
    end
end

local function tryInitialise()
    local base = getBaseAddon()
    if not isBaseReady(base) then return false end
    ensureSettings()
    rebuildSkinCriteriaMap(base)
    registerBaseCallbacks(base)
    registerHooks()
    registerTargetEvents()
    tryInspectTarget()
    requestUpdate()
    return true
end

local function onInitialised()
    tryInitialise()
end

function EliteTargetFrame_GetSettings()
    ensureSettings()
    ensureLayerOffsets()
    return settings
end

function EliteTargetFrame_GetLayerOffset(layerName, axis)
    ensureLayerOffsets()
    local layer = settings.layerOffsets[layerName]
    if not layer then return 0 end
    return layer[axis] or 0
end

function EliteTargetFrame_SetLayerOffset(layerName, axis, value)
    ensureLayerOffsets()
    if settings.layerOffsets[layerName] then
        settings.layerOffsets[layerName][axis] = value
    end
    requestUpdate()
end

function EliteTargetFrame_SetSetting(key, value)
    ensureSettings()
    settings[key] = value
    requestUpdate()
end

function EliteTargetFrame_RequestUpdate()
    requestUpdate()
end

bootstrap = CreateFrame("Frame")
bootstrap:RegisterEvent("ADDON_LOADED")
bootstrap:RegisterEvent("PLAYER_ENTERING_WORLD")
bootstrap:RegisterEvent("ZONE_CHANGED_NEW_AREA")
bootstrap:RegisterEvent("DISPLAY_SIZE_CHANGED")

bootstrap:SetScript("OnEvent", function(_, event, arg1)
    if event == "ADDON_LOADED" and arg1 == ADDON_NAME then
        ensureSettings()
    elseif event == "PLAYER_ENTERING_WORLD" then
        local base = getBaseAddon()
        if base and type(base.WhenInitialised) == "function" then
            base:WhenInitialised(onInitialised)
        end
        if not tryInitialise() and C_Timer and C_Timer.After then
            C_Timer.After(0.5, tryInitialise)
            C_Timer.After(2, tryInitialise)
        end
    elseif event == "PLAYER_TARGET_CHANGED" then
        onTargetContextChanged()
    elseif event == "INSPECT_READY" then
        if UnitExists("target") and (not arg1 or UnitGUID("target") == arg1) then
            requestUpdate()
        end
    elseif event == "UNIT_LEVEL" then
        if arg1 == "target" then
            requestUpdate()
        end
    elseif event == "ZONE_CHANGED_NEW_AREA" or event == "DISPLAY_SIZE_CHANGED" then
        requestUpdate()
    end
end)
