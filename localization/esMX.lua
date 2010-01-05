if( GetLocale() ~= "esMX" ) then return end
local L = {}
--@localization(locale="esMX", format="lua_additive_table", escape-non-ascii=true, handle-unlocalized="ignore")@
local ElitistGroup = select(2, ...)
ElitistGroup.L = setmetatable(L, {__index = ElitistGroup.L})
