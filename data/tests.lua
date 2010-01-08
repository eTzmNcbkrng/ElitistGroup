local TEST_DATA
function ElitistGroup:Test()
	local results = {gear = {passed = 0, tests = 0}, gems = {passed = 0, tests = 0}, enchants = {passed = 0, tests = 0}}
	
	for type, list in pairs(TEST_DATA) do
		local tbl = ElitistGroup[type == "gear" and "ITEM_TALENTTYPE" or type == "gems" and "GEM_TALENTTYPE" or type == "enchants" and "ENCHANT_TALENTTYPE"]
		for itemID, expected in pairs(list) do
			local itemType = type == "enchants" and tbl[string.match(itemID, "item:%d+:(%d+)")] or tbl[itemID]
			if( itemType == "unknown" or itemType ~= expected ) then
				results[type].failed = true
				table.insert(results[type], {item = itemID, type = itemType, expected = expected})
			else
				results[type].passed = results[type].passed + 1
			end
			
			results[type].tests = results[type].tests + 1
		end
	end
	
	for testType, testData in pairs(results) do
		if( testData.failed ) then
			print(string.format("Failed %d of %d tests for %s.", (testData.tests - testData.passed), testData.tests, testType))
			for _, result in pairs(testData) do
				if( type(result) == "table" ) then
					print(string.format("[%s] %s, %s expected got %s", result.item, select(2, GetItemInfo(result.item)) or result.item, result.expected, result.type))
				end
			end
		else
			print(string.format("Passed %d of %d tests for %s!", testData.passed, testData.tests, testType))
		end
	end
end


