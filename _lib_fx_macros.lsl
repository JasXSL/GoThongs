
// Remove all spells casted by sender on the caster
#define fxlib$removeAllMySpellsOn(target) FX$send(target, llGetKey(), "[0,0,0,0,[0,0,\"\",[[36,0,\"\",\"\",\""+(string)llGetKey()+"\",0,0,0,0,0]],[],[],[],0,0,0]]");


