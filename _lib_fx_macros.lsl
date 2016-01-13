
// Remove all spells casted by sender on the caster
#define fxlib$removeAllMySpellsOn(target) FX$send(target, llGetKey(), "[38,0,0,0,[0,24,\"\",[[36,0,\"\",\"\",\""+(string)llGetKey()+"\",0,0,0,0,0]],[],[],[],0,0,0]]");
#define fxlib$dealDamageOn(target, damage) FX$send(target, llGetKey(), "[9,0,0,0,[0,1,\"\",[[1,-"+(string)damage+"],[6,\"<.3,.2,.1>\"]],[],[],[],0,0,0]]");

