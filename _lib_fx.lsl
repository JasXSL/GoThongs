// Fxs
/*
	These are ACTIVE effects. When building passives, use got FXCcmpiler.lsl
	
	A note about the values that say multiply_by
	This is an offset from zero. So if you wanted to reduce damage taken by 30%, you would set the value to -0.3
	The values are multiplicative and -0.3 gets converted into a multiplier of 0.7
	This is to make sure that no matter how many damage reduction effects you have, you still won't go under 0 unless the value is less than -1

*/

// * = not implemented yet
// p = effect is passive
	// The flags in the top 2 are the SMAFlags defined in got Status
	// Note: These MUST be positive! And can only range between 0 and 255
	// Comment below each row (if any) is what it compiles to in the compiled effects table
	#define fx$DAMAGE_DURABILITY 1				// [(float)amount_to_rem[, (int)flags, (float)life_steal]] - Life steal is generally "$M$h" For 100% multiplied by healing done multi
	#define fx$AROUSE 2							// [(float)amount_to_add[, (int)flags]]
	#define fx$PAIN 3							// [(float)amount_to_add[, (int)flags]]
	#define fx$MANA 4							// [(float)amount_to_add[, (int)flags]]
	#define fx$TRIGGER_SOUND 5					// [(key)uuid, (float)vol, (bool)self_only] - UUID can also be a JSON array of random sounds
	#define fx$HITFX 6							// [(vec)color, (int)flags]
		#define fxhfFlag$NOANIM 1					// Don't use standard takehit anim
		#define fxhfFlag$NOSOUND 2					// Don't use a default sound
		#define fxhfFlag$PAIN_HEAVY 0x4				// Could be used for RP purposes
		#define fxhfFlag$AROUSAL 0x8				// Could be used for RP purposes
		#define fxhfFlag$AROUSAL_HEAVY 0x10			// 16 Could be used for RP purposes
		#define fxhfFlag$IGNORE_TYPE 0x20			// 32 Prevents RP grunts
		
		// New flags for slot specific
		#define fxhfFlag$SLOT_GROIN 0x40			// 64
		#define fxhfFlag$SLOT_BUTT 0x80				// 128
		#define fxhfFlag$SLOT_BREASTS 0x100			// 256
		#define fxhfFlag$SLOT_STOMACH 0x200			// 512
		
		#define fxhfColor$none "<-1,-1,-1>"
		#define fxhfColor$phys "<1,.5,.5>"
		#define fxhfColor$arouse "<1,.5,1>"
		#define fxhfColor$toxic "<.8,1,.7>"
		#define fxhfColor$holy "<1,1,.7>"
		#define fxhfColor$cold "<.5,.8,1>"
	
	
	#define fx$ANIM 7							// (str)anim(or array), (int)start, (bool)ignore_immediate, (int)flags, (float)duration | If ignore immediate is set, it will not be run on instant effects or ticks.
	#define fx$DODGE 8							// (float)chance_to_add - Adds a chance to dodge bad spells unless undodgable
		#define fxf$DODGE db4$8 				//p (float)chance_to_not_dodge=1
	//#define fx$DEBUG 9							// [(str)message]
	#define fx$REM_BY_NAME 10					// (str)name, (int)raise_event, (bool)only_by_caster
	#define fx$REM_THIS 11						// (int)raise_event - Only works within a tick
	#define fx$THONG_VISUAL 12					// (vec)color, (float)glow, (str)preset, (int)dur - see ThongManMethod$fxVisual
	#define fx$SET_FLAG 13						// (int)flags
		#define fxf$SET_FLAG db4$13				//p (int)flags & ~unset_flags = 0
	#define fx$UNSET_FLAG 14					// (int)flags - Overrides fx$SET_FLAG
		#define fxf$UNSET_FLAG db4$14			// (int)flags
		
		#define fx$F_STUNNED 0x1					// Unable to move or attack
		#define fx$F_PACIFIED 0x2					// Unable to attack but can use friendly spells. For NPC it doesn't affect spells, but only auto attacks
		#define fx$F_INVUL 0x4						// Cannot take damage
		#define fx$F_ROOTED 0x8						// Unable to move but can attack
		#define fx$F_QUICKRAPE 0x10					// 16 Inside of a quickrape - This one is autochecked for in got FX and does not need a condition
		#define fx$F_SILENCED 0x20					// 32 Unable to cast any spells at all
		#define fx$F_BLINDED 0x40					// 64 Makes screen black
		#define fx$F_NOROT 0x80						// 128 Unable to rotate
		#define fx$F_BLURRED 0x100					// 256 Blurry screen
		#define fx$F_NO_TARGET 0x200				// 512 This player can not be targeted by NPCs
		#define fx$F_NO_PULL 0x400					// 1024 Blocks fx$PULL (37)
		#define fx$F_NO_DEATH 0x800					// 2048 PC - Prevents the player from going below 0 HP and instead raises StatusEvt$death_hit
		#define fx$F_CAST_WHILE_MOVING 0x1000		// 4096 PC - Allows you to cast while moving
		#define fx$F_SHOW_GENITALS 0x2000			// 8192 PC - Renders the character naked
		#define fx$F_DISARM 0x4000					// PC - Disables weapon graphic
		#define fx$F_NO_INTERRUPT 0x8000			// 32768 - PC - Blocks interrupts
		#define fx$F_ALWAYS_BEHIND 0x10000			// PC - All attacks made from this character are treated as from behind
		#define fx$F_NO_PROCS 0x20000					// PC - Disables procs
		#define fx$F_STUNNED_IMPORTANT 0x40000		// NPC - Effect stuns bosses as well
		#define fx$F_FORCE_MOUSELOOK 0x80000		// PC - Makes only mouselook work
		#define fx$F_SPELLS_MAX_RANGE 0x100000		// PC - Makes all spells cast as if they were done from max range (10m)
		#define fx$F_IMPORTANT_DISPEL 0x200000		// 2097152 Highlight player to mark an important dispel
		#define fx$F_NO_NUDE_PENALTY 0x400000		// 4194304 PC - Ignores nudity penalty
		#define fx$F_NO_CLASS_ATTACH 0x8000000		// 134217728 - See fx$ATTACH - Detaches related ones when set
		
		// Should coincide with above
		#define fx$FLAG_DESCS (list)\
			"Stunned" + \
			"Pacified" + \
			"Invulnerable" + \
			"Rooted" + \
			"In Scene" + \
			"Silenced" + \
			"Blinded" + \
			"No Rotation" + \
			"Blurred" + \
			"Nontargetable" + \
			"Non-pullable" + \
			"No death" + \
			"Cast while moving" + \
			"Naked" + \
			"Disarmed" + \
			"Noninterruptable" + \
			"Always backstab" + \
			"No procs" + \
			"Important stun" + \
			"Forced mouselook" + \
			"Casting at max range" + \
			"Has important dispellable effect" + \
			"No nude penalty" + \
			"No class attach"
			

		#define fx$NOCAST (fx$F_STUNNED|fx$F_QUICKRAPE|fx$F_SILENCED)
		#define fx$UNVIABLE (fx$F_QUICKRAPE|fx$F_NO_TARGET)
		
	#define fx$MANA_REGEN_MULTI 15				// (float)add
		#define fxf$MANA_REGEN_MULTI db4$15		//p (float)multi=1
	#define fx$DAMAGE_TAKEN_MULTI 16			// (float)add, (bool)by_caster
		#define fxf$DAMAGE_TAKEN_MULTI db4$16	//p [0,(float)global,key2int(uuid),(float)uuid_multi...]=[0,1]
	#define fx$DAMAGE_DONE_MULTI 17				// (float)add, (bool)to_caster - Also affects healing done
		#define fxf$DAMAGE_DONE_MULTI db4$17	//p [0,(float)global,key2int(uuid),(float)uuid_multi...]=[0,1] - note: In these functions, 0 always MUST be first
	#define fx$CASTTIME_MULTI 18				// (float)add
		#define fxf$CASTTIME_MULTI db4$18		//p (float)multi=1
	#define fx$SPELL_DMG_TAKEN_MOD 19			// (str)spellName, (float)add, (bool)by_caster - PC only SpellName is the FX package name :: Increases efficiency of dur/man/ars/pain sections of a spell, useful for heals too
		#define fxf$SPELL_DMG_TAKEN_MOD db4$19	//p [key2int(caster) or 0=global+"_"+(str)spellname, (float)multi]=[]
	#define fx$ICON 20							// (key)icon, (str)description - Description can use a macro <|s3|> for a value multiplied by stacks. In this case s3 = stacks*3
	#define fx$INTERRUPT 21						// (bool)force - Force will override fx$F_NO_INTERRUPT
	#define fx$SPELL_DMG_DONE_MOD 22			// (int)index, (float)add - Index is the index of the spell, 0 is rest and then 1-4 for the others, 5 for weapon :: Increases efficiency of spells cast by you with this name
		#define fxf$SPELL_DMG_DONE_MOD db4$22	//p [abil5multi,abil0multi...]=[1,1,1,1,1,1]
	#define fx$FULLREGEN 23						// NULL - Fully restores a player
	#define fx$DISPEL 24						// (int)detrimental, (int)nr
	#define fx$COOLDOWN_MULTI 25				// (float)add - Also increases time between attacks in NPCs
		#define fxf$COOLDOWN_MULTI db4$25		//p (float)multi=1
	#define fx$MANA_COST_MULTI 26				// (float)add  - PC only
		#define fxf$MANA_COST_MULTI db4$26		//p (float)multi=1
	#define fx$HUD_TEXT 27						// (str)text, (bool)output_into_chat, (bool)play_sound
	#define fx$AGGRO 28							// (float)amt - NPC only
	#define fx$RESET_COOLDOWNS 29				// (int)flags, 0x1 = rest, 0x2 = abil1 etc, charges=1 - PC only. Adds charges to a spell.
	#define fx$RAND 30							// (float)chance, (bool)multiply_by_stacks, (arr)fxobj1, (arr)fxobj2... - Pseudo effect. If llFrand(1)<=chance, then the trailing fxobjs are run (fxobj is (int)fx, (var)data1.... Only works for instant effects. Multiply_by_stacks will make it so if you have a chance of .2, and 3 stacks, that's a chance of 0.6
	#define fx$FORCE_SIT 31						// (key)object, (int)flags
		#define fx$FORCE_SIT$ALLOW_UNSIT 0x1		// allow_unsit
		#define fx$FORCE_SIT$NO_AUTO_UNSIT 0x2		// Do not auto unsit when the effect ends
		
	#define fx$CRIT_ADD 32						// (float)amt - Increases chance of doing double damage
		#define fxf$CRIT_ADD db4$32				//p (float)multi=1 - Spell script needs to subtract 1 from this
	#define fx$ROT_TOWARDS 33					// (vec)pos - PC ONLY, Rotates the player towards a global position
	#define fx$PARTICLES 34						// (float)duration, (int)prim, (arr)particles - PC_ONLY - See ThongMan$particles
	#define fx$TAUNT 35							// (bool)inverse - NPC ONLY, resets everyone but this player's aggro. If inverse is set, reset this player's aggro only
	#define fx$REM 36							// Accepts the same arguments as FX$rem at got FX.lsl
	#define fx$PULL 37							// (vec)pos, (float)speed, (bool)awayFromSender - PC only. (Use PF_TRIGGER_IMMEDIATE) Instant effect but is cleared on effect fade for duration effects. If awayFromSender is TRUE it multiplies the vector by the sender Z rotation and adds your current position
	#define fx$SPAWN_VFX 38						// (str)name, (vec)posOffset, (rot)rotoffset, (int)flags, (int)startParam, (str)customData(PC_ONLY) - Spawns a visual effect from the SpellFX container on the HUD. Flags are defined in got SpellFX.lsl customData can be requested by regionsaying 
	#define fx$REGION_SAY 39					// (int)chan, (str)message, (int)flags - Does what it says on the box
		#define fx$RSFlag$to_owner 0x1				// RegionSayTo to owner
		// You can use the following consts
		#define fx$RSConst$stacks "%S%"				// Is replaced with stacks
		
	#define fx$AROUSAL_MULTI 40					// (float)add - PC only, Increases or decreases arousal generation
		#define fxf$AROUSAL_MULTI db4$40		//p (float)multi=1
	#define fx$PAIN_MULTI 41					// (float)add - PC only, Increases or decreases pain generation
		#define fxf$PAIN_MULTI db4$41			//p (float)multi=1
	#define fx$ALERT 42							// (str)text, (bool)ownersay, (bool)sound - PC only, standard alert
	#define fx$ATTACH 43						// attachment1, attachment2... - Attachment names must NOT be a number. The last entry can be used to set flags. MUST be treated as INT when passed through llJson2List
		#define fx$ATTACH_CLASSATT 0x1				// This is treated as class attachments. Any attachments added through _ENCH_ (name of passive passed from the website through thongs/weapons/enchants) are automatically treated as this for backwards compatibility.
	#define fx$MOVE_SPEED 44					// (float)add - NPC: Multiplies against normal move speed. PC: Sprint regen multiplier. Lower is slower.
		#define fxf$MOVE_SPEED db4$44			//p (float)multi=1
	#define fx$SPELL_MANACOST_MULTI 45			// (int)index, (float)multiply - PC only.
		#define fxf$SPELL_MANACOST_MULTI db4$45	//p [spell5,spell0,spell1...]=[1,1,1,1,1,1]
	#define fx$SPELL_CASTTIME_MULTI 46			// (int)index, (float)multiply - PC only.
		#define fxf$SPELL_CASTTIME_MULTI db4$46	//p [spell5,spell0,spell1...]=[1,1,1,1,1,1]
	#define fx$SPELL_COOLDOWN_MULTI 47			// (int)index, (float)multiply - PC only.
		#define fxf$SPELL_COOLDOWN_MULTI db4$47	//p [spell5,spell0,spell1...]=[1,1,1,1,1,1]
	#define fx$ADD_FX 48						// (arr)wrapper[, (int)targ_flags, (float)range] - Adds a wrapper as a self cast or if flags are set, uses those for targets. Instant only,
		#define FXAF$SELF 0x1						// Apply FX on victim
		#define FXAF$CASTER 0x2						// Apply FX on caster
		#define FXAF$AOE 0x4						// Apply FX on AOE
		#define FXAF$SMART_HEAL 0x8					// Targets the lowest HP party member. Only use this for PC because using this on an NPC will also target the party
	#define fx$ADD_STACKS 49					// (int)stacks, (str)name... - See FXMethod$addStacks -  Adds (resets timer) or removes stacks (does not affect timer)
	#define fx$SPELL_HIGHLIGHT 50				// (int)index, (int)min_stacks - PC Only - Draws a yellow border around a spell. 0 is the bottom ability, then 1-4 for the upper row. If min_stacks is set, then you need a minimum of that amount of stacks for it to proc
		#define fxf$SPELL_HIGHLIGHT db4$50		//p (int)bitwise_combo=0
	#define fx$HEALING_TAKEN_MULTI 51			// (float)add, (bool)by_caster - Increases or decreases healing received
		#define fxf$HEALING_TAKEN_MULTI db4$51	//p [0,(float)global,key2int(uuid),(float)uuid_multi...]=[0,1]
	#define fx$HEALING_DONE_MULTI 52			// (float)add - Increases or decreases healing done
		#define fxf$HEALING_DONE_MULTI db4$52	//p (float)multi=1
	#define fx$SPAWN_MONSTER 53					// (str)name, (vec)foot_offset, (rot)rot_offset, (str)desc, (bool)from_sender - Spawns a monster from HUD
	#define fx$SET_TEAM 54						// (int)team - (PC ONLY for now)
		#define fxf$SET_TEAM db4$54				//p (int)team=1 - The first one is used if multiple ones are applied.
	#define fx$CUBETASKS 55						// (arr)tasks - PC ONLY Sends cubetasks to the owner
	#define fx$BEFUDDLE 56						// (float)perc - PC ONLY - Adds a chance on spell cast to target a random player
		#define fxf$BEFUDDLE db4$56				//p (float)perc=1 - The spell script will need to subtract 1 from this
	#define fx$CONVERSION 57					// (int)conversion1, (int)conversion2... - PC ONLY - See got FXCompiler.lsl
		#define fxf$CONVERSION db4$57			//p [(int)conversion1,(int)conversion2...]=[]
	#define fx$LTB 58							// (str)asset, (arr)conf - PC Only - Spawns a long term buff visual which sticks around on the affected player until the spell is removed. For conf, see got BuffSpawn. It's a strided list.
	#define fx$REFRESH_SPRINT 59				// (float)amount - PC Only - Instant only. 0 refreshes sprint entirely, higher/lower adds or subtracts a percentage
	#define fx$HP_ADD 60						// (int)amount - PC only - Increases max HP by amount nr of points.
		#define fxf$HP_ADD db4$60				//p (int)amount=0
	#define fx$GRAVITY 61						// (float)n=1.0 - PC only - 
		#define fxf$GRAVITY db4$61				//p (float)buoyancy=0.0 - Additive. Higher = more boyant.
	#define fx$PUSH 62							// (vec)dir - PC only - Applies an impulse
	#define fx$CLASS_VIS 63						// (var)data[, (float)timeout=1] - PC only. Sends class vis data to got ClassAtt. Start is sent on add/instant and end is sent on fade with -1
	#define fx$MANA_MULTI 64					// (float)amount - PC only, increases or decreases max mana
		#define fxf$MANA_MULTI db4$64			//p (float)amount=1
	#define fx$HP_MULTI 65						// (float)amount - Increases or decreases max HP
		#define fxf$HP_MULTI db4$65			//p (float)amount=1
	#define fx$REDUCE_CD 66						// (int)spells, (float)seconds - Instant effect. spells is bitwise combination of (hotkeys) 1=5, 2=1, 4=2...
	#define fx$FOV 67							// (float)fov - Field of view. PC only. Only one is picked.
		#define fxf$FOV db4$67					//p (float)fov=0
	#define fx$PROC_BEN 68						// (float)multiplier - Affects chances of procs from passives and nondetrimental effects. Target script must subtract 1.
		#define fxf$PROC_BEN db4$68				//p (float)multiplier=1
	#define fx$PROC_DET 69						// (float)multiplier - Affects chances of detrimental effects. Target script must subtract 1.
		#define fxf$PROC_DET db4$69				//p (float)multiplier=1
	#define fx$STANCE 70						// (str)anim/(obj)override - Overrides the stance and/or AO. PC only. Non instant only. If an object it should be like: {ao_type:ao_anim}
	#define fx$LOOK_AT 71						// (vec)pos/(float)rotation/"SENDER" - PC only. Turns the avatar towards a position
	#define fx$DAMAGE_ARMOR 72					// (int)points - PC only. 50 per slot. Can be negative to restore
	#define fx$MAX_PAIN_MULTI 73				// (float)amount - Adds or lowers max pain/arousal
		#define fxf$MAX_PAIN_MULTI db4$73		//p (float)amount=1
	#define fx$MAX_AROUSAL_MULTI 74				// (float)amount - Adds or lowers max pain/arousal
		#define fxf$MAX_AROUSAL_MULTI db4$74	//p (float)amount=1
	#define fx$HP_ARMOR_DMG_MULTI 75			// (float)amount - Adds or lowers armor damage taken from HP damage
		#define fxf$HP_ARMOR_DMG_MULTI db4$75	//p (float)amount=1
	#define fx$ARMOR_DMG_MULTI 76				// (float)amount - Adds or lowers armor damage taken
		#define fxf$ARMOR_DMG_MULTI db4$76		//p (float)amount=1
	#define fx$QTE_MOD 77						// (float)amount - Increases or decreases nr of clicks needed in quicktime events
		#define fxf$QTE_MOD db4$77				//p (float)amount=1
	#define fx$COMBAT_HP_REGEN 78				// (float)amount - Allow HP regen to continue in combat, multiplied by amount
		#define fxf$COMBAT_HP_REGEN db4$78		//p (float)amount=1 (Subtract 1 in got Status)
	#define fx$MAX_AROUSAL_ADD 79				// (int)amount - Adds or subtracts max arousal by points
		#define fxf$MAX_AROUSAL_ADD db4$79 		//p (int)amount=0
	#define fx$MAX_PAIN_ADD 80					// (int)amount - Adds or subtracts max pain by points
		#define fxf$MAX_PAIN_ADD db4$80			//p (int)amount=0
	#define fx$MANA_ADD 81						// (int)amount - Adds or subtracts max mana by points
		#define fxf$MANA_ADD db4$81				//p (int)amount=0
	#define fx$HP_REGEN_MULTI 82				// (float)multi - Changes how fast you regenerate out of combat
		#define fxf$HP_REGEN_MULTI db4$82		//p (float)multi=1
	#define fx$PAIN_REGEN_MULTI 83				// (float)multi - Adjusts how fast pain fades
		#define fxf$PAIN_REGEN_MULTI db4$83		//p (float)multi=1
	#define fx$AROUSAL_REGEN_MULTI 84			// (float)multi - Adjusts how fast arousal fades
		#define fxf$AROUSAL_REGEN_MULTI db4$84	//p (float)multi=1
	#define fx$SPRINT_FADE_MULTI 85				// (float)multi - Adjust how fast your sprint fades. Negative value gives longer sprint.
		#define fxf$SPRINT_FADE_MULTI db4$85	//p (float)multi=1
	#define fx$BACKSTAB_MULTI 86				// (float)multi - Multiplies backstab
		#define fxf$BACKSTAB_MULTI db4$86		//p (float)multi=1
	#define fx$SWIM_SPEED_MULTI 87				// (float)multi - Affects swim speed. Greater is faster.
		#define fxf$SWIM_SPEED_MULTI db4$87		//p (float)multi=1
	/* Removed because of security issue
	#define fx$RUN_METHOD 88					// (int)target, (str)script, (int)method, (arr)args, (str)cb - Runs a method.
		#define FXRMTarg$linkset 0x1				// Runs on victim HUD
		#define FXRMTarg$owner 0x2					// Runs on victim owner
	*/
	#define fx$REDIR_SPEECH 89					// (int)channel - Redirects speech to a channel. Use the constants below to automatically speak as avatar. Only one is active at a time.
		#define fx$REDIR_SPEECH$CH$MUFFLE 9132		// When using this channel you will make muffled sound effects
		#define fxf$REDIR_SPEECH db4$89			//p (int)channel=0
	#define fx$DAMAGE_TAKEN_FRONT 90			// (float)add
		#define fxf$DAMAGE_TAKEN_FRONT db4$90	//p (float)multi=1
	#define fx$DAMAGE_TAKEN_BEHIND 91			// (float)add
		#define fxf$DAMAGE_TAKEN_BEHIND db4$91	//p (float)multi=1	
	#define fx$FALL_DMG_HEIGHT 92				// (float)add - Raises or lowers fall height before tripping by a percentage.
		#define fxf$FALL_DMG_HEIGHT db4$92		//p (float)multi=1
	
