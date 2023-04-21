#ifndef _gotLevelData
#define _gotLevelData

#define gotLevelDataMethod$cellDesc 1	 		// (str)description - Cell Description received from database
#define gotLevelDataMethod$cellData 2			// (var)questData - QuestData received from database
#define gotLevelDataMethod$died 3				// Add one to the death counter
#define gotLevelDataMethod$setFinished 4		// (key)player||(int)-1[, (bool)evtOnFinished] - Set that this player has finished the level. Once all players have finished, the cell moves to the next unless evtOnFinished is set in which case it raises LevelEvt$levelCompleted. If using the latter. Send this command again with "" for user to finalize. If player is -1, then all players have finished
#define gotLevelDataMethod$difficulty 5			// (int)difficulty, (bool)isChallenge - Sets difficulty on the level
#define gotLevelDataMethod$enableWipeTracker 6	// Resets and enables the wipe tracker. The wipe tracker will reset the quest if count(PLAYERS) players have died
#define gotLevelDataMethod$getScripts 7			// (int)remotePin, (arr)scripts - Gets monster scripts from the level

#define gotLevelData$cellData(data) runMethod(ROOT_LEVEL, "got LevelData", gotLevelDataMethod$cellData, [data], TNN)
#define gotLevelData$cellDesc(desc) runMethod(ROOT_LEVEL, "got LevelData", gotLevelDataMethod$cellDesc, [desc], TNN)
#define gotLevelData$died( killer ) runOnDbPlayers(_i, targ, runOmniMethodOn(targ, "got LevelData", gotLevelDataMethod$died, (list)killer, TNN);)
#define gotLevelData$setFinished(player, overrideFinish) runMethod((string)LINK_THIS, "got LevelData", gotLevelDataMethod$setFinished, [player, overrideFinish], TNN)
#define gotLevelData$difficulty(difficulty, challenge) runMethod(ROOT_LEVEL, "got LevelData", gotLevelDataMethod$difficulty, [difficulty, challenge], TNN)
#define gotLevelData$enableWipeTracker() runMethod((str)LINK_THIS, "got LevelData", gotLevelDataMethod$enableWipeTracker, [], TNN)
#define gotLevelData$getScripts(targ, pin, scripts) runMethod((str)targ, "got LevelData", gotLevelDataMethod$getScripts, [pin, scripts], TNN)


#endif
