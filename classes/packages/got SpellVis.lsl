#define USE_EVENTS
#include "got/_core.lsl"
 
// Abil prims
list ABILS = [0,0,0,0,0,0];			// Ability mains
list ABILS_BG = [0,0,0,0,0,0];		// Highlight background
list ABILS_OL = [0,0,0,0,0,0];
#define ABIL_BG_SCALE <0.15680, 0.04833, 0.02577>


#define ABIL_BORDER_READY_COLOR 
#define ABIL_BORDER_READY_ALPHA 0.75


int CACHE_BORDERS = 0;		// 4bit
#define getAbilityBorder(index) ((CACHE_BORDERS>>(index*4))&0xF)
#define setAbilityBorder(index, border) CACHE_BORDERS = (CACHE_BORDERS&~(0xF<<(index*4)))|(border<<(index*4))
#define ABIL_BORDER_DEFAULT 1
#define ABIL_BORDER_RECHARGING 2
#define ABIL_BORDER_NO_CHARGES 3	// no charges, mana, or gcd
#define ABIL_BORDER_CASTING 4
#define ABIL_BORDER_QUEUE 5
#define ABIL_BORDERS [	\
	<1,1,1>, 0.6,		/* default */ \
	<.5, .5, .5>, 0.5,	\
	ZERO_VECTOR, 0.6,	\
	<0.8,1,0.8>, 1.0,	/* casting... */ \
	<1,1,.5>, 1.0		/* queued */ \
]
 
integer BFL;
#define BFL_INI 0x1
#define BFL_CASTING 0x2

list CACHE_MANA_COST = [0,0,0,0,0];     // Mana cost of all spells
float CACHE_MANA = 50;

#define CCSTRIDE 2
list CACHE_COOLDOWNS = [0,0, 0,0, 0,0, 0,0, 0,0];		// First one is time black expires, second is time white expires
int CACHE_CHARGES = 0;					// 4 bit per spell, leftmost bit is if the spell was on the GCD last update
int CACHE_MAX_CHARGES = 0;				// Same as above
int CACHE_GCD;							// 1 bit, if spell is affected by global cooldown
int CACHE_ON_GCD;						// Same as above, but for spells currently on the GCD

#define setSpellCharges(index, charges) CACHE_CHARGES = ((CACHE_CHARGES&~(0xF<<(index*4)))|(charges<<(index*4)))
#define getSpellCharges(index) ((CACHE_CHARGES>>(index*4))&0xF)
#define getSpellMaxCharges(index) ((CACHE_MAX_CHARGES>>(index*4))&0xF)
#define setSpellMaxCharges(index, charges) CACHE_MAX_CHARGES = ((CACHE_MAX_CHARGES&~(0xF<<(index*4)))|(charges<<(index*4)))


list FX_CACHE;
#define FXSTRIDE 6
#define fxc$rezzable 0
#define fxc$finishAnim 1
#define fxc$finishSound 2
#define fxc$castAnim 3
#define fxc$castSound 4
#define fxc$flags 5

// Contains particles
list PARTICLE_CACHE;
#define fxp$timeout 0
#define fxp$prim 1
#define fxp$particles 2
#define PSTRIDE 3

// Flags from got Status
integer STATUS_FLAGS;
integer QUEUED_SPELL = -1;
integer SPELL_CASTED = -1;

string SPELL_ANIMS;

// Fx stuff
integer fxFlags;
integer fxHighlight;    // Bitwise combination, 0x1 for rest, 0x2 for abil1 etc
float manamod = 1;        // Global mana cost mod
float cdmod = 1;        // Global cooldown mod
list manacostMulti = [1,1,1,1,1];

integer WEAPON_SHEATHED = TRUE;

// Removes all cast and cooldown bars
#define stopCast(abil) llSetLinkPrimitiveParamsFast(llList2Integer(ABILS, abil), [PRIM_COLOR, 2, <1,1,1>, 0])

