#define WeaponMethod$remove 1		// (str)objName+(int)HAND || "*" || "" (internal only) - Removes a weapon
#define WeaponMethod$ini 2			// (int)attach_slot, (vec)pos, (rot)rotation

#define Weapon$remove(targ, data) runMethod(targ, "got Weapon", WeaponMethod$remove, [data], TNN)
#define Weapon$ini(targ, slot, pos, rot, scale) runMethod(targ, "got Weapon", WeaponMethod$ini, [slot, pos, rot, scale], TNN)
#define Weapon$removeAll() runOmniMethod("got Weapon", WeaponMethod$remove, ["_WEAPON_"], TNN)
