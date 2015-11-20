#define LanguageMethod$text 1		// (int)lang, (str)text, (str)unknownText, (key)sound, (float)vol=1 - 

#define Language$text(targ, lang, text, unknown, sound, vol) runMethod(targ, "got Language", LanguageMethod$text, [lang, text, unknown, sound, vol], TNN)
#define Language$common(targ, lang, text, sound, vol) runMethod(targ, "got Language", LanguageMethod$text, [lang, text, "", sound, vol], TNN)


#define LANGUAGE_COMMON 0x0
#define LANGUAGE_SKELETAL 0x1

