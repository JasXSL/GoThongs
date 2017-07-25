#define StatusMethod$debugOut 0				// void - Outputs into chat: [(int)maxHP, (int)maxMana, (int)maxArousal, (int)maxPain]

// debug got Status, 1, 0, 1, -2000 - damage self 20 HP
#define StatusMethod$batchUpdateResources 1 	// (int)type, (int)numArgs, (var)arg1, arg2... - Strided list of resources to add or subtract. Number of args should match numArgs. Floats are auto converted to int with f2i. Use the SMBUR$build* functions to make sure the syntax matches
	#define SMBUR$durability 0						// (float)durability, (str)spellName, (int)flags[, (key)attacker(NPC_ONLY)]
	#define SMBUR$mana 1							// (float)mana, (str)spellName, (int)flags
	#define SMBUR$arousal 2							// (float)arousal, (str)spellName, (int)flags
	#define SMBUR$pain 3							// (float)pain, (str)spellName, (int)flags
	
	#define SMAFlag$IS_PERCENTAGE 0x1			// multiply durability by total HP	
	#define SMAFlag$OVERRIDE_CINEMATIC 0x2		// Allow this effect even during cinematics
	
	#define SMBUR$buildDurability(durability, spellName, flags) [SMBUR$durability, 3, f2i(durability), spellName, flags]
	#define SMBUR$buildDurabilityNPC(durability, spellName, flags, attacker) [SMBUR$durability, 4, f2i(durability), spellName, flags, attacker]
	#define SMBUR$buildMana(mana, spellName, flags) [SMBUR$mana, 3, f2i(mana), spellName, flags]
	#define SMBUR$buildArousal(arousal, spellName, flags) [SMBUR$arousal, 3, f2i(arousal), spellName, flags]
	#define SMBUR$buildPain(pain, spellName, flags) [SMBUR$pain, 3, f2i(pain), spellName, flags]
	
#define StatusMethod$fullregen 5		// NULL
#define StatusMethod$setTargeting 6		// (Bool)targeting - This sender is now targeting you. Send status updates to them
#define StatusMethod$get 7				// returns [STATUS_FLAGS, FXFLAGS, DURABILITY/maxDurability(), MANA/maxMana(), AROUSAL/maxArousal(), PAIN/maxPain(), (int)sex_flags, (int)team]
#define StatusMethod$spellModifiers 8	// [(arr)SPELL_DMG_TAKEN_MOD, ]
										// See got FXCompiler for more info
#define StatusMethod$addTextureDesc 9	// pid, texture, desc, added, duration, stacks - Adds a spell icon
#define StatusMethod$remTextureDesc 10	// (key)texture						
#define StatusMethod$getTextureDesc 11	// (int)pos, (key)texture - Gets info about a spell by pos
#define StatusMethod$setSex 12			// (int)sex - 
#define StatusMethod$outputStats 13		// NULL - Forces stats update (pc only)
#define StatusMethod$loading 14			// (bool)loading - Sets loading flag
#define StatusMethod$setDifficulty 15	// (int)difficulty - between 0->5
#define StatusMethod$stacksChanged 16	// (int)PID, (int)added, (float)duration, (int)stacks - Sent when stacks have changed.
#define StatusMethod$coopInteract 17		// void - Coop player has interacted with you
#define StatusMethod$toggleBossFight 18			// (bool)fight - Received from GUI, toggles boss fight on or off
#define StatusMethod$setTeam 19					// (int)team - PC/NPC

#define StatusMethod$debug 20			// void - Outputs your resources in human readable format
#define StatusMethod$kill 21			// PC only for now - Kills the player immediately
	

// Monster only
#define StatusMethod$monster_dropAggro 100		// (key)target, (int)complete - Drops aggro. If complete is 0, it removes the player from aggro list. If 1 it preserves the aggro until the enemy is seen/deals damage again, like if 2 players are fighting and the tank gets out of LOS it will not remove the aggro next time it sees the tank. If 2 it will just reset the aggro number to 1. If 3, it shuffles all aggro
#define StatusMethod$monster_setFlag 101		// (int)flag
#define StatusMethod$monster_remFlag 102		// (int)flag - Can be used to set a status flag on a monster
#define StatusMethod$monster_takehit 103		// void - Triggers monster take hit visual
#define StatusMethod$monster_aggro 104			// (key)targ, (float)amt
#define StatusMethod$monster_attemptTarget 105	// (int)force - Same effect as clicking the monster
#define StatusMethod$monster_taunt 106			// (key)targ, (bool)inverse - Resets everyone but target's aggro or if inverse is set, resets target's aggro
#define StatusMethod$monster_aggroed 107		// (key)targ, (float)range, (int)team - Sent by monsters when they aggro a player naturally. Aggros everything in range.
#define StatusMethod$monster_rapeMe 108			// void - Sent as omni from player upon death
#define StatusMethod$monster_overrideDesc 109	// (str)desc - Overrides the monster description

