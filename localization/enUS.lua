local ElitistGroup = select(2, ...)
ElitistGroup.L = {
--@localization(locale="enUS", format="lua_table", same-key-is-true=true)@
}

--@debug@
ElitistGroup.L = setmetatable(ElitistGroup.L, {
	__index = function(tbl, value)
		rawset(tbl, value, value)
		return value
	end,
})
--@end-debug@
