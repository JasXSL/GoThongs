#ifndef _FXCompiler_Shared
#define _FXCompiler_Shared


/*
recacheFlags(){

	integer pre = CACHE_FLAGS;
	integer i; CACHE_FLAGS = 0;
	list data = getDFXSlice(fx$SET_FLAG, 1);

	for( ; i<count(data); i+=2 )
		CACHE_FLAGS = CACHE_FLAGS|l2i(data,i+1);
	
	data = getDFXSlice(fx$UNSET_FLAG, 1);
    
	for(i=0; i<count(data); i+=2)
		CACHE_FLAGS = CACHE_FLAGS&~l2i(data,i+1);
	
	#ifndef IS_NPC
	if( ~pre&fx$F_NO_PULL && CACHE_FLAGS&fx$F_NO_PULL )
		llStopMoveToTarget();
	#endif
	
}

// compiles a stat for output and returns it as a compressed integer
// Additive can also be 2 in which case it is inverse multiplicative
int _st( integer type, integer additive ){
	
	// The value we want to add should be the first value
	float out = additive != 1;		
	list check = getDFXSlice( type, 1 );
	
	integer i;
	for( ; i<count(check); i+=2 ){
		
		float val = l2f(check, i+1);
		if( additive == 2 )
			val = -val;
		
		int stacks = getStacks(dPid(l2i(check, i)), FALSE);
		if( additive == 1 )
			out += (val*stacks);
		else
			out *= (val*stacks+1);
		
	}	
	
	return f2i(out);

}

// Handler for a modifier that can also be limited to caster, such as damage and healing taken
// Does similar to stat, except check is a 2-stride array: [int charID, float modifier] this also uses multiplication
// charid of 0 is wildcard
list cMod( int t ){

	list out = [];
	list check = getDFXSlice( t, 2 );
	integer i;
	for( ; i<count(check); i += 3 ){
		
		int stacks = getStacks(dPid(l2i(check, i)), FALSE);
		int caster = l2i(check, i+2);

		// Find the intUUID in out
		int pos = llListFindList(llList2ListStrided(out, 0, -1, 2), (list)caster);
		float v = 1;
		if( ~pos )
			v = l2f(out, pos*2+1);
		v *= (1+l2f(check, i+1)*stacks);

		if( ~pos )
			out = llListReplaceList(out, (list)v, pos*2+1, pos*2+1);
		else
			out+= llList2List(check, i+2, i+2) + v;
		
	}	
	
	return out;

}
*/


#endif


