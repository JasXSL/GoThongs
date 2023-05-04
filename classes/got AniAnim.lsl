#ifndef _AniAnim
#define _AniAnim
// Uses same methods as MaskAnim

#define AniAnimMethod$customAnim 100	// (str)anim, (int)start, (int)flags, (float)duration | Tries to fetch and play a custom anim from owner


#define AniAnim$customAnim(targ, anim, start, flags, duration, preventNonHumanoid) \
	runMethod((str)targ, "got AniAnim", AniAnimMethod$customAnim, (list)(anim)+(start) + (flags) + (duration) + (preventNonHumanoid), TNN)
	
#define AniAnim$restart(animName) runMethod((string)LINK_SET, "got AniAnim", MaskAnimMethod$start, (list)animName+ true, TNN)
#define AniAnim$start(animName) runMethod((string)LINK_SET, "got AniAnim", MaskAnimMethod$start, (list)animName, TNN)
#define AniAnim$stop(animName) runMethod((string)LINK_SET, "got AniAnim", MaskAnimMethod$stop, (list)animName, TNN)


#endif
