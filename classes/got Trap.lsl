#define TrapMethod$forceSit 1		// (key)victim, (float)duration[, (key)prim, (int)strip] - Will automatically send the forceSit quickrape to a player and sit them onto any "SEAT" named prim in the linkset. Prim can be a non key value instead of SEAT
#define TrapMethod$end 2			// void - Force end
#define TrapMethod$useQTE 3			// (int)numTaps - Use a quicktime event. 0 numTaps disables

#define TrapEvent$triggered 1
#define TrapEvent$seated 2
#define TrapEvent$unseated 3
#define TrapEvent$qteButton 4		// (bool)correct - A QTE button has been pushed


#define Trap$useQTE(numTaps) runMethod((str)LINK_THIS, "got Trap", TrapMethod$useQTE, [numTaps], TNN)
#define Trap$forceSit(victim, duration, prim, strip) runMethod((string)LINK_THIS, "got Trap", TrapMethod$forceSit, [victim, duration, prim, strip], TNN)
#define Trap$end(targ) runMethod((str)targ, "got Trap", TrapMethod$end, [], TNN)
