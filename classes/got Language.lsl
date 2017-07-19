#define LanguageMethod$text 1		// (int)lang, (str)text, (str)unknownText, (key)sound, (float)vol=1 - 

// Texts can be XLS texts
#define Language$text(targ, lang, text, unknown, sound, vol) runMethod(targ, "got Language", LanguageMethod$text, [lang, xparse(llGetOwnerKey((str)targ), text), unknown, sound, vol], TNN)
#define Language$common(targ, text, sound, vol) runMethod(targ, "got Language", LanguageMethod$text, [LANGUAGE_COMMON, xparse(llGetOwnerKey((str)targ), text), "", sound, vol], TNN)


#define LANGUAGE_COMMON 0x0
#define LANGUAGE_SKELETAL 0x1
#define LANGUAGE_GOBLIN 0x2

// Preset sounds
#define Language$sounds$skeleton$screech ["acdd0291-505d-b4be-9046-ab2bf847a4cf", "7082161b-06ff-50a1-5b89-d95f1e4e9085"]
