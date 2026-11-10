-- [ SPEC COMPAT ] Forever talent-tree → retail texture-def spec matching (TipTac C_Traits split).

EliteTargetFrame_SpecCompat = EliteTargetFrame_SpecCompat or {}
local SC = EliteTargetFrame_SpecCompat

SC.RETAIL_SPEC_TREE_INDEX = {
    [71] = 1, [72] = 2, [73] = 3,
    [65] = 1, [66] = 2, [70] = 3,
    [253] = 1, [254] = 2, [255] = 3,
    [259] = 1, [260] = 2, [261] = 3,
    [256] = 1, [257] = 2, [258] = 3,
    [250] = 1, [251] = 2, [252] = 3,
    [262] = 1, [263] = 2, [264] = 3,
    [62] = 1, [63] = 2, [64] = 3,
    [265] = 1, [266] = 2, [267] = 3,
    [268] = 1, [270] = 2, [269] = 3,
    [102] = 1, [103] = 2, [104] = 3, [105] = 4,
    [577] = 1, [581] = 2, [1480] = 3,
    [1467] = 1, [1468] = 2, [1473] = 3,
}

SC.RETAIL_SPEC_CLASS = {
    [71] = "WARRIOR", [72] = "WARRIOR", [73] = "WARRIOR",
    [65] = "PALADIN", [66] = "PALADIN", [70] = "PALADIN",
    [253] = "HUNTER", [254] = "HUNTER", [255] = "HUNTER",
    [259] = "ROGUE", [260] = "ROGUE", [261] = "ROGUE",
    [256] = "PRIEST", [257] = "PRIEST", [258] = "PRIEST",
    [250] = "DEATHKNIGHT", [251] = "DEATHKNIGHT", [252] = "DEATHKNIGHT",
    [262] = "SHAMAN", [263] = "SHAMAN", [264] = "SHAMAN",
    [62] = "MAGE", [63] = "MAGE", [64] = "MAGE",
    [265] = "WARLOCK", [266] = "WARLOCK", [267] = "WARLOCK",
    [268] = "MONK", [270] = "MONK", [269] = "MONK",
    [102] = "DRUID", [103] = "DRUID", [104] = "DRUID", [105] = "DRUID",
    [577] = "DEMONHUNTER", [581] = "DEMONHUNTER", [1480] = "DEMONHUNTER",
    [1467] = "EVOKER", [1468] = "EVOKER", [1473] = "EVOKER",
}

function SC.IsForever(addon)
    if addon and addon.GameType and type(addon.GameType.IsGame) == "function" then
        local ok, result = pcall(function() return addon.GameType:IsGame("forever") end)
        if ok and result then
            return true
        end
    end
    local toc = select(4, GetBuildInfo())
    return type(toc) == "number" and toc >= 16000 and toc < 20000
end

