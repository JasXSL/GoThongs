/*
	
	Description is similar to jas Interact: task$arg1$arg2$$task2...
	The first task is just an integer specifying range of interaction, if not set, it defaults to 3
	ex: 3$$book$HowToBeHumerus - This would open the book when touched within 3m
	Task is not case sensitive
	
*/

#define InteractMethod$interactWithMe 1			// void - interacts with the prim that sent the call, checks description


#define Interact$interactWithMe(targ) runMethod(targ, "got Interact", InteractMethod$interactWithMe, [], TNN)

