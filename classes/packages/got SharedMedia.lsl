#define USE_EVENTS
//#define USE_SHARED ["#ROOT", "got Bridge"]
//#define DEBUG DEBUG_UNCOMMON
#include "got/_core.lsl"

#define BOOK_URL "http://jasx.org/lsl/got/hud/book.php"

integer BFL;
#define BFL_BROWSER_SHOWN 0x1
#define BFL_LOADED 0x2

integer P_PAPER;
#define PAPER_SIZE <0.50000, 0.50000, 0.1>
#define PAPER_POS <.12, 0.0, 0.7>
integer P_BROWSER_BG;
integer P_BOOK_BG;
#define BG_POS <0.000000, 0.020000, 0.660035>
integer P_BROWSER;
#define BROWSER_SIZE <0.85809, 0.44789, 0.02049>
#define BROWSER_POS <-0.074654, 0.031065, 0.582690>
vector b_size = BROWSER_SIZE;
vector b_pos = BROWSER_POS;
float b_scale = 1;

checkPos(){
    if(~BFL&BFL_LOADED)return;
    list d = llGetLinkPrimitiveParams(P_BROWSER, [PRIM_SIZE, PRIM_POS_LOCAL]);
    vector size = llList2Vector(d,0);
    float area = size.x*size.y;
    float cur = b_size.x*b_size.y;
    
    vector pos = llList2Vector(d, 1);
    pos.x = 0;
    vector check = b_pos;
    check.x = 0;
    
    if(llFabs(area-cur)>.1 || llVecDist(pos,check) > 0.001){
        b_size = size;
        b_pos = <b_pos.x, pos.y, pos.z>;
        
        vector origin = BROWSER_SIZE;
        cur = origin.x*origin.y;
        b_scale = area/cur;
        
        Bridge$saveBrowser(b_pos, b_scale);
    }
    
}


onEvt(string script, integer evt, string data){
    if(script == "got Bridge" && evt == BridgeEvt$userDataChanged){
        list dta = llJson2List(j(data, 1)); // Browser conf
        if(llList2Float(dta, 1)>0){
            b_scale = llList2Float(dta, 1);
            b_size = BROWSER_SIZE*b_scale;
        }
        vector p = (vector)llList2String(dta, 0);
        if(p != ZERO_VECTOR){
            b_pos.y = p.y;
            b_pos.z = p.z;
        }
        BFL = BFL|BFL_LOADED;
        if(BFL&BFL_BROWSER_SHOWN)
            llSetLinkPrimitiveParamsFast(P_BROWSER, [PRIM_SIZE, b_size, PRIM_POSITION, b_pos]);
        
    }
}



