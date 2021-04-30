
function onInit()
	if User.getRulesetName() == "5E" and Session.IsHost then
		Comm.registerSlashHandler("alcheck", checkCharacter);
	end
end

function checkCharacter()

	for _,node in pairs(DB.getChildren("charsheet")) do
		local tCharacter = {tOriginalScores = {}, tAdjustedScores = {}, tClass = {}, tRace = {}, tFeats = {}, tMagicItems = {}, 
							sName = "", aHitpoints = {}, nASI = 0, nPointBuy = 0, sScoresValid = "Valid"};

		tCharacter.sName = DB.getValue(node, "name", "");
		tCharacter.tClass = getClass(node);
		tCharacter.tRace = getRace(node);
		tCharacter.tMagicItems = getMagicItems(node);
		tCharacter.tFeats = getFeats(node);
		tCharacter.aHitpoints = checkHP(node);
		tCharacter.tOriginalScores = getAbilityScores(node);
		tCharacter.tAdjustedScores = getAbilityScores(node);

		tCharacter = checkAbilityScores(tCharacter);
		outputStory(tCharacter);
	end	
end
function getTier(nLevel)
	local aTier =  {sName = "", nMagic = 0};
	if nLevel < 5 then
		aTier.sName = "T1";
		aTier.nMagic = 1;
	elseif nLevel >= 5 and nLevel <= 10 then
		aTier.sName = "T2";
		aTier.nMagic = 3;
	elseif nLevel >=11 and nLevel <= 16 then
		aTier.sName = "T3";
		aTier.nMagic = 6;
	else
		aTier.sName = "T4";
		aTier.nMagic = 10;
	end 
	return aTier;
end

