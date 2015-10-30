#define DevtoolMethod$spawnAt 1			// (str)obj, (vec)pos, (rot)rotation


#define Devtool$spawnAt(obj, pos, rot) runMethod(llGetOwner(), "got Devtool", DevtoolMethod$spawnAt, [obj, pos, rot], TNN)
