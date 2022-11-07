#ifndef _gotFollower
#define _gotFollower

/*
	
	Script for NPCs in follower mode.
	To install, put ["MSC","got Follower"] in the monster config
	You might also want to use the invulnerability flag and set team appropriately
	
	This listens to the MonsterEvt$state evt to 
	
*/

#define FollowerMethod$enable 1				// (key)target, (float)distance, (float)angle, (float)distconstraint - Enables/Updates following of the target, radius can be used to set the followers preferred position, starts at PI (behind player). Distconstraint is how far from the preferred point it can get before navigating.
#define FollowerMethod$disable 2			// 

#define FollowerEvt$targetLost 1			// void - Target we're following has been lost

#define Follower$enable(target, distance, radius, distconstraint) runMethod((str)LINK_ROOT, "got Follower", FollowerMethod$enable, [target, distance, radius, distconstraint], TNN)
#define Follower$disable() runMethod((str)LINK_ROOT, "got Follower", FollowerMethod$disable, [], TNN)


#endif