// Note: In strided ones (ex [0,1.0]) the second value MUST be seen as a float or searching will screw up.
#define fx$NO_PASSIVE -0x80000000	// Marks the index as not having a passive
#define fx$DEFAULTS (list)	\
	fx$NO_PASSIVE + /* 0 (reserved) */ \
	fx$NO_PASSIVE + /* 1 */ \
	fx$NO_PASSIVE + /* 2 */ \
	fx$NO_PASSIVE + /* 3 */ \
	fx$NO_PASSIVE + /* 4 */ \
	fx$NO_PASSIVE + /* 5 */ \
	fx$NO_PASSIVE + /* 6 */ \
	fx$NO_PASSIVE + /* 7 */ \
	1.0 + /* 8 chance NOT to dodge */ \
	fx$NO_PASSIVE + /* 9 */ \
	fx$NO_PASSIVE + /* 10 */ \
	fx$NO_PASSIVE + /* 11 */ \
	fx$NO_PASSIVE + /* 12 */ \
	0 + /* 13 flags */ \
	0 + /* 14 unset flags */ \
	1.0 + /* 15 MANA_REGEN_MULTI */ \
	"[0,1.0]" + /* 16 DAMAGE_TAKEN_MULTI */ \
	"[0,1.0]" + /* 17 DAMAGE_DONE_MULTI */ \
	1.0 + /* 18 CASTTIME_MULTI */ \
	"[]" + /* 19 SPELL_DMG_TAKEN_MOD */ \
	fx$NO_PASSIVE + /* 20 */ \
	fx$NO_PASSIVE + /* 21 */ \
	"[1,1,1,1,1,1]" + /* 22 SPELL_DMG_DONE_MOD */ \
	fx$NO_PASSIVE + /* 23 */ \
	fx$NO_PASSIVE + /* 24 */ \
	1.0 + /* 25 COOLDOWN_MULTI */ \
	1.0 + /* 26 MANA_COST_MULTI */ \
	fx$NO_PASSIVE + /* 27 */ \
	fx$NO_PASSIVE + /* 28 */ \
	fx$NO_PASSIVE + /* 29 */ \
	fx$NO_PASSIVE + /* 30 */ \
	fx$NO_PASSIVE + /* 31 */ \
	1.0 + /* 32 CRIT_ADD */ \
	fx$NO_PASSIVE + /* 33 */ \
	fx$NO_PASSIVE + /* 34 */ \
	fx$NO_PASSIVE + /* 35 */ \
	fx$NO_PASSIVE + /* 36 */ \
	fx$NO_PASSIVE + /* 37 */ \
	fx$NO_PASSIVE + /* 38 */ \
	fx$NO_PASSIVE + /* 39 */ \
	1.0 + /* 40 AROUSAL_MULTI */ \
	1.0 + /* 41 PAIN_MULTI */ \
	fx$NO_PASSIVE + /* 42 */ \
	fx$NO_PASSIVE + /* 43 */ \
	1.0 + /* 44 MOVE_SPEED */ \
	"[1,1,1,1,1,1]" + /* 45 SPELL_MANACOST_MULTI */ \
	"[1,1,1,1,1,1]" + /* 46 SPELL_CASTTIME_MULTI */ \
	"[1,1,1,1,1,1]" + /* 47 SPELL_COOLDOWN_MULTI */ \
	fx$NO_PASSIVE + /* 48 */ \
	fx$NO_PASSIVE + /* 49 */ \
	0 + /* 50 SPELL_HIGHLIGHT */ \
	"[0,1.0]" + /* 51 HEALING_TAKEN_MULTI */ \
	1.0 + /* 52 HEALING_DONE_MULTI */ \
	fx$NO_PASSIVE + /* 52 */ \
	-1 + /* 54 SET_TEAM. -1 means use default */ \
	fx$NO_PASSIVE + /* 55 */ \
	1.0 + /* 56 BEFUDDLE */ \
	"[]" + /* 57 CONVERSION */ \
	fx$NO_PASSIVE + /* 58 */ \
	fx$NO_PASSIVE + /* 59 */ \
	0 + /* 60 HP_ADD */ \
	0 + /* 61 GRAVITY */ \
	fx$NO_PASSIVE + /* 62 */ \
	fx$NO_PASSIVE + /* 63 */ \
	1.0 + /* 64 MANA_MULTI */ \
	1.0 + /* 65 HP_MULTI */ \
	fx$NO_PASSIVE + /* 66 */ \
	0 + /* 67 FOV */ \
	1.0 + /* 68 PROC_BEN */ \
	1.0 + /* 69 PROC_DET */ \
	fx$NO_PASSIVE + /* 70 */ \
	fx$NO_PASSIVE + /* 71 */ \
	fx$NO_PASSIVE + /* 72 */ \
	1.0 + /* 73 MAX_PAIN_MULTI */ \
	1.0 + /* 74 MAX_AROUSAL_MULTI */ \
	1.0 + /* 75 HP_ARMOR_DMG_MULTI */ \
	1.0 + /* 76 ARMOR_DMG_MULTI */ \
	1.0 + /* 77 QTE_MOD */ \
	1.0 + /* 78 COMBAT_HP_REGEN */ \
	0 + /* 79 MAX_AROUSAL_ADD */ \
	0 + /* 80 MAX_PAIN_ADD */ \
	0 + /* 81 MANA_ADD */ \
	1.0 + /* 82 HP_REGEN_MULTI */ \
	1.0 + /* 83 PAIN_REGEN_MULTI */ \
	1.0 + /* 84 AROUSAL_REGEN_MULTI */ \
	1.0 + /* 85 SPRINT_FADE_MULTI */ \
	1.0 + /* 86 BACKSTAB_MULTI */ \
	1.0 + /* 87 SWIM_SPEED_MULTI */ \
	fx$NO_PASSIVE + /* 88 REMOVED*/ \
	0 + /* 89 REDIR CHAT */ \
	1.0 + /* 90 DAMAGE TAKEN FRONT */ \
	1.0 + /* 91 DAMAGE TAKEN BEHIND */ \
	1.0 /* 92 FALL DAMAGE HEIGHT */
												
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
	#define fx$COND_CASTER_RANGE 16				// (float)range - Caster range must be less or equal than range
	#define fx$COND_NAME 17						// (str)name - Recipient has name
	#define fx$COND_SAME_OWNER 18				// void - Recipient has the same owner as the sender
	#define fx$COND_RANDOM 19					// (float)chance between 0 and 1
	//#define fx$COND_STATUS_FLAGS 20				// (int)flags - Has all of these flags
	//#define fx$COND_FX_FLAGS 21					// (int)flags - Has all of these fx flags
	
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
	