function outputStory(tCharacter)
	local nodeStory = DB.createChild("encounter");
	local nASI = getNumberASI(tCharacter.tClass);
	local nTotalLevel = 0;


	if nodeStory then
		DB.setValue(nodeStory, "name", "string", "00 - AL Validation: " .. tCharacter.sName);
		Interface.openWindow("encounter", nodeStory);
		local sAddDesc = "";

		local sValid = ""
	

		-- Output Race
		sAddDesc = sAddDesc .. "<h>Race: " ..  tCharacter.tRace.sRace .. " (" .. tCharacter.tRace.sValid .. ")</h> ";
		if  tCharacter.tRace.sValid == "Valid" then
			sAddDesc = sAddDesc .. "<list><li><b>Ability Score Increase:</b> " ;
			for _,nScore in ipairs( tCharacter.tRace.aScores) do
				sAddDesc = sAddDesc .. tostring(nScore) .. " ";
			end
			sAddDesc = sAddDesc .."</li><li><b>Source:</b> " ..   tCharacter.tRace.sSource .. " </li></list>";
		end
	
		-- Output Classes
		for _,nodeClass in ipairs( tCharacter.tClass) do
			sAddDesc = sAddDesc .. "<h>Class: </h>" .. nodeClass.sClass .. " (" .. nodeClass.sSubclass.. ") (" .. nodeClass.sValid .. ") <list>";
			sAddDesc = sAddDesc .. "<li> <b>Level:</b> " .. nodeClass.nLevel .. " </li><li><b>Source:</b> " ..  nodeClass.sSource .. " </li></list>";
			nTotalLevel = nTotalLevel + nodeClass.nLevel;
		end
		
		
		-- Output HP
		sAddDesc = sAddDesc .. "<h>Hit Points: (" .. tCharacter.aHitpoints.sValid .. ") </h> ";
		sAddDesc = sAddDesc .. "<list><li><b>Actual:</b> " ..  tCharacter.aHitpoints.nTotal .. " </li>";
		sAddDesc = sAddDesc .. "<li><b>Calculated:</b> " ..  tCharacter.aHitpoints.nCalculated .. " </li></list>";


		local sFeatsNum = "";
		if  tCharacter.tRace.sRace == "human-variant" then
			sFeatsNum = tostring(nASI+1);
		else
			sFeatsNum = tostring(nASI);
		end
		if (tonumber(sFeatsNum) >= #tCharacter.tFeats) then
			sValid = "Valid";
		else
			sValid = "Invalid";
		end	
		for _,nodeFeat in ipairs(tCharacter.tFeats) do
			if nodeFeat[1]:match("invalid") then
				sValid = "Invalid";
			end
		end
		-- Output Feats
		sAddDesc = sAddDesc .. "<h>Feats: Allowed (" .. sFeatsNum .. ") (" .. sValid .. ")</h>";
		for _,nodeFeat in ipairs( tCharacter.tFeats) do
			sAddDesc = sAddDesc .."<list><li><b>Feat:</b> " ..  nodeFeat[1] .. " </li>";
			if nodeFeat[2] == "" then
				sAddDesc = sAddDesc .."<li><b>Ability Score Increase:</b> None </li>";
			else
				sAddDesc = sAddDesc .."<li><b>Ability Score Increase:</b> 1" ..  nodeFeat[2] .. " </li>";
			end
			sAddDesc = sAddDesc .."<li><b>Source:</b> " .. nodeFeat[3] .." </li></list><p />";
		end
		
		if tCharacter.nPointBuy > 27 or tCharacter.nPointBuy == -1 then
			sValid = "Invalid";
		else
			sValid = "Valid";
		end	
		-- Output Ability Scorez
		sAddDesc = sAddDesc .. "<h>Ability Scores ("   .. sValid .. ") </h>";
		sAddDesc = sAddDesc .. "<table><tr><td colspan=\"6\"><b>Current Scores</b></td></tr><tr>"
		for _,nodeScore in ipairs( tCharacter.tOriginalScores) do
			sAddDesc = sAddDesc .. "<td><b>" .. nodeScore.sLabel .. "</b></td>"
		end
		sAddDesc = sAddDesc .. "</tr><tr>"
		for _,nodeScore in ipairs(tCharacter.tOriginalScores) do
			sAddDesc = sAddDesc .. "<td>" .. tostring(nodeScore.nScore) .. "</td>"
		end
		sAddDesc = sAddDesc .. "</tr></table>"

		sAddDesc = sAddDesc .."<list><li><b>Race ASI:</b> "  
		for _,nScore in ipairs( tCharacter.tRace.aScores) do
			sAddDesc = sAddDesc .. tostring(nScore) .. " ";
		end
		sAddDesc = sAddDesc .. " </li>";
		for _,nodeFeat in ipairs( tCharacter.tFeats) do
			if nodeFeat[2] ~= "" then
				sAddDesc = sAddDesc .."<li><b>Feat ASI:</b> 1 " ..  nodeFeat[2] .. " - " .. nodeFeat[1].. " </li>";
			end
		end		
		sAddDesc = sAddDesc .."<li><b>Level ASI:</b> " ..  tostring(tCharacter.nASI) .. " </li>";
		if tCharacter.nPointBuy > 27  then
			sAddDesc = sAddDesc .."<li><b>Point Buy:</b> " .. tostring(tCharacter.nPointBuy) .. " (Invalid) </li></list>";
		elseif tCharacter.nPointBuy == -1 then
			sAddDesc = sAddDesc .."<li><b>Point Buy:</b> One or more scores above 15 or below 8. (Invalid) </li></list>";
		else
			sAddDesc = sAddDesc .."<li><b>Point Buy:</b> " .. tostring(tCharacter.nPointBuy) .. " </li></list>";
		end


		sAddDesc = sAddDesc .. "<table><tr><td colspan=\"6\"><b>Reverse Ajusted ASI Ability Scores</b></td></tr><tr>"
		for _,nodeScore in ipairs(tCharacter.tAdjustedScores) do
			sAddDesc = sAddDesc .. "<td><b>" .. nodeScore.sLabel .. "</b></td>"
		end
		sAddDesc = sAddDesc .. "</tr><tr>"
		for _,nodeScore in ipairs(tCharacter.tAdjustedScores) do
			sAddDesc = sAddDesc .. "<td>" .. tostring(nodeScore.nScore) .. "</td>"
		end
		sAddDesc = sAddDesc .. "</tr></table>"
		
		local aTier = getTier(nTotalLevel);
		if #tCharacter.tMagicItems > aTier.nMagic then
			sValid = "(Invalid)";
		else
			sValid = "(Valid)";
		end
		sAddDesc = sAddDesc .. "<h>Magic Items " .. aTier.sName .. ": Allowed (" .. aTier.nMagic .. ") " .. sValid .. " </h>";
		for _,nodeItem in ipairs(tCharacter.tMagicItems) do
			sAddDesc = sAddDesc .."<list><li><b>Item:</b> " ..  nodeItem.sName .. " </li>";
			sAddDesc = sAddDesc .."<li><b>Type:</b> " ..  nodeItem.sType .. " </li>";
			sAddDesc = sAddDesc .."<li><b>Rarity:</b> " ..  nodeItem.sRarity .. " </li></list><p />";
		end

		if sAddDesc ~= "" then			
			DB.setValue(nodeStory, "text", "formattedtext", DB.getValue(nodeStory, "text", "") .. sAddDesc);
		end
	end
end

function calculatePointBuy(aStats)
	local nPoints = 0;
	for i=1,#aStats do	
		if 	aStats[i].nScore >= 8 and aStats[i].nScore <= 13 then
			nPoints = nPoints + aStats[i].nScore - 8;
		elseif aStats[i].nScore == 14 then
			nPoints = nPoints +7;
		elseif aStats[i].nScore == 15 then
			nPoints = nPoints +9;
		else
			-- Error, value is either > 15 or < 8 -- Illegal
			return -1;
		end
	end
	return nPoints;
end

-- Sort the array so the stat scores are biggest to lowest
function bubbleSortAbilityScores(aStats)
	for i=1,#aStats-1 do
		local aCurrent = aStats[i];
		if aCurrent.nScore < aStats[i+1].nScore then
			aStats[i] = aStats[i+1];
			aStats[i+1] = aCurrent;
			aStats = bubbleSortAbilityScores(aStats);
			break;
		end
	end
	return aStats;
end

function sortScoresStandard(aStats)
	local aScoresStandard = {{},{},{},{},{},{}};
	for _,aScore in ipairs(aStats) do
		if aScore.sLabel == "STR" then
			aScoresStandard[1] = aScore;
		elseif aScore.sLabel == "DEX" then
			aScoresStandard[2] = aScore;
		elseif aScore.sLabel == "CON" then
			aScoresStandard[3] = aScore;
		elseif aScore.sLabel == "INT" then
			aScoresStandard[4] = aScore;
		elseif aScore.sLabel == "WIS" then
			aScoresStandard[5] = aScore;
		elseif aScore.sLabel == "CHA" then
			aScoresStandard[6] = aScore;
		end
	end
	return aScoresStandard;
end

function getAbilityScores(nodeActor)
	local aCharacterScores = {};
	table.insert(aCharacterScores, {nScore = ActorManager5E.getAbilityScore(nodeActor, "strength"), sLabel = "STR"});
	table.insert(aCharacterScores, {nScore = ActorManager5E.getAbilityScore(nodeActor, "dexterity"), sLabel = "DEX"});
	table.insert(aCharacterScores, {nScore = ActorManager5E.getAbilityScore(nodeActor, "constitution"), sLabel = "CON"});
	table.insert(aCharacterScores, {nScore = ActorManager5E.getAbilityScore(nodeActor, "intelligence"), sLabel = "INT"});
	table.insert(aCharacterScores, {nScore = ActorManager5E.getAbilityScore(nodeActor, "wisdom"), sLabel = "WIS"});
	table.insert(aCharacterScores, {nScore = ActorManager5E.getAbilityScore(nodeActor, "charisma"), sLabel = "CHA"});
	return aCharacterScores;
end

function checkAbilityScores(tCharacter)
	-- Sort the scores highest to lowest
    tCharacter.tAdjustedScores = bubbleSortAbilityScores(tCharacter.tAdjustedScores);
	-- Subtrack off racial bonus from highest scores
	local aRace = tCharacter.tRace.aScores;
	for i=1,#aRace do
		tCharacter.tAdjustedScores[i].nScore = tCharacter.tAdjustedScores[i].nScore - aRace[i];
	end

	-- Re-sort
	tCharacter.tAdjustedScores = bubbleSortAbilityScores(tCharacter.tAdjustedScores);
	--  Subtrack off any feat bonus from highest scores
	if next(tCharacter.tFeats) then
		for i=1,#tCharacter.tFeats do
			for j=1,#tCharacter.tAdjustedScores do
				if tCharacter.tFeats[i][2]:match(tCharacter.tAdjustedScores[j].sLabel) then
					tCharacter.tAdjustedScores[j].nScore = tCharacter.tAdjustedScores[j].nScore -1;
					tCharacter.tAdjustedScores = bubbleSortAbilityScores(tCharacter.tAdjustedScores);
					break;
				end
			end
		end
	end

	-- Re-sort
	tCharacter.tAdjustedScores = bubbleSortAbilityScores(tCharacter.tAdjustedScores);

	-- Calculate ASI off of # feats, sometimes ASI doesn't get added to the sheet.
	tCharacter.nASI = getASIPoints(tCharacter.tFeats, tCharacter.tRace, tCharacter.tClass);
	-- This is an error only because we are invalid on feats. If we dont' set it to 0 however 
	-- our other calcs won't work.
	if tCharacter.nASI < 0 then
		tCharacter.nASI = 0;
	end
	local nASI = tCharacter.nASI;
	-- Keep taking ASI points from the highest value
	while nASI ~= 0 do
		tCharacter.tAdjustedScores[1].nScore = tCharacter.tAdjustedScores[1].nScore - 1;
		nASI = nASI - 1;
		tCharacter.tAdjustedScores = bubbleSortAbilityScores(tCharacter.tAdjustedScores);
	end;
	
	tCharacter.nPointBuy = calculatePointBuy(tCharacter.tAdjustedScores);
	if tCharacter.nPointBuy > 27 then
		sScoresValid = "Invalid: Point buy > 27";
	elseif tCharacter.nPointBuy == -1 then
		sScoresValid = "Invalid: One more scores > 27 or < 8 ";
	end;

	tCharacter.tAdjustedScores = sortScoresStandard(tCharacter.tAdjustedScores);
	return tCharacter;
end

function checkHP(nodeActor)
	local aHitPoints = {nTotal = 0, nCalculated = 0, nConBonus = 0, nClassBonus = 0, nOtherBonus = 0, sValid = "Valid"}
	local nCalculatedHP = 0;
	local nBonus = 0;
	local nTotalHP = DB.getValue(nodeActor, "hp.total", 0)
	local nConBonus = DB.getValue(nodeActor, "abilities.constitution.bonus", 0);

	if CharManager.hasTrait(nodeActor, CharManager.TRAIT_DWARVEN_TOUGHNESS) then
		nBonus = nBonus + 1;
	end
	if CharManager.hasFeat(nodeActor, CharManager.FEAT_TOUGH) then
		nBonus = nBonus + 2;
	end

	for _,nodeClass in pairs(DB.getChildren(nodeActor, "classes")) do
		local aDice = DB.getValue(nodeClass, "hddie");
		local nHDSides = 0;
		local nClassBonus = 0;
		if aDice then
			nHDSides = tonumber(aDice[1]:sub(2));
		end
		local nLevel = DB.getValue(nodeClass, "level", 0);
		local sClassName = StringManager.trim(DB.getValue(nodeClass, "name", "")):lower();
		if (sClassName == CharManager.CLASS_SORCERER) and CharManager.hasFeature(nodeActor, CharManager.FEATURE_DRACONIC_RESILIENCE) then
			nClassBonus = 1;
		end
		for i=1,nLevel do
			local nValue = 0;
			-- First Level
			if nCalculatedHP == 0 then
				nValue = nHDSides;
			else
				nValue = math.floor(((nHDSides + 1) / 2) + 0.5);
			end
			nCalculatedHP = nCalculatedHP + nValue + nConBonus + nBonus + nClassBonus;
		end
	end

	aHitPoints.nTotal = nTotalHP;
	aHitPoints.nCalculated = nCalculatedHP;
	aHitPoints.nConBonus = nConBonus;
	aHitPoints.nOtherBonus = nBonus;
	aHitPoints.nClassBonus = nClassBonus;

	if aHitPoints.nTotal ~= aHitPoints.nCalculated then 
		aHitPoints.sValid = "Invaild: Discrepency " .. tostring( aHitPoints.nTotal -  aHitPoints.nCalculated); 
	end
	return aHitPoints;
end

function getNumberASI(aClass)
	local nASI = 0;
	
	for i=1,#aClass do
		local nLevel = 0;
		nLevel = aClass[i].nLevel;
		nASI = nASI + math.floor(nLevel/4);

		if aClass[i].sClass == "rogue" and aClass[i].nLevel >= 12 then
			nASI = nASI + 1;
		end

		if aClass[i].nLevel == 19 then
			nASI = nASI + 1;
		end
	end
	return nASI;
end

function getASIPoints(aCharFeats, aRace, aClass)
	local nASIPoints = 0;
	local nFeats = #aCharFeats;

	-- Ignore the first level feat for human variant so all calcualtions work
	if aRace.sName == "human-variant" and nFeats >= 1 then
		nFeats = nFeats - 1;
	end 
	
	 for i=1,#aClass do
		local nLevel = 0;
		-- Todo check for high level rogues
		nLevel = aClass[i].nLevel;
		nASIPoints = nASIPoints + (math.floor(nLevel/4) * 2);
	 end
	 nASIPoints = nASIPoints - (nFeats *2);

	return nASIPoints
end
function getRace(nodeActor)
	local aRace = {sRace = "", aScores = {}, sSource = "", sValid = "Valid"}
	aRace.sRace = StringManager.trim(DB.getValue(nodeActor, "race", "")):lower();

	if aRace.sRace == "mountain dwarf"  then
		aRace.aScores = {2,2};
		aRace.sSource = "PHB";
	elseif aRace.sRace == "dragonborn" or  aRace.sRace == "hill dwarf" or aRace.sRace == "half-orc" or aRace.sRace == "tiefling" 
	or aRace.sRace == "forest gnome" or aRace.sRace == "rock gnome" or aRace.sRace == "high elf" or aRace.sRace == "wood elf" 
	or aRace.sRace == "dark elf (drow)" or aRace.sRace == "halfling (lightfoot)" or aRace.sRace == "halfling (stout)" then
		aRace.aScores = {2,1};
		aRace.sSource = "PHB";
	elseif aRace.sRace == "half-elf" then
		aRace.aScores = {2,1,1};
		aRace.sSource = "PHB";
	elseif aRace.sRace == "human" then
		aRace.aScores = {1,1,1,1,1,1};
		aRace.sSource = "PHB";
	elseif aRace.sRace == "human-variant" then
		aRace.aScores = {1,1};
		aRace.sSource = "PHB";
	elseif aRace.sRace:match("assimar") or aRace.sRace == "bugbear" or aRace.sRace == "firbolg" or aRace.sRace == "goblin" 
	or aRace.sRace == "goliath" or aRace.sRace == "kenku" or aRace.sRace == "lizardfolk" or aRace.sRace == "orc" or aRace.sRace == "tabaxi" 
	or aRace.sRace == "yuan-ti pureblood" then
		aRace.aScores = {2,1};
		aRace.sSource = "VGM";
	elseif aRace.sRace == "aasimar" or aRace.sRace == "kobold" then
		aRace.aScores = {2};
		aRace.sSource = "VGM";
	elseif aRace.sRace == "triton" then
		aRace.aScores = {1,1,1};
		aRace.sSource = "VGM";
	elseif aRace.sRace == "duergar" or aRace.sRace == "deep gnome" or aRace.sRace == "eladrin" or aRace.sRace == "sea elf" 
	or aRace.sRace == "shadar-kai" or aRace.sRace:match("tiefling") then
		aRace.aScores = {2,1};
		aRace.sSource = "MTF";
	elseif aRace.sRace == "gith" then
		aRace.aScores = {1};
		aRace.sSource = "MTF";
	elseif aRace.sRace == "shield dwarf"  then
		aRace.aScores = {2,2};
		aRace.sSource = "SCA";
	elseif aRace.sRace == "gray dwarf (duergar)" or aRace.sRace == "gold dwarf" or aRace.sRace == "moon elf" or aRace.sRace == "sun elf" 
	or aRace.sRace == "wood elf" or aRace.sRace:match("half-elf-variant") or aRace.sRace:match("tiefling-variant") 
	or aRace.sRace == "deep gnome (svirfneblin)" or aRace.sRace == "halfling (ghostwise)" or aRace.sRace == "halfling (strongheart)" then
		aRace.aScores = {2,1};
		aRace.sSource = "SCA";
	else
		aRace.sVaild = "Invalid: Non-legal race";
	end

	return aRace;
end

function getMagicItems(nodeActor)
	local aMagicItems = {}
	for _,vItem in pairs(DB.getChildren(nodeActor, "inventorylist")) do
		local sName = DB.getValue(vItem, "name", "");
		local sNodeType = DB.getValue(vItem, "type", "");
		if not(sNodeType == "Potion" or sNodeType == "Scroll" or  sNodeType ==  "Adventuring Gear") then
			local sNodeRarity = DB.getValue(vItem, "rarity", "");
			if sNodeRarity ~= "" then
				local aItem = {sName = sName, sType = sNodeType, sRarity = sNodeRarity};
				table.insert(aMagicItems, aItem);
			end
		end
	end
	return aMagicItems;
end

function getClass(nodeActor)
	local aClassActor = {aClass = {}};
	local aClass = {nLevel = 0, sClass = "", sSubclass = "",sSource = "" , sValid = ""};
	for _,nodeClass in pairs(DB.getChildren(nodeActor, "classes")) do
		aClass.nLevel = DB.getValue(nodeClass, "level", 0);
		aClass.sClass = StringManager.trim(DB.getValue(nodeClass, "name", "")):lower();
		for _,vFeature in pairs(DB.getChildren(nodeActor, "featurelist")) do
			local sFeature = DB.getValue(vFeature, "name", ""):lower();
			if aClass.sClass == "artificer" then
				if aClass.nLevel >= 3 and (sFeature == "alchemist" or sFeature == "armorer" or sFeature == "artillerist" or sFeature == "battle smith") then
					aClass.sSubclass = sFeature;
					aClass.sSource = "TCE";
					aClass.sValid = "Valid";
					break;
				elseif (aClass.nLevel >= 3) then
					aClass.sValid = "Invalid: Missing or invalid subclass";	
				end			
			elseif aClass.sClass == "barbarian" then
				if aClass.nLevel >= 3 and (sFeature == "path of the berserker" or sFeature == "path of the totem warrior")  then
					aClass.sSubclass = sFeature;
					aClass.sSource = "PHB";
					aClass.sValid = "Valid";
					break;
				elseif aClass.nLevel >= 3 and (sFeature == "path of the battlerager" or sFeature == "path of the totem warrior - expanded")  then
					aClass.sSubclass = sFeature;
					aClass.sSource = "SCA";
					aClass.sValid = "Valid";
					break;
				elseif aClass.nLevel >= 3 and (sFeature == "path of the beast" or sFeature == "path of the wild magic")  then
					aClass.sSubclass = sFeature;
					aClass.sSource = "TCE";
					aClass.sValid = "Valid";
					break;
				elseif aClass.nLevel >= 3 and (sFeature == "path of the ancestral guardian" or sFeature == "path of the storm herald" or sFeature == "path of the zealot") then
					aClass.sSubclass = sFeature;
					aClass.sSource = "XGE";
					aClass.sValid = "Valid";
					break;
				elseif  aClass.nLevel >= 3 then
					aClass.sValid = "Invalid: Missing or invalid subclass";	
				end			
			elseif aClass.sClass == "bard" then
				if aClass.nLevel >= 3 and (sFeature == "college of lore" or sFeature == "college of lore") then
					aClass.sSubclass = sFeature;
					aClass.sSource = "PHB";
					aClass.sValid = "Valid";
					break;
				elseif aClass.nLevel >= 3 and (sFeature == "college of creation" or sFeature == "college of eloquence") then
					aClass.sSubclass = sFeature;
					aClass.sSource = "TCE";
					aClass.sValid = "Valid";
					break;
				elseif aClass.nLevel >= 3 and (sFeature == "college of glamour" or sFeature == "college of swords" or sFeature == "college of whispers") then
					aClass.sSubclass = sFeature;
					aClass.sSource = "XGE";
					aClass.sValid = "Valid";
					break;
				elseif  aClass.nLevel >= 3 then
					aClass.sValid = "Invalid: Missing or invalid subclass";	
				end			
			elseif aClass.sClass == "cleric" then
				if sFeature == "knowledge domain" or sFeature == "life domain" or sFeature == "light domain" or sFeature == "nature domain"
				or sFeature == "tempest domain" or sFeature == "trickery domain" or sFeature == "war domain" then
					aClass.sSubclass = sFeature;
					aClass.sSource = "PHB";
					aClass.sValid = "Valid";
					break;
				elseif sFeature == "arcana domain" then
					aClass.sSubclass = sFeature;
					aClass.sSource = "SCA";
					aClass.sValid = "Valid";
					break;
				elseif sFeature == "order domain" or sFeature == "peace domain" or sFeature == "twilight domain" then
					aClass.sSubclass = sFeature;
					aClass.sSource = "TCE";
					aClass.sValid = "Valid";
					break;
				elseif sFeature == "forge domain" or sFeature == "grave domain"  then
					aClass.sSubclass = sFeature;
					aClass.sSource = "XGE";
					aClass.sValid = "Valid";
					break;
				else
					aClass.sValid = "Invalid: Missing or invalid subclass";	
				end			
			elseif aClass.sClass == "druid" then
				if aClass.nLevel >= 2 and (sFeature == "circle of the land" or sFeature == "circle of the moon") then
					aClass.sSubclass = sFeature;
					aClass.sSource = "PHB";
					aClass.sValid = "Valid";
					break;
				elseif aClass.nLevel >= 2 and (sFeature == "circle of the spores" or sFeature == "circle of the stars" or sFeature == "circle of the wildfire") then
					aClass.sSubclass = sFeature;
					aClass.sSource = "TCE";
					aClass.sValid = "Valid";
					break;				
				elseif aClass.nLevel >= 2 and (sFeature == "circle of the dreams" or sFeature == "circle of the shepherd") then
					aClass.sSubclass = sFeature;
					aClass.sSource = "XGE";
					aClass.sValid = "Valid";
					break;
				elseif aClass.nLevel >= 2 then
					aClass.sValid = "Invalid: Missing or invalid subclass";	
				end			
			elseif aClass.sClass == "fighter" then
				if aClass.nLevel >= 3 and (sFeature == "champion" or sFeature == "battlemaster") then
					aClass.sSubclass = sFeature;
					aClass.sSource = "PHB";
					aClass.sValid = "Valid";
					break;
				elseif aClass.nLevel >= 3 and (sFeature == "purple dragon knight") then
					aClass.sSubclass = sFeature;
					aClass.sSource = "SCA";
					aClass.sValid = "Valid";
					break;
				elseif aClass.nLevel >= 3 and (sFeature == "psi warrior"  or sFeature == "rune knight") then
					aClass.sSubclass = sFeature;
					aClass.sSource = "TCE";
					aClass.sValid = "Valid";
					break;
				elseif aClass.nLevel >= 3 and (sFeature == "arcane archer" or sFeature == "cavalier" or sFeature == "samurai") then
					aClass.sSubclass = sFeature;
					aClass.sSource = "XGE";
					aClass.sValid = "Valid";
					break;
				elseif aClass.nLevel >= 3  then
					aClass.sValid = "Invalid: Missing or invalid subclass";	
				end			
			elseif aClass.sClass == "monk" then
				if aClass.nLevel >= 3 and (sFeature == "way of the open hand" or sFeature == "way of shadow" or sFeature == "way of the four elements") then
					aClass.sSubclass = sFeature;
					aClass.sSource = "PHB";
					aClass.sValid = "Valid";
					break;
				elseif aClass.nLevel >= 3 and (sFeature == "way of the long death" or sFeature == "way of the sun soul") then
					aClass.sSubclass = sFeature;
					aClass.sSource = "SCA|XGE";
					aClass.sValid = "Valid";
					break;
				elseif aClass.nLevel >= 3 and (sFeature == "way of mercy" or sFeature == "way of the astral self") then
					aClass.sSubclass = sFeature;
					aClass.sSource = "TCE";
					aClass.sValid = "Valid";
					break;
				elseif aClass.nLevel >= 3 and (sFeature == "way of the drunken master" or sFeature == "way of the kensei") then
					aClass.sSubclass = sFeature;
					aClass.sSource = "XGE";
					aClass.sValid = "Valid";
					break;
				elseif aClass.nLevel >= 3 then
					aClass.sValid = "Invalid: Missing or invalid subclass";	
				end			
			elseif aClass.sClass == "paladin" then
				if aClass.nLevel >= 3 and (sFeature == "oath of devotion" or sFeature == "oath of the ancients" or sFeature == "oath of vengeance") then
					aClass.sSubclass = sFeature;
					aClass.sSource = "PHB";
					aClass.sValid = "Valid";
					break;
				elseif aClass.nLevel >= 3 and (sFeature == "oath of the crown") then
					aClass.sSubclass = sFeature;
					aClass.sSource = "SCA";
					aClass.sValid = "Valid";
					break;
				elseif aClass.nLevel >= 3 and (sFeature == "oath of glory" or sFeature == "oath of the watchers") then
					aClass.sSubclass = sFeature;
					aClass.sSource = "TCE";
					aClass.sValid = "Valid";
					break;
				elseif aClass.nLevel >= 3 and (sFeature == "oath of conquest" or sFeature == "oath of redemption") then
					aClass.sSubclass = sFeature;
					aClass.sSource = "XGE";
					aClass.sValid = "Valid";
					break;
				elseif aClass.nLevel >= 3 then
					aClass.sValid = "Invalid: Missing or invalid subclass";	
				end			
			elseif aClass.sClass == "ranger" then
				if aClass.nLevel >= 3 and (sFeature == "hunter" or sFeature == "beastmaster") then
					aClass.sSubclass = sFeature;
					aClass.sSource = "PHB";
					aClass.sValid = "Valid";
					break;
				elseif aClass.nLevel >= 3 and (sFeature == "fey wanderer" or sFeature == "swarmkeeper") then
					aClass.sSubclass = sFeature;
					aClass.sSource = "TCE";
					aClass.sValid = "Valid";
					break;
				elseif aClass.nLevel >= 3 and (sFeature == "gloom stalker" or sFeature == "horizon walker"  or sFeature == "monster slayer") then
					aClass.sSubclass = sFeature;
					aClass.sSource = "XGE";
					aClass.sValid = "Valid";
					break;
				elseif aClass.nLevel >= 3 then
					aClass.sValid = "Invalid: Missing or invalid subclass";	
				end			
			elseif aClass.sClass == "rogue" then
				if aClass.nLevel >= 3 and (sFeature == "theif" or sFeature == "assassin" or sFeature == "arcane trickster") then
					aClass.sSubclass = sFeature;
					aClass.sSource = "PHB";
					aClass.sValid = "Valid";
					break;
				elseif aClass.nLevel >= 3 and (sFeature == "mastermind")  then
					aClass.sSubclass = sFeature;
					aClass.sSource = "SCA";
					aClass.sValid = "Valid";
					break;
				elseif aClass.nLevel >= 3 and (ssFeature == "swashbuckler") then
					aClass.sSubclass = sFeature;
					aClass.sSource = "SCA|XGE";
					aClass.sValid = "Valid";
					break;
				elseif aClass.nLevel >= 3 and (sFeature == "phantom" or sFeature == "soulknife") then
					aClass.sSubclass = sFeature;
					aClass.sSource = "TCE";
					aClass.sValid = "Valid";
					break;
				elseif aClass.nLevel >= 3 and (sFeature == "inquisitive" or sFeature == "mastermind" or sFeature == "scout") then
					aClass.sSubclass = sFeature;
					aClass.sSource = "XGE";
					aClass.sValid = "Valid";
					break;
				elseif aClass.nLevel >= 3 then
					aClass.sValid = "Invalid: Missing or invalid subclass";	
				end			
			elseif aClass.sClass == "sorcerer" then
				if sFeature == "draconic bloodline" or sFeature == "wild magic" then
					aClass.sSubclass = sFeature;
					aClass.sSource = "PHB";
					aClass.sValid = "Valid";
					break;
				elseif sFeature == "storm sorcery" then
					aClass.sSubclass = sFeature;
					aClass.sSource = "SCA|XGE";
					aClass.sValid = "Valid";
					break;
				elseif sFeature == "aberrant mind" or sFeature == "clockwork soul"  then
					aClass.sSubclass = sFeature;
					aClass.sSource = "TCE";
					aClass.sValid = "Valid";
					break;
				elseif sFeature == "divine soul" or sFeature == "shadow magic"  then
					aClass.sSubclass = sFeature;
					aClass.sSource = "XGE";
					aClass.sValid = "Valid";
					break;
				else
					aClass.sValid = "Invalid: Missing or invalid subclass";	
				end			
			elseif aClass.sClass == "warlock" then
				if sFeature == "the archfey" or sFeature == "the fiend" or sFeature == "the great old one" then
					aClass.sSubclass = sFeature;
					aClass.sSource = "PHB";
					aClass.sValid = "Valid";
					break;
				elseif sFeature == "the undying"  then
					aClass.sSubclass = sFeature;
					aClass.sSource = "SCA";
					aClass.sValid = "Valid";
					break;
				elseif sFeature == "the fathomless" or sFeature == "the genie"  then
					aClass.sSubclass = sFeature;
					aClass.sSource = "TCE";
					aClass.sValid = "Valid";
					break;
				elseif sFeature == "the celestial" or sFeature == "hexblade"  then
					aClass.sSubclass = sFeature;
					aClass.sSource = "XGE";
					aClass.sValid = "Valid";
					break;
				else
					aClass.sValid = "Invalid: Missing or invalid subclass";	
				end			
			elseif aClass.sClass == "wizard" then
				if aClass.nLevel >= 2 and (sFeature == "school of abjuration" or sFeature == "school of conjuration" or sFeature == "school of divination" or 
				sFeature == "school of enchantment" or sFeature == "school of evocation" or sFeature == "school of illusion" or 
				sFeature == "school of necromancy" or sFeature == "school of transmutation") then
					aClass.sSubclass = sFeature;
					aClass.sSource = "PHB";
					aClass.sValid = "Valid";
					break;
				elseif aClass.nLevel >= 2 and (sFeature == "bladesinging") then
					aClass.sSubclass = sFeature;
					aClass.sSource = "SCA|TCE";
					aClass.sValid = "Valid";
					break;
				elseif aClass.nLevel >= 2 and (sFeature == "order of scribes")  then
					aClass.sSubclass = sFeature;
					aClass.sSource = "TCE";
					aClass.sValid = "Valid";
					break;
				elseif aClass.nLevel >= 2 and (sFeature == "war magic") then
					aClass.sSubclass = sFeature;
					aClass.sSource = "XGE";
					aClass.sValid = "Valid";
					break;
				elseif aClass.nLevel >= 2 then
					aClass.sValid = "Invalid: Missing or invalid subclass";	
				end			
			else
				aClass.sValid = "Invalid: Invalid class";	
			end
		end
		table.insert(aClassActor, aClass);
	end
	return aClassActor;
end

function getFeats(nodeActor)
	local aFeats = {
		{"actor", "CHA", "PHB"},
		{"alert", "", "PHB"},
		{"artificer initiate", "", "TCE"},
		{"athlete", "STR|DEX", "PHB"},
		{"bountiful luck",  "", "XGE"},
		{"charger", "", "PHB"},
		{"chef", "CON|WIS", "TCE"},
		{"crossbow expert", "", "PHB"},
		{"crusher","STR|CON", "TCE"},
		{"defensive duelist", "", "PHB"},
		{"dragon fear", "STR|CON|CHA", "XCE"},
		{"dragon hide", "STR|CON|CHA", "XCE"},
		{"drow high magic", "", "XCE"},
		{"dual wielder", "", "PHB"},
		{"dungeon delver", "", "PHB"},
		{"durable", "CON", "PHB"},
		{"dwarven fortitude", "CON", "XGE"},
		{"eldritch adept", "", "TCE"},
		{"elemental adept", "", "PHB"},
		{"elven accuracy", "DEX|INT|WIS|CHA", "XGE"},
		{"fade away", "INT|DEX", "XGE"},
		{"fey teleportation", "INT|CHA", "XGE"},
		{"fey touched", "INT|WIS|CHA", "TCE"},
		{"fighting initiate", "", "TCE"},
		{"flames of phlegethos", "INT|CHA", "XGE"},
		{"grappler", "", "PHB"},
		{"great weapon master", "", "PHB"},
		{"gunner", "DEX", "TCE"},
		{"healer", "", "PHB"},
		{"heavily armored", "STR", "PHB"},
		{"heavy armor master", "STR", "PHB"},
		{"infernal constitution", "CON", "XGE"},
		{"inspiring leader", "", "PHB"},
		{"keen mind", "INT", "PHB"},
		{"lightly armored", "STR|DEX", "PHB"},
		{"linguist", "INT", "PHB"},
		{"lucky", "", "PHB"},
		{"mage slayer", "", "PHB"},
		{"magic initiate", "", "PHB"},
		{"martial adept", "", "PHB"},
		{"medium armor master", "", "PHB"},
		{"metamagic adept", "", "TCE"},
		{"mobile", "", "PHB"},
		{"moderately armored", "STR|DEX", "PHB"},
		{"mounted combatant", "", "PHB"},
		{"observant", "INT|WIS", "PHB"},
		{"orcish fury", "STR|CON", "XGE"},
		{"piercer", "STR|DEX", "TCE"},
		{"poisoner", "", "TCE"},
		{"polearm master", "", "PHB"},
		{"prodigy", "", "XGE"},
		{"resilient", "STR|DEX|CON|INT|WIS|CHA", "PHB"},
		{"ritual caster", "", "PHB"},
		{"savage attacker", "", "PHB"},
		{"second chance", "DEX|CON|CHA", "XGE"},
		{"sentinel", "", "PHB"},
		{"shadow touched", "INT|WIS|CHA", "TCE"},
		{"sharpshooter", "", "PHB"},
		{"shield master", "", "PHB"},
		{"skill expert", "STR|DEX|CON|INT|WIS|CHA", "TCE"},
		{"skilled", "", "PHB"},
		{"skulker", "", "PHB"},
		{"slasher", "STR|DEX", "TCE"},
		{"spell sniper", "", "PHB"},
		{"squat nimbleness", "STR|DEX", "XGE"},
		{"svirfneblin magic", "", "MTF"},
		{"tavern Brawler", "STR|CON", "PHB"},
		{"telekinetic", "INT|WIS|CHA", "TCE"},
		{"telepathic", "INT|WIS|CHA", "TCE"},
		{"tough", "", "PHB"},
		{"war caster", "", "PHB"},
		{"weapon master", "STR|DEX", "PHB"},
		{"wood elf magic", "", "XGE"},
	};
	local aCharFeats = {};
	for k, v2 in pairs (DB.getChildren(nodeActor, "featlist")) do
		local sLabel =  StringManager.trim(DB.getValue(v2, "name", "")):lower();
		local nMatch = 0;
		for i=1,#aFeats do
			if sLabel == aFeats[i][1] then
				table.insert(aCharFeats, aFeats[i]);
				nMatch = 1;
				break;
			end
		end
		if nMatch == 0 then
			table.insert(aCharFeats .. (" (Invalid)"), {sLabel, "", ""});
		end
	end
	return aCharFeats;
end