onEvt(string script, integer evt, list data){

    // Status flags updated
    if(script == "got Status" && evt == StatusEvt$flags){

        integer pre = STATUS_FLAGS;
        STATUS_FLAGS = llList2Integer(data,0);
        
        integer hideOn = (StatusFlag$dead|StatusFlag$loading);
        
        if( BFL&BFL_INI && (!(pre&hideOn) && STATUS_FLAGS&hideOn) || (pre&hideOn && !(STATUS_FLAGS&hideOn)) )
            SpellVis$toggle(TRUE);        // Auto hides if dead. So we can just go with TRUE for both cases
        
    }
    
    else if(script == "got Status" && evt == StatusEvt$resources){
	
        // [(float)dur, (float)max_dur, (float)mana, (float)max_mana, (float)arousal, (float)max_arousal, (float)pain, (float)max_pain] - PC only
        CACHE_MANA = l2f(data, 2);
		updateBorders();
		
    }
    else if( script == "got FXCompiler" && evt == FXCEvt$spellMultipliers )
        manacostMulti = llJson2List(llList2String(data,1));
	
	// Builds the buttons on the HUD
    else if(script == "got SpellMan" && evt == SpellManEvt$recache){
	
        FX_CACHE = [];
        PARTICLE_CACHE = [];
        CACHE_MANA_COST = [];
		CACHE_CHARGES = 0;
		CACHE_COOLDOWNS = (list)0+0+ 0+0+ 0+0+ 0+0+ 0+0+ 0+0;
        CACHE_GCD = 0;
		
        // Set textures
        list set = [];

        integer i;
        for(i=0; i<5; i++){
            
            list d = llJson2List(db3$get(BridgeSpells$name+"_temp"+(str)i, []));
            if(d == [])
                d = llJson2List(db3$get(BridgeSpells$name+(str)i, []));
				
            string visuals = llList2String(d, BSSAA$fx); // Visuals
            list p = llJson2List(j(visuals, 3));
			while( count(p) < 2 )
				p+= 0;
            PARTICLE_CACHE += l2f(p, 0);
            PARTICLE_CACHE += llList2List(p, 1, 1);
            PARTICLE_CACHE += l2s(p, 2);

            set += [
                PRIM_LINK_TARGET, llList2Integer(ABILS, i),
                PRIM_TEXTURE, 1, llList2String(d, BSSAA$texture), <1,1,0>, <0,0,0>,0,
                PRIM_COLOR, 1, <1,1,1>, 1
            ];
            
            FX_CACHE+=[
                j(visuals, 0),
                j(visuals, 1),
                j(visuals, 2),
                j(visuals, 4),
                j(visuals, 5),
                l2i(d, BSSAA$target_flags) // Flags
            ];
			
			// Global cooldown
			if( ~l2i(d, BSSAA$target_flags)&SpellMan$NO_GCD )
				CACHE_GCD = CACHE_GCD | (1 << i);
			
			setSpellCharges(i, l2i(d,BSSAA$charges));
            CACHE_MANA_COST += llList2Float(d, 3);
			
			
        }
		
		// Clone here because current charges contain max charges
		CACHE_MAX_CHARGES = CACHE_CHARGES;
        
        if( FX_CACHE ){
		
            BFL = BFL|BFL_INI;
            llSetLinkPrimitiveParamsFast(0, set);
            SpellVis$toggle(TRUE);
            GUI$toggle(TRUE);
			
        }
		
    }
    
    // Spell handlers
    
    // CAST START
    else if(script == "got SpellMan" && evt == SpellManEvt$cast){
	
        BFL = BFL|BFL_CASTING;
        
        // SpellMan handles all the conversions from -1 to 0-5, so this is the true index
        
        float ct = i2f(l2i(data, 0));                    // Cast time
        SPELL_CASTED = l2i(data, 2);


        if( ct>0 )
            setAbilitySpinner(SPELL_CASTED, 0, ct, FALSE, __LINE__);                // Not an instant spell, show cast bar
		
        list visual = llList2List(FX_CACHE, SPELL_CASTED*FXSTRIDE, SPELL_CASTED*FXSTRIDE+FXSTRIDE-1);
        
        // particles
        list p = llList2List(PARTICLE_CACHE, SPELL_CASTED*PSTRIDE, SPELL_CASTED*PSTRIDE+PSTRIDE-1);
		
		
		// Send to class specific visuals
		if( l2i(p, 0) == -2 )
			gotClassAtt$spellStart(l2s(p, 1), ct+1);
		// Send to global thongmanager
		else if( llList2String(p, fxp$particles) != "" )
			ThongMan$particles(ct+1, l2i(p, fxp$prim), l2s(p, fxp$particles));
        
        list sounds = [llList2String(visual, fxc$castSound)];
        if(llJsonValueType((string)sounds, []) == JSON_ARRAY)
            sounds = llJson2List((string)sounds);
        
		SPELL_ANIMS = "";
		if( llList2String(visual, fxc$castAnim) )				
			SPELL_ANIMS = llList2String(visual, fxc$castAnim);

		if( SPELL_ANIMS )
			AnimHandler$anim(SPELL_ANIMS, TRUE, 0,0,0);
        
        integer loop = TRUE;
        if(llGetListEntryType(sounds, 0) == TYPE_INTEGER && !llList2Integer(sounds, 0)){
            loop = FALSE;
            sounds = llDeleteSubList(sounds, 0, 0);
        }
        
        key sound = llList2String(sounds, 0);
        float vol = llList2Float(sounds, 1);
        if(sound)
            ThongMan$sound(sound, vol, loop);
    }
    
	else if( script == "got SpellMan" && evt == SpellManEvt$charges ){
	
		CACHE_CHARGES = l2i(data, 0);
		updateSpellCharges();
		updateBorders();
		
	}
	
    // CAST FINISH
    else if(script == "got SpellMan" && evt == SpellManEvt$complete){
	
        
        integer casted = l2i(data, 0);                    // Spell casted index 0-4
        list SPELL_TARGS = llJson2List(l2s(data, 3));                    // Targets casted at
        
        list visual = llList2List(FX_CACHE, casted*FXSTRIDE, casted*FXSTRIDE+FXSTRIDE-1);

        // ANimations and sounds
                
        list sounds = [llList2String(visual, fxc$finishSound)];
        if(llJsonValueType((string)sounds, []) == JSON_ARRAY)
            sounds = llJson2List((string)sounds);
        
		
		list p = llList2List(PARTICLE_CACHE, casted*PSTRIDE, casted*PSTRIDE+PSTRIDE-1);
		
		// index 3 of visual has -2 for class attach
		if( l2i(p, 0) == -2 ){

			// First block after the -2 that contains weapon trails etc
			
			// Use class attach visual
			if( l2s(p, 1) )
				gotClassAtt$spellEnd(l2s(p, 1), 1, "["+mkarr(SPELL_TARGS)+"]");
				
			// Use weapon trail
			if( l2s(p, 2) != "" )
				Weapon$trail(l2s(p,2));
			
		}
        
        if( llList2String(visual, fxc$finishAnim) == "_WEAPON_" )
            WeaponLoader$anim();
		else if( llList2String(visual, fxc$finishAnim) )
			AnimHandler$anim(llList2String(visual, fxc$finishAnim), TRUE, 0, 0, 0);
        
        
            
        list_shift_each(sounds, v,
            key s = v;
            float vol = 1; 
            if(llJsonValueType(v, []) == JSON_ARRAY){
                s = jVal(v, [0]);
                vol = (float)jVal(v, [1]);
            }
            if(s)
                llTriggerSound(s, vol);
        )
        
        onSpellEnd(casted, i2f(l2f(data, 5)));
		
    }
	
	
	
	// Cast interrupted
    else if(script == "got SpellMan" && evt == SpellManEvt$interrupted){
	
		list p = llList2List(PARTICLE_CACHE, SPELL_CASTED*PSTRIDE, SPELL_CASTED*PSTRIDE+PSTRIDE-1);
		if( l2i(p, 0) == -2 )
			gotClassAtt$spellEnd(l2s(p, 1), 0, "[]");
        onSpellEnd(l2i(data,0), i2f(l2i(data, 1)));
		
    }
	// weapon sheathed
	else if( script == "got WeaponLoader" && evt == WeaponLoaderEvt$sheathed )
		WEAPON_SHEATHED = l2i(data, 0);
	
}

