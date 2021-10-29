#ifndef _Projectile
#define _Projectile

// Set object description to 1 or [1] (first JSON element of desc) to prevent default behavior
// Projectile description array index
#define ProjectileDesc$preventDefault 0			// Prevents default behavior
#define ProjectileDesc$flags 1					// 
#define ProjectileDesc$speed 2					// Base speed multiplier
#define ProjectileDesc$wiggleIntensity 3		// Wiggle the projectile. Recommended value is 0.5, intensity will be randomized with -+50%
#define ProjectileDesc$heightOffset 4
#define ProjectileDesc$arc 5					// Similar to wiggle but creates an arc

#define ProjectileEvt$gotTarget 1		// (key)target
#define ProjectileEvt$targetReached 2	// (key)target - You now have 2 sec to do something before the object removes


// For projectiles using the got Projectile.template template:
#define Projectile$quickSpawn(obj, targ, startpos, startrot) llRezAtRoot(obj, startpos, ZERO_VECTOR, startrot, (int)("0x"+llGetSubString((string)targ,0,7)))

#endif
