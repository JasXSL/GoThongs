#ifndef __CardGame
#define __CardGame

// 4-bit array that maps a clicked dir pad tile to a direction. Does not include adjacent. MSB is bottom right (face 7). 
#define DIR_PAD_VALID 50479120
/*
	// 0 is not valid movement
	((pl$ROT_UP+1) << 4) | // 1 is up
	// 2 is invalid
	((pl$ROT_LEFT+1) << 12) | // 3 is left
	((pl$ROT_RIGHT+1) << 16) | // 4 is right
	// 5 is invalid
	((pl$ROT_DN+1) << 24)// 6 is down
	// 7 is invalid
*/


// Card game channel
#define cg$chan 0x175


// Link message tasks. XOBJ uses -1 and below. So we can use positive for custom. nr is event and str is a json array of data
#define cg$EVT_ROOT_INIT 1		// Root script has initialized
#define cg$EVT_UPDATE_POS 2		// (int)player, (int)flags - Handled by _Tiles, a player position has changed
	#define cgPos$WARP 0x1			// Warp directly to pos
#define cg$EVT_UPDATE_TOOL 3	// void - Handled by _Tiles. Updates the visible player tool.
#define cg$EVT_TILE_CLICK 4		// (int)idx, (int)x, (int)y - A player has clicked a tile
#define cg$EVT_GEN_DECKS 5		// void - Generates the decks for all players.
#define cg$EVT_GEN_DONE 6		// void - Decks have been generated




// Marker -> host
/*
#define cgHost$task$dir 0		// (int)index - Clicked direction pad.

#define cgHost$task(task, data) llRegionSay(cg$chan, mkarr((list)"CHT" + task + data))
*/



// Host -> marker
#define cgMarker$task$loc 0		// (vector)pos, (rot)rotation
// this space for rent
// this space for rent
#define cgMarker$task$ping 3	// Todo
#define cgMarker$task$walk 4	// (vector)pos, (rot)rotation - Walk and auto rotate towards a position


#define cgMarker$task(targ, task, data) llRegionSayTo(targ, cg$chan, mkarr((list)"CMT" + (task) + data))

#define cgMarker$loc(targ, pos, rot) cgMarker$task(targ, cgMarker$task$loc, (pos) + (rot))
#define cgMarker$walk(targ, pos, rot) cgMarker$task(targ, cgMarker$task$walk, (pos) + (rot))







// DB4 definitions
// Game var table
#define table$cfg "CFG"
	#define table$cfg$tiles 0			// vector nr x/y tiles
	#define table$cfg$monsterTurn 1		// (int)isMonsterTurn
	#define table$cfg$numPlayers 2		// (int)nrPlayers

#define cfg$getInt(type) (int)db4$getFastSingle(TABLE_CONF, type)
#define cfg$getNumPlayers() cfg$getInt(table$cfg$numPlayers) 


// Player table
#define table$pl "PL"		// A number is added to this for each player. Max 8 players.

#define pl$MARKER 0			// uuid of marker
#define pl$CONTROLLER 1		// "" for NPC
#define pl$RXY 2			// 0b00 rot, 00000000x 00000000y X and Y are positive pointing from top left
	#define pl$ROT_UP 0			
	#define pl$ROT_RIGHT 1
	#define pl$ROT_DN 2
	#define pl$ROT_LEFT 3
#define pl$TOOLSET 3		// int current tool
	#define pl$TOOL_NONE 0
	#define pl$TOOL_WALK 1
#define pl$CLASS 4			// Player class
	#define pl$CLASS_AVATAR 0		// 
	#define pl$CLASS_QUADROPUS 1	// 
	
#define pl$tChar(idx) llGetSubString(TABLE_PL, idx, idx)
#define pl$getInt(idx, type) (int)db4$getFastSingle(pl$tChar(idx), type)
#define pl$getKey(idx, type) (key)db4$getFastSingle(pl$tChar(idx), type)

#define pl$set(idx, type, data) db4$replaceFastSingle(pl$tChar(idx), type, data)


#define pl$getController(idx) pl$getKey(idx, pl$CONTROLLER)
#define pl$getMarker(idx) pl$getKey(idx, pl$MARKER)
#define pl$getRXY(idx) pl$getInt(idx, pl$RXY)
#define pl$getToolset(idx) pl$getInt(idx, pl$TOOLSET)
#define pl$getClass(idx) pl$getInt(idx, pl$CLASS)


#define pl$setMarker(idx, marker) pl$set(idx, pl$MARKER, marker)
#define pl$setController(idx, controller) pl$set(idx, pl$CONTROLLER, controller)
#define pl$setRXY(idx, pack) pl$set(idx, pl$RXY, pack)
#define pl$setToolset(idx, toolset) pl$set(idx, pl$TOOLSET, toolset)
#define pl$setClass(idx, class) pl$set(idx, pl$CLASS, class)