// Use this function for everything that should run when a spell is done or interrupted
onSpellEnd(integer index, float casttime){
    BFL = BFL&~BFL_CASTING;
	
	stopCast(index);
	
    // Stops casting animations
	if( SPELL_ANIMS )
        AnimHandler$anim(SPELL_ANIMS, FALSE, 0, 0, 0);
	
	SPELL_CASTED = -1;
	updateBorders();
	
}

updateSpellCharges(){
	
	int i; list out;
	for( i=0; i<6; ++i ){
		
		if( getSpellMaxCharges(i) > 1 ){

			vector color = <.8,1,.8>;
			int c = getSpellCharges(i);
			if( c == 0 )
				color = <1,.8,.8>;
			else if( c < getSpellMaxCharges(i) )
				color = <1,1,1>;
				
			int y = c/16;
			int x = c-y*16;
			out+= [
				PRIM_LINK_TARGET, l2i(ABILS, i),
				PRIM_COLOR, 5, color, 1,
				PRIM_TEXTURE, 5, 
					"b8fbd724-51ac-eef4-ab8c-e643241de558", 
					<1./16, 1./4, 0>, 
					<1.0/32.0-1.0/16.0*8.0+1.0/16*x, 1.0/8.0 + 1.0/4.0 - 1.0/4*y, 0>, 
					0
			];
			
		}
		
		
	}
	PP(0, out);
	
}