function SC.GetForeverPointsSpent(unit)
    if not C_Traits or not C_Traits.GetConfigInfo then
        return nil
    end
    unit = unit or "player"
    local is_self = UnitIsUnit and UnitIsUnit(unit, "player")

    local config_id
    if is_self then
        if C_ClassTalents and C_ClassTalents.GetActiveConfigID then
            config_id = C_ClassTalents.GetActiveConfigID()
        end
    else
        if not C_Traits.HasValidInspectData or not C_Traits.HasValidInspectData() then
            return nil
        end
        if Constants and Constants.TraitConsts then
            config_id = Constants.TraitConsts.INSPECT_TRAIT_CONFIG_ID
        end
    end
    if not config_id then
        return nil
    end

    local ok_info, config_info = pcall(C_Traits.GetConfigInfo, config_id)
    if not ok_info or type(config_info) ~= "table" or type(config_info.treeIDs) ~= "table" then
        return nil
    end

    local points_spent = {}
    local total_spent = 0
    for _, tree_id in ipairs(config_info.treeIDs) do
        local tree_spent = 0
        local ok_cur, currency_info = pcall(C_Traits.GetTreeCurrencyInfo, config_id, tree_id, false)
        if ok_cur and type(currency_info) == "table" then
            for _, item in ipairs(currency_info) do
                if type(item.spent) == "number" then
                    tree_spent = tree_spent + item.spent
                end
            end
        end
        points_spent[#points_spent + 1] = tree_spent
        total_spent = total_spent + tree_spent
    end

    if total_spent > 0 and #points_spent < 2 then
        local tree_id = config_info.treeIDs[1]
        local split
        if tree_id and C_Traits.GetTreeNodes and C_Traits.GetNodeInfo then
            local nodes = {}
            local x_count, x_list = {}, {}
            local min_x, max_x
            local ok_nodes, node_ids = pcall(C_Traits.GetTreeNodes, tree_id)
            if ok_nodes and type(node_ids) == "table" then
                for _, node_id in ipairs(node_ids) do
                    local ok_n, node_info = pcall(C_Traits.GetNodeInfo, config_id, node_id)
                    if ok_n and type(node_info) == "table" and type(node_info.posX) == "number" then
                        local x = node_info.posX
                        local rank = (type(node_info.currentRank) == "number") and node_info.currentRank or 0
                        nodes[#nodes + 1] = { x = x, rank = rank }
                        if not x_count[x] then
                            x_count[x] = 0
                            x_list[#x_list + 1] = x
                        end
                        x_count[x] = x_count[x] + 1
                        min_x = (not min_x) and x or math.min(min_x, x)
                        max_x = (not max_x) and x or math.max(max_x, x)
                    end
                end
            end

            if #nodes > 0 and max_x and min_x and max_x > min_x then
                local per_column = { 0, 0, 0 }
                table.sort(x_list)
                local clusters = {}
                if #x_list >= 2 then
                    local gaps = {}
                    for i = 2, #x_list do
                        gaps[#gaps + 1] = x_list[i] - x_list[i - 1]
                    end
                    table.sort(gaps)
                    local threshold = gaps[math.ceil(#gaps / 2)] * 2.5
                    local current = { minX = x_list[1], maxX = x_list[1], count = x_count[x_list[1]] }
                    clusters[#clusters + 1] = current
                    for i = 2, #x_list do
                        if x_list[i] - x_list[i - 1] > threshold then
                            current = { minX = x_list[i], maxX = x_list[i], count = 0 }
                            clusters[#clusters + 1] = current
                        end
                        current.maxX = x_list[i]
                        current.count = current.count + x_count[x_list[i]]
                    end
                end

                if #clusters >= 3 then
                    local by_count = {}
                    for _, cluster in ipairs(clusters) do
                        by_count[#by_count + 1] = cluster
                    end
                    table.sort(by_count, function(a, b)
                        if a.count ~= b.count then
                            return a.count > b.count
                        end
                        return a.minX < b.minX
                    end)
                    local trees = { by_count[1], by_count[2], by_count[3] }
                    table.sort(trees, function(a, b) return a.minX < b.minX end)
                    for _, node in ipairs(nodes) do
                        for column, tree in ipairs(trees) do
                            if node.x >= tree.minX and node.x <= tree.maxX then
                                per_column[column] = per_column[column] + node.rank
                                break
                            end
                        end
                    end
                else
                    local width = (max_x - min_x) / 3
                    for _, node in ipairs(nodes) do
                        local column = math.min(3, math.floor((node.x - min_x) / width) + 1)
                        per_column[column] = per_column[column] + node.rank
                    end
                end

                if per_column[1] + per_column[2] + per_column[3] > 0 then
                    split = per_column
                end
            end
        end

        if split then
            points_spent = split
        end
    end

    return points_spent
end

--[[
 * Dominant tree from C_Traits. Untalented (0 points) → nil (class-base skins).
 * Never use GetSpecialization() on Forever: it returns 1 even with 0 points spent.
--]]
function SC.GetDominantTreeIndex(unit)
    unit = unit or "player"
    local points = SC.GetForeverPointsSpent(unit)
    if type(points) == "table" then
        local best_index, best_points, total = nil, -1, 0
        for i, spent in ipairs(points) do
            local n = tonumber(spent) or 0
            total = total + n
            if n > best_points then
                best_points = n
                best_index = i
            end
        end
        if total > 0 and best_index then
            return best_index, points, best_points
        end
        return nil, points, 0
    end

    if SC.IsForever(nil) then
        return nil, nil, 0
    end

    if UnitIsUnit and UnitIsUnit(unit, "player") then
        if C_SpecializationInfo and type(C_SpecializationInfo.GetSpecialization) == "function" then
            local ok, idx = pcall(C_SpecializationInfo.GetSpecialization)
            if ok and type(idx) == "number" and idx > 0 then
                return idx, points, 0
            end
        end
    end

    return nil, points, 0
end

function SC.RetailSpecToForeverId(addon, retail_spec_id, class_id)
    if type(retail_spec_id) ~= "number" then
        return nil
    end
    local tree_index = SC.RETAIL_SPEC_TREE_INDEX[retail_spec_id]
    if not tree_index or not class_id then
        return nil
    end
    local getter = addon and addon.GetSpecializationInfoForClassID
    if type(getter) == "function" then
        local ok, forever_id = pcall(getter, class_id, tree_index)
        if ok and forever_id then
            return forever_id
        end
    end
    if C_ClassTalents and C_ClassTalents.GetTraitTreeForSpec and C_Traits and C_Traits.GetGroupDisplayInfoByTreeID then
        local ok_spec, base_spec = pcall(function()
            if GetSpecializationInfoForClassID then
                return GetSpecializationInfoForClassID(class_id, 1)
            end
        end)
        if ok_spec and base_spec then
            local ok_tree, tree_id = pcall(C_ClassTalents.GetTraitTreeForSpec, base_spec)
            if ok_tree and tree_id then
                local ok_groups, groups = pcall(C_Traits.GetGroupDisplayInfoByTreeID, tree_id)
                if ok_groups and type(groups) == "table" and groups[tree_index] then
                    return groups[tree_index].groupID
                end
            end
        end
    end
    return nil
end

function SC.ResolveUnitSpecialization(base, unit)
    if not unit or not UnitExists(unit) or not UnitIsPlayer(unit) then
        return nil
    end

    if SC.IsForever(base) then
        local dominant = SC.GetDominantTreeIndex(unit)
        if dominant then
            local class_id = select(3, UnitClass(unit))
            -- Return Forever groupID when possible so SpecsMatch can compare either side.
            for retail_id, tree_index in pairs(SC.RETAIL_SPEC_TREE_INDEX) do
                if tree_index == dominant then
                    local forever_id = SC.RetailSpecToForeverId(base, retail_id, class_id)
                    if forever_id then
                        return forever_id
                    end
                end
            end
            -- Prefer retail ChrSpecialization id for this class + tree (SpecsMatch also checks tree index).
            local _, class_file = UnitClass(unit)
            for retail_id, tree_index in pairs(SC.RETAIL_SPEC_TREE_INDEX) do
                if tree_index == dominant then
                    local retail_class = SC.RETAIL_SPEC_CLASS and SC.RETAIL_SPEC_CLASS[retail_id]
                    if not retail_class or retail_class == class_file then
                        SC._lastDominantIndex = dominant
                        SC._lastDominantUnit = unit
                        return retail_id
                    end
                end
            end
            SC._lastDominantIndex = dominant
            SC._lastDominantUnit = unit
            return dominant
        end
    end

    if UnitIsUnit(unit, "player") then
        if base and type(base.GetCurrentSpecID) == "function" then
            local ok, spec_id = pcall(base.GetCurrentSpecID)
            if ok and spec_id ~= nil then
                return spec_id
            end
        end
        if PlayerUtil and type(PlayerUtil.GetCurrentSpecID) == "function" then
            local ok, spec_id = pcall(PlayerUtil.GetCurrentSpecID)
            if ok and spec_id ~= nil then
                return spec_id
            end
        end
        return nil
    end

    if type(GetInspectSpecialization) == "function" then
        local ok, spec_id = pcall(GetInspectSpecialization, unit)
        if ok and spec_id and spec_id ~= 0 then
            return spec_id
        end
    end
    return nil
end

function SC.SpecsMatch(base, actual_spec_id, want_spec, class_id)
    if want_spec == nil then
        return false
    end

    local want_id = want_spec
    if type(want_spec) == "string" and base and type(base.GetSpecialization) == "function" then
        local spec_info = base:GetSpecialization(want_spec)
        if type(spec_info) == "table" and spec_info.id then
            want_id = spec_info.id
        end
    end

    if actual_spec_id ~= nil and actual_spec_id == want_id then
        return true
    end

    if not SC.IsForever(base) then
        return false
    end

    local want_index = SC.RETAIL_SPEC_TREE_INDEX[want_id]
    if not want_index then
        return false
    end

    -- Compare by dominant tree index for the last resolved unit / player / target.
    local unit = "target"
    if UnitExists("target") and UnitIsPlayer("target") then
        unit = "target"
    else
        unit = "player"
    end
    local dominant = SC.GetDominantTreeIndex(unit)
    if dominant == want_index then
        return true
    end

    local forever_want = SC.RetailSpecToForeverId(base, want_id, class_id)
    return forever_want ~= nil and actual_spec_id == forever_want
end
