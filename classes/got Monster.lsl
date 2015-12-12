#define MonsterMethod$toggleFlags 1		// [(int)flags_to_set, (int)flags_to_remove] - set will be ORed, remove will be and NOT ed
#define MonsterMethod$lookOverride 2	// (key)id or "" - Forces the monster to look at this ID instead of aggro target
#define MonsterMethod$KFM 3				// (arr)kfm_a, (arr)kfm_b - Runs a keyframed motion on an npc

#define Monster$stop() runMethod((string)LINK_THIS, "got Monster", MonsterMethod$toggleFlags, [Monster$RF_IMMOBILE|Monster$RF_PACIFIED, 0], TNN)
#define Monster$start() runMethod((string)LINK_THIS, "got Monster", MonsterMethod$toggleFlags, [0, Monster$RF_IMMOBILE|Monster$RF_PACIFIED], TNN)
#define Monster$setFlags(flags) runMethod((string)LINK_THIS, "got Monster", MonsterMethod$toggleFlags, [flags], TNN)
#define Monster$unsetFlags(flags) runMethod((string)LINK_THIS, "got Monster", MonsterMethod$toggleFlags, [0, flags], TNN)
#define Monster$lookOverride(targ) runMethod((string)LINK_THIS, "got Monster", MonsterMethod$lookOverride, [targ], TNN)


// Settings = [aggrorange, speed]

#define MonsterEvt$inRange 1 			// (key)target
#define MonsterEvt$lostRange 2			// (key)target
#define MonsterEvt$attack 3				// (key)targe - Raised on "_a" frame received
#define MonsterEvt$rapeStart 4			// (key)target
#define MonsterEvt$rapeEnd 5			// (key)target
#define MonsterEvt$players 6			// (arr)players
#define MonsterEvt$runtimeFlagsChanged 7// (int)flags
#define MonsterEvt$attackStart 8		// (key)targ - Raised on attack start regardless of "_a" frame


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


#define Monster$atkFrame "_a"

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