updateBorders(){
	
	
	list set = [];
	integer i;
	for( i=0; i<6; ++i ){
		
		int n = ABIL_BORDER_DEFAULT;
		
		// Queued
		if( QUEUED_SPELL == i )
			n = ABIL_BORDER_QUEUE;
		// Actively casting
		else if( i == SPELL_CASTED )
			n = ABIL_BORDER_CASTING;
		else if( !getSpellCharges(i) || CACHE_MANA < l2f(CACHE_MANA_COST, i)*l2f(manacostMulti, i) )
			n = ABIL_BORDER_NO_CHARGES;
		else if( getSpellCharges(i) < getSpellMaxCharges(i) )
			n = ABIL_BORDER_RECHARGING;

		// set global cooldown status
		// this is only used to force a refresh if a global cooldown starts while a local cooldown remaining is less than global
		if( CACHE_GCD&i )
			n = n|8;
			
		// Global cooldown or border changed
		if( n != getAbilityBorder(i) ){
		
			vector abilColor = ONE_VECTOR;
			float castAlpha = 0;
			int type = n&~8;
			
			// If on cooldown because no charges are available then we make it darker
			if( type == ABIL_BORDER_NO_CHARGES )
				abilColor = <.5,.5,.5>;
			// A little darker if it is still on a charge cooldown
			else if( type == ABIL_BORDER_RECHARGING )
				abilColor = <.85,.85,.85>;

			list b = ABIL_BORDERS;
			set += (list)PRIM_LINK_TARGET + l2i(ABILS, i) +
				PRIM_COLOR + 0 + l2v(b, (type-1)*2) + l2f(b, (type-1)*2+1) +
				PRIM_COLOR + 1 + abilColor + 1
			;
			
			setAbilityBorder(i, n);
		}
	}
	
	if(set)
		PP(0, set);

}

setAbilitySpinner( integer abil, float startPercent, float duration, integer reverse, integer line ){
    
	if( duration<=0 )
		return;
		
    float total = 128./duration; // Total frames are 128
    integer startFrame = llRound(startPercent*127.); 
	integer totalFrames = 127-startFrame;
	
	if( reverse ){
		// Swap
		totalFrames = 127-startFrame;
		startFrame = 0;
	}
	
    integer flags;
    vector color = <.5,1,.5>;
    if(reverse){
        color = <0,0,0>;
        flags = REVERSE;
    }

	//qd("Setting castbar on "+(str)abil+" "+(str)startPercent+" "+(str)duration+" "+(str)reverse);
    float width = .25; float height = 1./32;
	// Shows the cast/cdbar
    llSetLinkPrimitiveParamsFast(llList2Integer(ABILS, abil), [ PRIM_COLOR, 2, color, 0.75 ]);
    llSetLinkTextureAnim(llList2Integer(ABILS, abil), 0, 2, 4,32, 0,32, total);
    llSleep(.05);
    llSetLinkTextureAnim(llList2Integer(ABILS, abil), ANIM_ON|flags, 2, 4,32, startFrame, totalFrames, total);
}

// Targets are uuids
handleRezzed( int casted, list targets ){
	
	list visual = llList2List(FX_CACHE, casted*FXSTRIDE, casted*FXSTRIDE+FXSTRIDE-1);
	
	list visuals = [llList2String(visual, fxc$rezzable)];
	if(llJsonValueType((string)visuals, []) == JSON_ARRAY)
		visuals = llJson2List((string)visuals);

	// rez visuals
	list_shift_each(targets, val, 
		
		if( (key)val ){}
		else
			val = llGetOwner();
		
		integer i;
		for( ; i < count(visuals); ++i ){
		
			string v = llList2String(visuals, i); 
			if( v ){
			
				string targ = val;
				if( prAttachPoint(targ) )
					targ = llGetOwnerKey(val);
				
				if( llJsonValueType(v, []) == JSON_ARRAY )
					SpellFX$spawnInstant(v, targ);
				else
					SpellFX$spawn(v, targ);
				
			}
			
		}
	)

}


