#define WeaponMethod$remove 1		// (str)objName+(int)HAND || "*" || "" (internal only) - Removes a weapon
#define WeaponMethod$ini 2			// (int)attach_slot, (vec)pos, (rot)rotation
// Sent on custom channel for speed
//#define WeaponMethod$trail 3		// [(int)generator(0-2), (int)age_100ths (vec)color, int scale_100ths, int alpha_10ths, int glow_10ths, int duration_100ths, int predelay_100ths]... | Sub arrays of weapon trails

#define gotWeaponFxChan (playerChan(llGetOwner())+0xDEDD)

#define Weapon$remove(targ, data) runMethod(targ, "got Weapon", WeaponMethod$remove, [data], TNN)
#define Weapon$ini(targ, slot, pos, rot, scale) runMethod(targ, "got Weapon", WeaponMethod$ini, [slot, pos, rot, scale], TNN)
#define Weapon$removeAll() runOmniMethod("got Weapon", WeaponMethod$remove, ["_WEAPON_"], TNN)
#define Weapon$trail(trails) llRegionSayTo(llGetOwner(), gotWeaponFxChan, trails)
