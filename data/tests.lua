local TEST_DATA
function ElitistGroup:Test()
	local results = {gear = {passed = 0, tests = 0}, gems = {passed = 0, tests = 0}, enchants = {passed = 0, tests = 0}}
	
	for type, list in pairs(TEST_DATA) do
		local tbl = ElitistGroup[type == "gear" and "ITEM_TALENTTYPE" or type == "gems" and "GEM_TALENTTYPE" or type == "enchants" and "ENCHANT_TALENTTYPE"]
		for itemID, expected in pairs(list) do
			local itemQuality = type == "gear" and select(3, GetItemInfo(itemID))
			if( not itemQuality or itemQuality > 1 ) then
				local itemType = tbl[itemID]
				if( itemType == "unknown" or itemType ~= expected ) then
					results[type].failed = true
					table.insert(results[type], {item = itemID, type = itemType, expected = expected})
				else
					results[type].passed = results[type].passed + 1
				end
				
				results[type].tests = results[type].tests + 1
			end
		end
	end
	
	for testType, testData in pairs(results) do
		if( testData.failed ) then
			print(string.format("Failed %d of %d tests for %s.", (testData.tests - testData.passed), testData.tests, testType))
			for _, result in pairs(testData) do
				if( type(result) == "table" ) then
					if( testType == "enchants" ) then
						result.item = string.format("item:6948:%s", result.item)
					end
					
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
		["item:47729"] = "melee-dps",
		["item:37217"] = "melee-dps",
		["item:50800"] = "physical-all",
		["item:37651"] = "caster",
		["item:44008"] = "caster-spirit",
		["item:47867"] = "physical-all",
		["item:47456"] = "caster",
		["item:41836"] = "pvp",
		["item:50264"] = "physical-all",
		["item:30344"] = "pvp",
		["item:40433"] = "caster",
		["item:48992"] = "pvp",
		["item:40241"] = "caster",
		["item:41655"] = "pvp",
		["item:50259"] = "caster",
		["item:46075"] = "pvp",
		["item:47695"] = "caster-spirit",
		["item:47197"] = "melee-dps",
		["item:30490"] = "pvp",
		["item:50056"] = "caster",
		["item:37061"] = "caster",
		["item:45286"] = "physical-dps",
		["item:40807"] = "pvp",
		["item:47688"] = "physical-all",
		["item:49983"] = "physical-dps",
		["item:47496"] = "physical-all",
		["item:37630"] = "caster-spirit",
		["item:44504"] = "physical-dps",
		["item:38287"] = "physical-dps",
		["item:45292"] = "caster",
		["item:47311"] = "physical-all",
		["item:40717"] = "physical-all",
		["item:47495"] = "melee-dps",
		["item:49848"] = "caster-spirit",
		["item:45620"] = "caster-spirit",
		["item:37642"] = "physical-all",
		["item:47664"] = "tank",
		["item:42117"] = "pvp",
		["item:50207"] = "tank",
		["item:47803"] = "caster",
		["item:47415"] = "tank",
		["item:45288"] = "caster",
		["item:37620"] = "tank",
		["item:41965"] = "pvp",
		["item:47991"] = "tank",
		["item:50263"] = "caster-spirit",
		["item:48272"] = "physical-all",
		["item:47692"] = "caster",
		["item:28377"] = "pvp",
		["item:48190"] = "physical-all",
		["item:35135"] = "pvp",
		["item:50783"] = "caster",
		["item:47562"] = "caster",
		["item:50240"] = "caster",
		["item:48151"] = "caster-spirit",
		["item:34676"] = "tank",
		["item:48592"] = "caster",
		["item:47174"] = "caster-spirit",
		["item:48240"] = "physical-all",
		["item:48362"] = "physical-all",
		["item:48369"] = "physical-all",
		["item:51200"] = "caster",
		["item:50376"] = "physical-all",
		["item:40527"] = "melee",
		["item:45819"] = "melee-dps",
		["item:40367"] = "physical-all",
		["item:35645"] = "physical-all",
		["item:42034"] = "pvp",
		["item:43829"] = "physical-dps",
		["item:50270"] = "physical-all",
		["item:40682"] = "caster-dps",
		["item:47773"] = "caster",
		["item:50312"] = "caster-spirit",
		["item:47302"] = "physical-all",
		["item:47482"] = "caster",
		["item:47260"] = "tank",
		["item:47768"] = "caster",
		["item:43838"] = "physical-dps",
		["item:43947"] = "melee-dps",
		["item:48020"] = "melee",
		["item:45973"] = "physical-dps",
		["item:45294"] = "caster-spirit",
		["item:49968"] = "caster-spirit",
		["item:47420"] = "physical-all",
		["item:44014"] = "physical-dps",
		["item:47568"] = "physical-all",
		["item:49000"] = "pvp",
		["item:47668"] = "tank/dps",
		["item:47511"] = "physical-dps",
		["item:37867"] = "caster-spirit",
		["item:47710"] = "caster-spirit",
		["item:49980"] = "caster",
		["item:50194"] = "melee-dps",
		["item:39500"] = "caster",
		["item:49823"] = "caster",
		["item:50845"] = "caster",
		["item:50827"] = "physical-all",
		["item:50355"] = "physical-dps",
		["item:40733"] = "melee",
		["item:50788"] = "physical-dps",
		["item:40881"] = "pvp",
		["item:49809"] = "caster-spirit",
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
		["item:37696"] = "caster-spirit",
		["item:47268"] = "melee",
		["item:47795"] = "caster",
		["item:50098"] = "physical-dps",
		["item:45205"] = "melee-dps",
		["item:45825"] = "tank",
		["item:40326"] = "caster-spirit",
		["item:45931"] = "physical-dps",
		["item:49485"] = "physical-all",
		["item:48194"] = "physical-all",
		["item:49838"] = "physical-all",
		["item:49298"] = "caster",
		["item:47305"] = "tank",
		["item:48653"] = "tank",
		["item:30487"] = "pvp",
		["item:48279"] = "physical-all",
		["item:48155"] = "caster-spirit",
		["item:39425"] = "caster",
		["item:47501"] = "caster",
		["item:42597"] = "healer",
		["item:42032"] = "pvp",
		["item:50009"] = "caster-spirit",
		["item:32054"] = "pvp",
		["item:44898"] = "pvp",
		["item:50762"] = "physical-all",
		["item:41971"] = "pvp",
		["item:50386"] = "caster",
		["item:45696"] = "tank",
		["item:45933"] = "caster",
		["item:48400"] = "physical-dps",
		["item:46139"] = "caster-spirit",
		["item:48559"] = "tank",
		["item:49891"] = "caster",
		["item:47293"] = "caster-spirit",
		["item:50763"] = "tank",
		["item:50028"] = "caster",
		["item:50997"] = "caster-spirit",
		["item:44167"] = "caster",
		["item:47329"] = "physical-all",
		["item:50789"] = "physical-all",
		["item:47604"] = "caster",
		["item:43566"] = "physical-all",
		["item:39139"] = "melee-dps",
		["item:49835"] = "tank",
		["item:47243"] = "tank",
		["item:45821"] = "tank",
		["item:42122"] = "pvp",
		["item:42069"] = "pvp",
		["item:50463"] = "melee-dps",
		["item:44399"] = "melee-dps",
		["item:50398"] = "caster",
		["item:50105"] = "physical-all",
		["item:41001"] = "pvp",
		["item:47598"] = "caster",
		["item:30489"] = "pvp",
		["item:47492"] = "physical-dps",
		["item:37232"] = "caster",
		["item:40410"] = "tank",
		["item:45144"] = "tank",
		["item:45285"] = "physical-dps",
		["item:48299"] = "caster",
		["item:47582"] = "physical-all",
		["item:47473"] = "melee",
		["item:48149"] = "caster-spirit",
		["item:47446"] = "physical-dps",
		["item:44402"] = "tank",
		["item:50781"] = "caster",
		["item:40718"] = "tank",
		["item:46087"] = "pvp",
		["item:50792"] = "physical-all",
		["item:47271"] = "healer",
		["item:47316"] = "caster",
		["item:42115"] = "pvp",
		["item:45510"] = "melee-dps",
		["item:50822"] = "caster",
		["item:47296"] = "physical-all",
		["item:47890"] = "caster",
		["item:41681"] = "pvp",
		["item:50773"] = "caster-spirit",
		["item:40743"] = "tank",
		["item:47660"] = "tank",
		["item:41087"] = "pvp",
		["item:50340"] = "caster-dps",
		["item:47259"] = "physical-all",
		["item:48630"] = "melee-dps",
		["item:49306"] = "tank",
		["item:50268"] = "tank",
		["item:48999"] = "pvp",
		["item:49116"] = "tank",
		["item:48465"] = "tank",
		["item:47249"] = "caster",
		["item:45145"] = "tank",
		["item:47282"] = "physical-all",
		["item:45831"] = "caster-spirit",
		["item:47771"] = "caster",
		["item:50290"] = "tank",
		["item:41910"] = "pvp",
		["item:46191"] = "caster-spirit",
		["item:47200"] = "caster-spirit",
		["item:50203"] = "physical-all",
		["item:37574"] = "healer/dps",
		["item:42114"] = "pvp",
		["item:45257"] = "caster-spirit",
		["item:40578"] = "melee-dps",
		["item:47855"] = "caster",
		["item:48557"] = "tank",
		["item:40927"] = "pvp",
		["item:39193"] = "caster",
		["item:50807"] = "caster-spirit",
		["item:41946"] = "pvp",
		["item:47885"] = "tank",
		["item:47281"] = "physical-all",
		["item:48360"] = "physical-all",
		["item:48498"] = "melee",
		["item:47667"] = "melee-dps",
		["item:47285"] = "physical-dps",
		["item:50796"] = "caster",
		["item:42990"] = "dps",
		["item:49979"] = "caster-spirit",
		["item:47913"] = "caster",
		["item:49490"] = "caster-spirit",
		["item:47799"] = "caster-spirit",
		["item:46017"] = "caster",
		["item:47705"] = "physical-all",
		["item:50262"] = "physical-all",
		["item:51205"] = "caster",
		["item:48069"] = "caster-spirit",
		["item:49998"] = "physical-all",
		["item:40270"] = "caster-spirit",
		["item:48043"] = "physical-all",
		["item:45833"] = "physical-dps",
		["item:47429"] = "melee",
		["item:41766"] = "pvp",
		["item:48152"] = "caster-spirit",
		["item:40400"] = "tank",
		["item:47458"] = "melee-dps",
		["item:42075"] = "pvp",
		["item:47461"] = "physical-all",
		["item:42070"] = "pvp",
		["item:45466"] = "caster",
		["item:50088"] = "physical-all",
		["item:37220"] = "tank",
		["item:38231"] = "melee",
		["item:50399"] = "caster",
		["item:41142"] = "pvp",
		["item:42081"] = "pvp",
		["item:50079"] = "melee-dps",
		["item:40883"] = "pvp",
		["item:50005"] = "caster",
		["item:41223"] = "pvp",
		["item:39404"] = "physical-all",
		["item:41205"] = "pvp",
		["item:37873"] = "caster",
		["item:38117"] = "melee-dps",
		["item:50314"] = "caster",
		["item:47280"] = "caster",
		["item:47714"] = "caster",
		["item:40462"] = "caster-spirit",
		["item:50402"] = "physical-all",
		["item:47796"] = "caster-spirit",
		["item:45694"] = "caster-spirit",
		["item:50273"] = "caster",
		["item:41226"] = "pvp",
		["item:38322"] = "caster",
		["item:47691"] = "caster-spirit",
		["item:47442"] = "physical-all",
		["item:47732"] = "caster-spirit",
		["item:41235"] = "pvp",
		["item:45493"] = "caster-spirit",
		["item:40786"] = "pvp",
		["item:37949"] = "physical-dps",
		["item:48390"] = "physical-dps",
		["item:50095"] = "melee-dps",
		["item:42058"] = "pvp",
		["item:47500"] = "tank",
		["item:47494"] = "physical-all",
		["item:39726"] = "tank",
		["item:47862"] = "caster",
		["item:47600"] = "physical-all",
		["item:47997"] = "caster",
		["item:47277"] = "caster-spirit",
		["item:47497"] = "tank",
		["item:41650"] = "pvp",
		["item:44661"] = "caster",
		["item:46140"] = "caster-spirit",
		["item:50296"] = "physical-all",
		["item:43353"] = "tank",
		["item:50267"] = "physical-dps",
		["item:37150"] = "melee-dps",
		["item:45680"] = "caster",
		["item:45210"] = "physical-all",
		["item:35613"] = "physical-all",
		["item:44324"] = "physical-dps",
		["item:42126"] = "pvp",
		["item:48005"] = "caster",
		["item:41355"] = "melee-dps",
		["item:47256"] = "caster-spirit",
		["item:44309"] = "caster-spirit",
		["item:49791"] = "melee-dps",
		["item:41217"] = "pvp",
		["item:50211"] = "caster",
		["item:45447"] = "caster-spirit",
		["item:47514"] = "tank",
		["item:49076"] = "caster-dps",
		["item:40880"] = "pvp",
		["item:50352"] = "tank",
		["item:40939"] = "pvp",
		["item:47226"] = "caster",
		["item:47176"] = "physical-dps",
		["item:50803"] = "physical-all",
		["item:50228"] = "physical-all",
		["item:47596"] = "physical-all",
		["item:45829"] = "physical-all",
		["item:47910"] = "tank",
		["item:42949"] = "melee-dps",
		["item:45495"] = "caster-spirit",
		["item:38218"] = "physical-dps",
		["item:47290"] = "tank",
		["item:43305"] = "caster",
		["item:40432"] = "caster",
		["item:47309"] = "caster-spirit",
		["item:40574"] = "melee-dps",
		["item:48001"] = "caster",
		["item:40342"] = "healer",
		["item:45828"] = "caster",
		["item:40849"] = "pvp",
		["item:37216"] = "caster",
		["item:32368"] = "tank",
		["item:28065"] = "caster-dps",
		["item:37171"] = "melee-dps",
		["item:48333"] = "caster",
		["item:50805"] = "caster-spirit",
		["item:50313"] = "caster",
		["item:49473"] = "caster-spirit",
		["item:37390"] = "physical-dps",
		["item:50278"] = "caster",
		["item:37667"] = "physical-all",
		["item:47419"] = "caster-spirit",
		["item:40255"] = "caster",
		["item:47327"] = "caster-spirit",
		["item:47709"] = "physical-all",
		["item:47770"] = "caster-spirit",
		["item:39306"] = "caster",
		["item:43404"] = "caster-spirit",
		["item:42067"] = "pvp",
		["item:40187"] = "caster",
		["item:49888"] = "physical-dps",
		["item:46072"] = "pvp",
		["item:48363"] = "physical-all",
		["item:47307"] = "caster",
		["item:48669"] = "melee-dps",
		["item:39421"] = "physical-all",
		["item:45490"] = "caster",
		["item:42116"] = "pvp",
		["item:49817"] = "physical-all",
		["item:48062"] = "caster-spirit",
		["item:50470"] = "physical-all",
		["item:40250"] = "physical-all",
		["item:35651"] = "melee-dps",
		["item:48244"] = "physical-all",
		["item:48188"] = "physical-all",
		["item:51557"] = "caster",
		["item:50244"] = "caster",
		["item:50198"] = "physical-dps",
		["item:47215"] = "healer",
		["item:49478"] = "physical-dps",
		["item:47908"] = "caster",
		["item:49790"] = "caster-spirit",
		["item:47731"] = "tank",
		["item:47522"] = "physical-all",
		["item:47874"] = "caster",
		["item:49951"] = "melee-dps",
		["item:47248"] = "physical-all",
		["item:34075"] = "physical-dps",
		["item:37557"] = "physical-dps",
		["item:47528"] = "physical-all",
		["item:49496"] = "physical-all",
		["item:42074"] = "pvp",
		["item:39888"] = "melee-dps",
		["item:48275"] = "physical-all",
		["item:47993"] = "physical-dps",
		["item:50286"] = "caster-spirit",
		["item:37723"] = "physical-dps",
		["item:40403"] = "physical-all",
		["item:50794"] = "tank",
		["item:50787"] = "physical-all",
		["item:50196"] = "caster",
		["item:48009"] = "tank",
		["item:44912"] = "pvp",
		["item:50272"] = "melee-dps",
		["item:38614"] = "physical-all",
		["item:47213"] = "caster-dps",
		["item:40350"] = "caster",
		["item:40402"] = "tank",
		["item:49304"] = "caster",
		["item:41349"] = "pvp",
		["item:35161"] = "pvp",
		["item:50285"] = "tank",
		["item:37192"] = "caster",
		["item:40463"] = "caster-spirit",
		["item:44306"] = "melee-dps",
		["item:47859"] = "physical-dps",
		["item:28442"] = "physical-all",
		["item:48044"] = "tank",
		["item:47412"] = "physical-all",
		["item:40387"] = "tank",
		["item:39393"] = "physical-all",
		["item:46137"] = "caster",
		["item:47661"] = "tank/dps",
		["item:48391"] = "physical-dps",
		["item:48598"] = "caster",
		["item:43502"] = "caster-spirit",
		["item:50169"] = "physical-all",
		["item:41347"] = "pvp",
		["item:45115"] = "caster-spirit",
		["item:40840"] = "pvp",
		["item:47798"] = "caster-spirit",
		["item:47322"] = "caster",
		["item:47261"] = "caster",
		["item:40510"] = "caster",
		["item:40707"] = "tank",
		["item:50760"] = "tank",
		["item:40722"] = "tank",
		["item:24145"] = "unknown",
		["item:47418"] = "physical-all",
		["item:40108"] = "caster",
		["item:48296"] = "caster",
		["item:47468"] = "caster",
		["item:44253"] = "tank/dps",
		["item:50260"] = "healer/dps",
		["item:47303"] = "physical-all",
		["item:47895"] = "caster",
		["item:47448"] = "caster",
		["item:45557"] = "caster",
		["item:41231"] = "pvp",
		["item:47772"] = "caster",
		["item:45308"] = "caster",
		["item:40974"] = "pvp",
		["item:47671"] = "healer",
		["item:47861"] = "caster",
		["item:48047"] = "physical-dps",
		["item:40323"] = "caster-spirit",
		["item:49821"] = "caster",
		["item:41903"] = "pvp",
		["item:50000"] = "physical-all",
		["item:41156"] = "pvp",
		["item:45675"] = "physical-dps",
		["item:47467"] = "caster",
		["item:50339"] = "caster",
		["item:47422"] = "caster",
		["item:47586"] = "caster",
		["item:49988"] = "physical-all",
		["item:50309"] = "caster",
		["item:49832"] = "tank",
		["item:43171"] = "caster-spirit",
		["item:48148"] = "caster-spirit",
		["item:48195"] = "physical-all",
		["item:40685"] = "caster",
		["item:50283"] = "caster",
		["item:46081"] = "caster",
		["item:40579"] = "tank",
		["item:47588"] = "caster-spirit",
		["item:47804"] = "caster-spirit",
		["item:48012"] = "caster",
		["item:47287"] = "caster",
		["item:50403"] = "tank",
		["item:48006"] = "physical-all",
		["item:50824"] = "physical-all",
		["item:41086"] = "pvp",
		["item:47462"] = "caster",
		["item:28425"] = "physical-all",
		["item:47805"] = "caster",
		["item:42989"] = "pvp",
		["item:24146"] = "unknown",
		["item:47221"] = "physical-all",
		["item:40288"] = "caster",
		["item:39232"] = "caster",
		["item:47173"] = "caster",
		["item:48622"] = "melee-dps",
		["item:48388"] = "melee-dps",
		["item:48191"] = "physical-all",
		["item:41670"] = "pvp",
		["item:48659"] = "tank",
		["item:39606"] = "melee-dps",
		["item:50401"] = "physical-all",
		["item:48386"] = "physical-dps",
		["item:48461"] = "tank",
		["item:48652"] = "tank",
		["item:47320"] = "melee-dps",
		["item:46341"] = "caster",
		["item:47267"] = "physical-all",
		["item:50819"] = "caster",
		["item:33812"] = "pvp",
		["item:47678"] = "tank",
		["item:48011"] = "tank",
		["item:49795"] = "tank",
		["item:47421"] = "tank",
		["item:48328"] = "caster",
		["item:42551"] = "physical-all",
		["item:40723"] = "caster-spirit",
		["item:47475"] = "physical-all",
		["item:47177"] = "physical-all",
		["item:50107"] = "caster-spirit",
		["item:49996"] = "caster-spirit",
		["item:45291"] = "caster-spirit",
		["item:47315"] = "tank",
		["item:47272"] = "physical-all",
		["item:47856"] = "caster",
		["item:48395"] = "physical-dps",
		["item:40460"] = "caster-spirit",
		["item:45166"] = "tank",
		["item:45269"] = "caster",
		["item:42578"] = "healer",
		["item:40720"] = "caster",
		["item:37166"] = "physical-dps",
		["item:47852"] = "tank",
		["item:37660"] = "caster",
		["item:45702"] = "caster-spirit",
		["item:50397"] = "caster",
		["item:49853"] = "tank",
		["item:37683"] = "caster-spirit",
		["item:48993"] = "pvp",
		["item:47860"] = "caster",
		["item:47477"] = "caster",
		["item:47476"] = "tank",
		["item:30486"] = "pvp",
		["item:50779"] = "melee-dps",
		["item:48196"] = "physical-all",
		["item:47262"] = "caster-spirit",
		["item:48997"] = "pvp",
		["item:45511"] = "caster",
		["item:41144"] = "pvp",
		["item:44312"] = "tank",
		["item:42418"] = "physical-dps",
		["item:47662"] = "healer",
		["item:45827"] = "physical-all",
		["item:47457"] = "physical-all",
		["item:49481"] = "caster",
		["item:48338"] = "caster",
		["item:47308"] = "caster-spirit",
		["item:50469"] = "caster-spirit",
		["item:50778"] = "physical-all",
		["item:47232"] = "melee-dps",
		["item:48340"] = "caster",
		["item:49994"] = "caster",
		["item:33503"] = "physical-dps",
		["item:47318"] = "caster",
		["item:48007"] = "physical-all",
		["item:48724"] = "caster",
		["item:42042"] = "pvp",
		["item:45319"] = "tank",
		["item:39296"] = "physical-all",
		["item:40979"] = "pvp",
		["item:40884"] = "pvp",
		["item:50809"] = "caster",
		["item:48364"] = "physical-all",
		["item:48186"] = "caster",
		["item:50235"] = "tank",
		["item:47214"] = "physical-dps",
		["item:48978"] = "pvp",
		["item:45334"] = "tank",
		["item:48335"] = "caster",
		["item:49126"] = "melee-dps",
		["item:49895"] = "physical-all",
		["item:47298"] = "tank",
		["item:47580"] = "caster",
		["item:48334"] = "caster",
		["item:39092"] = "melee-dps",
		["item:48361"] = "physical-all",
		["item:50387"] = "physical-all",
		["item:45520"] = "caster-spirit",
		["item:47858"] = "caster",
		["item:50761"] = "melee-dps",
		["item:47279"] = "caster",
		["item:41833"] = "pvp",
		["item:50468"] = "caster",
		["item:42987"] = "tank/dps",
		["item:47326"] = "caster",
		["item:48656"] = "tank",
		["item:39229"] = "caster",
		["item:48396"] = "physical-dps",
		["item:48242"] = "physical-all",
		["item:48192"] = "physical-all",
		["item:47730"] = "physical-all",
		["item:47554"] = "caster-spirit",
		["item:40074"] = "physical-all",
		["item:47777"] = "caster",
		["item:49897"] = "physical-all",
		["item:45509"] = "tank/dps",
		["item:50447"] = "tank",
		["item:49960"] = "tank",
		["item:37082"] = "tank",
		["item:49978"] = "caster",
		["item:41835"] = "pvp",
		["item:51212"] = "physical-dps",
		["item:50455"] = "melee-dps",
		["item:47733"] = "caster",
		["item:39723"] = "melee-dps",
		["item:47219"] = "caster",
		["item:48337"] = "caster",
		["item:48658"] = "tank",
		["item:48463"] = "tank",
		["item:49992"] = "caster",
		["item:47774"] = "caster",
		["item:40907"] = "pvp",
		["item:45560"] = "tank",
		["item:47304"] = "melee-dps",
		["item:50777"] = "physical-all",
		["item:47775"] = "caster-spirit",
		["item:49484"] = "caster-spirit",
		["item:45564"] = "physical-all",
		["item:48628"] = "melee",
		["item:43405"] = "caster",
		["item:41898"] = "pvp",
		["item:42036"] = "pvp",
		["item:47218"] = "caster-spirit",
		["item:33919"] = "pvp",
		["item:48181"] = "caster",
		["item:47659"] = "physical-all",
		["item:50342"] = "physical-dps",
		["item:49786"] = "caster-spirit",
		["item:40530"] = "physical-dps",
		["item:48670"] = "tank",
		["item:40888"] = "pvp",
		["item:47684"] = "physical-all",
		["item:50776"] = "physical-all",
		["item:48273"] = "physical-all",
		["item:47229"] = "physical-dps",
		["item:41953"] = "pvp",
		["item:37840"] = "physical-all",
		["item:50764"] = "physical-all",
		["item:47884"] = "physical-all",
		["item:48595"] = "caster",
		["item:49812"] = "melee-dps",
		["item:50230"] = "melee-dps",
		["item:45823"] = "caster",
		["item:47416"] = "physical-all",
		["item:47800"] = "caster",
		["item:49487"] = "tank",
		["item:49118"] = "tank",
		["item:50458"] = "caster-dps",
		["item:48629"] = "melee-dps",
		["item:40671"] = "tank",
		["item:50212"] = "caster-spirit",
		["item:47286"] = "caster",
		["item:47438"] = "caster-spirit",
		["item:45835"] = "caster",
		["item:45451"] = "caster",
		["item:48655"] = "tank",
		["item:50782"] = "caster",
		["item:46159"] = "physical-all",
		["item:47273"] = "tank",
		["item:48697"] = "physical-all",
		["item:39102"] = "melee-dps",
		["item:40808"] = "pvp",
		["item:37869"] = "caster",
		["item:45822"] = "caster-spirit",
		["item:47563"] = "caster",
		["item:41386"] = "melee-dps",
		["item:42078"] = "pvp",
		["item:47584"] = "caster-spirit",
		["item:49486"] = "caster-spirit",
		["item:39420"] = "physical-all",
		["item:40991"] = "pvp",
		["item:47295"] = "caster",
		["item:41157"] = "pvp",
		["item:49121"] = "physical-all",
		["item:41034"] = "pvp",
		["item:47481"] = "melee-dps",
		["item:47734"] = "physical-dps",
		["item:43306"] = "tank",
		["item:50966"] = "caster",
		["item:47869"] = "physical-dps",
		["item:50118"] = "physical-all",
		["item:33813"] = "pvp",
		["item:48408"] = "pvp",
		["item:48278"] = "physical-all",
		["item:40465"] = "caster-spirit",
		["item:50266"] = "caster",
		["item:47573"] = "physical-dps",
		["item:40977"] = "pvp",
		["item:47670"] = "caster-dps",
		["item:41649"] = "pvp",
		["item:47220"] = "physical-dps",
		["item:48722"] = "dps",
		["item:45212"] = "physical-all",
		["item:47887"] = "physical-all",
		["item:37194"] = "physical-all",
		["item:40889"] = "pvp",
		["item:47283"] = "tank",
		["item:47988"] = "physical-all",
		["item:37718"] = "caster",
		["item:40933"] = "pvp",
		["item:47888"] = "tank",
		["item:47425"] = "caster-spirit",
		["item:48150"] = "caster-spirit",
		["item:39233"] = "caster",
		["item:40963"] = "pvp",
		["item:38259"] = "physical-dps",
		["item:50310"] = "tank",
		["item:44914"] = "pvp",
		["item:50048"] = "melee-dps",
		["item:47701"] = "caster",
		["item:47222"] = "physical-all",
		["item:50384"] = "caster",
		["item:37653"] = "melee-dps",
		["item:47793"] = "caster-spirit",
		["item:39607"] = "melee",
		["item:40789"] = "pvp",
		["item:50868"] = "caster",
		["item:35678"] = "caster",
		["item:47592"] = "tank",
		["item:45824"] = "melee-dps",
		["item:49977"] = "caster",
		["item:50392"] = "caster",
		["item:43565"] = "tank",
		["item:42035"] = "pvp",
		["item:50356"] = "tank",
		["item:45384"] = "tank",
		["item:48494"] = "physical-dps",
		["item:47276"] = "caster",
		["item:49474"] = "melee-dps",
		["item:40298"] = "caster",
		["item:42642"] = "physical-all",
		["item:41216"] = "pvp",
		["item:47509"] = "caster",
		["item:47658"] = "caster-spirit",
		["item:40569"] = "caster",
		["item:50333"] = "physical-all",
		["item:37784"] = "tank",
		["item:48339"] = "caster",
		["item:49074"] = "physical-dps",
		["item:40866"] = "pvp",
		["item:48666"] = "caster",
		["item:47264"] = "caster-spirit",
		["item:48041"] = "tank",
		["item:48626"] = "physical-dps",
		["item:48067"] = "caster-spirit",
		["item:47447"] = "caster",
		["item:42988"] = "caster",
		["item:30488"] = "pvp",
		["item:38251"] = "physical-dps",
		["item:42599"] = "healer",
		["item:49475"] = "tank",
		["item:50388"] = "tank",
		["item:40529"] = "melee",
		["item:43279"] = "tank",
		["item:44063"] = "tank",
		["item:47493"] = "physical-dps",
		["item:47902"] = "physical-dps",
		["item:46078"] = "pvp",
		["item:42027"] = "pvp",
		["item:50860"] = "tank",
		["item:47529"] = "physical-all",
		["item:45283"] = "tank",
		["item:47590"] = "physical-dps",
		["item:43363"] = "tank",
		["item:47284"] = "physical-all",
		["item:47571"] = "tank",
		["item:48462"] = "tank",
		["item:45260"] = "caster-spirit",
		["item:42614"] = "healer",
		["item:48271"] = "physical-all",
		["item:50452"] = "physical-all",
		["item:48014"] = "physical-all",
		["item:47666"] = "dps",
		["item:45135"] = "caster-spirit",
		["item:47699"] = "tank",
		["item:48153"] = "caster-spirit",
		["item:39714"] = "physical-all",
		["item:39680"] = "melee-dps",
		["item:47569"] = "caster",
		["item:42028"] = "pvp",
		["item:37856"] = "healer/dps",
		["item:39239"] = "melee-dps",
		["item:50227"] = "caster",
		["item:37852"] = "physical-all",
		["item:23346"] = "unknown",
		["item:51170"] = "tank",
		["item:39423"] = "caster",
		["item:47696"] = "melee-dps",
		["item:45297"] = "caster-spirit",
		["item:40705"] = "healer",
		["item:49845"] = "caster",
		["item:40684"] = "physical-dps",
		["item:50214"] = "caster",
		["item:39717"] = "tank",
		["item:40254"] = "caster",
		["item:47882"] = "tank",
		["item:50206"] = "physical-all",
		["item:46136"] = "caster",
		["item:43085"] = "tank",
		["item:48661"] = "tank",
		["item:50293"] = "physical-all",
		["item:39260"] = "caster",
		["item:45322"] = "tank",
		["item:50767"] = "caster-spirit",
		["item:47881"] = "melee",
		["item:40882"] = "pvp",
		["item:47989"] = "physical-all",
		["item:48561"] = "tank",
		["item:48008"] = "physical-dps",
		["item:47310"] = "caster",
		["item:47909"] = "caster-spirit",
		["item:48654"] = "tank",
		["item:47314"] = "physical-all",
		["item:47880"] = "healer",
		["item:50318"] = "caster-spirit",
		["item:50396"] = "caster",
		["item:48298"] = "caster",
		["item:48028"] = "caster",
		["item:48591"] = "caster",
		["item:43828"] = "caster",
		["item:47870"] = "tank",
		["item:40826"] = "pvp",
		["item:47257"] = "physical-all",
		["item:50790"] = "tank",
		["item:47269"] = "tank",
		["item:45167"] = "caster",
		["item:40978"] = "pvp",
		["item:50808"] = "tank",
		["item:41204"] = "pvp",
		["item:48065"] = "caster-spirit",
		["item:41816"] = "melee-dps",
		["item:46086"] = "pvp",
		["item:47872"] = "tank",
		["item:40204"] = "caster",
		["item:50991"] = "tank",
		["item:47216"] = "tank",
	},
	["gems"] = {
		["item:40027"] = "caster",
		["item:40015"] = "tank",
		["item:40127"] = "pvp",
		["item:41339"] = "never",
		["item:40155"] = "caster",
		["item:40175"] = "caster",
		["item:40114"] = "physical-dps",
		["item:40136"] = "physical-dps",
		["item:40162"] = "melee",
		["item:36767"] = "tank",
		["item:40129"] = "melee-dps",
		["item:41401"] = "caster",
		["item:40089"] = "tank",
		["item:36766"] = "physical-dps",
		["item:39999"] = "physical-dps",
		["item:42148"] = "caster",
		["item:40147"] = "physical-all",
		["item:40113"] = "caster",
		["item:40150"] = "physical-all",
		["item:40169"] = "healer/dps",
		["item:40134"] = "caster",
		["item:49110"] = "all",
		["item:39947"] = "melee-dps",
		["item:40159"] = "physical-dps",
		["item:41398"] = "physical-all",
		["item:40053"] = "physical-dps",
		["item:40023"] = "physical-all",
		["item:40123"] = "caster",
		["item:40111"] = "melee-dps",
		["item:40168"] = "pvp",
		["item:40112"] = "physical-all",
		["item:40025"] = "caster",
		["item:41397"] = "tank",
		["item:40151"] = "caster",
		["item:40014"] = "tank/dps",
		["item:40052"] = "physical-dps",
		["item:39905"] = "physical-all",
		["item:40022"] = "melee-dps",
		["item:40026"] = "caster-spirit",
		["item:40179"] = "caster",
		["item:40128"] = "healer/dps",
		["item:40146"] = "melee-dps",
		["item:40149"] = "pvp",
		["item:39996"] = "melee-dps",
		["item:24058"] = "melee-dps",
		["item:41396"] = "tank",
		["item:40038"] = "melee-dps",
		["item:40145"] = "pvp",
		["item:40044"] = "physical-all",
		["item:40124"] = "healer/dps",
		["item:40016"] = "pvp",
		["item:40126"] = "tank",
		["item:40132"] = "caster",
		["item:40165"] = "healer/dps",
		["item:40118"] = "melee",
		["item:39998"] = "caster",
		["item:40133"] = "caster-spirit",
		["item:40125"] = "tank/dps",
		["item:39927"] = "never",
		["item:40117"] = "physical-dps",
		["item:40009"] = "caster-spirit",
		["item:40140"] = "physical-dps",
		["item:42158"] = "pvp",
		["item:42157"] = "tank",
		["item:42142"] = "melee-dps",
		["item:41285"] = "dps",
		["item:40139"] = "tank",
		["item:40138"] = "tank",
		["item:40156"] = "physical-dps",
		["item:40153"] = "caster",
		["item:40167"] = "tank",
		["item:40017"] = "healer/dps",
		["item:41375"] = "never",
		["item:40029"] = "physical-dps",
		["item:40130"] = "physical-all",
		["item:40031"] = "tank",
		["item:42144"] = "caster",
		["item:25894"] = "never",
		["item:44066"] = "pvp",
		["item:40152"] = "caster",
		["item:40090"] = "pvp",
		["item:40088"] = "tank/dps",
		["item:41333"] = "caster",
		["item:40094"] = "caster",
		["item:40013"] = "healer/dps",
		["item:40181"] = "pvp",
		["item:40012"] = "caster",
		["item:40166"] = "tank/dps",
		["item:39900"] = "melee-dps",
		["item:40103"] = "pvp",
		["item:41389"] = "caster",
		["item:40148"] = "physical-all",
		["item:40037"] = "melee-dps",
		["item:40085"] = "caster",
		["item:40164"] = "caster",
		["item:45883"] = "caster",
		["item:40135"] = "pvp",
		["item:41380"] = "tank",
		["item:40051"] = "caster",
		["item:40001"] = "tank",
		["item:40142"] = "melee-dps",
		["item:40032"] = "tank",
		["item:40055"] = "physical-dps",
		["item:40008"] = "tank",
		["item:40119"] = "tank",
		["item:41438"] = "caster",
		["item:42153"] = "physical-dps",
		["item:41381"] = "never",
	},
	["enchants"] = {
		["3845"] = "physical-dps",
		["3825"] = "healer/dps",
		["3721"] = "caster",
		["3225"] = "dps",
		["1075"] = "tank",
		["3835"] = "physical-dps",
		["1147"] = "caster-spirit",
		["3756"] = "physical-dps",
		["3875"] = "physical-dps",
		["3368"] = "melee-dps",
		["1103"] = "physical-all",
		["3728"] = "caster",
		["1119"] = "caster",
		["3817"] = "physical-dps",
		["368"] = "physical-all",
		["1892"] = "tank",
		["3236"] = "tank",
		["3233"] = "caster",
		["3720"] = "caster",
		["3607"] = "healer/dps",
		["2658"] = "tank/dps",
		["3252"] = "all",
		["3294"] = "tank",
		["3253"] = "tank",
		["983"] = "physical-all",
		["1952"] = "tank",
		["3822"] = "physical-all",
		["3325"] = "physical-all",
		["1071"] = "tank",
		["1603"] = "physical-dps",
		["3327"] = "physical-all",
		["3603"] = "tank/dps",
		["3855"] = "caster",
		["3849"] = "tank",
		["3809"] = "caster",
		["2332"] = "caster",
		["2647"] = "melee-dps",
		["3850"] = "tank",
		["3256"] = "physical-all",
		["1900"] = "melee-dps",
		["3793"] = "pvp",
		["1099"] = "physical-all",
		["3828"] = "physical-dps",
		["2326"] = "caster",
		["1953"] = "tank",
		["3869"] = "tank",
		["1597"] = "physical-dps",
		["3246"] = "caster",
		["3859"] = "caster",
		["1951"] = "tank",
		["3794"] = "pvp",
		["3604"] = "healer/dps",
		["3010"] = "physical-dps",
		["3757"] = "tank",
		["3795"] = "pvp",
		["3808"] = "physical-dps",
		["1606"] = "physical-dps",
		["3807"] = "caster",
		["3788"] = "tank",
		["3820"] = "caster",
		["3260"] = "tank",
		["3330"] = "tank",
		["3222"] = "physical-all",
		["3789"] = "melee-dps",
		["3245"] = "pvp",
		["3832"] = "all",
		["3810"] = "caster",
		["3834"] = "caster",
		["3854"] = "caster",
		["0"] = "none",
		["3606"] = "all",
		["3790"] = "dps",
		["3722"] = "caster",
		["1600"] = "physical-dps",
		["3297"] = "tank",
		["3719"] = "caster-spirit",
		["1128"] = "caster",
		["3872"] = "caster-spirit",
		["3758"] = "caster",
		["3836"] = "caster",
		["369"] = "caster",
		["2673"] = "tank/dps",
		["3838"] = "caster",
		["2933"] = "pvp",
		["3326"] = "physical-dps",
		["3827"] = "physical-dps",
		["2986"] = "physical-dps",
		["3328"] = "physical-dps",
		["3852"] = "tank/pvp",
		["3244"] = "caster",
		["3873"] = "caster",
		["3853"] = "pvp",
		["3818"] = "tank",
		["2661"] = "all",
		["3837"] = "tank",
		["3605"] = "physical-dps",
		["3296"] = "caster-spirit",
		["3824"] = "physical-dps",
		["684"] = "melee-dps",
		["884"] = "tank",
		["3816"] = "tank",
		["2939"] = "physical-dps",
		["904"] = "physical-all",
		["3847"] = "tank",
		["3608"] = "ranged",
		["3797"] = "pvp",
		["3819"] = "caster",
		["3003"] = "physical-dps",
		["3831"] = "healer/dps",
		["3232"] = "all",
		["3243"] = "pvp",
		["3823"] = "physical-dps",
		["849"] = "physical-all",
		["3234"] = "tank/dps",
		["3718"] = "caster-spirit",
		["3829"] = "physical-dps",
		["3811"] = "tank",
		["3826"] = "tank/dps",
		["908"] = "tank",
		["3830"] = "caster",
	},
}
