// Fxs
// * = not implemented yet
	// The flags in the top 2 are the SMAFlags defined in got Status
	#define fx$DAMAGE_DURABILITY 1				// [(int)amount_to_rem[, (int)flags]]
	#define fx$AROUSE 2							// [(int)amount_to_add[, (int)flags]]
	#define fx$PAIN 3							// [(int)amount_to_add]
	#define fx$MANA 4							// [(int)amount_to_add]
	#define fx$TRIGGER_SOUND 5					// [(key)uuid, (float)vol] - UUID can also be a JSON array of random sounds
	#define fx$HITFX 6							// [(vec)color, (int)flags]
		#define fxhfFlag$NOANIM 1					// Don't use standard takehit anim
		#define fxhfFlag$NOSOUND 2					// Don't use a default sound
		
		#define fxhfColor$phys "<1,.5,.5>"
		#define fxhfColor$arouse "<1,.5,1>"
		#define fxhfColor$toxic "<.8,1,.7>"
		#define fxhfColor$holy "<1,1,.7>"
		#define fxhfColor$cold "<.5,.8,1>"
		
		
	#define fx$ANIM 7							// [(str)anim, (int)start]
	#define fx$DODGE 8							// *(int)chance_to_add - Adds a chance to dodge bad spells unless undodgable
	#define fx$DEBUG 9							// [(str)message]
	#define fx$REM_BY_NAME 10					// [(str)name, (int)raise_event]
	#define fx$REM_THIS 11						// [(int)raise_event]
	#define fx$THONG_VISUAL 12					// see ThongManMethod$fxVisual
	#define fx$SET_FLAG 13						// [(int)flags]
	#define fx$UNSET_FLAG 14					// [(int)flags] - Overrides fx$SET_FLAG
		// Max 16 flags are supported
		#define fx$F_STUNNED 0x1					// Unable to move or attack
		#define fx$F_PACIFIED 0x2					// Unable to attack but can use friendly spells. For NPC it doesn't affect spells, but only auto attacks
		#define fx$F_INVUL 0x4						// Cannot take damage
		#define fx$F_ROOTED 0x8						// Unable to move but can attack
		#define fx$F_QUICKRAPE 0x10					// Inside of a quickrape - This one is autochecked for in got FX and does not need a condition
		#define fx$F_SILENCED 0x20					// Unable to cast any spells at all
		
		#define fx$NOCAST (fx$F_STUNNED|fx$F_QUICKRAPE|fx$F_SILENCED)
	#define fx$MANA_REGEN_MULTIPLIER 15			// (float)add
	#define fx$DAMAGE_TAKEN_MULTIPLIER 16		// (float)add
	#define fx$DAMAGE_DONE_MULTIPLIER 17		// (float)add
	#define fx$CASTTIME_MULTIPLIER 18			// (float)add
	#define fx$SPELL_DMG_TAKEN_MOD 19			// (str)spellName, (float)add - Misnomer. It increases efficiency of dur/man/ars/pain sections of a spell, useful for heals too
	#define fx$ICON 20							// (key)icon, (str)description
	#define fx$INTERRUPT 21						// 
	#define fx$SPELL_DMG_DONE_MOD 22			// (str)spellName, (float)add - Increases efficiency of spells cast by you with this name
	#define fx$FULLREGEN 23						// NULL - Fully restores a player
	#define fx$DISPEL 24						// (int)detrimental, (int)nr
	#define fx$COOLDOWN_MULTIPLIER 25			// (float)add
	#define fx$MANA_COST_MULTIPLIER 26			// (float)add - PC only
	#define fx$HUD_TEXT 27						// (str)text, (bool)output_into_chat, (bool)play_sound
	#define fx$AGGRO 28							// (float)amt - NPC only
	#define fx$RESET_COOLDOWNS 29				// (int)flags, 0x1 = rest, 0x2 = abil1 etc - PC only
	#define fx$RAND 30							// (float)chance, (bool)multiply_by_stacks, (arr)fxobj1, (arr)fxobj2... - Pseudo effect. If llFrand(1)<=chance, then the trailing fxobjs are run (fxobj is (int)fx, (var)data1.... Only works for instant effects. Multiply_by_stacks will make it so if you have a chance of .2, and 3 stacks, that's a chance of 0.6
	#define fx$FORCE_SIT 31						// (key)object, (bool)allow_unsit 
	#define fx$CRIT_MULTIPLIER 32				// (float)amt - Increases chance of doing double damage
	
// conditions
	// Built in
	#define fx$COND_HAS_PACKAGE_NAME 1			// [(str)name1, (str)name2...] - Recipient has a package with at least one of these names
	#define fx$COND_HAS_PACKAGE_TAG 2			// [(int)tag1, (int)tag2...] - Recipient has a tackage with a tag with at least one of these
	
	// User defined
	#define fx$COND_HAS_STATUS 3				// [(int)flags, OR(int)flags] - [FLAG_X|FLAG_Y] = has at least one flag. [FLAG_X, FLAG_Y] has BOTH flags
	#define fx$COND_HAS_FXFLAGS 4				// [(int)flags, OR(int)flags] - Same as above. Except for fxflags

	#define fx$COND_HP_GREATER_THAN 5			// [(float)0-1.]
	#define fx$COND_MANA_GREATER_THAN 6			// [(float)0-1.]
	#define fx$COND_PAIN_GREATER_THAN 7			// [(float)0-1.]
	#define fx$COND_AROUSAL_GREATER_THAN 8		// [(float)0-1.]
	
	#define fx$COND_IS_NPC 9					// NULL - Victim is NPC
	#define fx$COND_TARGETING_CASTER 10			// NULL - NPC ONLY, If the victim currently has the sender as their target
	
// Reserved names:
	#define FXN$INFUSION "_I"					// Bloodlust
	#define FXN$QUICKRAPE "_Q"					// Quickrape
	
// Tags
						
	
	