TEST_DATA = {
	["gear"] = {
		["item:47673"] = "melee-dps",
		["item:47412"] = "physical-all",
		["item:37651"] = "caster",
		["item:44008"] = "caster",
		["item:37718"] = "caster",
		["item:38259"] = "physical-dps",
		["item:30344"] = "pvp",
		["item:48148"] = "caster",
		["item:50259"] = "caster",
		["item:46075"] = "pvp",
		["item:47197"] = "melee-dps",
		["item:30490"] = "pvp",
		["item:50056"] = "caster",
		["item:37061"] = "caster",
		["item:45286"] = "physical-dps",
		["item:48652"] = "tank",
		["item:49983"] = "physical-dps",
		["item:47496"] = "physical-all",
		["item:37630"] = "caster",
		["item:44504"] = "physical-dps",
		["item:38287"] = "physical-dps",
		["item:45292"] = "caster",
		["item:47495"] = "melee-dps",
		["item:49848"] = "caster",
		["item:45620"] = "caster",
		["item:37642"] = "physical-all",
		["item:47664"] = "tank",
		["item:40974"] = "pvp",
		["item:50207"] = "tank",
		["item:47803"] = "caster",
		["item:47415"] = "tank",
		["item:45288"] = "caster",
		["item:37620"] = "tank",
		["item:41965"] = "pvp",
		["item:47991"] = "tank",
		["item:50263"] = "caster",
		["item:43353"] = "tank",
		["item:47692"] = "caster",
		["item:28377"] = "pvp",
		["item:48190"] = "physical-all",
		["item:35135"] = "pvp",
		["item:50783"] = "caster",
		["item:47562"] = "caster",
		["item:50240"] = "caster",
		["item:50309"] = "caster",
		["item:34676"] = "tank",
		["item:47174"] = "caster",
		["item:48362"] = "physical-all",
		["item:48369"] = "physical-all",
		["item:51200"] = "caster",
		["item:47691"] = "caster",
		["item:40527"] = "melee",
		["item:45819"] = "melee-dps",
		["item:40367"] = "physical-all",
		["item:35645"] = "physical-all",
		["item:39726"] = "tank",
		["item:50270"] = "physical-all",
		["item:40682"] = "caster-dps",
		["item:47773"] = "caster",
		["item:50312"] = "caster",
		["item:44063"] = "tank",
		["item:47482"] = "caster",
		["item:47768"] = "caster",
		["item:48390"] = "physical-dps",
		["item:45973"] = "physical-dps",
		["item:45294"] = "caster",
		["item:49968"] = "caster",
		["item:47880"] = "healer",
		["item:47568"] = "physical-all",
		["item:49000"] = "pvp",
		["item:47668"] = "tank/dps",
		["item:47511"] = "physical-dps",
		["item:37867"] = "caster",
		["item:47710"] = "caster",
		["item:50194"] = "melee-dps",
		["item:39500"] = "caster",
		["item:49823"] = "caster",
		["item:50845"] = "caster",
		["item:50827"] = "physical-all",
		["item:50355"] = "physical-dps",
		["item:40733"] = "melee",
		["item:50788"] = "melee",
		["item:40881"] = "pvp",
		["item:49809"] = "caster",
		["item:40890"] = "pvp",
		["item:47675"] = "physical-dps",
		["item:43408"] = "caster",
		["item:48560"] = "tank",
		["item:50210"] = "caster",
		["item:47560"] = "caster",
		["item:46082"] = "physical-dps",
		["item:45555"] = "physical-all",
		["item:47735"] = "tank",
		["item:47849"] = "physical-all",
		["item:50771"] = "caster",
		["item:37696"] = "caster",
		["item:47268"] = "melee",
		["item:47795"] = "caster",
		["item:45825"] = "tank",
		["item:40326"] = "caster",
		["item:45931"] = "physical-dps",
		["item:49485"] = "physical-all",
		["item:48194"] = "physical-all",
		["item:49298"] = "caster",
		["item:47305"] = "tank",
		["item:48653"] = "tank",
		["item:30487"] = "pvp",
		["item:48279"] = "physical-all",
		["item:48155"] = "caster",
		["item:39425"] = "caster",
		["item:47501"] = "caster",
		["item:42597"] = "healer",
		["item:42032"] = "pvp",
		["item:50009"] = "caster",
		["item:32054"] = "pvp",
		["item:44898"] = "pvp",
		["item:51205"] = "caster",
		["item:47522"] = "physical-all",
		["item:50386"] = "caster",
		["item:45696"] = "tank",
		["item:45933"] = "caster",
		["item:48400"] = "physical-dps",
		["item:46139"] = "caster",
		["item:48559"] = "tank",
		["item:49891"] = "caster",
		["item:50763"] = "tank",
		["item:50028"] = "caster",
		["item:50997"] = "caster",
		["item:47285"] = "physical-dps",
		["item:47329"] = "physical-all",
		["item:50789"] = "physical-all",
		["item:47604"] = "caster",
		["item:37856"] = "healer/dps",
		["item:39139"] = "melee-dps",
		["item:49835"] = "tank",
		["item:47243"] = "tank",
		["item:45821"] = "tank",
		["item:42122"] = "pvp",
		["item:42069"] = "pvp",
		["item:50463"] = "melee-dps",
		["item:50398"] = "caster",
		["item:50470"] = "physical-all",
		["item:41001"] = "pvp",
		["item:30489"] = "pvp",
		["item:48244"] = "physical-all",
		["item:37232"] = "caster",
		["item:40410"] = "tank",
		["item:45144"] = "tank",
		["item:45285"] = "physical-dps",
		["item:48299"] = "caster",
		["item:47582"] = "physical-all",
		["item:50805"] = "caster",
		["item:48149"] = "caster",
		["item:47446"] = "physical-dps",
		["item:44402"] = "tank",
		["item:50781"] = "caster",
		["item:40718"] = "tank",
		["item:46087"] = "pvp",
		["item:50792"] = "physical-all",
		["item:47271"] = "healer",
		["item:47316"] = "caster",
		["item:42115"] = "pvp",
		["item:50822"] = "caster",
		["item:47890"] = "caster",
		["item:50773"] = "caster",
		["item:40743"] = "tank",
		["item:47660"] = "tank",
		["item:42114"] = "pvp",
		["item:50340"] = "caster-dps",
		["item:47259"] = "physical-all",
		["item:48630"] = "melee-dps",
		["item:40342"] = "healer",
		["item:48999"] = "pvp",
		["item:49116"] = "tank",
		["item:48465"] = "tank",
		["item:47249"] = "caster",
		["item:45831"] = "caster",
		["item:41910"] = "pvp",
		["item:46191"] = "caster",
		["item:47200"] = "caster",
		["item:47855"] = "caster",
		["item:48557"] = "tank",
		["item:40927"] = "pvp",
		["item:50808"] = "tank",
		["item:50807"] = "caster",
		["item:47885"] = "tank",
		["item:48360"] = "physical-all",
		["item:50790"] = "tank",
		["item:49979"] = "caster",
		["item:47913"] = "caster",
		["item:47799"] = "caster",
		["item:46017"] = "caster",
		["item:47705"] = "physical-all",
		["item:50262"] = "physical-all",
		["item:40270"] = "caster",
		["item:47429"] = "melee",
		["item:48152"] = "caster",
		["item:40400"] = "tank",
		["item:47458"] = "melee-dps",
		["item:43828"] = "caster",
		["item:42070"] = "pvp",
		["item:45466"] = "caster",
		["item:37220"] = "tank",
		["item:41142"] = "pvp",
		["item:42081"] = "pvp",
		["item:50079"] = "melee-dps",
		["item:41223"] = "pvp",
		["item:39404"] = "physical-all",
		["item:37873"] = "caster",
		["item:38117"] = "melee-dps",
		["item:47714"] = "caster",
		["item:40462"] = "caster",
		["item:50402"] = "physical-all",
		["item:45694"] = "caster",
		["item:38322"] = "caster",
		["item:47442"] = "physical-all",
		["item:47732"] = "caster",
		["item:41235"] = "pvp",
		["item:45493"] = "caster",
		["item:45495"] = "caster",
		["item:42058"] = "pvp",
		["item:47500"] = "tank",
		["item:47494"] = "physical-all",
		["item:47862"] = "caster",
		["item:47277"] = "caster",
		["item:50296"] = "physical-all",
		["item:44661"] = "caster",
		["item:50267"] = "physical-dps",
		["item:45680"] = "caster",
		["item:35613"] = "physical-all",
		["item:47256"] = "caster",
		["item:44309"] = "caster",
		["item:50214"] = "caster",
		["item:45447"] = "caster",
		["item:40880"] = "pvp",
		["item:50352"] = "tank",
		["item:40939"] = "pvp",
		["item:50228"] = "physical-all",
		["item:50803"] = "physical-all",
		["item:47596"] = "physical-all",
		["item:42949"] = "melee-dps",
		["item:47290"] = "tank",
		["item:43305"] = "caster",
		["item:40432"] = "caster",
		["item:47309"] = "caster",
		["item:45828"] = "caster",
		["item:32368"] = "tank",
		["item:48333"] = "caster",
		["item:50313"] = "caster",
		["item:50278"] = "caster",
		["item:37667"] = "physical-all",
		["item:47419"] = "caster",
		["item:40255"] = "caster",
		["item:47327"] = "caster",
		["item:45135"] = "caster",
		["item:48669"] = "melee-dps",
		["item:48363"] = "physical-all",
		["item:47307"] = "caster",
		["item:45490"] = "caster",
		["item:42116"] = "pvp",
		["item:48188"] = "physical-all",
		["item:35651"] = "melee-dps",
		["item:50244"] = "caster",
		["item:47571"] = "tank",
		["item:47731"] = "tank",
		["item:47908"] = "caster",
		["item:47874"] = "caster",
		["item:37557"] = "physical-dps",
		["item:47528"] = "physical-all",
		["item:50169"] = "physical-all",
		["item:42074"] = "pvp",
		["item:48275"] = "physical-all",
		["item:50794"] = "tank",
		["item:50356"] = "tank",
		["item:50196"] = "caster",
		["item:48009"] = "tank",
		["item:47213"] = "caster-dps",
		["item:40350"] = "caster",
		["item:49304"] = "caster",
		["item:37192"] = "caster",
		["item:28442"] = "physical-all",
		["item:47859"] = "physical-dps",
		["item:48044"] = "tank",
		["item:39393"] = "physical-all",
		["item:46137"] = "caster",
		["item:47661"] = "tank/dps",
		["item:48391"] = "physical-dps",
		["item:43502"] = "caster",
		["item:47261"] = "caster",
		["item:47322"] = "caster",
		["item:40707"] = "tank",
		["item:40722"] = "tank",
		["item:47418"] = "physical-all",
		["item:47468"] = "caster",
		["item:44253"] = "tank/dps",
		["item:50260"] = "healer/dps",
		["item:48339"] = "caster",
		["item:47475"] = "physical-all",
		["item:47671"] = "healer",
		["item:48047"] = "physical-dps",
		["item:40323"] = "caster",
		["item:49821"] = "caster",
		["item:47861"] = "caster",
		["item:50000"] = "physical-all",
		["item:41156"] = "pvp",
		["item:45675"] = "physical-dps",
		["item:47467"] = "caster",
		["item:48195"] = "physical-all",
		["item:43171"] = "caster",
		["item:50283"] = "caster",
		["item:50403"] = "tank",
		["item:40579"] = "tank",
		["item:40685"] = "caster",
		["item:47804"] = "caster",
		["item:50824"] = "physical-all",
		["item:49977"] = "caster",
		["item:47462"] = "caster",
		["item:47805"] = "caster",
		["item:42989"] = "pvp",
		["item:48659"] = "tank",
		["item:47173"] = "caster",
		["item:48191"] = "physical-all",
		["item:48386"] = "physical-dps",
		["item:39606"] = "melee-dps",
		["item:50401"] = "physical-all",
		["item:48461"] = "tank",
		["item:46341"] = "caster",
		["item:47267"] = "physical-all",
		["item:33812"] = "pvp",
		["item:48011"] = "tank",
		["item:40723"] = "caster",
		["item:47177"] = "physical-all",
		["item:50107"] = "caster",
		["item:49996"] = "caster",
		["item:47272"] = "physical-all",
		["item:48395"] = "physical-dps",
		["item:40460"] = "caster",
		["item:45166"] = "tank",
		["item:45269"] = "caster",
		["item:48150"] = "caster",
		["item:37166"] = "physical-dps",
		["item:50397"] = "caster",
		["item:49853"] = "tank",
		["item:37683"] = "caster",
		["item:48993"] = "pvp",
		["item:44914"] = "pvp",
		["item:47477"] = "caster",
		["item:41903"] = "pvp",
		["item:30486"] = "pvp",
		["item:50779"] = "melee-dps",
		["item:48196"] = "physical-all",
		["item:47262"] = "caster",
		["item:48997"] = "pvp",
		["item:47476"] = "tank",
		["item:41144"] = "pvp",
		["item:50376"] = "physical-all",
		["item:41204"] = "pvp",
		["item:47662"] = "healer",
		["item:50048"] = "melee-dps",
		["item:45833"] = "physical-dps",
		["item:49481"] = "caster",
		["item:48338"] = "caster",
		["item:47308"] = "caster",
		["item:41953"] = "pvp",
		["item:50778"] = "physical-all",
		["item:47232"] = "melee-dps",
		["item:41231"] = "pvp",
		["item:49994"] = "caster",
		["item:50268"] = "tank",
		["item:47318"] = "caster",
		["item:48007"] = "physical-all",
		["item:48724"] = "caster",
		["item:47492"] = "physical-dps",
		["item:45319"] = "tank",
		["item:41087"] = "pvp",
		["item:40882"] = "pvp",
		["item:40884"] = "pvp",
		["item:42034"] = "pvp",
		["item:45212"] = "physical-all",
		["item:42067"] = "pvp",
		["item:50235"] = "tank",
		["item:41217"] = "pvp",
		["item:41205"] = "pvp",
		["item:42117"] = "pvp",
		["item:47302"] = "physical-all",
		["item:42028"] = "pvp",
		["item:48186"] = "caster",
		["item:40963"] = "pvp",
		["item:45829"] = "physical-all",
		["item:48334"] = "caster",
		["item:41226"] = "pvp",
		["item:50761"] = "melee-dps",
		["item:42551"] = "physical-all",
		["item:47869"] = "physical-dps",
		["item:47858"] = "caster",
		["item:49496"] = "physical-all",
		["item:42075"] = "pvp",
		["item:43306"] = "tank",
		["item:50468"] = "caster",
		["item:42987"] = "tank/dps",
		["item:47326"] = "caster",
		["item:40807"] = "pvp",
		["item:48151"] = "caster",
		["item:48396"] = "physical-dps",
		["item:50227"] = "caster",
		["item:48192"] = "physical-all",
		["item:47730"] = "physical-all",
		["item:40789"] = "pvp",
		["item:47303"] = "physical-all",
		["item:48992"] = "pvp",
		["item:49897"] = "physical-all",
		["item:50198"] = "physical-dps",
		["item:41157"] = "pvp",
		["item:45509"] = "tank/dps",
		["item:37082"] = "tank",
		["item:49978"] = "caster",
		["item:46159"] = "physical-all",
		["item:51212"] = "physical-dps",
		["item:50455"] = "melee-dps",
		["item:47569"] = "caster",
		["item:39723"] = "melee-dps",
		["item:46081"] = "caster",
		["item:47867"] = "physical-all",
		["item:48658"] = "tank",
		["item:41086"] = "pvp",
		["item:41971"] = "pvp",
		["item:47774"] = "caster",
		["item:49992"] = "caster",
		["item:49478"] = "physical-dps",
		["item:47282"] = "physical-all",
		["item:41898"] = "pvp",
		["item:47772"] = "caster",
		["item:49484"] = "caster",
		["item:45564"] = "physical-all",
		["item:48628"] = "melee",
		["item:43405"] = "caster",
		["item:50392"] = "caster",
		["item:42036"] = "pvp",
		["item:40463"] = "caster",
		["item:49960"] = "tank",
		["item:48181"] = "caster",
		["item:47659"] = "physical-all",
		["item:47218"] = "caster",
		["item:49786"] = "caster",
		["item:40530"] = "physical-dps",
		["item:50286"] = "caster",
		["item:40888"] = "pvp",
		["item:44167"] = "caster",
		["item:50776"] = "physical-all",
		["item:50387"] = "physical-all",
		["item:47670"] = "caster-dps",
		["item:47229"] = "physical-dps",
		["item:47678"] = "tank",
		["item:47273"] = "tank",
		["item:47884"] = "physical-all",
		["item:47852"] = "tank",
		["item:46140"] = "caster",
		["item:46136"] = "caster",
		["item:47248"] = "physical-all",
		["item:49118"] = "tank",
		["item:47800"] = "caster",
		["item:49487"] = "tank",
		["item:45520"] = "caster",
		["item:48626"] = "physical-dps",
		["item:39680"] = "melee-dps",
		["item:40671"] = "tank",
		["item:47493"] = "physical-dps",
		["item:48388"] = "melee-dps",
		["item:47438"] = "caster",
		["item:47314"] = "physical-all",
		["item:45451"] = "caster",
		["item:48655"] = "tank",
		["item:50782"] = "caster",
		["item:48654"] = "tank",
		["item:45291"] = "caster",
		["item:48697"] = "physical-all",
		["item:42990"] = "dps",
		["item:47684"] = "physical-all",
		["item:37869"] = "caster",
		["item:45334"] = "tank",
		["item:47563"] = "caster",
		["item:48273"] = "physical-all",
		["item:48337"] = "caster",
		["item:47584"] = "caster",
		["item:49486"] = "caster",
		["item:40250"] = "physical-all",
		["item:40991"] = "pvp",
		["item:48595"] = "caster",
		["item:40979"] = "pvp",
		["item:45835"] = "caster",
		["item:39229"] = "caster",
		["item:42614"] = "healer",
		["item:48335"] = "caster",
		["item:50272"] = "melee-dps",
		["item:39092"] = "melee-dps",
		["item:44912"] = "pvp",
		["item:50118"] = "physical-all",
		["item:33813"] = "pvp",
		["item:48629"] = "melee-dps",
		["item:48278"] = "physical-all",
		["item:40465"] = "caster",
		["item:50266"] = "caster",
		["item:48364"] = "physical-all",
		["item:40977"] = "pvp",
		["item:40889"] = "pvp",
		["item:42042"] = "pvp",
		["item:47798"] = "caster",
		["item:48722"] = "dps",
		["item:48656"] = "tank",
		["item:47887"] = "physical-all",
		["item:37194"] = "physical-all",
		["item:40684"] = "physical-dps",
		["item:48463"] = "tank",
		["item:47860"] = "caster",
		["item:40402"] = "tank",
		["item:40933"] = "pvp",
		["item:47287"] = "caster",
		["item:47425"] = "caster",
		["item:47600"] = "physical-all",
		["item:47315"] = "tank",
		["item:47320"] = "melee-dps",
		["item:47421"] = "tank",
		["item:42988"] = "caster",
		["item:47456"] = "caster",
		["item:47222"] = "physical-all",
		["item:47895"] = "caster",
		["item:40387"] = "tank",
		["item:50384"] = "caster",
		["item:43565"] = "tank",
		["item:39607"] = "melee",
		["item:47701"] = "caster",
		["item:47457"] = "physical-all",
		["item:48153"] = "caster",
		["item:47777"] = "caster",
		["item:48340"] = "caster",
		["item:45824"] = "melee-dps",
		["item:50469"] = "caster",
		["item:48014"] = "physical-all",
		["item:28425"] = "physical-all",
		["item:49812"] = "melee-dps",
		["item:50764"] = "physical-all",
		["item:45384"] = "tank",
		["item:47219"] = "caster",
		["item:47276"] = "caster",
		["item:37840"] = "physical-all",
		["item:40298"] = "caster",
		["item:51557"] = "caster",
		["item:41216"] = "pvp",
		["item:43363"] = "tank",
		["item:47658"] = "caster",
		["item:40569"] = "caster",
		["item:37784"] = "tank",
		["item:47448"] = "caster",
		["item:47554"] = "caster",
		["item:48666"] = "caster",
		["item:40866"] = "pvp",
		["item:50760"] = "tank",
		["item:47264"] = "caster",
		["item:50787"] = "physical-all",
		["item:48328"] = "caster",
		["item:47793"] = "caster",
		["item:47447"] = "caster",
		["item:47586"] = "caster",
		["item:47226"] = "caster",
		["item:45827"] = "physical-all",
		["item:50285"] = "tank",
		["item:48012"] = "caster",
		["item:50388"] = "tank",
		["item:40529"] = "melee",
		["item:43279"] = "tank",
		["item:50211"] = "caster",
		["item:45557"] = "caster",
		["item:30488"] = "pvp",
		["item:47902"] = "physical-dps",
		["item:41034"] = "pvp",
		["item:34075"] = "physical-dps",
		["item:50819"] = "caster",
		["item:45283"] = "tank",
		["item:47590"] = "physical-dps",
		["item:49790"] = "caster",
		["item:47284"] = "physical-all",
		["item:33919"] = "pvp",
		["item:48462"] = "tank",
		["item:45260"] = "caster",
		["item:45822"] = "caster",
		["item:47286"] = "caster",
		["item:49817"] = "physical-all",
		["item:47666"] = "dps",
		["item:49988"] = "physical-all",
		["item:47733"] = "caster",
		["item:47699"] = "tank",
		["item:47770"] = "caster",
		["item:47709"] = "physical-all",
		["item:37390"] = "physical-dps",
		["item:42578"] = "healer",
		["item:47775"] = "caster",
		["item:47215"] = "healer",
		["item:37216"] = "caster",
		["item:45702"] = "caster",
		["item:37852"] = "physical-all",
		["item:43404"] = "caster",
		["item:51170"] = "tank",
		["item:38218"] = "physical-dps",
		["item:47696"] = "melee-dps",
		["item:45297"] = "caster",
		["item:47734"] = "physical-dps",
		["item:49845"] = "caster",
		["item:49076"] = "caster-dps",
		["item:47529"] = "physical-all",
		["item:35161"] = "pvp",
		["item:47856"] = "caster",
		["item:47729"] = "melee-dps",
		["item:50206"] = "physical-all",
		["item:50293"] = "physical-all",
		["item:43085"] = "tank",
		["item:47988"] = "physical-all",
		["item:47514"] = "tank",
		["item:50447"] = "tank",
		["item:47422"] = "caster",
		["item:47221"] = "physical-all",
		["item:47573"] = "physical-dps",
		["item:45115"] = "caster",
		["item:40907"] = "pvp",
		["item:48561"] = "tank",
		["item:40074"] = "physical-all",
		["item:50966"] = "caster",
		["item:47497"] = "tank",
		["item:50273"] = "caster",
		["item:47796"] = "caster",
		["item:48670"] = "tank",
		["item:50342"] = "physical-dps",
		["item:50396"] = "caster",
		["item:50458"] = "caster-dps",
		["item:50212"] = "caster",
		["item:50318"] = "caster",
		["item:48271"] = "physical-all",
		["item:50314"] = "caster",
		["item:40826"] = "pvp",
		["item:50005"] = "caster",
		["item:49473"] = "caster",
		["item:47269"] = "tank",
		["item:45511"] = "caster",
		["item:40978"] = "pvp",
		["item:47580"] = "caster",
		["item:41946"] = "pvp",
		["item:47257"] = "physical-all",
		["item:48001"] = "caster",
		["item:50762"] = "physical-all",
		["item:47872"] = "tank",
		["item:47771"] = "caster",
		["item:50991"] = "tank",
		["item:47216"] = "tank",
	},
	["gems"] = {
		["item:40027"] = "caster",
		["item:40015"] = "tank",
		["item:40051"] = "caster",
		["item:40155"] = "caster",
		["item:40114"] = "physical-dps",
		["item:40136"] = "physical-dps",
		["item:40162"] = "melee",
		["item:36767"] = "tank",
		["item:40129"] = "melee-dps",
		["item:41401"] = "caster",
		["item:40089"] = "tank",
		["item:36766"] = "physical-dps",
		["item:39999"] = "physical-dps",
		["item:40147"] = "physical-all",
		["item:40113"] = "caster",
		["item:40150"] = "physical-all",
		["item:40169"] = "healer/dps",
		["item:40134"] = "caster",
		["item:49110"] = "all",
		["item:40159"] = "physical-dps",
		["item:41398"] = "physical-all",
		["item:41397"] = "tank",
		["item:39905"] = "physical-all",
		["item:40022"] = "melee-dps",
		["item:40026"] = "caster",
		["item:40179"] = "caster",
		["item:40128"] = "healer/dps",
		["item:39996"] = "melee-dps",
		["item:40038"] = "melee-dps",
		["item:40145"] = "pvp",
		["item:40029"] = "physical-dps",
		["item:40124"] = "healer/dps",
		["item:40123"] = "caster",
		["item:40052"] = "physical-dps",
		["item:40164"] = "caster",
		["item:40165"] = "healer/dps",
		["item:40118"] = "melee",
		["item:45883"] = "caster",
		["item:40133"] = "caster",
		["item:40125"] = "tank/dps",
		["item:40090"] = "pvp",
		["item:40117"] = "physical-dps",
		["item:41333"] = "caster",
		["item:40140"] = "physical-dps",
		["item:39927"] = "caster",
		["item:40168"] = "pvp",
		["item:42142"] = "melee-dps",
		["item:41339"] = "never",
		["item:40135"] = "pvp",
		["item:40138"] = "tank",
		["item:39998"] = "caster",
		["item:40153"] = "caster",
		["item:40167"] = "tank",
		["item:40017"] = "healer/dps",
		["item:41375"] = "never",
		["item:41285"] = "dps",
		["item:40146"] = "melee-dps",
		["item:40103"] = "pvp",
		["item:42144"] = "caster",
		["item:25894"] = "never",
		["item:40111"] = "melee-dps",
		["item:40152"] = "caster",
		["item:40112"] = "physical-all",
		["item:40055"] = "physical-dps",
		["item:40181"] = "pvp",
		["item:40088"] = "tank/dps",
		["item:40142"] = "melee-dps",
		["item:40156"] = "physical-dps",
		["item:40012"] = "caster",
		["item:40166"] = "tank/dps",
		["item:40013"] = "healer/dps",
		["item:40148"] = "physical-all",
		["item:41389"] = "caster",
		["item:40009"] = "caster",
		["item:40132"] = "caster",
		["item:40085"] = "caster",
		["item:40094"] = "caster",
		["item:40130"] = "physical-all",
		["item:24058"] = "melee-dps",
		["item:41380"] = "tank",
		["item:40031"] = "tank",
		["item:40001"] = "tank",
		["item:40014"] = "tank/dps",
		["item:40016"] = "pvp",
		["item:40025"] = "caster",
		["item:40008"] = "tank",
		["item:40119"] = "tank",
		["item:41438"] = "caster",
		["item:42153"] = "physical-dps",
		["item:40151"] = "caster",
	},
	["enchants"] = {
		["item:48462:3253"] = "tank",
		["item:48653:3253"] = "tank",
		["item:46017:3834"] = "caster",
		["item:51200:3832"] = "all",
		["item:47604:0"] = "none",
		["item:30490:2986"] = "physical-dps",
		["item:47273:3822"] = "physical-all",
		["item:47442:3845"] = "physical-dps",
		["item:49478:3817"] = "physical-dps",
		["item:50392:3820"] = "caster",
		["item:48195:3823"] = "physical-dps",
		["item:46341:3722"] = "caster",
		["item:42551:3795"] = "pvp",
		["item:47329:3789"] = "melee-dps",
		["item:40530:3875"] = "physical-dps",
		["item:28377:368"] = "physical-all",
		["item:48560:3816"] = "tank",
		["item:40410:3294"] = "tank",
		["item:50776:3607"] = "healer/dps",
		["item:47259:3822"] = "physical-all",
		["item:42949:0"] = "none",
		["item:47773:3234"] = "tank/dps",
		["item:47596:3832"] = "all",
		["item:50808:3327"] = "physical-all",
		["item:50048:3789"] = "melee-dps",
		["item:50782:3604"] = "dps",
		["item:47467:2332"] = "caster",
		["item:43353:3325"] = "physical-all",
		["item:47771:3820"] = "caster",
		["item:43171:3244"] = "caster",
		["item:40460:3246"] = "caster",
		["item:47885:1075"] = "tank",
		["item:40671:0"] = "none",
		["item:24146:0"] = "none",
		["item:47560:3826"] = "tank/dps",
		["item:47528:3789"] = "melee-dps",
		["item:40367:3826"] = "tank/dps",
		["item:48360:3808"] = "physical-dps",
		["item:47448:1128"] = "caster",
		["item:48340:0"] = "none",
		["item:48465:3811"] = "tank",
		["item:50000:3756"] = "physical-dps",
		["item:50760:0"] = "none",
		["item:50273:3855"] = "caster",
		["item:40323:2326"] = "caster",
		["item:35651:0"] = "none",
		["item:40888:1600"] = "physical-dps",
		["item:45260:1147"] = "caster",
		["item:47269:3232"] = "all",
		["item:47322:3834"] = "caster",
		["item:39393:3828"] = "physical-dps",
		["item:50285:0"] = "none",
		["item:50787:3789"] = "melee-dps",
		["item:50396:3810"] = "caster",
		["item:50266:0"] = "none",
		["item:48044:2673"] = "tank/dps",
		["item:50056:3721"] = "caster",
		["item:40723:3831"] = "healer/dps",
		["item:48652:0"] = "none",
		["item:50764:1099"] = "physical-all",
		["item:47582:3845"] = "physical-dps",
		["item:47869:3845"] = "physical-dps",
		["item:48669:1099"] = "physical-all",
		["item:49821:1128"] = "caster",
		["item:47584:2332"] = "caster",
		["item:49823:3831"] = "healer/dps",
		["item:47604:3252"] = "all",
		["item:37852:0"] = "none",
		["item:41217:3793"] = "pvp",
		["item:47573:3845"] = "physical-dps",
		["item:39680:0"] = "none",
		["item:39139:1597"] = "physical-dps",
		["item:50267:3225"] = "dps",
		["item:47684:3817"] = "physical-dps",
		["item:45384:3822"] = "physical-all",
		["item:47852:3850"] = "tank",
		["item:47696:3875"] = "physical-dps",
		["item:42070:3831"] = "healer/dps",
		["item:37867:1147"] = "caster",
		["item:41965:3852"] = "pvp",
		["item:47456:3606"] = "all",
		["item:30486:2933"] = "pvp",
		["item:41142:3603"] = "tank/dps",
		["item:47318:3719"] = "caster",
		["item:47277:2332"] = "caster",
		["item:50267:3789"] = "melee-dps",
		["item:48362:3823"] = "physical-dps",
		["item:41086:3297"] = "tank",
		["item:47267:3608"] = "ranged",
		["item:41156:3795"] = "pvp",
		["item:39425:3296"] = "caster",
		["item:28425:0"] = "none",
		["item:50079:1603"] = "physical-dps",
		["item:34676:1952"] = "tank",
		["item:47569:3830"] = "caster",
		["item:33812:2658"] = "tank/dps",
		["item:48148:3809"] = "caster",
		["item:50312:0"] = "none",
		["item:42075:0"] = "none",
		["item:47412:3832"] = "all",
		["item:49786:3252"] = "all",
		["item:47177:3234"] = "tank/dps",
		["item:48658:3260"] = "tank",
		["item:50470:3831"] = "healer/dps",
		["item:40927:3246"] = "caster",
		["item:41903:1075"] = "tank",
		["item:49988:3823"] = "physical-dps",
		["item:47482:3232"] = "all",
		["item:48670:3294"] = "tank",
		["item:48364:1603"] = "physical-dps",
		["item:41910:2332"] = "caster",
		["item:47803:3604"] = "dps",
		["item:48337:3234"] = "tank/dps",
		["item:40807:0"] = "none",
		["item:47772:3246"] = "caster",
		["item:41953:3233"] = "caster",
		["item:47714:3810"] = "caster",
		["item:47501:3722"] = "caster",
		["item:41087:3252"] = "all",
		["item:47675:3817"] = "physical-dps",
		["item:48993:3853"] = "pvp",
		["item:49968:3834"] = "caster",
		["item:48151:3820"] = "caster",
		["item:43305:3831"] = "healer/dps",
		["item:45269:2332"] = "caster",
		["item:40977:1075"] = "tank",
		["item:49994:2332"] = "caster",
		["item:41223:369"] = "caster",
		["item:50845:3810"] = "caster",
		["item:48992:3720"] = "caster",
		["item:47861:0"] = "none",
		["item:50792:3808"] = "physical-dps",
		["item:47709:3808"] = "physical-dps",
		["item:50212:0"] = "none",
		["item:49845:3830"] = "caster",
		["item:40270:0"] = "none",
		["item:47867:983"] = "physical-all",
		["item:48339:3721"] = "caster",
		["item:47554:3831"] = "healer/dps",
		["item:49496:3828"] = "physical-dps",
		["item:47798:3810"] = "caster",
		["item:40866:3793"] = "pvp",
		["item:47692:0"] = "none",
		["item:41226:2661"] = "all",
		["item:45493:3728"] = "caster",
		["item:40463:3252"] = "all",
		["item:40963:3794"] = "pvp",
		["item:46139:3872"] = "caster",
		["item:40933:3797"] = "pvp",
		["item:47493:3828"] = "physical-dps",
		["item:49848:0"] = "none",
		["item:45835:3246"] = "caster",
		["item:40907:3252"] = "all",
		["item:30489:3010"] = "physical-dps",
		["item:49484:0"] = "none",
		["item:47804:3820"] = "caster",
		["item:51205:3838"] = "caster",
		["item:42081:1099"] = "physical-all",
		["item:50776:3608"] = "ranged",
		["item:41205:3823"] = "physical-dps",
		["item:49817:3326"] = "physical-dps",
		["item:49979:3246"] = "caster",
		["item:50293:3811"] = "tank",
		["item:48997:3853"] = "pvp",
		["item:48149:3832"] = "all",
		["item:48461:3832"] = "all",
		["item:50789:3756"] = "physical-dps",
		["item:41001:3246"] = "caster",
		["item:42069:3243"] = "pvp",
		["item:47777:0"] = "none",
		["item:45212:3828"] = "physical-dps",
		["item:49891:3872"] = "caster",
		["item:45319:983"] = "physical-all",
		["item:41157:3795"] = "pvp",
		["item:47501:3831"] = "healer/dps",
		["item:48626:3832"] = "all",
		["item:40826:3795"] = "pvp",
		["item:49304:3830"] = "caster",
		["item:41034:3873"] = "caster",
		["item:48561:3822"] = "physical-all",
		["item:47710:3794"] = "pvp",
		["item:47586:3758"] = "caster",
		["item:46137:3832"] = "all",
		["item:48188:3818"] = "tank",
		["item:40722:0"] = "none",
		["item:50268:0"] = "none",
		["item:50278:3832"] = "all",
		["item:40884:0"] = "none",
		["item:41144:3222"] = "physical-all",
		["item:47560:0"] = "none",
		["item:40789:0"] = "none",
		["item:47770:3872"] = "caster",
		["item:47590:3832"] = "all",
		["item:47884:3368"] = "melee-dps",
		["item:47701:0"] = "none",
		["item:48155:3719"] = "caster",
		["item:48271:3328"] = "physical-dps",
		["item:47256:3831"] = "healer/dps",
		["item:48557:3297"] = "tank",
		["item:47256:3825"] = "healer/dps",
		["item:50788:3826"] = "tank/dps",
		["item:47774:3820"] = "caster",
		["item:47902:3823"] = "physical-dps",
		["item:43565:1099"] = "physical-all",
		["item:50794:1071"] = "tank",
		["item:47522:0"] = "none",
		["item:48463:3818"] = "tank",
		["item:47284:3826"] = "tank/dps",
		["item:50789:3845"] = "physical-dps",
		["item:47495:0"] = "none",
		["item:50210:0"] = "none",
		["item:41216:0"] = "none",
		["item:49298:3834"] = "caster",
		["item:50207:1075"] = "tank",
		["item:50469:3831"] = "healer/dps",
		["item:43363:0"] = "none",
		["item:50470:1099"] = "physical-all",
		["item:46191:0"] = "none",
		["item:47805:3872"] = "caster",
		["item:48328:3820"] = "caster",
		["item:47264:3832"] = "all",
		["item:48333:3820"] = "caster",
		["item:50783:3232"] = "all",
		["item:39500:0"] = "none",
		["item:48334:3246"] = "caster",
		["item:47249:3718"] = "caster",
		["item:46140:3820"] = "caster",
		["item:44898:3606"] = "all",
		["item:45135:3232"] = "all",
		["item:41231:1597"] = "physical-dps",
		["item:45493:3859"] = "caster",
		["item:47415:3297"] = "tank",
		["item:47457:2939"] = "physical-dps",
		["item:47586:0"] = "none",
		["item:50118:3832"] = "all",
		["item:39092:0"] = "none",
		["item:47496:3850"] = "tank",
		["item:48595:3807"] = "caster",
		["item:47582:3850"] = "tank",
		["item:49809:1119"] = "caster",
		["item:48655:3822"] = "physical-all",
		["item:28442:3225"] = "dps",
		["item:45283:3850"] = "tank",
		["item:37630:983"] = "physical-all",
		["item:40991:3245"] = "pvp",
		["item:47500:3788"] = "tank",
		["item:49790:3855"] = "caster",
		["item:40882:1597"] = "physical-dps",
		["item:48395:3793"] = "pvp",
		["item:45166:3232"] = "all",
		["item:48630:1603"] = "physical-dps",
		["item:48390:3793"] = "pvp",
		["item:47800:3872"] = "caster",
		["item:48628:3823"] = "physical-dps",
		["item:47775:3872"] = "caster",
		["item:47691:3819"] = "caster",
		["item:44008:3758"] = "caster",
		["item:40890:1600"] = "physical-dps",
		["item:48369:3823"] = "physical-dps",
		["item:47691:3797"] = "pvp",
		["item:48659:3818"] = "tank",
		["item:48654:3818"] = "tank",
		["item:47497:3818"] = "tank",
		["item:40529:3823"] = "physical-dps",
		["item:42074:1099"] = "physical-all",
		["item:50318:0"] = "none",
		["item:47699:0"] = "none",
		["item:50286:0"] = "none",
		["item:50273:3790"] = "dps",
		["item:40979:3232"] = "all",
		["item:50194:1603"] = "physical-dps",
		["item:50227:3830"] = "caster",
		["item:50009:3232"] = "all",
		["item:47492:1603"] = "physical-dps",
		["item:47861:2326"] = "caster",
		["item:43279:1892"] = "tank",
		["item:49992:3854"] = "caster",
		["item:50782:0"] = "none",
		["item:46136:3810"] = "caster",
		["item:47418:3831"] = "healer/dps",
		["item:44167:0"] = "none",
		["item:40927:0"] = "none",
		["item:47860:3838"] = "caster",
		["item:47501:0"] = "none",
		["item:47796:3820"] = "caster",
		["item:47248:3826"] = "tank/dps",
		["item:47692:3820"] = "caster",
		["item:30488:3003"] = "physical-dps",
		["item:45520:3246"] = "caster",
		["item:30487:684"] = "melee-dps",
		["item:48190:3822"] = "physical-all",
		["item:40722:1099"] = "physical-all",
		["item:47446:3789"] = "melee-dps",
		["item:45833:1603"] = "physical-dps",
		["item:47795:3719"] = "caster",
		["item:50296:2673"] = "tank/dps",
		["item:48192:3330"] = "tank",
		["item:50822:3246"] = "caster",
		["item:37216:0"] = "none",
		["item:40400:1952"] = "tank",
		["item:48299:3809"] = "caster",
		["item:48188:0"] = "none",
		["item:50272:3832"] = "all",
		["item:47269:1075"] = "tank",
		["item:48656:3811"] = "tank",
		["item:50966:3854"] = "caster",
		["item:47511:1597"] = "physical-dps",
		["item:47177:3330"] = "tank",
		["item:50283:3826"] = "tank/dps",
		["item:47710:3809"] = "caster",
		["item:47197:0"] = "none",
		["item:48396:3832"] = "all",
		["item:50771:3834"] = "caster",
		["item:49983:3232"] = "all",
		["item:47604:3832"] = "all",
		["item:50244:3810"] = "caster",
		["item:48047:3823"] = "physical-dps",
		["item:48244:1603"] = "physical-dps",
		["item:47314:3789"] = "melee-dps",
		["item:37840:0"] = "none",
		["item:50794:0"] = "none",
		["item:47805:3719"] = "caster",
		["item:40939:0"] = "none",
		["item:48150:3719"] = "caster",
		["item:37620:0"] = "none",
		["item:47422:3834"] = "caster",
		["item:42058:3825"] = "healer/dps",
		["item:45620:3834"] = "caster",
		["item:48186:3832"] = "all",
		["item:41946:3820"] = "caster",
		["item:47770:3719"] = "caster",
		["item:37696:3758"] = "caster",
		["item:48629:3817"] = "physical-dps",
		["item:39723:3817"] = "physical-dps",
		["item:48012:3232"] = "all",
		["item:45564:1075"] = "tank",
		["item:47248:1075"] = "tank",
		["item:40569:3832"] = "all",
		["item:49481:3797"] = "pvp",
		["item:48194:3817"] = "physical-dps",
		["item:48388:3795"] = "pvp",
		["item:47475:3789"] = "melee-dps",
		["item:37061:1128"] = "caster",
		["item:47221:3837"] = "tank",
		["item:50761:3847"] = "tank",
		["item:47895:1128"] = "caster",
		["item:47580:2332"] = "caster",
		["item:37082:0"] = "none",
		["item:50468:3831"] = "healer/dps",
		["item:50206:0"] = "none",
		["item:40326:1147"] = "caster",
		["item:48181:3820"] = "caster",
		["item:47256:3722"] = "caster",
		["item:47173:2661"] = "all",
		["item:40579:1953"] = "tank",
		["item:43502:1147"] = "caster",
		["item:49960:3757"] = "tank",
		["item:51212:3817"] = "physical-dps",
		["item:40462:3719"] = "caster",
		["item:48012:3826"] = "tank/dps",
		["item:37667:1606"] = "physical-dps",
		["item:48666:3859"] = "caster",
		["item:48275:3252"] = "all",
		["item:40889:3845"] = "physical-dps",
		["item:50286:3826"] = "tank/dps",
		["item:47793:3810"] = "caster",
		["item:48273:3222"] = "physical-all",
		["item:23346:0"] = "none",
		["item:50827:3222"] = "physical-all",
		["item:48400:3808"] = "physical-dps",
		["item:47696:3793"] = "pvp",
		["item:47773:3246"] = "caster",
		["item:47302:3827"] = "physical-dps",
		["item:50819:3810"] = "caster",
		["item:39726:3253"] = "tank",
		["item:48191:3811"] = "tank",
		["item:47285:3789"] = "melee-dps",
		["item:47277:2326"] = "caster",
		["item:47699:3837"] = "tank",
		["item:47261:3834"] = "caster",
		["item:41226:3845"] = "physical-dps",
		["item:45291:2332"] = "caster",
		["item:48153:3246"] = "caster",
		["item:40907:0"] = "none",
		["item:40743:1075"] = "tank",
		["item:48278:3823"] = "physical-dps",
		["item:47326:3246"] = "caster",
		["item:47768:3810"] = "caster",
		["item:47529:0"] = "none",
		["item:40298:3819"] = "caster",
		["item:48391:3252"] = "all",
		["item:50240:3246"] = "caster",
		["item:46159:3330"] = "tank",
		["item:47232:0"] = "none",
		["item:50214:3819"] = "caster",
		["item:48279:3793"] = "pvp",
		["item:47496:3757"] = "tank",
		["item:40527:1603"] = "physical-dps",
		["item:49473:3819"] = "caster",
		["item:48148:3810"] = "caster",
		["item:47571:3757"] = "tank",
		["item:39404:983"] = "physical-all",
		["item:50824:0"] = "none",
		["item:50107:3246"] = "caster",
		["item:47908:3721"] = "caster",
		["item:50028:3834"] = "caster",
		["item:50210:3834"] = "caster",
		["item:47887:3252"] = "all",
		["item:45680:1119"] = "caster",
		["item:48196:3832"] = "all",
		["item:47600:3832"] = "all",
		["item:24145:0"] = "none",
		["item:37856:0"] = "none",
		["item:48395:3808"] = "physical-dps",
		["item:40733:3845"] = "physical-dps",
		["item:50210:3830"] = "caster",
		["item:48152:3246"] = "caster",
		["item:47705:3808"] = "physical-dps",
		["item:40465:3807"] = "caster",
		["item:43085:1952"] = "tank",
		["item:49996:3832"] = "all",
		["item:48190:0"] = "none",
		["item:41204:0"] = "none",
		["item:47799:0"] = "none",
		["item:47775:0"] = "none",
		["item:47421:1952"] = "tank",
		["item:47514:3811"] = "tank",
		["item:47678:3818"] = "tank",
		["item:49897:1597"] = "physical-dps",
		["item:39606:0"] = "none",
		["item:40402:2673"] = "tank/dps",
		["item:50469:3722"] = "caster",
		["item:40722:1951"] = "tank",
		["item:47803:3246"] = "caster",
		["item:47320:1099"] = "physical-all",
		["item:51170:3811"] = "tank",
		["item:39607:3823"] = "physical-dps",
		["item:47226:0"] = "none",
		["item:47497:0"] = "none",
		["item:50214:0"] = "none",
		["item:47884:3827"] = "physical-dps",
		["item:47874:3834"] = "caster",
		["item:40250:1099"] = "physical-all",
		["item:33813:2647"] = "melee-dps",
		["item:49835:0"] = "none",
		["item:40880:3232"] = "all",
		["item:47522:2673"] = "tank/dps",
		["item:47425:3832"] = "all",
		["item:48014:3817"] = "physical-dps",
		["item:48363:3817"] = "physical-dps",
		["item:45973:1099"] = "physical-all",
		["item:42067:3605"] = "physical-dps",
		["item:50805:3854"] = "caster",
		["item:37620:3850"] = "tank",
		["item:47586:2332"] = "caster",
		["item:47287:1128"] = "caster",
		["item:43405:0"] = "none",
		["item:48559:0"] = "none",
		["item:50779:3817"] = "physical-dps",
		["item:50807:3820"] = "caster",
		["item:45288:3252"] = "all",
		["item:48338:3820"] = "caster",
		["item:47991:3850"] = "tank",
		["item:47262:3826"] = "tank/dps",
		["item:45334:3832"] = "all",
		["item:47462:3832"] = "all",
		["item:47438:2332"] = "caster",
		["item:41971:3246"] = "caster",
		["item:48386:3832"] = "all",
		["item:48653:0"] = "none",
		["item:48335:3832"] = "all",
		["item:47800:0"] = "none",
		["item:47257:1099"] = "physical-all",
	},
}
