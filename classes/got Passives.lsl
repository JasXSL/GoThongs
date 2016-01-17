#define PassivesMethod$set 1							// (str)name, (arr)[(int)attributeid1, (var)attributeval1...] - Sets a passive with name
#define PassivesMethod$rem 2							// (str)name - Removes a passive by name
#define PassivesMethod$get 3							// void - Returns a list of passives affecting the player
#define PassivesMethod$setActive 4						// (arr)actives - Sent from got FXCompiler, sends active effects flattened array to be merged with passives

// The passives attributes should match got FXCompiler update attributes

#define PassivesEvt$data 1								// Contains FXCUpd values from got FXCompiler.lsl

#define Passives$toFloat(val) ((float)val/100)			// Convert back to float

#define Passives$set(targ, name, passives) runMethod((string)targ, "got Passives", PassivesMethod$set, [name, mkarr(passives)], TNN)
#define Passives$rem(targ, name) runMethod((string)targ, "got Passives", PassivesMethod$set, [name], TNN)
#define Passives$get(targ, callback) runMethod((string)targ, "got Passives", PassivesMethod$get, [], callback)
#define Passives$setActive(active) runMethod((string)LINK_ROOT, "got Passives", PassivesMethod$setActive, [mkarr(active)], TNN)




