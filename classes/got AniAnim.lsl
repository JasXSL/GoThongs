

#define AniAnimMethod$customAnim 100	// (str)anim, (int)start | Tries to fetch and play a custom anim from owner


#define AniAnim$customAnim(targ, anim, start) runMethod((str)targ, "got AniAnim", AniAnimMethod$customAnim, (list)anim+start, TNN)
