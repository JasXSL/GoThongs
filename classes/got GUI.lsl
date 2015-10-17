#define GUIMethod$setCooldown 1			// (int)spell, (float)sec : -1 = rest
#define GUIMethod$status 2				// [(float)hp_perc, (float)mana_perc, (float)arousal_perc, (float)pain_perc, (int)flags, (int)fxflags]
#define GUIMethod$setActiveAbility 3	// (int)spell
#define GUIMethod$setCastedAbility 4	// (int)spell, (float)casttime : -1 = rest
#define GUIMethod$stopCast 5			// (int)spell - Removes both cast and cooldown
#define GUIMethod$setSpellTextures 6	// (arr)textures - Targ: 0 = self, 1 = friend, 2 = target - Sets little spell icons

#define GUIMethod$toggleQuit 8			// (bool)show, (bool)isHost
#define GUIMethod$setSpells 9			// void - Sets your spells from BridgeSpells$name[]
#define GUIMethod$close 10				// Closes the GUI
#define GUIMethod$setGlobalCooldowns 11	// (float)cd, (int)spell0, (int)spell1... FALSE = disregard, TRUE = set, -1 = remove

#define GUI$status(targ, hp, mana, arousal, pain, flags, fxflags) runMethod((string)targ, "got GUI", GUIMethod$status, [hp, mana, arousal, pain, flags, fxflags], TNN)
#define GUI$setCooldown(buttonMinusOne, sec) runMethod((string)LINK_ROOT, "got GUI", GUIMethod$setCooldown, [buttonMinusOne, sec], TNN)
#define GUI$setCastedAbility(buttonMinusOne, sec) runMethod((string)LINK_ROOT, "got GUI", GUIMethod$setCastedAbility, [buttonMinusOne, sec], TNN)
#define GUI$stopCast(buttonMinusOne) runMethod((string)LINK_ROOT, "got GUI", GUIMethod$stopCast, [buttonMinusOne], TNN)
#define GUI$setSpellTextures(targ, data) runMethod((string)targ, "got GUI", GUIMethod$setSpellTextures, [data], TNN)
#define GUI$toggleQuit(show) runMethod((string)LINK_ROOT, "got GUI", GUIMethod$toggleQuit, [show, TRUE], TNN)
#define GUI$toggleTargQuit(targ, show, host) runMethod(targ, "got GUI", GUIMethod$toggleQuit, [show, host], TNN)
#define GUI$setSpells() runMethod((string)LINK_ROOT, "got GUI", GUIMethod$setSpells, [], TNN)
#define GUI$close() runMethod((string)LINK_ROOT, "got GUI", GUIMethod$close, [], TNN)
#define GUI$setGlobalCooldowns(time, spells) runMethod((string)LINK_ROOT, "got GUI", GUIMethod$setGlobalCooldowns, [time]+spells, TNN)
