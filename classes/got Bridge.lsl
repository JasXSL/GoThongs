#define BridgeMethod$refreshThong 1		// Update thong from database
#define BridgeMethod$getToken 2			// Fetch a login token
#define BridgeMethod$dialog 3			// (str)message
#define BridgeMethod$fetchRape 4		// (str)monsterName[, (int)id] if id > 0 then it will trigger that specific rape
#define BridgeMethod$updateThong 5		// void - Make sure this is run every time you complete a cell
#define BridgeMethod$saveBrowser 6		// (vec)pos, (float)scale - Whenever browser has been edited
#define BridgeMethod$reURL 7			// on region change
#define BridgeMethod$getCellData 8		// *void - Sends LevelMethod$cellData and LevelMethod$cellDesc to the current cell, provided you are on the quest of the cell. Needs to be sent from the current cell
#define BridgeMethod$completeCell 9		// *(int)deaths, (int)monsters_killed, (int)continue - Marks a cell for completed. If continue is set, it will load the next level. Needs to be sent from the current cell
#define BridgeMethod$setQuestData 10	// *(var)data - Lets you store data (max-ish 1000 bytes due to SL max message length) for your current quest if you want to add parts where choices you make matter. Will be wiped whenever a quest is completed.
#define BridgeMethod$continueQuest 11	// *(int)cell = -1 - Spawn a cell from your current quest, provided you have completed the previous steps.
#define BridgeMethod$difficulty 12		// (int)difficulty - Sets difficulty

#define Bridge$refreshThong(phys) runMethod((string)LINK_ROOT, "got Bridge", BridgeMethod$refreshThong, [phys], TNN)
#define Bridge$getToken() runMethod((string)LINK_ROOT, "got Bridge", BridgeMethod$getToken, [], TNN)
#define Bridge$dialog(text) runMethod((string)LINK_ROOT, "got Bridge", BridgeMethod$dialog, [text], TNN)
#define Bridge$fetchRape(targ, monsterName) runMethod(targ, "got Bridge", BridgeMethod$fetchRape, [monsterName], TNN)
#define Bridge$saveBrowser(pos, scale) runMethod((string)LINK_ROOT, "got Bridge", BridgeMethod$saveBrowser, [pos, scale], TNN)
#define Bridge$reURL() runMethod((string)LINK_ROOT, "got Bridge", BridgeMethod$reURL, [], TNN)

#define Bridge$getCellData() runMethod(llGetOwner(), "got Bridge", BridgeMethod$getCellData, [], TNN)
#define Bridge$completeCell(targ, deaths, monsters_killed, continue) runMethod(targ, "got Bridge", BridgeMethod$completeCell, [deaths, monsters_killed, continue], TNN)
#define Bridge$setQuestData(targ, data) runMethod(targ, "got Bridge", BridgeMethod$setQuestData, [data], TNN)
#define Bridge$continueQuest() runMethod((string)LINK_THIS, "got Bridge", BridgeMethod$continueQuest, [-1], TNN)
#define Bridge$setQuestStage(stage) runMethod((string)LINK_THIS, "got Bridge", BridgeMethod$continueQuest, [stage], TNN)
#define Bridge$setDifficulty(difficulty) runMethod((string)LINK_THIS, "got Bridge", BridgeMethod$difficulty, [difficulty], TNN)




#define BridgeEvt$data_change 1
#define BridgeEvt$spells_change 2		// (arr)spells
#define BridgeEvt$thong_initialized 3	// void - Thong data fetched
#define BridgeEvt$userDataChanged 4		// (arr)userData, see class User.php fn.getOut

// Thong data
#define BridgeShared$data "a"			
	#define BSS$BONUS_STATS 0			// (arr)stats
	#define BSS$LEVEL 1					// (int)lv
	#define BSS$EXPP 2					// (float)perc
// User data
#define BridgeShared$userData "b"
	#define BSUD$FLAGS 0
	#define BSUD$BROWSER 1				// (arr)[pos, scale]
	#define BSUD$GOLD 2
	#define BSUD$LANG 3

// It needs a separate frame for spells
#define BridgeSpells$name "_BSS"
	#define BSSAA$TEXTURE 0
	#define BSSAA$WRAPPER 1
	#define BSSAA$MANA 2
	#define BSSAA$COOLDOWN 3
	#define BSSAA$TARGET_FLAGS 4
	
	