#define pl$packTile( x, y, rot ) ((rot<<16)|(y<<8)|x)
#define pl$unpackTile( pack, x, y, rot ) int x = pack&0xFF; int y = ((pack>>8)&0xFF); int rot = ((pack>>16)&3)
#define pl$dirToRot(dir) llEuler2Rot(<0,0,PI_BY_TWO-PI_BY_TWO*dir>)
#define pl$tileToPos(x,y) (TOPLEFT+<x,-y,0>)




// HELPER FUNCTIONS //
// Builds a temporary list to speed up searching 
#define PPSTRIDE 4
list tmpPP; // tool, dir, x, y

#define pp$tool 0
#define pp$dir 1
#define pp$x 1
#define pp$y 2

#define pp$getTool(idx) l2i(tmpPP, PPSTRIDE*idx+pp$tool)
#define pp$getDir(idx) l2i(tmpPP, PPSTRIDE*idx+pp$dir)
#define pp$getX(idx) l2i(tmpPP, PPSTRIDE*idx+pp$x)
#define pp$getY(idx) l2i(tmpPP, PPSTRIDE*idx+pp$y)



buildPP(){
    
    tmpPP = [];
    NR_PLAYERS = cfg$getNumPlayers();
    integer i;
    for(; i < NR_PLAYERS; ++i ){
        
        integer pos = pl$getRXY(i);
        pl$unpackTile(pos, x, y, r);
        tmpPP += [pl$getToolset(i), r, x, y];

    }
    
}
#define releasePP() tmpPP = [];

#define runPP( code ) \
	buildPP(); \
	code \
	releasePP();












// Card design arrays:
// Should match pl$CLASS+1
list ca_textures = [
	"8ddc91b0-9e5d-0201-2446-8a079db60634",	// Base
	"8e649ab3-7b24-05d1-65e6-b9359fdb9d84", // Avatar
	"" 	// Quadropus
];
#define ca$tx$avatar 1			// 1024x512 texture of 4x 256x512 cards


#define table$cards "CRD"		// Builds an index of cards we need in the current game
#define table$player_decks "DEK"	// Each index corresponds to a player. An array of 3 arrays [(arr)held, (arr)draw, (arr)discard] 
									// Each array has a card index from table$cards
// Get deck data for a player
#define pd$DECK_HELD 0
#define pd$DECK_DRAW 1
#define pd$DECK_DISCARD 2
#define pd$get(idx) db4$getFast(DECK_TABLE, idx)
#define pd$set(idx, arrays) db4$replaceFast(DECK_TABLE, idx, arrays)

// Get card data
#define ct$get(idx) db4$getFast(CARD_TABLE, idx)


#define ca$energy 0				// Energy
#define ca$range 1				// range in tiles. 0 becomes a self cast.
#define ca$hitType 2
	#define ca$hitType$dir 0			// Hits everything in a line.
	#define ca$hitType$pbaoe 1			// Hits everything around you
#define ca$targTypes 3
	#define ca$targType$enemy 0x1		// Hit enemies
	#define ca$targType$friend 0x2		// Hit friends
	#define ca$targType$empty 0x4		// Hit empty tiles
	#define ca$targType$friend_obj 0x8	// Hit friendly objects
	#define ca$targType$enemy_obj 0x10	// Hit enemy objects
	#define ca$targType$self 0x20		// Allows to place it on yourself
#define ca$fx 4					// 2 strided array of (int)fx, (var)data
	#define ca$fx$damage 0				// (int)dmg Damage or healing
	#define ca$fx$root 1				// (int)turns
	#define ca$fx$stun 2				// (int)turns
	#define ca$fx$block 3				// (int)stacks
	#define ca$fx$daze 4				// (int)energy
	#define ca$fx$energy 5				// (int)amount
	#define ca$fx$dash 6				// (int)steps - Adds additional movement
	#define ca$fx$pushAway 7			// (int)steps - Pushes the enemy away from the caster. note: should only be used on directional
#define ca$flags 5
	#define ca$flag$pick_targ 0x1		// You usually want this. Lets you pick a single target within targTypes. Otherwise it will hit ALL targets in the direction you pick.
	#define ca$flag$dmg_invert_friend 0x2	// Inverts damage when it hits a friend
#define ca$conds 6				// Strided array of (int)cond, (var)data
#define ca$texture 7			// (int)texture per class relative to ca$textures
#define ca$textureOffset 8		// Offset on said texture
#define ca$atkAnim 9			// (str)anim
#define ca$tarAnim 10			// (str)anim
#define ca$tarFx 11				// (str)hitfx











#endif
