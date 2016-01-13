#define StatusMethod$addDurability 1		// [(float)durability, (key)caster, (str)spellName, (int)flags]
	#define SMAFlag$IS_PERCENTAGE 0x1			// multiply durability by total HP	
#define StatusMethod$addMana 2		// [(float)durability, (str)spellName[, (int)flags]]
#define StatusMethod$addArousal 3		// [(float)durability, (str)spellName[, (int)flags]]
#define StatusMethod$addPain 4		// [(float)durability, (str)spellName]
#define StatusMethod$fullregen 5		// NULL
#define StatusMethod$setTargeting 6		// (Bool)targeting - This sender is now targeting you. Send status updates to them
#define StatusMethod$get 7				// returns [STATUS_FLAGS, FXFLAGS, DURABILITY/maxDurability(), MANA/maxMana(), AROUSAL/maxArousal(), PAIN/maxPain(), (int)sex_flags]
#define StatusMethod$spellModifiers 8	// [(arr)SPELL_DMG_TAKEN_MOD, ]
										// See got FXCompiler for more info
#define StatusMethod$addTextureDesc 9	// pid, texture, desc, added, duration, stacks - Adds a spell icon
#define StatusMethod$remTextureDesc 10	// (key)texture						
#define StatusMethod$getTextureDesc 11	// (int)pos, (key)texture - Gets info about a spell by pos
#define StatusMethod$setSex 12			// (int)sex - 
#define StatusMethod$outputStats 13		// NULL - Forces stats update (pc only)
#define StatusMethod$loading 14			// (bool)loading - Sets loading flag
#define StatusMethod$setDifficulty 15	// (int)difficulty, (bool)sendToCoop - between 0->5
#define StatusMethod$stacksChanged 16	// (int)PID, (int)stacks - Sent when stacks have changed.

// Monster only
#define StatusMethod$monster_dropAggro 100		// (key)target, (int)complete - Drops aggro. If complete is 0, it removes the player from aggro list. If 1 it preserves the aggro until the enemy is seen/deals damage again, like if 2 players are fighting and the tank gets out of LOS it will not remove the aggro next time it sees the tank. If 2 it will just reset the aggro number to 1.
#define StatusMethod$monster_setFlag 101		// (int)flag
#define StatusMethod$monster_remFlag 102		// (int)flag - Can be used to set a status flag on a monster
#define StatusMethod$monster_takehit 103		// void - Triggers monster take hit visual
#define StatusMethod$monster_aggro 104			// (key)targ, (float)amt
#define StatusMethod$monster_attemptTarget 105	// (int)force - Same effect as clicking the monster
#define StatusMethod$monster_taunt 106			// (key)targ - Resets everyone but target's aggro 
#define StatusMethod$monster_aggroed 107		// (key)targ, (float)range - Sent by monsters when they aggro a player naturally. Aggros everything in range.
#define StatusMethod$monster_rapeMe 108			// void - Sent as omni from player upon death

#define StatusShared$dur "a"		// [(float)current, (float)max]
#define StatusShared$mana "b"		// [(float)current, (float)max]
#define StatusShared$arousal "c"	// [(float)current, (float)max]
#define StatusShared$pain "d"		// [(float)current, (float)max]
#define StatusShared$sex "e"
#define StatusShared$flags "g"		// (int)flags


// CLIMBABLE DOCUMENTATION
// Climbable items onStart and onEnd events can contain a JSON array: [(int)flags]
#define StatusClimbFlag$root_at_end 1		// Set onEnd to root for 1.5 sec after dropping off the ladder or thing



#define StatusEvt$flags 1					// (int)flags
#define StatusEvt$monster_gotTarget 2		// [(key)id], Monster only
// Monster doesn't have shared vars so status is sent this way
#define StatusEvt$monster_hp_perc 3			// HP/maxHP
#define StatusEvt$dead 4					// (int)dead
#define StatusEvt$monster_targData 5		// contains same vars as StatusMethod$get returns
#define StatusEvt$monster_init 6			// Sent once the config has loaded
#define StatusEvt$difficulty 7				// [(int)difficulty]

// Turns off features to make this static like a door or something
// #define STATUS_IS_STATIC

/*
#define StatusEvt$died 2
#define StatusEvt$mana_full 3
#define StatusEvt$arousal_full 4
#define StatusEvt$pain_full 5
*/

// Shortcuts
#define _statusFlags() (integer)db2$get("got Status", [StatusShared$flags])
// Checks if target is attackable utilizing the data returned from Status$get
#define _attackable(getData) (!((int)j(getData, 0)&StatusFlags$NON_VIABLE)&&!((int)j(getData,1)&fx$UNVIABLE))

