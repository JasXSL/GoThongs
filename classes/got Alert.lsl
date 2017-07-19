/*
	XLS Translations Needed
*/

#define AlertMethod$alert 1		// (int)message 
#define AlertMethod$freetext 2	// (str)message, (int)output_in_chat, (int)||(str)sound

#define A$(id) runMethod((string)LINK_ROOT, "got Alert", AlertMethod$alert, [id], TNN)
#define AM$(id) runMethod((string)LINK_ROOT, "got Alert", AlertMethod$alert, [id, true], TNN)
#define AS$(id) runMethod((string)LINK_ROOT, "got Alert", AlertMethod$alert, [id, false, true], TNN)
#define AMS$(id) runMethod((string)LINK_ROOT, "got Alert", AlertMethod$alert, [id, true, true], TNN)

// Sound can also be 2 for important alert
// Text can be an XLS text
#define Alert$freetext(targ, text, ownersay, sound) runMethod((str)targ, "got Alert", AlertMethod$freetext, [xparse(llGetOwnerKey((str)targ), text), ownersay, sound], TNN)





// Bridge
#define ABridge$loadingData 0
#define ABridge$thongChangeFail 1
#define ABridge$firstSetup 2

#define ABridge [ \
"$XL${\"en\":\"Loading thong data...\"}", \
"$XL${\"en\":\"Thong will be changed once you complete your current scene.\"}", \
"$XL${\"en\":\"Enable prim media to create your first thong! Click the GoThongs button to toggle the browser!\"}" \
]




// Root
#define ARoot$thongDetached 0
#define ARoot$thongEquipped 1
#define ARoot$nowInParty 2
#define ARoot$coopDisband 3
#define ARoot$continueQuest 4

#define ARoot [ \
"$XL${\"en\":\"Thong Detached\"}", \
"$XL${\"en\":\"Thong Equipped!\nYou can now start playing!\"}", \
"$XL${\"en\":\"Coop joined\"}", \
"$XL${\"en\":\"You are now playing solo.\"}", \
"$XL${\"en\":\"Spawning cell. Please wait.\"}" \
]

 
// SpellMan
#define ASpellMan$errTargInFront 0
#define ASpellMan$errVisionObscured 1
#define ASpellMan$errCastInProgress 2
#define ASpellMan$errCantCastYet 3
#define ASpellMan$errCantCastNow 4
#define ASpellMan$errPacified 5
#define ASpellMan$errInvalidTarget 6
#define ASpellMan$errInsufficientMana 7
#define ASpellMan$errOutOfRange 8
#define ASpellMan$interrupted 9

#define ASpellMan [ \
"$XL${\"en\":\"Target has to be in front of you.\"}", \
"$XL${\"en\":\"Your vision of the target is obscured.\"}", \
"$XL${\"en\":\"Another spell cast in progress\"}", \
"$XL${\"en\":\"Can't cast that yet\"}", \
"$XL${\"en\":\"Can't cast right now.\"}", \
"$XL${\"en\":\"You are pacified\"}", \
"$XL${\"en\":\"Invalid target\"}", \
"$XL${\"en\":\"Insufficient mana\"}", \
"$XL${\"en\":\"Out of range\"}", \
"$XL${\"en\":\"Interrupted\"}" \
]


