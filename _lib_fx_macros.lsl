
// Remove all spells casted by sender on the caster
#define fxlib$removeAllMySpellsOn(target) FX$send(target, llGetKey(), "[38,0,0,0,[0,24,\"\",[[36,0,\"\",\"\",\""+(string)llGetKey()+"\",0,0,0,0,0]],[],[],[],0,0,0]]", 0)
#define fxlib$removeSpellByName(target, name) FX$send(target, "", "[0,0,0,0,[0,0,\"\",[[10,\""+name+"\"]],[],[],[],0,0,0]]", 0)
#define fxlib$removeSpellByNameWithEvent(target, name) FX$send(target, "", "[0,0,0,0,[0,0,\"\",[[10,\""+name+"\",1]],[],[],[],0,0,0]]", 0)

#define fxlib$forceSit(targ, on, allowUnsit, duration) FX$send(targ, llGetKey(), "[0,0,0,0,["+(str)duration+",0,\"forceSat\",[[31,\""+(str)on+"\","+(str)allowUnsit+"]],[],[],[],0,0,0]]", 0)

#define fxlib$dealDamageOn(target, damage, color, team) FX$send(target, llGetKey(), "[9,0,0,0,[0,1,\"\",[[1,"+(string)damage+"],[6,\""+(str)color+"\"]],[],[],[],0,0,0]]", team)
#define fxlib$hitFX(target, color, flags) FX$send(target, "", "[0,0,0,0,[0,0,\"\",[[6,\""+(str)color+"\", "+(str)flags+"]],[],[],[],0,0,0]]", TEAM_PC)

