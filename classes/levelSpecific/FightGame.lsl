/*
	
	this was never completed because SL ran out of memory
	But maybe one day

*/
#ifndef __FightGame
#define __FightGame

#define PLAYERTYPE_AVATAR 0		// Avatar type
#define PLAYERTYPE_QUADROPUS 1
#define PLAYERTYPE_IMP_IMPALER 2
#define PLAYERTYPE_BLUEGLOB 3

// Character ability 0 (jump)
#define JUMP_TIME 1.0	// In seconds
#define JUMP_HEIGHT 150	// in centimeters
#define JUMP_OVER_HEIGHT 100	// Must be above this to jump over a player, or below to hit
#define HIT_RANGE 150			// Dist to hit
#define OFF_BALANCE_DUR 3
#define SNARE_DUR 6
#define HIT_PUSHBACK 25		// 25cm pushback per hit
#define DASH_DUR 0.4
#define ATK_CD 0.6
#define HIT_TELEGRAPH 0.3		// Time before hit lands after triggering it
#define ULT_PER_SEC 4

#define JAB_DAMAGE 5

#define FX_STUN 0x1				// Stunned
#define FX_ROOT 0x2				// Unable to move until dashing
#define FX_SNARE 0x4			// Unable to dash
#define FX_OFF_BALANCE 0x8		// Unable to block

#define OBJTYPE_PLAYER 0
#define OBJTYPE_PROJECTILE 1
#define OBJTYPE_HITFX 2

#define FXCOLORS (list)\
	<1,.5,.5> + \
	<.5,.5,0> + \
	<.2,.7,.2> + \
	<.5,.75,1>

// Sent from _MAIN to controller to move and to set animations
// syntax [(int)task,(var)arg1...]
integer ARENA_POS_CHAN = 0x175;
#define APCTASK_GOTO 0      // (int)pos - Go to an XY position relative to the left side of the arena. For compression, X and Y are stored as 11bit ints with cm precision. Arenas can be max 20m long.
#define APCTASK_ANIM 1      // (str)anim - (float)duration - 0 duration = OFF, -1 = permanent
#define APCTASK_POS 2       // (vec)pos - Sets an absolute position. 
#define APCTASK_ROT 3		// (int)deg - Sets Z rotation in degrees
#define APCTASK_ARENA 4		// (vec)center, (float)width, (vec)cam. Also stores the ID of the sender as the level.
#define APCTASK_STOP 5		// void - Stops kfm
#define APCTASK_PING 6		// void - Asks you to hookup
#define APCTASK_FX 7		// (int)FX_FLAGS - Updatse FX above your head
#define APCTASK_GETTYPE 8	// void - Asks you to trigger aic$type
#define APCTASK_TOGGLE 9	// void - Used in projectiles to toggle on/off

#define apcTask(targ, task, data) llRegionSayTo(targ, ARENA_POS_CHAN, mkarr((list)task + data))
#define apc$goto(targ, x,z) apcTask(targ, APCTASK_GOTO, (((z)<<11)|(x)))
#define apc$stop(targ) apcTask(targ, APCTASK_STOP, [])
#define apc$anim(targ, anim, dur) apcTask(targ, APCTASK_ANIM, (anim) + (dur))
#define apc$pos(targ, pos) apcTask(targ, APCTASK_POS, pos)
#define apc$rot(targ, deg) apcTask(targ, APCTASK_ROT, deg)
#define apc$arena(targ, center, width, cam) apcTask(targ, APCTASK_ARENA, center + width + cam)
#define apc$arenaAll(center, width, cam) llRegionSay(ARENA_POS_CHAN, mkarr((list)APCTASK_ARENA + center + width + cam))
#define apc$ping() llRegionSay(ARENA_POS_CHAN, "["+(str)APCTASK_PING+"]")
#define apc$fx(targ, fx) apcTask(targ, APCTASK_FX, (fx))
#define apc$getType(targ) apcTask(targ, APCTASK_GETTYPE, [])
#define apc$toggle(targ, on) apcTask(targ, APCTASK_TOGGLE, (int)(on)) 



// Sent from controller to _MAIN
integer ARENA_INPUT_CHAN = 0x176;
#define AICTASK_KEYS 0      // int pressed, int released - Raised when a button is pressed or released
#define AICTASK_HOOKUP 1	// (int)objtype - llRegionSay to hook up a controller to main
#define AICTASK_PTYPE 2		// (int)type - Sets your player type

#define aicTask(targ, task, data) llRegionSayTo(targ, ARENA_INPUT_CHAN, mkarr((list)task + data))

#define aic$hookup(objtype) llRegionSay(ARENA_INPUT_CHAN, mkarr((list)AICTASK_HOOKUP + objtype))
#define aic$keys(targ, pressed, released) aicTask(targ, AICTASK_KEYS, pressed + released)
#define aic$ptype(targ, pType) aicTask(targ, AICTASK_PTYPE, pType)






#endif
