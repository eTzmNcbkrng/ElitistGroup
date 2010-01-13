if( GetLocale() ~= "esES" ) then return end
local L = {}
--@localization(locale="esES", format="lua_additive_table", handle-unlocalized="ignore")@
local ElitistGroup = select(2, ...)
ElitistGroup.L = setmetatable(L, {__index = ElitistGroup.L})
