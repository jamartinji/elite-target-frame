-- [ LOCALE LOADER ] Picks the correct locale table based on GetLocale().

ETF_Locales = ETF_Locales or {}
local loc = (GetLocale and GetLocale()) or "enUS"
if loc == "es" and ETF_Locales.esES then loc = "esES" end
local fallback = ETF_Locales.enUS or {}
local defaultStrings = {
    SectionTextures = "Available textures",
    SearchFilter = "Filter...",
    SectionLayerOffsets = "Per-layer offset",
    LayerOffsetX = "X",
    LayerOffsetY = "Y",
}
ETF_L = setmetatable(ETF_Locales[loc] or {}, {
    __index = function(_, k) return fallback[k] or defaultStrings[k] or k end
})
