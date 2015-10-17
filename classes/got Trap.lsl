#define TrapMethod$forceSit 1		// (key)victim, (float)duration - Will automatically send the forceSit quickrape to a player and sit them onto any "SEAT" named prim in the linkset

#define TrapEvent$triggered 1
#define TrapEvent$seated 2
#define TrapEvent$unseated 3




#define Trap$forceSit(victim, duration) runMethod((string)LINK_THIS, "got Trap", TrapMethod$forceSit, [victim, duration], TNN)

