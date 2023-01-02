/*
	This one is specific to _Game and holds defines
*/


// Fighter stats array
#define FS_BUTTONS 0            // (int)buttons_held
#define FS_POS 1                // 11 bit of 00000000000posZ 00000000000posX from bottom left of arena
#define FS_FLAGS 2              // FF flags
#define FS_ABIL0 3              // llGetTime of last abil 0 use
#define FS_ABIL1 4              // llGetTime of last abil 1 use
#define FS_STUN 5               // llGetTime when stun expires

#define FS_ULT 7                // int between 0 and 100
#define FS_HP 8                 // int between 0 and 100
#define FS_PTYPE 9              // int playertype
#define FS_DASH 10              // llGetTime of when dash expires
#define FS_ATTACK 11            // llGetTime of when you can use an attack again
#define FS_HIT_SCH 12           // llGetTime of when your last used hit should land
#define FS_HIT_TYPE 13          // HF_* ID detailing what ability should hit
#define FS_OFF_BALANCE 14       // llGetTime of when off balance should fade. lasts 3 sec. Cannot block.
#define FS_SNARE 15             // llGetTime of when snare should fade. Prevents dashing for 6 seconds.
#define FS_ATTACK_SPEED 16		// Time before attack lands

#define FS_STRIDE 17
#define FS_DEFAULT (list) \
    0 + /* Buttons held */ \
    0 + /* Position */\
    0 + /* Flags */ \
    0 + /* Abil0 */ \
    0 + /* Abil1 */ \
    0 + /* Stun */ \
    0 + /* UNUSED */ \
    100 + /* Ult */ \
    100 + /* HP */ \
    PLAYERTYPE_AVATAR + /* See FightGame.lsl */ \
    0 + /* Dash */ \
    0 + /* Last attack */ \
    0 + /* Schedules a hit for this time */ \
    0 + /* Type of ability. 0 = jab, 1 = abil0, 2= abil1, 3 = abil2 */ \
    0 + /* Off balance ms */ \
    0 + /* Snare MS */ \
	0 /* Float attack speed */ \

#define fs$buildPos(x, z) (((z)<<11)|(x)) 
#define fs$splitPos(nr, xVar, zVar) int xVar = (nr&0x7FF); int zVar = (nr>>11)

// Macros for setting and getting from the player array
#define fs$getInt(idx, offs) l2i(FIGHTER_STATS, idx*FS_STRIDE+offs)
#define fs$getFloat(idx, offs) l2f(FIGHTER_STATS, idx*FS_STRIDE+offs)

#define fs$getButtons(idx) fs$getInt(idx, FS_BUTTONS) 
#define fs$getPos(idx) fs$getInt(idx, FS_POS) 
#define fs$getFlags(idx) fs$getInt(idx, FS_FLAGS) 
#define fs$getAbil0(idx) fs$getFloat(idx, FS_ABIL0)
#define fs$getAbil1(idx) fs$getFloat(idx, FS_ABIL1)
#define fs$getStun(idx) fs$getFloat(idx, FS_STUN)
#define fs$getUlt(idx) fs$getInt(idx, FS_ULT)
#define fs$getHP(idx) fs$getInt(idx, FS_HP)
#define fs$getPtype(idx) fs$getInt(idx, FS_PTYPE)
#define fs$getDash(idx) fs$getFloat(idx, FS_DASH)
#define fs$getAttack(idx) fs$getFloat(idx, FS_ATTACK)
#define fs$getHitSch(idx) fs$getFloat(idx, FS_HIT_SCH)
#define fs$getHitType(idx) fs$getInt(idx, FS_HIT_TYPE)
#define fs$getOffBalance(idx) fs$getFloat(idx, FS_OFF_BALANCE)
#define fs$getSnare(idx) fs$getFloat(idx, FS_SNARE)
#define fs$getAttackSpeed(idx) fs$getFloat(idx, FS_ATTACK_SPEED)

#define fs$set(idx, offs, val) FIGHTER_STATS = llListReplaceList(FIGHTER_STATS, (list)(val), idx*FS_STRIDE+offs, idx*FS_STRIDE+offs)

#define fs$setButtons(idx, val) fs$set(idx, FS_BUTTONS, val)
#define fs$setPos(idx, val) fs$set(idx, FS_POS, val)
#define fs$setFlags(idx, val) fs$set(idx, FS_FLAGS, val)
#define fs$setAbil0(idx, startTime) fs$set(idx, FS_ABIL0, startTime)
#define fs$setAbil1(idx, startTime) fs$set(idx, FS_ABIL1, startTime)
#define fs$setStun(idx, expiryTime) fs$set(idx, FS_STUN, expiryTime)
#define fs$setUlt(idx, val) fs$set(idx, FS_ULT, val)
#define fs$setHP(idx, val) fs$set(idx, FS_HP, val)
#define fs$setPtype(idx, type) fs$set(idx, FS_PTYPE, type)
#define fs$setDash(idx, startTime) fs$set(idx, FS_DASH, startTime)
#define fs$setAttack(idx, startTime) fs$set(idx, FS_ATTACK, startTime)
#define fs$setHitSch(idx, startTime) fs$set(idx, FS_HIT_SCH, startTime)
#define fs$setHitType(idx, type) fs$set(idx, FS_HIT_TYPE, type)
#define fs$setOffBalance(idx, startTime) fs$set(idx, FS_OFF_BALANCE, startTime)
#define fs$setSnare(idx, startTime) fs$set(idx, FS_SNARE, startTime)
#define fs$setAttackSpeed(idx, time) fs$set(idx, FS_ATTACK_SPEED, time)


