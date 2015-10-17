// Portal sends an evt$SCRIPT_INIT after all dependencies have been loaded with data being a json array of players

#define PortalMethod$reinit 1		// NULL - refetches all scripts
#define PortalMethod$remove 2		// NULL - Deletes object

#define PORTAL_SEARCH_SCRIPTS ["ton MeshAnim", "got Projectile", "got Status", "got Monster", "got FXCompiler", "got FX", "got NPCSpells", "jas Attached", "got Trap"]


#define portalStartPos() (vector)llList2String(llGetLinkPrimitiveParams(LINK_ROOT, [PRIM_TEXT]), 0)
#define portalLive() (llList2String(llGetLinkPrimitiveParams(LINK_ROOT, [PRIM_TEXT]), 0)!="")

_portal_spawn_std(string name, vector pos, rotation rot, vector spawnOffset){
	vector mpos = llGetPos();
	vector local = vecFloor(mpos)+(pos-vecFloor(pos));
	llRezAtRoot(name, local+spawnOffset, ZERO_VECTOR, rot, vec2int(pos));
}