// CLIMBABLE DOCUMENTATION
// Climbable items onStart and onEnd events can contain a JSON array: [(int)flags]
#define StatusClimbFlag$root_at_end 1		// Set onEnd to root for 1.5 sec after dropping off the ladder or thing

 

#define StatusEvt$flags 1					// (int)current_flags, (int)previous_flags - To get newly added flags do current_flags&~previous_flags, to get removed flags do previous_flags&~current_flags
#define StatusEvt$monster_gotTarget 2		// [(key)id], Monster only
// Monster doesn't have shared vars so status is sent this way
#define StatusEvt$monster_hp_perc 3			// HP/maxHP
#define StatusEvt$dead 4					// (int)dead
//#define StatusEvt$monster_targData 5		// contains same vars as StatusMethod$get returns
#define StatusEvt$monster_init 6			// Sent once the config has loaded
#define StatusEvt$difficulty 7				// [(int)difficulty]
#define StatusEvt$hurt 8					// [(float)amount, (key)id] - Raised when durability is damaged
#define StatusEvt$death_hit 9				// void - HP has reached 0 but fx$F_NO_DEATH is set
#define StatusEvt$genitals 10				// (int)genitals - Whenever genitals have changed. _core has a definition of these flags
#define StatusEvt$loading_level 11			// [(key)level]
#define StatusEvt$resources 12				// [(float)dur, (float)max_dur, (float)mana, (float)max_mana, (float)arousal, (float)max_arousal, (float)pain, (float)max_pain, (float)hpPerc] - PC only
#define StatusEvt$monster_aggro 13			// [player1, player2...] - Players who have aggroed the monster in order of max aggro
#define StatusEvt$team 14					// (int)team - Team has been updated
#define StatusEvt$interacted 15				// (key)id - Another player has interacted with you
 
// Turns off features to make this static like a door or something
// #define STATUS_IS_STATIC

/*
#define StatusEvt$died 2
#define StatusEvt$mana_full 3
#define StatusEvt$arousal_full 4
#define StatusEvt$pain_full 5
*/


// Checks if target is attackable utilizing the data returned from Status$get
#define _attackable(getData) (!(llList2Integer(getData, 0)&StatusFlags$NON_VIABLE)&&!(llList2Integer(getData,1)&fx$UNVIABLE))
#define _attackableAllowQuickrape(getData) (!(llList2Integer(getData, 0)&StatusFlags$NON_VIABLE))

// These accept vars instead of getdata, usefulf or parseDesc
#define _attackableV(status_flags, fxflags) (!(status_flags&StatusFlags$NON_VIABLE)&&!(fxflags&fx$UNVIABLE))
#define _attackableVQuickrape(status_flags) (!(status_flags&StatusFlags$NON_VIABLE))


#define StatusConst$COMBAT_DURATION 6

// GoThongs supports max 16 flags
#define StatusFlag$dead 0x1			// Checked for automatically by fx
#define StatusFlag$cutscene 0x2		// In cutscene
#define StatusFlag$casting 0x4		// 
#define StatusFlag$raped 0x8		// Dead and raped.
#define StatusFlag$inLevel 0x10		// If currently in a quest level. If not set it's just dicking around with the dev tools
#define StatusFlag$pained 0x20		// Damage taken increased 50%
#define StatusFlag$aroused 0x40		// Damage done reduced 50%
#define StatusFlag$swimming 0x80	// Swimming
#define StatusFlag$climbing 0x100	// Climbing
#define StatusFlag$loading 0x200	// Loading a level
#define StatusFlag$invul 0x400		// Invulnerable after rape
#define StatusFlag$combat 0x800		// In combat
#define StatusFlag$boss_fight 0x1000// In boss fight
#define StatusFlag$coopBreakfree 0x2000	// Coop player can break you free now (challenge mode)

#define StatusFlags$combatLocked (StatusFlag$combat|StatusFlag$boss_fight)
#define StatusFlags$noCast (StatusFlag$dead|StatusFlag$raped|StatusFlag$climbing)

#define StatusFlags$NON_VIABLE (StatusFlag$dead|StatusFlag$raped|StatusFlag$loading|StatusFlag$cutscene)		// For monsters to assume the PC can't be interacted with


#define Status$setTargeting(targ, on) runMethod(targ, "got Status", StatusMethod$setTargeting, [on], TNN)

/*
#define Status$addDurability(amt, spellName, flags) runMethod((string)LINK_ROOT, "got Status", StatusMethod$addDurability, [amt, "", spellName, flags], TNN)
#define Status$addMana(amt, spellName, flags) runMethod((string)LINK_ROOT, "got Status", StatusMethod$addMana, [amt, spellName, flags], TNN)
#define Status$addArousal(amt, spellName, flags) runMethod((string)LINK_ROOT, "got Status", StatusMethod$addArousal, [amt, spellName, flags], TNN)
#define Status$addPain(amt, spellName, flags) runMethod((string)LINK_ROOT, "got Status", StatusMethod$addPain, [amt, spellName, flags], TNN)
*/


