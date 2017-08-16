#define MonsterMethod$toggleFlags 1		// [(int)flags_to_set, (int)flags_to_remove[, (int)is_spellflags]] - set will be ORed, remove will be and NOT ed
#define MonsterMethod$lookOverride 2	// (key)id or "" - Forces the monster to look at this ID instead of aggro target
#define MonsterMethod$KFM 3				// (arr)kfm_a, (arr)kfm_b - Runs a keyframed motion on an npc
#define MonsterMethod$atkspeed 4		// (float)speed
#define MonsterMethod$seek 5			// (var)targ, (float)dist, (str)callback - Tries to walk the monster to a location. Targ can be a key or a global vector. Raises MonsterEvt$seekFail or MonsterEvt$seekComplete with callback
#define MonsterMethod$seekStop 6		// Stops the current seek action


#define Monster$stop() runMethod((string)LINK_THIS, "got Monster", MonsterMethod$toggleFlags, [Monster$RF_IMMOBILE|Monster$RF_PACIFIED, 0], TNN)
#define Monster$start() runMethod((string)LINK_THIS, "got Monster", MonsterMethod$toggleFlags, [0, Monster$RF_IMMOBILE|Monster$RF_PACIFIED], TNN)
#define Monster$setFlags(flags) runMethod((string)LINK_THIS, "got Monster", MonsterMethod$toggleFlags, [flags], TNN)
#define Monster$unsetFlags(flags) runMethod((string)LINK_THIS, "got Monster", MonsterMethod$toggleFlags, [0, flags], TNN)

#define Monster$setSpellFlags(flags) runMethod((string)LINK_THIS, "got Monster", MonsterMethod$toggleFlags, [flags, 0, 1], TNN)
#define Monster$unsetSpellFlags(flags) runMethod((string)LINK_THIS, "got Monster", MonsterMethod$toggleFlags, [0, flags, 1], TNN)

#define Monster$lookOverride(targ) runMethod((string)LINK_THIS, "got Monster", MonsterMethod$lookOverride, [targ], TNN)
#define Monster$atkspeed(speed) runMethod((string)LINK_THIS, "got Monster", MonsterMethod$atkspeed, [atkspeed], TNN)
#define Monster$seek(targ, seekTarg, dist, callback) runMethod((str)targ, "got Monster", MonsterMethod$seek, [seekTarg, dist, callback], TNN)
#define Monster$seekStop(targ) runMethod((str)targ, "got Monster", MonsterMethod$seekStop, [], TNN)


// Settings = [aggrorange, speed]

#define MonsterEvt$inRange 1 			// (key)target
#define MonsterEvt$lostRange 2			// (key)target
#define MonsterEvt$attack 3				// (key)targe - Raised on "_a" frame received
#define MonsterEvt$rapeStart 4			// (key)target
#define MonsterEvt$rapeEnd 5			// (key)target
#define MonsterEvt$players 6			// (arr)players
#define MonsterEvt$runtimeFlagsChanged 7// (int)flags
#define MonsterEvt$attackStart 8		// (key)targ - Raised on attack start regardless of "_a" frame
#define MonsterEvt$seekFail 9			// void - Failed to seek to target
#define MonsterEvt$seekComplete 10		// void - Reached current target
#define MonsterEvt$confIni 11			// void - Configuration has been received, monster is starting up
#define MonsterEvt$state 12				// (int)state - Monster state has changed

// Runtime flags
#define Monster$RF_IMMOBILE 1
#define Monster$RF_PACIFIED 2			// No attacks, but can aggro
#define Monster$RF_NOROT 4
#define Monster$RF_NOAGGRO 8			// No new aggro, but will keep attacking until it's lost all current aggro
#define Monster$RF_FREEZE_AGGRO 0x10	// While this is set got Monster will not lose it's aggro target on itself
#define Monster$RF_NO_DEATH 0x20		// Don't delete on death, let LocalConf handle it
#define Monster$RF_INVUL 0x40			// Invulnerable
#define Monster$RF_NO_TARGET 0x80		// Not targetable 
#define Monster$RF_NO_SPELLS 0x100		// Unable to cast spells
#define Monster$RF_IS_BOSS 0x200		// Shows up in the boss bar
#define Monster$RF_FLYING 0x400			// Travels in a linear fashion to enemy groin height without following the ground
#define Monster$RF_360_VIEW 0x800		// Does not get shorter aggro range when players are behind it
#define Monster$RF_FOLLOWER 0x1000		// Follower mode enabled

#define Monster$atkFrame "_a"


// Monster runtime states
#define MONSTER_STATE_IDLE 0
#define MONSTER_STATE_CHASING 1
#define MONSTER_STATE_SEEKING 2

// Sends a custom command that updates settings
// Unlike LocalConfEvt$iniData this is a strided list consisting of [(int)index, (var)value]
// Str is a JSON array of the params. 
// See the MLC$ index below
#define Monster$updateSettings(settings) llMessageLinked(LINK_ROOT, TASK_MONSTER_SETTINGS, mkarr(settings), "")


// LocalConf INI data:
// [(int)RUNTIME_FLAGS, (float)speed, (float)hitbox, (float)atkspeed, (float)dmg, (float)wander, (int)maxhp, (float)aggro_range, (key)aggrosound, (key)dropaggrosound, (key)takehitsound, (key)attacksound, (key)deathsound, (key)icon]

#define MLC$RF 0
#define MLC$speed 1
#define MLC$hitbox 2
#define MLC$atkspeed 3
#define MLC$dmg 4
#define MLC$wander 5
#define MLC$maxhp 6
#define MLC$aggro_range 7
#define MLC$aggro_sound 8
#define MLC$dropaggro_sound 9
#define MLC$takehit_sound 10
#define MLC$attacksound 11
#define MLC$deathsound 12
#define MLC$icon 13
#define MLC$rapePackage 14			// lets you use a rape from another monster, useful for monsters that share the same visual
#define MLC$drops 15				// [[(str)name, (float)chance]...]
#define MLC$team 16
#define MLC$range_add 17			// (int)decimeters - Range increase in decimeters players players can hit this monster 
#define MLC$height_add 18			// (int)decimeters - Offset the Z center used for LOS calculations