timerEvent(string id, string data){
    
	// GCD is handled in batches to save on run speed
	if( id == "GCD" ){
		
		int i; list set;
		for( i=0; i<5; ++i ){
		
			if( CACHE_ON_GCD&(1<<i) ){
			
				CACHE_COOLDOWNS = llListReplaceList(CACHE_COOLDOWNS, (list)0.0, i*2, i*2);
				set += (list)PRIM_LINK_TARGET + llList2Integer(ABILS, i) + 
					PRIM_COLOR + 2 + ZERO_VECTOR + 0
				;
				
			}
			
		}
		CACHE_ON_GCD = 0;
		updateBorders();
		if( set )
			PP(0, set);
	}
	
	
	if( startsWith(id, "CD_") ){
        
		integer a = (int)llGetSubString(id, 3, -1);
		CACHE_COOLDOWNS = llListReplaceList(CACHE_COOLDOWNS, (list)0.0, a*2, a*2);
		// Resets the coloration
		if(SPELL_CASTED != a || ~BFL&BFL_CASTING){
			
			stopCast(a);
			updateBorders();
			
		}
    }
	
	if( startsWith(id, "CH_") ){
		
		int a = (int)llGetSubString(id, 3, -1);
		CACHE_COOLDOWNS = llListReplaceList(CACHE_COOLDOWNS, (list)0.0, a*2+1, a*2+1);
		llSetLinkPrimitiveParamsFast(l2i(ABILS_OL, a), [PRIM_COLOR, 1, ZERO_VECTOR, 0]);
	
	}
	
}

