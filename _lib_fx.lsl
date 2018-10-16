// Fxs
/*
	
	A note about the values that say multiply_by
	This is an offset from zero. So if you wanted to reduce damage taken by 30%, you would set the value to -0.3
	The values are multiplicative and -0.3 gets converted into a multiplier of 0.7
	This is to make sure that no matter how many damage reduction effects you have, you still won't go under 0 unless the value is less than -1

*/

// * = not implemented yet
	// The flags in the top 2 are the SMAFlags defined in got Status
	// Note: These MUST be positive! And can only range between 0 and 255
	#define fx$DAMAGE_DURABILITY 1				// [(int)amount_to_rem[, (int)flags]]
	#define fx$AROUSE 2							// [(int)amount_to_add[, (int)flags]]
	#define fx$PAIN 3							// [(int)amount_to_add[, (int)flags]]
	#define fx$MANA 4							// [(int)amount_to_add[, (int)flags]]
	#define fx$TRIGGER_SOUND 5					// [(key)uuid, (float)vol, (bool)self_only] - UUID can also be a JSON array of random sounds
	#define fx$HITFX 6							// [(vec)color, (int)flags]
		#define fxhfFlag$NOANIM 1					// Don't use standard takehit anim
		#define fxhfFlag$NOSOUND 2					// Don't use a default sound
		#define fxhfFlag$PAIN_HEAVY 0x4				// Could be used for RP purposes
		#define fxhfFlag$AROUSAL 0x8				// Could be used for RP purposes
		#define fxhfFlag$AROUSAL_HEAVY 0x10			// Could be used for RP purposes
		#define fxhfFlag$IGNORE_TYPE 0x20			// Prevents RP grunts
		
		// New flags for slot specific
		#define fxhfFlag$SLOT_GROIN 0x40
		#define fxhfFlag$SLOT_BUTT 0x80
		#define fxhfFlag$SLOT_BREASTS 0x100
		#define fxhfFlag$SLOT_STOMACH 0x200
		
		#define fxhfColor$phys "<1,.5,.5>"
		#define fxhfColor$arouse "<1,.5,1>"
		#define fxhfColor$toxic "<.8,1,.7>"
		#define fxhfColor$holy "<1,1,.7>"
		#define fxhfColor$cold "<.5,.8,1>"
		
		
	#define fx$ANIM 7							// [(str)anim(or array), (int)start, (bool)ignore_immediate, (int)flags] | If ignore immediate is set, it will not be run on instant effects or ticks.
	#define fx$DODGE 8							// (float)chance_to_add - Adds a chance to dodge bad spells unless undodgable
	//#define fx$DEBUG 9							// [(str)message]
	#define fx$REM_BY_NAME 10					// [(str)name, (int)raise_event, (bool)only_by_caster]
	#define fx$REM_THIS 11						// [(int)raise_event] - Only works within a tick
	#define fx$THONG_VISUAL 12					// see ThongManMethod$fxVisual
	#define fx$SET_FLAG 13						// [(int)flags]
	#define fx$UNSET_FLAG 14					// [(int)flags] - Overrides fx$SET_FLAG
		#define fx$F_STUNNED 0x1					// Unable to move or attack
		#define fx$F_PACIFIED 0x2					// Unable to attack but can use friendly spells. For NPC it doesn't affect spells, but only auto attacks
		#define fx$F_INVUL 0x4						// Cannot take damage
		#define fx$F_ROOTED 0x8						// Unable to move but can attack
		#define fx$F_QUICKRAPE 0x10					// Inside of a quickrape - This one is autochecked for in got FX and does not need a condition
		#define fx$F_SILENCED 0x20					// Unable to cast any spells at all
		#define fx$F_BLINDED 0x40					// Makes screen black
		#define fx$F_NOROT 0x80						// Unable to rotate
		#define fx$F_BLURRED 0x100					// Blurry screen
		#define fx$F_NO_TARGET 0x200				// This player can not be targeted by NPCs
		#define fx$F_NO_PULL 0x400					// Blocks fx$PULL (37)
		#define fx$F_NO_DEATH 0x800					// PC - Prevents the player from going below 0 HP and instead raises StatusEvt$death_hit
		#define fx$F_CAST_WHILE_MOVING 0x1000		// PC - Allows you to cast while moving
		#define fx$F_SHOW_GENITALS 0x2000			// PC - Renders the character naked
		#define fx$F_DISARM 0x4000					// PC - Disables weapon graphic
		#define fx$F_NO_INTERRUPT 0x8000			// PC - Blocks interrupts
		#define fx$F_ALWAYS_BEHIND 0x10000			// PC - All attacks made from this character are treated as from behind
		#define fx$NO_PROCS 0x20000					// PC - Disables procs
		#define fx$F_STUNNED_IMPORTANT 0x40000		// NPC - Effect stuns bosses as well
		#define fx$F_FORCE_MOUSELOOK 0x80000		// PC - Makes only mouselook work
		
		#define fx$NOCAST (fx$F_STUNNED|fx$F_QUICKRAPE|fx$F_SILENCED)
		#define fx$UNVIABLE (fx$F_QUICKRAPE|fx$F_NO_TARGET)
		
		

	#define fx$MANA_REGEN_MULTI 15				// (float)add
	#define fx$DAMAGE_TAKEN_MULTI 16			// (float)add, (bool)by_caster
	#define fx$DAMAGE_DONE_MULTI 17				// (float)add, (bool)to_caster
	#define fx$CASTTIME_MULTI 18				// (float)add
	#define fx$SPELL_DMG_TAKEN_MOD 19			// (str)spellName, (float)add, (bool)by_caster - PC only SpellName is the FX package name :: Increases efficiency of dur/man/ars/pain sections of a spell, useful for heals too
	#define fx$ICON 20							// (key)icon, (str)description
												// Description can use a macro <|s3|> for a value multiplied by stacks
	#define fx$INTERRUPT 21						// (bool)force - Force will override fx$F_NO_INTERRUPT
	#define fx$SPELL_DMG_DONE_MOD 22			// (int)index, (float)add - Index is the index of the spell, 0 is rest and then 1-4 for the others :: Increases efficiency of spells cast by you with this name
	#define fx$FULLREGEN 23						// NULL - Fully restores a player
	#define fx$DISPEL 24						// (int)detrimental, (int)nr
	#define fx$COOLDOWN_MULTI 25				// (float)add - Also increases time between attacks in NPCs
	#define fx$MANA_COST_MULTI 26				// (float)add - PC only
	#define fx$HUD_TEXT 27						// (str)text, (bool)output_into_chat, (bool)play_sound
	#define fx$AGGRO 28							// (float)amt - NPC only
	#define fx$RESET_COOLDOWNS 29				// (int)flags, 0x1 = rest, 0x2 = abil1 etc, charges=1 - PC only. Adds charges to a spell.
	#define fx$RAND 30							// (float)chance, (bool)multiply_by_stacks, (arr)fxobj1, (arr)fxobj2... - Pseudo effect. If llFrand(1)<=chance, then the trailing fxobjs are run (fxobj is (int)fx, (var)data1.... Only works for instant effects. Multiply_by_stacks will make it so if you have a chance of .2, and 3 stacks, that's a chance of 0.6
	#define fx$FORCE_SIT 31						// (key)object, (bool)allow_unsit 
	#define fx$CRIT_ADD 32						// (float)amt - Increases chance of doing double damage
	#define fx$ROT_TOWARDS 33					// (vec)pos - PC ONLY, Rotates the player towards a global position
	#define fx$PARTICLES 34						// (float)duration, (int)prim, (arr)particles - PC_ONLY - See ThongMan$particles
	#define fx$TAUNT 35							// (bool)inverse - NPC ONLY, resets everyone but this player's aggro. If inverse is set, reset this player's aggro only
	#define fx$REM 36							// Accepts the same arguments as FX$rem at got FX.lsl
	#define fx$PULL 37							// (vec)pos, (float)speed - PC only. (Use PF_TRIGGER_IMMEDIATE) Instant effect but is cleared on effect fade for duration effects
	#define fx$SPAWN_VFX 38						// (str)name, (vec)posOffset, (rot)rotoffset, (int)flags, (int)startParam - PC only. Spawns a visual effect from the SpellFX container on the HUD
	#define fx$REGION_SAY 39					// (int)chan, (str)message - Does what it says on the box
	#define fx$AROUSAL_MULTI 40					// (float)add - PC only, Increases or decreases arousal generation
	#define fx$PAIN_MULTI 41					// (float)add - PC only, Increases or decreases pain generation
	#define fx$ALERT 42							// (str)text, (bool)ownersay, (bool)sound - PC only, standard alert
	#define fx$ATTACH 43						// attachment1, attachment2...
	#define fx$MOVE_SPEED 44					// (float)add - NPC only, reduces movement speed
	#define fx$SPELL_MANACOST_MULTI 45			// (int)index, (float)multiply - PC only
	#define fx$SPELL_CASTTIME_MULTI 46			// (int)index, (float)multiply - PC only
	#define fx$SPELL_COOLDOWN_MULTI 47			// (int)index, (float)multiply - PC only
	#define fx$ADD_FX 48						// (arr)wrapper[, (int)targ_flags, (float)range] - Adds a wrapper as a self cast or if flags are set, uses those for targets. Instant only,
		#define FXAF$SELF 0x1						// Apply FX on victim
		#define FXAF$CASTER 0x2						// Apply FX on caster
		#define FXAF$AOE 0x4						// Apply FX on AOE
	#define fx$ADD_STACKS 49					// (int)stacks, (str)name... - See FXMethod$addStacks -  Adds (resets timer) or removes stacks (does not affect timer)
	#define fx$SPELL_HIGHLIGHT 50				// (int)index, (int)min_stacks - PC Only - Draws a yellow border around a spell. 0 is the bottom ability, then 1-4 for the upper row. If min_stacks is set, then you need a minimum of that amount of stacks for it to proc
	#define fx$HEALING_TAKEN_MULTI 51			// (float)add, (bool)by_caster - Increases or decreases healing received
	#define fx$HEALING_DONE_MULTI 52			// (float)add - Increases or decreases healing done
	#define fx$SPAWN_MONSTER 53					// (str)name, (vec)foot_offset, (rot)rot_offset, (str)desc - (PC only) Spawns a monster from HUD
	#define fx$SET_TEAM 54						// (int)team - (PC ONLY for now)Overrides the current team
	#define fx$CUBETASKS 55						// (arr)tasks - PC ONLY Sends cubetasks to the owner
	#define fx$BEFUDDLE 56						// (float)perc - PC ONLY - Adds a chance on spell cast to target a random player
	#define fx$CONVERSION 57					// (int)conversion1, (int)conversion2... - PC ONLY - See got FXCompiler.lsl
	#define fx$LTB 58							// (str)asset, (arr)conf - PC Only - Spawns a long term buff visual which sticks around on the affected player until the spell is removed.
	#define fx$REFRESH_SPRINT 59				// void - PC Only - Instant only. Refreshes sprint
	#define fx$HP_ADD 60						// (float)amount - PC only - Increases max HP by amount nr of points.
	#define fx$GRAVITY 61						// (float)n - PC only - Overrides gravity, the last call is the active one
	#define fx$PUSH 62							// (vec)dir - PC only - Applies an impulse
	#define fx$CLASS_VIS 63						// (var)data[, (float)timeout=1] - PC only. Sends class vis data to got ClassAtt. Start is sent on add/instant and end is sent on fade with -1
	#define fx$MANA_MULTI 64					// (float)amount - PC only, increases or decreases max mana
	#define fx$HP_MULTI 65						// (float)amount - Increases or decreases max HP
	#define fx$REDUCE_CD 66						// (int)spells, (float)seconds - spells is bitwise combination of (hotkeys) 1=5, 2=1, 4=2...
	#define fx$FOV 67							// (float)fov - Field of view. PC only. Last one in gets used
	
