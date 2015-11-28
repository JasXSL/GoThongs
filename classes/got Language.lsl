#define LanguageMethod$text 1		// (int)lang, (str)text, (str)unknownText, (key)sound, (float)vol=1 - 

#define Language$text(targ, lang, text, unknown, sound, vol) runMethod(targ, "got Language", LanguageMethod$text, [lang, text, unknown, sound, vol], TNN)
#define Language$common(targ, text, sound, vol) runMethod(targ, "got Language", LanguageMethod$text, [LANGUAGE_COMMON, text, "", sound, vol], TNN)


#define LANGUAGE_COMMON 0x0
#define LANGUAGE_SKELETAL 0x1

// Preset sounds
#define Language$sounds$skeleton$screech ["acdd0291-505d-b4be-9046-ab2bf847a4cf", "7082161b-06ff-50a1-5b89-d95f1e4e9085"]
