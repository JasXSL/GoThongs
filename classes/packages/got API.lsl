#define USE_DB4
#define USE_EVENTS
#include "got/_core.lsl"

integer chan;
list bindings;			// (key)targ, (int)chan

sendClassAttTags(){
	list tags;
	
	string data = hud$bridge$thongData();
	tags += [
		gotTag$level+"_"+j(data, BSS$LEVEL)
	];
	data = hud$bridge$userData();
	tags += [
		gotTag$gold+"_"+j(data, BSUD$GOLD), // measured in copper
		gotTag$difficulty+"_"+j(data, BSUD$DIFFICULTY),
		gotTag$class+"_"+j(data, BSUD$THONG_CLASS_ID),
		gotTag$role+"_"+j(data, BSUD$THONG_ROLE),
		gotTag$className+"_"+j(data, BSUD$THONG_NAME)
	];
	
	gotClassAtt$descMeta(tags);
}

onEvt(string script, integer evt, list data){

	if( bindings ){
		
		// Pregenerate the message
		string msg = GotAPI$buildAction(GotAPI$actionEvt, ([
			script, evt, mkarr(data)
		]));
		
		integer i;
		for( ; i < count(bindings); i += 2 )
			llRegionSayTo(llList2Key(bindings, i), llList2Integer(bindings, i+1), msg);
			
	}
	
	if( script == "got Bridge" && (evt == BridgeEvt$userDataChanged || evt == BridgeEvt$data_change) ){
		sendClassAttTags();
	}

}

outputBindStatus(key id, integer bound){
	integer evt = GotAPIEvt$bound;
	if(!bound)
		evt = GotAPIEvt$unbound;
		
	string msg = GotAPI$buildAction(GotAPI$actionEvt, ([
		llGetScriptName(), evt
	]));
	llRegionSayTo(id, GotAPI$chan(llGetOwnerKey(id)), msg);
}

timerEvent(string id, string data){
	
	// Make sure the asset remains within the region
	if(id == "P"){
	
		integer i;
		for( ; i<count(bindings) && bindings != []; i += 2 ){
			
			if(llKey2Name(l2k(bindings, i)) == ""){
			
				bindings = llDeleteSubList(bindings, i, i+1);
				i-=2;
				
			}
			
		}
		
	}
	
}

#define durFxPercStr(effect) (str)((float)fx$getDurEffect(effect)*100)
#define durFxPerc(effect) ((float)fx$getDurEffect(effect)*100)


