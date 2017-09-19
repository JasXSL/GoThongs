// Set object description to 1 or [1] (first JSON element of desc) to prevent default behavior
// Projectile description array index
#define ProjectileDesc$preventDefault 0			// Prevents default behavior
#define ProjectileDesc$flags 1					// 
	//
#define ProjectileDesc$speed 2					// Base speed multiplier
#define ProjectileDesc$wiggleIntensity 3		// Wiggle the projectile. Recommended value is 0.5, intensity will be randomized with -+50%

#define ProjectileEvt$gotTarget 1		// (key)target
#define ProjectileEvt$targetReached 2	// (key)target - You now have 2 sec to do something before the object removes