// GoThongs supports max 16 flags
#define StatusFlag$dead 0x1			// (int)dead - Checked for automatically by fx
#define StatusFlag$game_started 0x2	// 
#define StatusFlag$casting 0x4		// 
#define StatusFlag$raped 0x8		// Dead and raped.
#define StatusFlag$inLevel 0x10		// If currently in a quest level. If not set it's just dicking around with the dev tools
#define StatusFlag$pained 0x20		// Damage taken increased 50%
#define StatusFlag$aroused 0x40		// Damage done reduced 50%
#define StatusFlag$swimming 0x80	// Swimming
#define StatusFlag$climbing 0x100	// Climbing
#define StatusFlag$loading 0x200	// Loading a level
#define StatusFlag$invul 0x400		// Invulnerable after rape

#define StatusFlags$noCast (StatusFlag$dead|StatusFlag$raped|StatusFlag$climbing)

#define StatusFlags$NON_VIABLE (StatusFlag$dead|StatusFlag$raped)		// For monsters to assume the PC can't be interacted with

#define Status$setTargeting(targ, on) runMethod(targ, "got Status", StatusMethod$setTargeting, [on], TNN)
#define Status$addDurability(amt, spellName, flags) runMethod((string)LINK_ROOT, "got Status", StatusMethod$addDurability, [amt, "", spellName, flags], TNN)
#define Status$addMana(amt, spellName, flags) runMethod((string)LINK_ROOT, "got Status", StatusMethod$addMana, [amt, spellName, flags], TNN)
#define Status$addArousal(amt, spellName, flags) runMethod((string)LINK_ROOT, "got Status", StatusMethod$addArousal, [amt, spellName, flags], TNN)
#define Status$addPain(amt, spellName, flags) runMethod((string)LINK_ROOT, "got Status", StatusMethod$addPain, [amt, spellName, flags], TNN)
#define Status$fullregen() runMethod((string)LINK_ROOT, "got Status", StatusMethod$fullregen, [], TNN)
#define Status$fullregenTarget(targ) runMethod(targ, "got Status", StatusMethod$fullregen, [], TNN)
#define Status$get(targ, cb) runMethod(targ, "got Status", StatusMethod$get, [], cb)
#define Status$spellModifiers(SPELL_DMG_TAKEN_MOD) runMethod((string)LINK_ROOT, "got Status", StatusMethod$spellModifiers, [mkarr(SPELL_DMG_TAKEN_MOD)], TNN)
#define Status$addTextureDesc(pid, texture, desc, added, duration, stacks) runMethod((string)LINK_ROOT, "got Status", StatusMethod$addTextureDesc, [pid, texture, desc, added, duration, stacks], TNN)
#define Status$remTextureDesc(pid) runMethod((string)LINK_ROOT, "got Status", StatusMethod$remTextureDesc, [pid], TNN)
#define Status$getTextureDesc(targ, pid) runMethod(targ, "got Status", StatusMethod$getTextureDesc, [pid], TNN)
#define Status$setSex(sex) runMethod((string)LINK_ROOT, "got Status", StatusMethod$setSex, [sex], TNN)
#define Status$loading(targ, loading) runMethod(targ, "got Status", StatusMethod$loading, [loading], TNN)
#define Status$setDifficulty(targ, difficulty, sendToCoop) runMethod(targ, "got Status", StatusMethod$setDifficulty, [difficulty, sendToCoop], TNN)
#define Status$stacksChanged(pid, added, duration, stacks) runMethod((string)LINK_ROOT, "got Status", StatusMethod$stacksChanged, [pid, added, duration, stacks], TNN)


// Monster
#define Status$dropAggro(targ) runMethod((string)LINK_ROOT, "got Status", StatusMethod$monster_dropAggro, [targ], TNN)
#define Status$addHP(amt, attacker, spellname, flags) runMethod((string)LINK_ROOT, "got Status", StatusMethod$addDurability, [amt, attacker, spellname, flags], TNN)
#define Status$hitfx(targ) runMethod(targ, "got Status", StatusMethod$monster_takehit, [], TNN)
#define Status$monster_attemptTarget(targ, force) runMethod(targ, "got Status", StatusMethod$monster_attemptTarget, [force], TNN)
#define Status$monster_aggro(targ, amt) runMethod((string)LINK_ROOT, "got Status", StatusMethod$monster_aggro, [targ, amt], TNN)
#define Status$dropAggroConditional(targ, condition) runMethod((string)LINK_ROOT, "got Status", StatusMethod$monster_dropAggro, [targ, condition], TNN)
#define Status$monster_taunt(targ) runMethod((string)LINK_ROOT, "got Status", StatusMethod$monster_taunt, [targ], TNN)
#define Status$monster_aggroed(player, range) runLimitMethod(llGetOwner(), "got Status", StatusMethod$monster_aggroed, [player, range], TNN, range)
#define Status$monster_rapeMe() runOnPlayers(k, runLimitMethod(k, "got Status", StatusMethod$monster_rapeMe, [], TNN, 10);)