// conditions
	// Built in
	#define fx$COND_HAS_PACKAGE_NAME 1			// [(str)name1, (str)name2...] - Recipient has a package with at least one of these names
	#define fx$COND_HAS_PACKAGE_TAG 2			// [(int)tag1, (int)tag2...] - Recipient has a tackage with a tag with at least one of these
	
	// User defined
	#define fx$COND_SAME_TEAM 0					// [(bool)inverse] - Same team
	#define fx$COND_SELF 13						// void - This spell effect was sent by the caster
	#define fx$COND_HAS_STATUS 3				// [(int)flags, OR(int)flags] - [FLAG_X|FLAG_Y] = has at least one flag. [FLAG_X, FLAG_Y] has BOTH flags
	#define fx$COND_HAS_FXFLAGS 4				// [(int)flags, OR(int)flags] - Same as above. Except for fxflags

	#define fx$COND_HP_GREATER_THAN 5			// [(float)0-1.]
	#define fx$COND_MANA_GREATER_THAN 6			// [(float)0-1.]
	#define fx$COND_PAIN_GREATER_THAN 7			// [(float)0-1.]
	#define fx$COND_AROUSAL_GREATER_THAN 8		// [(float)0-1.]
	
	#define fx$COND_IS_NPC 9					// NULL - Victim is NPC
	#define fx$COND_TARGETING_CASTER 10			// NULL - NPC ONLY, If the victim currently has the sender as their target
	
	// Too much code required for this. Use backstab Boolean B in math for player backstabs, or calculate two different effects on NPCs
	//#define fx$COND_CASTER_IS_BEHIND 11			// NULL - If the caster is behind the victim
	
	#define fx$COND_HAS_GENITALS 12				// (int)bitflags - See _core
	#define fx$COND_TEAM 14						// (int)team1, (int)team2... - Validates if the receiver is on any of these teams. If reverse it validates if the receiver is not on either of the teams
	#define fx$COND_CASTER_ANGLE 15				// Minimum angle from caster fwd. Positive X for player casters, positive Z for NPC casters. Viable values are 0-PI. 1.57 is "in front"
	
// Reserved names:
	#define FXN$INFUSION "_I"					// Bloodlust
	#define FXN$QUICKRAPE "_Q"					// Quickrape
	#define FXN$PULL "_P"						// Used in effects that pull a player towards a location
	
// Tags
	#define fx$TAG_LEGS_SPREAD 1				// Used by skelcrawler
	#define fx$TAG_QUICKRAPE_A 2				// Used by the trap script
	#define fx$TAG_UNAROUSED 3					// Used by anemone
	#define fx$TAG_LIFTED 4						// Lifted in the air by the leg hand
	#define fx$TAG_LUBED 5						// Triggered by trap, can be used by monsters
	#define fx$TAG_NAKED 6
	#define fx$TAG_ACTIVE_MITIGATION 7			// Used by tank active mitigation abilities
	#define fx$TAG_VULNERABLE 8					// Used in pvp events
