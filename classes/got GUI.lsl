#define GUIMethod$status 2				// [(float)hp_perc, (float)mana_perc, (float)arousal_perc, (float)pain_perc, (int)flags, (int)fxflags]
#define GUIMethod$setSpellTextures 6	// (arr)textures - Targ: 0 = self, 1 = friend, 2 = target - Sets little spell icons
#define GUIMethod$toggleQuit 8			// (bool)show, (bool)isHost
#define GUIMethod$toggle 10				// (bool)show - opens or Closes the GUI

#define GUI$myStatus(hp, mana, arousal, pain, flags, fxflags) runMethod((string)LINK_ROOT, "got GUI", GUIMethod$status, [hp, mana, arousal, pain, flags, fxflags], TNN)
#define GUI$setMySpellTextures(data) runMethod((string)LINK_ROOT, "got GUI", GUIMethod$setSpellTextures, data, TNN)

// These are excempt from XOBJ for speed purposes
#define GUI$status(targ, hp, mana, arousal, pain, flags, fxflags) llRegionSayTo(targ, GUI_CHAN(targ), "🐙A"+llDumpList2String([hp, mana,arousal,pain,flags,fxflags], ","))
#define GUI$setSpellTextures(targ, data) llRegionSayTo(targ, GUI_CHAN(targ), "🐙B"+llDumpList2String(data,","))

#define GUI$toggleQuit(show) runMethod((string)LINK_ROOT, "got GUI", GUIMethod$toggleQuit, [show, TRUE], TNN)
#define GUI$toggleTargQuit(targ, show, host) runMethod(targ, "got GUI", GUIMethod$toggleQuit, [show, host], TNN)
#define GUI$close() runMethod((string)LINK_ROOT, "got GUI", GUIMethod$toggle, [], TNN)
#define GUI$toggle(on) runMethod((string)LINK_ROOT, "got GUI", GUIMethod$toggle, [on], TNN)