default {

    state_entry(){

        list out;
        links_each(nr, name, 
            
			integer n = (integer)llGetSubString(name, -1, -1); 
            if( llGetSubString(name, 0, 3) == "Abil" ){
                ABILS = llListReplaceList(ABILS, [nr], n, n);
                
                float width = 1./4;
                float height = 1./32;
                out+= ([
                    PRIM_LINK_TARGET, nr,
                    PRIM_TEXTURE, 2, "0c2f81c7-8ecf-92ab-0351-6bbe109f0d0a", <width,height,0>, <-floor(4/2)*width+width/2+width, floor(32/2)*height-height/2-height, 0>, 0,
                    PRIM_COLOR, 2, <1,1,1>, 1
                ]);
				
            }
            else if(llGetSubString(name, 0, 1) == "BG"){
                ABILS_BG = llListReplaceList(ABILS_BG, [nr], n, n);
                llSetLinkTextureAnim(nr, ANIM_ON|LOOP, 0, 4, 8, 0, 0, 30);
                out+=([PRIM_LINK_TARGET, nr, PRIM_TEXTURE, 0, "47814d20-b171-43ff-d7b5-c02749508906", <1,1,0>, ZERO_VECTOR, 0, PRIM_SIZE, ABIL_BG_SCALE]);
            }
			else if( startsWith(name, "aol") ){
				
				float width = 1./4;
                float height = 1./32;
				ABILS_OL = llListReplaceList(ABILS_OL, [nr], n, n);
				out += 
					(list)PRIM_LINK_TARGET + nr +
					PRIM_COLOR + ALL_SIDES + ZERO_VECTOR + 0 +
					PRIM_TEXTURE + 1 + "d04a7c64-d7aa-0412-2432-2a693843bf81" + (<width,height,0>) + (<-floor(4/2)*width+width/2+width, floor(32/2)*height-height/2-height, 0>) + 0
				;
				
			}	
        )
        llSetLinkPrimitiveParamsFast(0, out);
        SpellVis$toggle(FALSE);
        
        
        // Debug
        //onEvt("got SpellMan", SpellManEvt$recache, []);
    }
    
    timer(){multiTimer([]);}
    
    #define LM_PRE \
    if(nr == TASK_FX){ \
        list data = llJson2List(s); \
        manamod = i2f(l2f(data, FXCUpd$MANACOST)); \
        cdmod = i2f(l2f(data, FXCUpd$COOLDOWN)); \
        fxFlags = l2i(data, FXCUpd$FLAGS);\
        integer pre = fxHighlight; \
        fxHighlight = llList2Integer(data, FXCUpd$SPELL_HIGHLIGHTS); \
        list out = []; \
        integer i; \
        for(i=0; i<count(ABILS_BG); i++){ \
            integer check = (int)llPow(2,i); \
            if(fxHighlight&check){ \
                out+= [ \
                    PRIM_LINK_TARGET, llList2Integer(ABILS_BG,i), \
                    PRIM_COLOR,0,<1,1,1>,1 \
                ]; \
            } \
            else if(pre&check){ \
                out+= [ \
                    PRIM_LINK_TARGET, llList2Integer(ABILS_BG,i), \
                    PRIM_COLOR,0,<1,1,1>,0 \
                ]; \
            } \
        } \
        PP(0,out); \
    } \
	else if( nr == TASK_SPELL_VIS ){ \
		handleRezzed((int)j(s, 0), llJson2List(j(s, 1))); \
	}
    
    // This is the standard linkmessages
    #include "xobj_core/_LM.lsl" 
    // Here's where you receive callbacks from running methods
    if(method$isCallback || id != "")
        return;
    
    if( METHOD == SpellVisMethod$setCooldowns ){
	
        float currentTime = i2f(l2i(PARAMS, -1));
        PARAMS = llDeleteSubList(PARAMS, -1, -1);
		list CDS;
        integer i;
		int CDSTRIDE = 4;
        for( i=0; i<count(PARAMS); i+=CDSTRIDE ){ // This has to match CDSTRIDE in got SpellMan
        
			integer index = i/CDSTRIDE;
			float start = i2f(l2i(PARAMS, i));				// Script time relative to spellMan when cooldown began
            float duration = i2f(l2i(PARAMS, i+1));			// Total duration of cooldown
            float CDRemaining = start+duration-currentTime;		// Total time left. No need for internal CD since it is only used in conjunction with an actual cooldown
            float gStart = i2f(l2i(PARAMS, i+2));
			float gDur= i2f(l2i(PARAMS, i+3));				// Internal GCD for multi charge spells
			float intCDRemaining = gStart+gDur-currentTime;

			int charges = getSpellCharges(index);
			int maxCharges = getSpellMaxCharges(index);
			
			float blackExpires = CDRemaining;
			float blackStartTime = start;
			float blackDuration = duration;
			float whiteStartTime = 0;
			
			int isGCD;	// this is a real gcd (not internal gcd)
			int whiteExists = (charges < maxCharges && charges && start+duration-currentTime > 0);
			// The black cooldown needs to be changed to GCD if GCD is greater, or a white cooldown exists 
			if( whiteExists || intCDRemaining > CDRemaining ){
				
				blackExpires = intCDRemaining;
				blackStartTime = gStart;
				blackDuration = gDur;
				isGCD = CACHE_GCD&(1<<index);

				// If a white cooldown exists, get the start time of the non-GCD
				if( whiteExists )
					whiteStartTime = start;
					
			}
			
			

			float bdr = blackStartTime+blackDuration;
			CDS += (list)bdr + whiteStartTime;

            if( 
				// not actively casting, or not casting this spell
				~BFL&BFL_CASTING || SPELL_CASTED != index
			){
				// Handle the black cooldown
				if( 
					// Cooldown has changed
					bdr != l2f(CACHE_COOLDOWNS, index*CCSTRIDE)
				){
					int draw_charge_timer;
					// Black CD has expired
					if( blackExpires <= 0 ){
						stopCast(index);
					}
					// Black CD is active
					else{

						// Set the primary (dark) cooldown
						setAbilitySpinner(index, (currentTime-blackStartTime)/blackDuration, blackDuration, TRUE, __LINE__);
						// Only one timer is needed for global cooldown
						if( isGCD ){
						
							CACHE_ON_GCD = CACHE_ON_GCD|(1<<index);
							multiTimer(["GCD", 0, blackExpires, FALSE]);
							
						}
						// Need a different for anything else
						else{
							
							CACHE_ON_GCD = CACHE_ON_GCD&~(1<<index);
							multiTimer(["CD_"+(str)index, 0, blackExpires, FALSE]);
							
						}
					}  
					
				}				
				

				// White expires has changed
				if( whiteStartTime != l2f(CACHE_COOLDOWNS, index*CCSTRIDE+1) ){
				
					// There is a secondary cooldown
					if( whiteStartTime+duration > currentTime ){
					
						// This is never the global cooldown, always use start
						float perc = (currentTime-start)/duration;
						float total = 128./duration; // Total frames are 128
						integer startFrame = llRound(perc*127.); 
						integer totalFrames = 127-startFrame;
						
						llSetLinkTextureAnim(l2i(ABILS_OL, index), 0, 1, 0,0, 0,0, 0);
						//qd("StartFrame: "+(str)startFrame+" Total frames: "+(str)(4*32-startFrame));
						llSetLinkTextureAnim(llList2Integer(ABILS_OL, index), ANIM_ON, 1, 4,32, startFrame, totalFrames, total);
						llSetLinkPrimitiveParamsFast(l2i(ABILS_OL, index), [PRIM_COLOR, 1, ONE_VECTOR, 1]);
						// Set a timer to remove the secondary cooldown
						multiTimer(["CH_"+(str)index, 0, CDRemaining, FALSE]);
						
					}
					// There is not a secondary cooldown. Hide the face
					else{
						
						multiTimer(["CH_"+(str)i]);
						llSetLinkPrimitiveParamsFast(l2i(ABILS_OL, index), [PRIM_COLOR, 1, ZERO_VECTOR, 0]);
						llSetLinkTextureAnim(l2i(ABILS_OL, index), 0, 1, 0,0, 0,0, 0);
						
					}
					
				}
				 
            }
			
        }
        // Stores CD values, can be negative
        CACHE_COOLDOWNS = CDS;
		updateBorders();
    }
    /*
    else if(METHOD == SpellVisMethod$stopCast){
        stopCast((integer)method_arg(0));
    }
    */


    // Show/hide spells
    else if(METHOD == SpellVisMethod$toggle){
    
        integer show = l2i(PARAMS, 0);
        integer i;  list out;
		// Hide
        if(!show || STATUS_FLAGS&(StatusFlag$dead|StatusFlag$loading)){
            for(i=0; i<llGetListLength(ABILS); i++){
                out += [
                    PRIM_LINK_TARGET, llList2Integer(ABILS, i),
                    PRIM_POSITION, ZERO_VECTOR,
                    PRIM_COLOR, 2, <1,1,1>, 0,
                    PRIM_LINK_TARGET, llList2Integer(ABILS_BG, i),
                    PRIM_POSITION, ZERO_VECTOR,
					PRIM_LINK_TARGET, llList2Integer(ABILS_OL, i),
                    PRIM_POSITION, ZERO_VECTOR
                ];
            }
            PP(0,out);
            return;
        }
        
        // Show
        for(i=0; i<llGetListLength(ABILS); i++){

            vector pos = <0, 0.29586-0.073965-0.14793*(i-1), .31>;
            if(i == 0)pos = <0,0,.27>;
            if(i == 5)pos = <0,0,.35>;
            
            // Check disabled spells here
            integer f = l2i(FX_CACHE, i*FXSTRIDE+fxc$flags);
            
            // Spell disabled via flag or does not exist
            if(f&SpellMan$HIDE || count(FX_CACHE)/FXSTRIDE <= i) // 0x400 = disabled
                pos = ZERO_VECTOR;
            
            out+= [
                PRIM_LINK_TARGET, llList2Integer(ABILS, i),
                PRIM_POSITION, pos,
                //PRIM_COLOR, 0, ABIL_BORDER_COLOR, ABIL_BORDER_ALPHA,
                PRIM_COLOR, 1, <1,1,1>, 1, 
                PRIM_COLOR, 3, ZERO_VECTOR, 0,
                PRIM_COLOR, 4, ZERO_VECTOR, 0,
                PRIM_COLOR, 5, ZERO_VECTOR, 0,
				PRIM_LINK_TARGET, llList2Integer(ABILS_BG, i),
                PRIM_POSITION, pos+<.02,0,0>,
                PRIM_COLOR, 0, <1,1,1>, 0,
				PRIM_LINK_TARGET, llList2Integer(ABILS_OL, i),
				PRIM_POSITION, pos-<.05,0,0>
			];
            
        }
        
        PP(0, out);
        updateSpellCharges();
		updateBorders();
		
    }
    
    else if(METHOD == SpellVisMethod$setQueue){
	
        list out = [];
        integer s = (int)method_arg(0);
        if( s == QUEUED_SPELL )
			return;

        QUEUED_SPELL = s;
		updateBorders();
		
    }


    // End link message code
    #define LM_BOTTOM  
    #include "xobj_core/_LM.lsl"  
}

