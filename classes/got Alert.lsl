
#define AlertMethod$alert 1		// (int)message 
#define AlertMethod$freetext 2	// (str)message, (int)output_in_chat, (int)sound

#define A$(id) runMethod((string)LINK_ROOT, "got Alert", AlertMethod$alert, [id], TNN)
#define AM$(id) runMethod((string)LINK_ROOT, "got Alert", AlertMethod$alert, [id, true], TNN)
#define AS$(id) runMethod((string)LINK_ROOT, "got Alert", AlertMethod$alert, [id, false, true], TNN)
#define AMS$(id) runMethod((string)LINK_ROOT, "got Alert", AlertMethod$alert, [id, true, true], TNN)

#define Alert$freetext(targ, text, ownersay, sound) runMethod(targ, "got Alert", AlertMethod$freetext, [text, ownersay, sound], TNN)





// Bridge
#define ABridge$loadingData 0
#define ABridge$thongChangeFail 1

#define ABridge [ \
"Loading thong data...", \
"Thong will be changed once you complete your current scene." \
]




// Root
#define ARoot$thongDetached 0
#define ARoot$thongEquipped 1
#define ARoot$nowInParty 2
#define ARoot$coopDisband 3
#define ARoot$continueQuest 4

#define ARoot [ \
"Thong Detached", \
"Thong Equipped!\nYou can now start playing!", \
"Coop joined", \
"Your coop partner has disbanded.", \
"Spawning cell. Please wait." \
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
"Target has to be in front of you.", \
"Your vision of the target is obscured.", \
"Another spell cast in progress", \
"Can't cast that yet", \
"Can't cast right now.", \
"You are pacified", \
"Invalid target", \
"Insufficient mana", \
"Out of range", \
"Interrupted" \
]


