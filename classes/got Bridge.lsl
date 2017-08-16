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

#define BridgeMethod$addGold 13			// (int)amount - callbacks (int)modified or 0 if it failed. Amount is in copper, multiply by 10 for silver, 100 for gold
#define BridgeMethod$getGold 14			// void - Returns [(int)gold]
#define BridgeMethod$audio 15			// (str)task, (var)data - See pubAudio in Bridge.php or use the BridgeMethod$audio macros
#define BridgeMethod$savePos 16			// (bool)offhand, (bool)back, (vec)pos, (rot)rotation - Saves weapon custom offset
#define BridgeMethod$saveScale 17		// (float)multiplier - Saves weapon scale multiplier
#define BridgeMethod$unlockWeapon 18	// (str)token - Unlocks a weapon by token
#define BridgeMethod$setBook 19			// (str)token - Loads a book
#define BridgeMethod$monstersKilled 20	// [[(str)monster, (vec)pos]...]

#define Bridge$refreshThong() runMethod((string)LINK_SET, "got Bridge", BridgeMethod$refreshThong, [], TNN)
#define Bridge$getToken() runMethod((string)LINK_SET, "got Bridge", BridgeMethod$getToken, [], TNN)
#define Bridge$dialog(text) runMethod((string)LINK_SET, "got Bridge", BridgeMethod$dialog, [text], TNN)
#define Bridge$fetchRape(targ, monsterName) runMethod(targ, "got Bridge", BridgeMethod$fetchRape, [monsterName], TNN)
#define Bridge$saveBrowser(pos, scale) runMethod((string)LINK_SET, "got Bridge", BridgeMethod$saveBrowser, [pos, scale], TNN)
#define Bridge$reURL() runMethod((string)LINK_SET, "got Bridge", BridgeMethod$reURL, [], TNN)

#define Bridge$getCellData() runMethod(llGetOwner(), "got Bridge", BridgeMethod$getCellData, [], TNN)
#define Bridge$completeCell(targ, deaths, monsters_killed, continue) runMethod(targ, "got Bridge", BridgeMethod$completeCell, [deaths, monsters_killed, continue], TNN)
#define Bridge$setQuestData(targ, data) runMethod(targ, "got Bridge", BridgeMethod$setQuestData, [data], TNN)
#define Bridge$continueQuest() runMethod((string)LINK_ROOT, "got Bridge", BridgeMethod$continueQuest, [-1], TNN)
#define Bridge$setQuestStage(stage) runMethod((string)LINK_ROOT, "got Bridge", BridgeMethod$continueQuest, [stage], TNN)
#define Bridge$addGold(targ, amount, cb) runMethod((string)targ, "got Bridge", BridgeMethod$addGold, [amount], cb)
#define Bridge$getGold(targ, cb) runMethod((string)targ, "got Bridge", BridgeMethod$getGold, [], cb)

#define Bridge$audioPlay(targ, file, volume, loop) runMethod((str)targ, "got Bridge", BridgeMethod$audio, ["play", file, volume, loop], TNN)
#define Bridge$audioStop(targ, file, fadeOut) runMethod((str)targ, "got Bridge", BridgeMethod$audio, ["stop", file, fadeOut], TNN)
#define Bridge$audioMusic(targ, file, volume, loop) runMethod((str)targ, "got Bridge", BridgeMethod$audio, ["music", file, volume, loop], TNN)
#define Bridge$audioMoment(targ, file, volume) runMethod((str)targ, "got Bridge", BridgeMethod$audio, ["moment", file, volume], TNN)
// Files are file names. Can be URLS but they have to start with http - Preferably OGG files
#define Bridge$audioPreload(targ, files) runMethod((str)targ, "got Bridge", BridgeMethod$audio, ["preload"]+files, TNN)
#define Bridge$savePos(offhand, back, pos, rot) runMethod((str)LINK_ROOT, "got Bridge", BridgeMethod$savePos, [offhand, back, pos, rot], TNN)
#define Bridge$saveScale(scale) runMethod((str)LINK_ROOT, "got Bridge", BridgeMethod$saveScale, [scale], TNN)
#define Bridge$unlockWeapon(targ, token) runMethod((str)targ, "got Bridge", BridgeMethod$unlockWeapon, [token], TNN)
#define Bridge$setBook(book) runMethod((str)LINK_ROOT, "got Bridge", BridgeMethod$setBook, [book], TNN)
#define Bridge$monstersKilled(targ, data) runMethod((str)targ, "got Bridge", BridgeMethod$monstersKilled, data, TNN)


#define BridgeEvt$data_change 1			// Thong data changed
#define BridgeEvt$spells_change 2		// (arr)spells
#define BridgeEvt$thong_initialized 3	// void - Thong data fetched
#define BridgeEvt$userDataChanged 4		// (arr)userData, see class User.php fn.getOut
#define BridgeEvt$goldChanged 5			// (int)gold
#define BridgeEvt$partyIcons 6			// (arr)UUIDs - UUIDs of the party

// Thong data
#define BridgeShared$data "a"			
	#define BSS$BONUS_STATS 0			// (arr)stats - Replace these with passives instead
	#define BSS$LEVEL 1					// (int)lv
	#define BSS$EXPP 2					// (float)perc
// User data
#define BridgeShared$userData "b"
	#define BSUD$FLAGS 0				// int Flags
	#define BSUD$BROWSER 1				// (arr)[pos, scale]
	#define BSUD$GOLD 2					// int Copper
	#define BSUD$LANG 3					// int Language bitwise
	#define BSUD$DIFFICULTY 4			// int Difficulty
	#define BSUD$W_SCALE 5				// float Mainhand scale offset
	#define BSUD$W_MH_OFFSET 6			// vec Mainhand offset
	#define BSUD$W_BACK_MH_OFFSET 7		// vec Mainhand back offset
	#define BSUD$W_OH_OFFSET 8			// vec Offhand offset
	#define BSUD$W_BACK_OH_OFFSET 9		// vec Offhand back offset
	#define BSUD$WDATA 10				// arr Weapondata
	#define BSUD$ENCHANTS 11			// arr Passives
	#define BSUD$IGNORE_TOKEN 12		// bool ignore - Don't reload the website
	
	
#define Bridge$userData() db3$get("got Bridge", [BridgeShared$userData])
	
// It needs a separate frame for spells, an ID nr of 0-4 is appended after _BSS_
#define BridgeSpells$name "_BSS_"
	#define BSSAA$texture 0
	#define BSSAA$id 1
	#define BSSAA$fxwrapper 2
	#define BSSAA$mana 3
	#define BSSAA$cooldown 4
	#define BSSAA$target_flags 5
	#define BSSAA$range 6
	#define BSSAA$casttime 7
	#define BSSAA$fx 8
	#define BSSAA$selfcast 9
	
	
