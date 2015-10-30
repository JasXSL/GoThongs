// Portal sends an evt$SCRIPT_INIT after all dependencies have been loaded with data being a json array of players

#define PortalMethod$resetAll 0		// void - Resets everything
#define PortalMethod$reinit 1		// NULL - refetches all scripts
#define PortalMethod$remove 2		// NULL - Deletes object
#define PortalMethod$save 3			// NULL - Auto callbacks
#define PortalMethod$iniData 4		// void - Sets config data

#define BIT_DEBUG 536870912			// This is the binary bit (29) that determines if it runs in debug mode or not
#define BIT_GET_DESC 1073741824		// This is the binary bit (30) that determines if it needs to get custom data from the spawner or not

#define PORTAL_SEARCH_SCRIPTS ["ton MeshAnim", "got Projectile", "got Status", "got Monster", "got FXCompiler", "got FX", "got NPCSpells", "jas Attached", "got Trap"]

#define Portal$save() runOmniMethod("got Portal", PortalMethod$save, [], "SV")
#define Portal$killAll() runOmniMethod("got Portal", PortalMethod$remove, [], TNN)
#define Portal$iniData(targ, data) runMethod(targ, "got Portal", PortalMethod$iniData, [data], TNN)

#define portalStartPos() (vector)j(llList2String(llGetLinkPrimitiveParams(LINK_ROOT, [PRIM_TEXT]), 0), 0)
#define portalLive() ((vector)j(llList2String(llGetLinkPrimitiveParams(LINK_ROOT, [PRIM_TEXT]),0), 0) != ZERO_VECTOR && !(integer)jVal(llList2String(llGetLinkPrimitiveParams(LINK_ROOT, [PRIM_TEXT]),0), 1))
// Get spawn desc config
#define portalConf() j(llList2String(llGetLinkPrimitiveParams(LINK_ROOT, [PRIM_TEXT]),0), 2)


#define PortalEvt$desc_updated 1		// Portal has received a custom desc from the level

_portal_spawn_std(string name, vector pos, rotation rot, vector spawnOffset, integer debug, integer reqDesc){
	vector mpos = llGetPos();
	vector local = vecFloor(mpos)+(pos-vecFloor(pos));
	integer int = vec2int(pos);
	if(debug)int = int|BIT_DEBUG;
	if(reqDesc)int = int|BIT_GET_DESC;
	llRezAtRoot(name, local+spawnOffset, ZERO_VECTOR, rot, int);
}

