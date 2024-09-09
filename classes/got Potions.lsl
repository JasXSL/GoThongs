#ifndef _Potions
#define _Potions

#define PotionsMethod$setPotion 1		// (str)name, (key)texture, (int)charges, (int)flags, (float)cooldown, (obj)spellData, (str)description, (str)prim_name
#define PotionsMethod$resetCooldown 2	// 
#define PotionsMethod$remove 3			// (int)allow_drop, (int)force_remove_no_drop
#define PotionsMethod$use 4				// 
#define PotionsMethod$fallStun 5		// (int)level - Level can be 0 or 1, 1 adding a debuff and stunning for more

#define PotionsFlag$no_drop 0x1			// Don't spawn an item if replaced
#define PotionsFlag$raise_event 0x2		// Raise event on the current level when potion is consumed
#define PotionsFlag$is_in_hud 0x4		// The potion is in HUD. Just have your avatar drop it
#define PotionsFlag$raise_drop_event 0x8	// Raise an event on drop instead of spawning a new one, does not work with flag is_in_hud

#define PotionsEvt$pickup 1				// (str)potion_name
#define PotionsEvt$drop 2				// (str)potion_name
#define PotionsEvt$use 3				// (str)potion_name

#define Potions$set(targ, name, texture, charges, flags, cooldown, spellData, desc, prim) runMethod(targ, "got Potions", PotionsMethod$setPotion, (list)(name) + (texture) + (charges) + (flags) + (cooldown) + (spellData) + (desc) + (prim), NORET)
#define Potions$setArray(targ, data) runMethod(targ, "got Potions", PotionsMethod$setPotion, (list)data, NORET)

#define Potions$resetCooldown(targ) runMethod(targ, "got Potions", PotionsMethod$resetCooldown, [], NORET)
#define Potions$remove(targ, allow_drop, force_rem) runMethod(targ, "got Potions", PotionsMethod$remove, [allow_drop, force_rem], NORET)
#define Potions$use(targ) runMethod(targ, "got Potions", PotionsMethod$use, [], NORET)
#define Potions$fallStun(targ, level) runMethod((str)targ, "got Potions", PotionsMethod$fallStun, (list)(level), TNN)

#define PotionName$minorHealing "Pot_mHP"
#define PotionName$minorMana "Pot_mMP"
#define PotionName$greaterHealing "Pot_gHP"
#define PotionName$greaterMana "Pot_gMP"


#endif