default{

    state_entry(){
	
		chan = GotAPI$chan(llGetOwner());
		llListen(chan, "", "", "");
		llRegionSay(chan, GotAPI$buildAction(GotAPI$actionIni, []));
		multiTimer(["P", "", 10, TRUE]);
		
    }
	
	timer(){multiTimer([]);}
	
	listen(integer chan, string name, key id, string message){

		if(!startsWith(message, "GA|"))
			return;
			
		list PLAYERS = hudGetPlayers();
		if( llListFindList(PLAYERS, [(str)llGetOwnerKey(id)]) == -1 )
			return;
			
		list data = llJson2List(llGetSubString(message, 3, -1));
		integer command = llList2Integer(data, 0);
		data = llDeleteSubList(data, 0, 0);
		
		if( command == GotAPI$cmdBind || command == GotAPI$cmdUnbind ){
		
			key targ = id;
			if(llList2Key(data, 0))targ = llList2Key(data, 0);
			integer pos = llListFindList(bindings, [targ]);
			

			if( command == GotAPI$cmdBind && ~pos )
				return outputBindStatus(targ, TRUE);
			if( command == GotAPI$cmdUnbind && pos == -1 )
				return outputBindStatus(targ, FALSE);
				
			// Bind
			if( command == GotAPI$cmdBind ){
				
				bindings+= [targ, GotAPI$chan(llGetOwnerKey(targ))];
				outputBindStatus(targ, TRUE);
				
			}
			// Unbind
			else{
				
				bindings = llDeleteSubList(bindings, pos, pos+1);
				outputBindStatus(targ, FALSE);
				
			}
			
			
		}
		
		else if( command == GotAPI$cmdEmulateEvent && llGetOwnerKey(id) == llGetOwner() )
			onEvt( l2s(data, 0), l2i(data, 1), llJson2List(l2s(data, 2)) );

	}
	
	
	
    // This is the standard linkmessages
    #include "xobj_core/_LM.lsl" 
	
	if( method$byOwner && METHOD == GotAPIMethod$getClassAttTags ){
		sendClassAttTags();
	}
	
    if( METHOD == GotAPIMethod$getStats ){
		
		list descs = fx$FLAG_DESCS;
		list descsOut;
		
		// Dumps all passive stats
		llOwnerSay("    :: MODIFIERS ::");
		int f = (int)fx$getDurEffect(fxf$SET_FLAG);
		integer i;
		for( ; i<32; ++i ){
			if( f&(1<<i) )
				descsOut += l2s(descs, i);
		}
		llOwnerSay("FLAGS > "+llList2CSV(descsOut));
		descs = descsOut = [];
		llOwnerSay("RESOURCE MODIFIERS > \n"+
			durFxPercStr(fxf$HP_MULTI)+"% +"+fx$getDurEffect(fxf$HP_ADD)+" HP \n"+
			durFxPercStr(fxf$MANA_MULTI)+"% +"+fx$getDurEffect(fxf$MANA_ADD)+" MP \n"+
			durFxPercStr(fxf$MAX_PAIN_MULTI)+"% +"+fx$getDurEffect(fxf$MAX_PAIN_ADD)+" Pain \n"+
			durFxPercStr(fxf$MAX_AROUSAL_MULTI)+"% +"+fx$getDurEffect(fxf$MAX_AROUSAL_ADD)+" Arousal"
		);
		
		list arrDmdm = llJson2List(fx$getDurEffect(fxf$DAMAGE_DONE_MULTI));
		int pos = llListFindList(arrDmdm, (list)0);
		float dmdm = 1.0;
		if( ~pos )
			dmdm = l2f(arrDmdm, pos+1);
		list arrDmtm = llJson2List(fx$getDurEffect(fxf$DAMAGE_TAKEN_MULTI));
		pos = llListFindList(arrDmtm, (list)0);
		float dmtm = 1.0;
		if( ~pos )
			dmtm = l2f(arrDmtm, pos+1);
			
		list arrHetm = llJson2List(fx$getDurEffect(fxf$HEALING_TAKEN_MULTI));
		pos = llListFindList(arrHetm, (list)0);
		float herm = 1.0;
		if( ~pos )
			herm = l2f(arrHetm, pos+1);
		
		llOwnerSay(
			"POWER> \n"+
			(str)llRound(dmdm*100)+"% Damage & Healing done "+mkarr(arrDmdm)+"\n"+
			durFxPercStr(fxf$HEALING_DONE_MULTI)+"% Healing done\n"+
			(str)(((float)fx$getDurEffect(fxf$CRIT_ADD)-1.0)*100)+"% Crit chance\n"+
			durFxPercStr(fxf$BACKSTAB_MULTI)+"% Damage done from behind\n"+
			fx$getDurEffect(fxf$SPELL_DMG_DONE_MOD)+" abil dmg done\n"
		);
		
		
		llOwnerSay(
			"REGEN >\n"+
			durFxPercStr(fxf$HP_REGEN_MULTI)+"% HP\n"+
			durFxPercStr(fxf$MANA_REGEN_MULTI)+"% MP\n"+
			durFxPercStr(fxf$PAIN_REGEN_MULTI)+"% Pain\n"+
			durFxPercStr(fxf$AROUSAL_REGEN_MULTI)+"% Arousal\n"+
			durFxPercStr(fxf$COMBAT_HP_REGEN)+"% Combat HP Regen"
		);
		

		llOwnerSay("DEFENSES >\n"+
			(str)(100-durFxPerc(fxf$DODGE))+"% Dodge\n"+	// Dodge is inverse
			(str)llRound(dmtm*100)+"% Damage Taken "+mkarr(arrDmtm)+"\n"+
			durFxPercStr(fxf$DAMAGE_TAKEN_FRONT)+"% Damage Taken from front\n"+
			durFxPercStr(fxf$DAMAGE_TAKEN_BEHIND)+"% Damage Taken from behind\n"+
			(str)llRound(100*herm)+"% Healing received "+mkarr(arrHetm)+"\n"+
			durFxPercStr(fxf$HP_ARMOR_DMG_MULTI)+"% HP to armor damage multiplier\n"+
			durFxPercStr(fxf$ARMOR_DMG_MULTI)+"% Global armor damage multiplier\n"+
			durFxPercStr(fxf$QTE_MOD)+"% Quick time event speed multiplier"+
			fx$getDurEffect(fxf$SPELL_DMG_TAKEN_MOD)+" Sp.dmg taken [(int)caster_(str)spellName, (float)multi...] caster=0xUUID, 0=ALL casters\n"
		);
		
		llOwnerSay("BEFUDDLE CHANCE >\n"+
			(str)llRound(100*((float)fx$getDurEffect(fxf$BEFUDDLE)-1.0))+"%"
		);
		llOwnerSay("MANA COST >\n"+
			durFxPercStr(fxf$MANA_COST_MULTI)+"%\n"+
			fx$getDurEffect(fxf$SPELL_MANACOST_MULTI) + " Per spell multiplier"
		);
		
		llOwnerSay("PROCS >\n"+
			durFxPercStr(fxf$PROC_BEN)+"% Beneficial proc chance\n"+
			durFxPercStr(fxf$PROC_DET)+"% Detrimental proc chance\n"
		);
		
		llOwnerSay("SPEED >\n"+
			durFxPercStr(fxf$CASTTIME_MULTI)+"% cast time multiplier "+fx$getDurEffect(fxf$SPELL_CASTTIME_MULTI)+"\n"+
			durFxPercStr(fxf$COOLDOWN_MULTI)+"% cooldown multiplier "+fx$getDurEffect(fxf$SPELL_COOLDOWN_MULTI)+"\n"+
			
			durFxPercStr(fxf$MOVE_SPEED)+"% sprint regeneration\n"+
			durFxPercStr(fxf$SPRINT_FADE_MULTI)+"% sprint duration\n"+
			durFxPercStr(fxf$SWIM_SPEED_MULTI)+"% swim speed"	
		);
		
		llOwnerSay("Conversions > "+fx$getDurEffect(fxf$CONVERSION));

	}
	
	if( method$byOwner && METHOD == GotAPIMethod$dumpLSD ){
		list keys = llLinksetDataListKeys(0,-1);
        integer i;
		list cats = [
			gotTable$bridge,"bridge",
			gotTable$bridgeSpells, "spells",
			gotTable$spellmanSpellsTemp, "tmpspells",
			gotTable$evtsNpcNear, "npcNear",
			gotTable$evtsSpellIcons, "sp.icons",
			gotTable$status, "status",
			gotTable$fxCompilerActives, "FX.Active",
			gotTable$primSwim, "PrimSwim",
			gotTable$root, "Root",
			gotTable$rootPlayers, "Players"			
		];
        for( i = 0; i < count(keys); ++i ){
            
			string k = l2s(keys, i);
			string cat = "???";
			integer pos = llListFindList(cats, (list)llGetSubString(k, 0,0));
			if( ~pos )
				cat = l2s(cats, pos+1);
			else{
				integer ord = llOrd(k, 0);
				if( ord >= gotTable$fxStart && ord < gotTable$fxStart+gotTable$fxStart$length ){
					cat = "FX."+(str)ord+"."+(str)llOrd(k, 1);
				}
			}
			llOwnerSay("["+cat+"] "+k+" >> "+llLinksetDataRead(k));
			
		}
	}

	if(method$byOwner && METHOD == GotAPIMethod$list && !(method$isCallback)){
		
		llOwnerSay("Currently bound items: Item | Owner | Chan");
		integer i;
		for(i=0; i<llGetListLength(bindings); i+= 2){
			key item = llList2Key(bindings, i);
			llOwnerSay(llKey2Name(item) +" | "+ llKey2Name(llGetOwnerKey(item)) +" | "+ llList2String(bindings, i+1));
		}
		
	}
    // End link message code
    #define LM_BOTTOM  
    #include "xobj_core/_LM.lsl"  
}

