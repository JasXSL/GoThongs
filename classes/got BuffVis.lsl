/*
	
	Handles long term buff visuals. These are visuals tied directly to a spell. Only works when PC is the target.

*/

#define BuffVisMethod$add 1						// (int)spellID, (str)visual, (var)config
#define BuffVisMethod$rem 2						// (int)spellID
#define BuffVisMethod$remInventory 3			// objects

#define BuffVis$add(id, visual, config) runMethod((str)LINK_ALL_OTHERS, "got BuffVis", BuffVisMethod$add, [id, visual, config], TNN)
#define BuffVis$rem(id) runMethod((str)LINK_ALL_OTHERS, "got BuffVis", BuffVisMethod$rem, [id], TNN)
#define BuffVis$remInventory(inventory) runMethod((str)LINK_ALL_OTHERS, "got BuffVis", BuffVisMethod$remInventory, inventory, TNN)
