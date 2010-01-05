if( GetLocale() ~= "zhCN" ) then return end

local ElitistGroup = select(2, ...)
ElitistGroup.L = setmetatable({
--@localization(locale="zhCN", format="lua_table", same-key-is-true=true, handle-unlocalized="ignore")@
}, {__index = ElitistGroup.L})