default 
{
    timer(){multiTimer([]);}
    
    state_entry(){
        links_each(nr, name, 
            if(name == "BROWSER")
                P_BROWSER = nr;
            else if(name == "BROWSERBG")
                P_BROWSER_BG = nr;
            else if(name == "PAPER")
                P_PAPER = nr;
            else if(name == "BOOKBG")
                P_BOOK_BG = nr;
        )
        list out;
        out+= [
            PRIM_LINK_TARGET, P_BROWSER,
            PRIM_SIZE, ZERO_VECTOR,
            PRIM_POSITION, ZERO_VECTOR,
            PRIM_COLOR, 0, <0,0,0>, .75,
            PRIM_COLOR, 2, <0,0,0>, .75,
            PRIM_LINK_TARGET, P_BROWSER_BG,
            PRIM_POSITION, ZERO_VECTOR,
            PRIM_SIZE, ZERO_VECTOR,
            PRIM_COLOR, 0, ZERO_VECTOR, .5,
            
            PRIM_LINK_TARGET, P_BOOK_BG,
            PRIM_POSITION, ZERO_VECTOR,
            PRIM_SIZE, ZERO_VECTOR,
            PRIM_COLOR, 0, ZERO_VECTOR, 0,
            
            PRIM_LINK_TARGET, P_PAPER,
            PRIM_POSITION, ZERO_VECTOR,
            PRIM_SIZE, ZERO_VECTOR
        ];
        llSetLinkPrimitiveParamsFast(0,out);
        llClearLinkMedia(P_BROWSER, 0);
        llSetLinkMedia(P_BROWSER, 1, [
            PRIM_MEDIA_CURRENT_URL, SITE_URL,
            PRIM_MEDIA_HOME_URL, SITE_URL,
            PRIM_MEDIA_CONTROLS, PRIM_MEDIA_CONTROLS_MINI,
            PRIM_MEDIA_AUTO_PLAY, TRUE,
            PRIM_MEDIA_WIDTH_PIXELS, 1024,
            PRIM_MEDIA_HEIGHT_PIXELS, 512,
            PRIM_MEDIA_FIRST_CLICK_INTERACT, TRUE,
            PRIM_MEDIA_PERMS_CONTROL, PRIM_MEDIA_PERM_OWNER,
            PRIM_MEDIA_PERMS_INTERACT, PRIM_MEDIA_PERM_OWNER
        ]);
        
        llClearLinkMedia(P_PAPER, 0);
        memLim(1.5);
    }

    
    // This is the standard linkmessages
    #include "xobj_core/_LM.lsl" 
    /*
        Included in all these calls:
        METHOD - (int)method  
        PARAMS - (var)parameters 
        SENDER_SCRIPT - (var)parameters
        CB - The callback you specified when you sent a task 
    */ 
    
    // Here's where you receive callbacks from running methods
    if(method$isCallback)
        return;
    
    
    if(method$internal){
        if(METHOD == SharedMediaMethod$toggleBrowser){
			string a = method_arg(0);
            if(a == "" || a == "1" || a =="0"){
                // Toggle
                list out;
                if(BFL&BFL_BROWSER_SHOWN && a != "0"){
                    checkPos();
                    BFL = BFL&~BFL_BROWSER_SHOWN;
                    out+= [
                        PRIM_SIZE, ZERO_VECTOR,
                        PRIM_POSITION, ZERO_VECTOR,
                        PRIM_LINK_TARGET, P_BROWSER_BG,
                        PRIM_SIZE, ZERO_VECTOR,
                        PRIM_POSITION, ZERO_VECTOR,
                        PRIM_COLOR, 0, ZERO_VECTOR, 0
                    ];
                }else{
                    BFL = BFL|BFL_BROWSER_SHOWN;
                    out+= [
                        PRIM_SIZE, b_size,
                        PRIM_POSITION, b_pos,
                        PRIM_LINK_TARGET, P_BROWSER_BG,
                        PRIM_SIZE, <2.5, 2.5, 0>,
                        PRIM_POSITION, BG_POS,
                        PRIM_COLOR, 0, ZERO_VECTOR, .5
                    ];
                }
                llSetLinkPrimitiveParamsFast(P_BROWSER, out);
            }else{
                // Update the URL
                llSetLinkMedia(P_BROWSER, 1, [
                    PRIM_MEDIA_CURRENT_URL, SITE_URL+"?token="+a
                ]);
            }
        }
        
    }
    
    if(method$byOwner){
        if(METHOD == SharedMediaMethod$setBook){
            list out;
            if(!isset(method_arg(0))){
                llClearLinkMedia(P_PAPER, 0);
                out = [
                    PRIM_LINK_TARGET, P_BOOK_BG,
                    PRIM_POSITION, ZERO_VECTOR,
                    PRIM_SIZE, ZERO_VECTOR,
                    PRIM_COLOR, 0, ZERO_VECTOR, 0,
                    
                    PRIM_LINK_TARGET, P_PAPER,
                    PRIM_POSITION, ZERO_VECTOR,
                    PRIM_SIZE, ZERO_VECTOR
                ];
            }else{
                llClearLinkMedia(P_PAPER, 0);
                llSetLinkMedia(P_PAPER, 0, [
                    PRIM_MEDIA_CURRENT_URL, BOOK_URL+"?id="+method_arg(0),
                    PRIM_MEDIA_HOME_URL, BOOK_URL+"?id="+method_arg(0),
                    PRIM_MEDIA_CONTROLS, PRIM_MEDIA_CONTROLS_MINI,
                    PRIM_MEDIA_AUTO_PLAY, TRUE,
                    PRIM_MEDIA_WIDTH_PIXELS, 512,
                    PRIM_MEDIA_HEIGHT_PIXELS, 512,
                    PRIM_MEDIA_FIRST_CLICK_INTERACT, TRUE,
                    PRIM_MEDIA_PERMS_CONTROL, PRIM_MEDIA_PERM_NONE,
                    PRIM_MEDIA_PERMS_INTERACT, PRIM_MEDIA_PERM_OWNER
                ]);
                vector bg = BG_POS;
                bg.x = .13;
                out = [
                    PRIM_LINK_TARGET, P_BOOK_BG,
                    PRIM_POSITION, bg,
                    PRIM_SIZE, <2.5, 2.5, 0>,
                    PRIM_COLOR, 0, ZERO_VECTOR, .5,
                    
                    PRIM_LINK_TARGET, P_PAPER,
                    PRIM_POSITION, PAPER_POS,
                    PRIM_SIZE, PAPER_SIZE
                ];
            }
            llSetLinkPrimitiveParamsFast(0, out);
        }
    }

    // Public code can be put here

    // End link message code
    #define LM_BOTTOM  
    #include "xobj_core/_LM.lsl"  
}

