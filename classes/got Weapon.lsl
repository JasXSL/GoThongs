#define WeaponMethod$remove 1		// (str)objName+(int)HAND || "*" || "" (internal only) - Removes a weapon
#define WeaponMethod$ini 2			// (int)attach_slot, (vec)pos, (rot)rotation
// Sent on custom channel for speed
//#define WeaponMethod$trail 3		
/*
	[
		(int)generator(0-2), 
		(int)age_100ths,
		(vec)color, 
		int scale_100ths, 
		int alpha_10ths, 
		int glow_10ths, 
		int duration_100ths, 
		int predelay_100ths
	]... | Sub arrays of weapon trails
*/
#define gotWeaponFxChan (playerChan(llGetOwner())+0xDEDD)

#define Weapon$remove(targ, data) runMethod(targ, "got Weapon", WeaponMethod$remove, [data], TNN)
#define Weapon$ini(targ, slot, pos, rot, scale, onBack) runMethod(targ, "got Weapon", WeaponMethod$ini, [slot, pos, rot, scale, onBack], TNN)
#define Weapon$removeAll() runOmniMethod("got Weapon", WeaponMethod$remove, ["_WEAPON_"], TNN)
#define Weapon$trail(trails) llRegionSayTo(llGetOwner(), gotWeaponFxChan, trails)

// 0b000000(6) task. Sent on gotWeaponFxChan
#define gotWeaponSettingChan ((int)("0x"+(string)llGetOwner())+696969)
#define gotWeapon$ctask$toggle 0x1	// 0b00 mainhand, offhand | Example: 0b10 000001 = show main hand, hide offhand

#define gotWeapon$ctask$setData(n, data) n = n|(data<<6);