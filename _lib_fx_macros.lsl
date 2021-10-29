
// Remove all spells casted by sender on the caster
#define fxlib$removeAllMySpellsOn(target) FX$send(target, llGetKey(), "[38,0,0,0,[0,24,\"\",[[36,0,\"\",\"\",\""+(string)llGetKey()+"\",0,0,0,0,0]],[],[],[],0,0,0]]", 0)
#define fxlib$removeSpellByName(target, name) FX$send((str)target, "", "[38,0,0,0,[0,24,\"\",[[10,\""+name+"\"]]]]", 0)
#define fxlib$removeMySpellByName(target, name) FX$send((str)target, llGetKey(), "[38,0,0,0,[0,24,\"\",[[10,\""+name+"\",0,1]]]]", 0)
#define fxlib$removeSpellByNameWithEvent(target, name) FX$send((str)target, "", "[0,0,0,0,[0,0,\"\",[[10,\""+name+"\",1]],[],[],[],0,0,0]]", 0)

#define fxlib$forceSit(targ, on, allowUnsit, duration) FX$send(targ, llGetKey(), "[0,0,0,0,["+(str)duration+",0,\"forceSat\",[[31,\""+(str)on+"\","+(str)((int)allowUnsit)+"]]]]", 0)
#define fxlib$remForceSit(targ) fxlib$removeSpellByName(targ, "forceSat")

#define fxlib$dealDamageOn(target, damage, color, team, hfxFlags) FX$send(target, llGetKey(), "[9,0,0,0,[0,1,\"\",[[1,"+(string)damage+"],[6,\""+(str)color+"\","+(str)(hfxFlags)+"]],[],[],[],0,0,0]]", team)


#define fxlib$dealDamageOnAllowQuickrape(target, damage, color, team, hfxFlags) FX$send(target, llGetKey(), "[13,0,0,0,[0,17,\"\",[[1,"+(string)damage+"],[6,\""+(str)color+"\","+(str)(hfxFlags)+"]],[],[],[],0,0,0]]", team)
#define fxlib$hitFX(target, color, flags) FX$send(target, "", "[0,0,0,0,[0,0,\"\",[[6,\""+(str)color+"\", "+(str)(flags)+"]],[],[],[],0,0,0]]", TEAM_PC)
#define fxlib$blind(target, duration) FX$send(target, "", "[0,0,0,0,["+(str)duration+",0,\"_blind\",[[13,64]],[],[],[],0,0,0]]", TEAM_PC)

#define fxlib$teleportPlayer(targ, position) \
	RLV$cubeTaskOn(targ, SupportcubeBuildTeleport(position))
	
	
// Teleports players in a radius based on num players
#define fxlib$teleportPlayers(position, radius) \
	integer num = count(PLAYERS); \
	runOnPlayers(targ, \
		vector base = position+(<llCos(i*(TWO_PI/num)), llSin(i*(TWO_PI/num)),0>*radius); \
		fxlib$teleportPlayer(targ, base); \
	) \
