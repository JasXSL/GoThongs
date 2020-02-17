/*
	
	Lives in the player class portrait prim
	Also handles the stat numbers

*/
#define USE_EVENTS
#include "got/_core.lsl"

integer SPOKEN;


int P_NRS_HP;
int P_NRS_MP;
int P_NRS_ARS;
int P_NRS_PAIN;

int HP;
int mHP;

int MP;
int mMP;

int PAIN;
int mPAIN;

int ARS;
int mARS;

integer UI = TRUE;

onEvt(string script, integer evt, list data){
    
	if(script == "got Bridge" && evt == BridgeEvt$userDataChanged){
        SPOKEN = llList2Integer(data, BSUD$LANG);
    }
	
	else if( script == "got GUI" && evt == GUIEvt$toggle ){
	
		UI = l2i(data, 0);
		if( !UI ){
			float alpha = 0.0;
			PP(0,(list)
				PRIM_LINK_TARGET + P_NRS_HP + PRIM_COLOR + ALL_SIDES + ONE_VECTOR + alpha +
				PRIM_LINK_TARGET + P_NRS_MP + PRIM_COLOR + ALL_SIDES + ONE_VECTOR + alpha +
				PRIM_LINK_TARGET + P_NRS_ARS + PRIM_COLOR + ALL_SIDES + ONE_VECTOR + alpha +
				PRIM_LINK_TARGET + P_NRS_PAIN + PRIM_COLOR + ALL_SIDES + ONE_VECTOR + alpha
			);
		}
		else{
			HP = MP = PAIN = ARS = -1;
			Status$outputStats();
		}
		
	}
	
	if( script == "got Status" && evt == StatusEvt$resources ){

		list out;
		if( HP != l2i(data, 0) || mHP != l2i(data, 1) ){
			HP = l2i(data, 0);
			mHP = l2i(data, 1);
			out += barNrs(P_NRS_HP, HP, mHP);
		}
		
		if( MP != l2i(data, 2) || mHP != l2i(data, 3) ){
			MP = l2i(data, 2);
			mMP = l2i(data, 3);
			out += barNrs(P_NRS_MP, MP, mMP);
		}
		
		if( ARS != l2i(data, 4) || mARS != l2i(data, 5) ){
			ARS = l2i(data, 4);
			mARS = l2i(data, 5);
			out += barNrs(P_NRS_ARS, ARS, mARS);
		}
		
		if( PAIN != l2i(data, 6) || mPAIN != l2i(data, 7) ){
			PAIN = l2i(data, 6);
			mPAIN = l2i(data, 7);
			out += barNrs(P_NRS_PAIN, PAIN, mPAIN);
		}
		
		if( count(out) && UI )
			PP(0, out);
		
	}
	
}

// Draws bar NRs
list barNrs( integer prim, integer a, integer b){

	string nrSprite = "808bf549-c54a-67c9-4b81-2b680bbe5161";
	float hz = 0.06250;
	float hzofs = 0.03125;
	
	if( a > 999 )
		a = 999;
	if( b > 999 )
		b = 999;
		
	string aTxt = (string)a;
	while( llStringLength(aTxt) < 3 )
		aTxt = " "+aTxt;
	string bTxt = (string)b;
	while( llStringLength(bTxt) < 3 )
		bTxt += " ";
		
	list out = (list)PRIM_LINK_TARGET + prim;
	integer i;
	for(i=0; i<7; ++i ){
		
		string char = llGetSubString(aTxt, i, i);
		if( i == 3 )
			char = "10";
		if( i > 3 )
			char = llGetSubString(bTxt, i-4, i-4);
	
		if( char == " " )
			out += (list) PRIM_COLOR + i + ONE_VECTOR + 0;
		else
			out += (list)
				PRIM_TEXTURE + i + "d72fed9b-e077-6ea1-fd98-9b28d879fd21" + (<0.06250,1,0>) + (<-0.46875+0.06250*(int)char,0,0>) + 0 +
				PRIM_COLOR + i + ONE_VECTOR + 1
			;
	
	}
	
	return out;
}





default{

    state_entry(){
	
        memLim(2);
		links_each( nr, name,
			if( name == "RNRS_HP" )
				P_NRS_HP = nr;
			else if( name == "RNRS_MP" )
				P_NRS_MP = nr;
			else if( name == "RNRS_ARS" )
				P_NRS_ARS = nr;
			else if( name == "RNRS_PAIN" )
				P_NRS_PAIN = nr;
		)
		
		Status$outputStats();
		
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
    if(method$isCallback){
        
        return;
    }
    
    if(METHOD == LanguageMethod$text){
        integer lang = (integer)method_arg(0);
        integer field = 1;
        if(~SPOKEN&lang && lang)field = 2;
        string text = method_arg(field);
        key sound = (key)method_arg(3);
        float vol = (float)method_arg(4);
        if(sound){
            if(vol <= 0)vol = 1;
            llPlaySound(sound, vol);
        }
        AM$(text);
        
    }
    
    // Public code can be put here

    // End link message code
    #define LM_BOTTOM  
    #include "xobj_core/_LM.lsl"  
}