#define HT_JAB 0
#define HT_ABIL0 1
#define HT_ABIL1 2
#define HT_ULT 3

// Projectiles
#define PJ_UUID 0			// UUID of projectile
#define PJ_POS 1			// Pos, or -1 if not launched
#define PJ_CASTER 2			// Index of caster player
#define PJ_ABIL 3			// Ability used to spawn projectile
#define PJ_DIR 4			// 16 bits up, 16 bits right minus 32768 in centimeters per second
#define PJ_SIZE 5			// 16 bits Z, 16 bits X
#define PJ_FLAGS 6			// 
	#define PF_TRIGGERED 0x1	// Triggered, do not trigger again

#define PJ_STRIDE 7

#define PJ_DEFAULT_MINUS_UUID \
	(list)-1 + 0 + 0 + 0 + 0 + 0

#define pj$getKey(idx, offs) l2k(PROJECTILES, idx*PJ_STRIDE+offs)
#define pj$getInt(idx, offs) l2i(PROJECTILES, idx*PJ_STRIDE+offs)

#define pj$buildDir(x,z) ((x+32768)|((z+32768)<<16))
#define pj$splitDir(dir, xVar, zVar) int xVar = ((dir&0xFFFF)-32768); int zVar = (((dir>>16)&0xFFFF)-32768)

#define pj$getUUID(idx) pj$getKey(idx, PJ_UUID)
#define pj$getPos(idx) pj$getInt(idx, PJ_POS)
#define pj$getCaster(idx) pj$getInt(idx, PJ_CASTER)
#define pj$getAbil(idx) pj$getInt(idx, PJ_ABIL)
#define pj$getDir(idx) pj$getInt(idx, PJ_DIR)
#define pj$getSize(idx) pj$getInt(idx, PJ_SIZE)
#define pj$getFlags(idx) pj$getInt(idx, PJ_FLAGS)





// Fighter config (based on fighter type)
#define FC_CD_0 0               // Ability 0 cooldown
#define FC_CD_1 1               // Ability 1 cooldown
#define FC_MAXHP 2              // Max HP
// Free slot
#define FC_DASH 4               // Dash cooldown
#define FC_RANGE_0 5			// int centimeters
#define FC_RANGE_1 6
#define FC_RANGE_ULT 7          // Int centimeter units
#define FC_ 8

#define FC_DEFAULT \
    (list)2.0 + 10 + 100 + 0 + 3 + 0 + HIT_RANGE + (HIT_RANGE*1.5)
#define FC_QUADROPUS \
    (list)2.0 + 6 + 100 + 0 + 3 + 0 + 0 + (HIT_RANGE*1.5)


#define FC_STRIDE 8


#define fc$getFloat(idx, offs) l2f(FIGHTER_CONF, idx*FC_STRIDE+offs)
#define fc$getInt(idx, offs) l2i(FIGHTER_CONF, idx*FC_STRIDE+offs)

#define fc$getCd0(idx) fc$getFloat(idx, FC_CD_0)
#define fc$getCd1(idx) fc$getFloat(idx, FC_CD_1)
#define fc$getRange0(idx) fc$getInt(idx, FC_RANGE_0)
#define fc$getRange1(idx) fc$getInt(idx, FC_RANGE_1)
#define fc$getRangeUlt(idx) fc$getInt(idx, FC_RANGE_ULT)

#define fc$getMaxHP(idx) fc$getInt(idx, FC_MAXHP)
#define fc$getDash(idx) fc$getFloat(idx, FC_DASH)






// Hit function flags
#define HF_UNBLOCKABLE 0x1
#define HF_NO_ULT_DMG 0x2		// Do 20 down to 50
#define HF_ULT_10 0x4           // Does exactly 10 ult damage
#define HF_NO_PUSHBACK 0x8
#define HF_NO_ATTACKER_PUSHBACK 0x10    // 








// Flags
#define FF_MOVING 0x1       // We are moving
#define FF_WALKING 0x2      // We are walking
#define FF_RIGHT 0x4        // We are turned right
#define FF_BLOCKING 0x8     // We are blocking
#define FF_JUMPING 0x10
//#define FF_DASHING 0x20
#define FF_JAB 0x40         // Handles the two jab animations
#define FF_ROOTED 0x80      // Unable to move until you dash
#define FF_PUSHBACK 0x100   // push back next frame
#define FF_PUSHBACK_RIGHT 0x200 // Next pushback is to the right





// Tools:
#define isAttacking(idx) (fs$getAttack(idx) > 0)
#define isDashing(idx) (llGetTime()-fs$getDash(idx) <= DASH_DUR)
#define isJumping(idx) (fs$getFlags(idx)&FF_JUMPING)

#define isStunned(idx) (fs$getStun(idx) > 0)
#define isSnared(idx) (fs$getSnare(idx) > 0)
#define isOffBalance(idx) (fs$getOffBalance(idx) > 0)
#define isRooted(idx) (fs$getFlags(idx)&FF_ROOTED)

#define isBlocking(idx) (!isJumping(idx) && (fs$getButtons(idx) & CONTROL_BACK) && !isDashing(idx) && !isAttacking(idx) && !isOffBalance(idx) && !isStunned(idx))

// Note: These do not check for stunned. Because that should be cached.
#define canWalk(idx) (!isBlocking(idx) && !isDashing(idx) && !isAttacking(idx) && !isRooted(idx))
#define canDash(idx) (!isAttacking(idx) && !isSnared(idx))
#define canAttack(idx) (!isAttacking(idx) && !isDashing(idx) && !isJumping(idx))
#define canGoThrough(idx) (llAbs((fs$getPos(idx)>>11) - (fs$getPos(!idx)>>11)) > 100) // Can pass through a player