#define Status$batchUpdateResources(SMBUR) runMethod((str)LINK_ROOT, "got Status", StatusMethod$batchUpdateResources, SMBUR, TNN)
// NPC
#define Status$addHP(amt, spellName, flags, attacker) Status$batchUpdateResources(SMBUR$buildDurabilityNPC(amt, spellName, flags, attacker))
// PC
#define Status$addDurability(amt, spellName, flags) Status$batchUpdateResources(SMBUR$buildDurability(amt, spellName, flags))
#define Status$addMana(amt, spellName, flags) Status$batchUpdateResources(SMBUR$buildMana(amt, spellName, flags))
#define Status$addArousal(amt, spellName, flags) Status$batchUpdateResources(SMBUR$buildArousal(amt, spellName, flags))
#define Status$addPain(amt, spellName, flags) Status$batchUpdateResources(SMBUR$buildPain(amt, spellName, flags))



#define Status$fullregen() runMethod((string)LINK_ROOT, "got Status", StatusMethod$fullregen, [], TNN)
#define Status$fullregenTarget(targ) runMethod(targ, "got Status", StatusMethod$fullregen, [], TNN)
#define Status$fullregenTargetNoInvul(targ) runMethod(targ, "got Status", StatusMethod$fullregen, [1], TNN)
#define Status$get(targ, cb) runMethod(targ, "got Status", StatusMethod$get, [], cb)
#define Status$spellModifiers(SPELL_DMG_TAKEN_MOD) runMethod((string)LINK_ROOT, "got Status", StatusMethod$spellModifiers, [mkarr(SPELL_DMG_TAKEN_MOD)], TNN)
#define Status$addTextureDesc(pid, texture, desc, added, duration, stacks) runMethod((string)LINK_ROOT, "got Status", StatusMethod$addTextureDesc, [pid, texture, desc, added, duration, stacks], TNN)
#define Status$remTextureDesc(pid) runMethod((string)LINK_ROOT, "got Status", StatusMethod$remTextureDesc, [pid], TNN)
#define Status$getTextureDesc(targ, pid) runMethod(targ, "got Status", StatusMethod$getTextureDesc, [pid], TNN)
#define Status$setSex(sex) runMethod((string)LINK_ROOT, "got Status", StatusMethod$setSex, [sex], TNN)
#define Status$loading(targ, loading) runMethod(targ, "got Status", StatusMethod$loading, [loading], TNN)
#define Status$setDifficulty(difficulty) runMethod((str)LINK_ROOT, "got Status", StatusMethod$setDifficulty, [difficulty], TNN)
#define Status$stacksChanged(pid, added, duration, stacks) runMethod((string)LINK_ROOT, "got Status", StatusMethod$stacksChanged, [pid, added, duration, stacks], TNN)
#define Status$refreshCombat() llMessageLinked(LINK_ROOT, TASK_REFRESH_COMBAT, "", "") 
#define Status$toggleBossFight(on) runMethod((str)LINK_ROOT, "got Status", StatusMethod$toggleBossFight, [on], TNN)
#define Status$coopInteract(targ) runMethod((str)targ, "got Status", StatusMethod$coopInteract, [], TNN)
#define Status$kill(targ) runMethod((str)targ, "got Status", StatusMethod$kill, [], TNN)


// Monster
#define Status$dropAggro(targ) runMethod((string)LINK_ROOT, "got Status", StatusMethod$monster_dropAggro, [targ], TNN)
#define Status$hitfx(targ) runMethod(targ, "got Status", StatusMethod$monster_takehit, [], TNN)
#define Status$monster_attemptTarget(targ, force) runMethod(targ, "got Status", StatusMethod$monster_attemptTarget, [force], TNN)
#define Status$monster_aggro(targ, amt) runMethod((string)LINK_ROOT, "got Status", StatusMethod$monster_aggro, [targ, amt], TNN)
#define Status$dropAggroConditional(targ, condition) runMethod((string)LINK_ROOT, "got Status", StatusMethod$monster_dropAggro, [targ, condition], TNN)
#define Status$monster_taunt(targ, inverse) runMethod((string)LINK_ROOT, "got Status", StatusMethod$monster_taunt, [targ, inverse], TNN)
#define Status$monster_aggroed(player, range, team) runLimitMethod(llGetOwner(), "got Status", StatusMethod$monster_aggroed, [player, range, team], TNN, range)
#define Status$monster_rapeMe() runOnPlayers(k, runLimitMethod(k, "got Status", StatusMethod$monster_rapeMe, [], TNN, 10);)
#define Status$monster_overrideDesc(desc) runMethod((str)LINK_ROOT, "got Status", StatusMethod$monster_overrideDesc, [desc], TNN)
#define Status$setTeam(targ, team) runMethod((str)targ, "got Status", StatusMethod$setTeam, [team], TNN)



