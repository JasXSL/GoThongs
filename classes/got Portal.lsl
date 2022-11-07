#ifndef _Portal
#define _Portal

// Helpful macros to automate
#define Portal$playerLists \
	list PLAYERS; \
	list PLAYER_HUDS;

#define Portal$isPlayerListIfStatement script == "got Portal" && (evt == evt$SCRIPT_INIT || evt == PortalEvt$players)
#define Portal$plif Portal$isPlayerListIfStatement
#define Portal$hif script == "got Portal" && evt == PortalEvt$playerHUDs

// Handles players and HUDs inside onEvt
#define Portal$handlePlayers() \
	if( Portal$plif ) \
		PLAYERS = data; \
	if( Portal$hif ) \
		PLAYER_HUDS = data;
	
	
#define Portal$handlePlayerLists() Portal$handlePlayers()

// Portal sends an evt$SCRIPT_INIT after all dependencies have been loaded with data being a json array of players

#define PortalMethod$resetAll 0				// void - Resets everything
#define PortalMethod$reinit 1				// NULL - refetches all scripts
#define PortalMethod$remove 2				// (bool)force - Deletes object. got LevelLite in a non live prim and persistent objects will ignore this unless force is TRUE
#define PortalMethod$save 3					// NULL - Auto callbacks
#define PortalMethod$iniData 4				// (str)data, (str)spawnround, (key)requester - Sets config data
#define PortalMethod$debugPlayers 5			// void - Says the loaded PLAYERS to the owner
#define PortalMethod$removeBySpawnround 6	// spawnround - Removes any item with a specific spawnround
#define PortalMethod$removeBySpawner 7		// (key)spawner - Removes any portal object spawned by spawner
#define PortalMethod$forceLiveInitiate 8	// Forces the portal to reinitialize as if it was live
#define PortalMethod$persistence 9			// (bool)persistant - Ignores remove calls unless override is true
#define PortalMethod$sendPlayers 10			// void - Forces a portal player and HUD event

#define BIT_DEBUG 536870912			// This is the binary bit (30) that determines if it runs in debug mode or not
#define BIT_GET_DESC 1073741824		// This is the binary bit (31) that determines if it needs to get custom data from the spawner or not
#define BIT_TEMP 2147483648			// Binary bit (32) that determines if the object should be temp or not

// got LevelData should NOT be in this. It's auto fetched along with got LevelLite
#define PORTAL_SEARCH_SCRIPTS (list)"ton MeshAnim"+"got Follower"+"jas MaskAnim"+"got AniAnim"+"got Projectile"+"got Status"+"got Monster"+"got FXCompiler"+"got FX"+"got NPCSpells"+"jas Attached"+"got Trap"+"got LevelLite"+"got LevelAux"+"got LevelLoader"+"got Spawner"+"got BuffSpawn"+"got ClassAtt"+"got PlayerPoser"+"got AnimeshScene"
#define PORTAL_SEARCH_OBJECTS ["Trigger"]

#define Portal$save() runOmniMethod("got Portal", PortalMethod$save, [], "SV")
#define Portal$killAll() runOmniMethod("got Portal", PortalMethod$remove, [], TNN)
// overrides all persistence
#define Portal$nukeAll() runOmniMethod("got Portal", PortalMethod$remove, [TRUE], TNN)
#define Portal$iniData(targ, data, spawnround, requester) runMethod(targ, "got Portal", PortalMethod$iniData, [data, spawnround, requester], TNN)
#define Portal$removeBySpawnround(spawnround) runOmniMethod("got Portal", PortalMethod$removeBySpawnround, [spawnround], TNN)
#define Portal$removeSpawnedByThis() runOmniMethod("got Portal", PortalMethod$removeBySpawner, [llGetKey()], TNN)
#define Portal$kill(targ) runMethod((str)targ, "got Portal", PortalMethod$remove, [], TNN)
#define Portal$persistence(on) runMethod((str)LINK_THIS, "got Portal", PortalMethod$persistence, [on], TNN)
#define Portal$sendPlayers() runMethod((str)LINK_THIS, "got Portal", PortalMethod$sendPlayers, [], TNN)

// Get spawn desc config
#define portalConf() llList2String(llGetLinkPrimitiveParams(LINK_THIS, [PRIM_TEXT]),0)
// Config is an array:
/*
	00	(vec)pos
	01	(int)live
	02	(var)customDesc
	03	(str)spawnround
*/
#define portalConf$pos (vector)j(portalConf(), 0)
#define portalConf$live (int)j(portalConf(), 1)
#define portalConf$desc j(portalConf(), 2)
#define portalConf$spawnround j(portalConf(), 3)




#define PortalEvt$desc_updated 1		// (var)desc_from_spawner - Portal has received a custom desc from the level
#define PortalEvt$spawner 2				// (key)spawner - Spawner is the key of the object that requested the spawn
#define PortalEvt$playerHUDs 3			// (arr)huds - Player HUDs have changed
#define PortalEvt$players 4				// (arr)players - Player UUIDs have been updated

_portal_spawn_std(string name, vector pos, rotation rot, vector spawnOffset, integer debug, integer reqDesc, integer temp){
	vector mpos = llGetRootPosition();
	vector local = vecFloor(mpos)+(pos-vecFloor(pos));
	integer in = vec2int(pos);
	if(debug)in = in|BIT_DEBUG;
	if(reqDesc)in = in|BIT_GET_DESC;
	if(temp)in = in|BIT_TEMP;
	llRezAtRoot(name, local+spawnOffset, ZERO_VECTOR, rot, in);
}

#endif

