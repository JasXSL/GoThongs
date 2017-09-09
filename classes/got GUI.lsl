#define GUIMethod$toggleObjectives 1	// (bool)on - Shows or hides the objectives 
//#define GUIMethod$status 2				// [(float)hp_perc, (float)mana_perc, (float)arousal_perc, (float)pain_perc, (int)flags, (int)fxflags]
#define GUIMethod$toggleLoadingBar 3	// (int)on, (float)time - Turns the loading bar on or off
#define GUIMethod$toggleSpinner 4		// (int)on, (str)loadingText - Sets a spinner
#define GUIMethod$togglePotion 5		// (key)texture || "", (int)stacks - Toggles a potion. If texture is not a key, it hides instead
#define GUIMethod$potionCD 7			// (float)cooldown || 0 - Sets cooldown overlay over potion
#define GUIMethod$setSpellTextures 6	// (arr)textures - Targ: 0 = self, 1 = friend, 2 = target - Sets little spell icons. Data is [(int)PID, (key)texture, (int)time_added_ms, (int)duration_ms, (int)stacks]
#define GUIMethod$toggleQuit 8			// (bool)show
#define GUIMethod$toggle 10				// (bool)show - opens or Closes the GUI
#define GUIMethod$toggleBoss 11			// (key)texture OR "" to clear, (bool)manual_hp OR (key)boss - Toggles the boss portrait. If manual_hp is set, only bossHP calls will update the HP
#define GUIMethod$bossHP 12				// (float)perc - Sets boss HP percentage

//#define GUI$myStatus(hp, mana, arousal, pain, flags, fxflags) runMethod((string)LINK_ROOT, "got GUI", GUIMethod$status, [hp, mana, arousal, pain, flags, fxflags], TNN)
#define GUI$setMySpellTextures(data) runMethod((string)LINK_ROOT, "got GUI", GUIMethod$setSpellTextures, data, TNN)

// These are excempt from XOBJ for speed purposes. Status updates run on GUI_CHAN
// Data is an int containing 4x 7bit ints (int)7-bit-hp/man/ars/pain (( Currently only one value is used ))
//#define GUI$status(targ, data) llRegionSayTo(targ, GUI_CHAN(targ), (str)data)
// Texture updates run on GUI_CHAN+1
//#define GUI$status(targ, hp, mana, arousal, pain, flags, fxflags) llRegionSayTo(targ, GUI_CHAN(targ), "A,"+llDumpList2String([hp, mana,arousal,pain,flags,fxflags], ","))
#define GUI$setSpellTextures(targ, data) llRegionSayTo(targ, GUI_CHAN(targ)+1, data)

#define GUI$toggleQuit(show) runMethod((string)LINK_ROOT, "got GUI", GUIMethod$toggleQuit, [show], TNN)
#define GUI$toggleTargQuit(targ, show, host) runMethod(targ, "got GUI", GUIMethod$toggleQuit, [show, host], TNN)
#define GUI$close() runMethod((string)LINK_ROOT, "got GUI", GUIMethod$toggle, [], TNN)
#define GUI$toggle(on) runMethod((string)LINK_ROOT, "got GUI", GUIMethod$toggle, [on], TNN)
#define GUI$toggleLoadingBar(targ, on, time) runMethod(targ, "got GUI", GUIMethod$toggleLoadingBar, [on, time], TNN)
#define GUI$toggleSpinner(targ, on, loadingText) runMethod(targ, "got GUI", GUIMethod$toggleSpinner, [on, loadingText], TNN)

#define GUI$togglePotion(texture, stacks) runMethod((str)LINK_ROOT, "got GUI", GUIMethod$togglePotion, [texture, stacks], TNN)
#define GUI$potionCD(cd) runMethod((str)LINK_ROOT, "got GUI", GUIMethod$potionCD, [cd], TNN)
#define GUI$toggleObjectives(targ, on) runMethod(targ, "got GUI", GUIMethod$toggleObjectives, [on], TNN)
#define GUI$toggleBoss(targ, texture, manual_hp) runMethod((str)(targ), "got GUI", GUIMethod$toggleBoss, [texture, manual_hp], TNN)
#define GUI$bossHP(targ, perc) runMethod((str)(targ), "got GUI", GUIMethod$bossHP, [perc], TNN)
