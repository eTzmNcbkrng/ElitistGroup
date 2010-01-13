local ElitistGroup = select(2, ...)
local L = {}
--@localization(locale="enUS", format="lua_additive_table")@


ElitistGroup.L = L
--@debug@
ElitistGroup.L = setmetatable(ElitistGroup.L, {
	__index = function(tbl, value)
		rawset(tbl, value, value)
		return value
	end,
})
--@end-debug@
