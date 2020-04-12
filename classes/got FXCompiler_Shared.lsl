#ifndef _FXCompiler_Shared
#define _FXCompiler_Shared
// Shared preprocessor definitions for the fxcompilers
// Duration effects
/*
	DFX:
	[
		(int):
			// 4 unused
			0b000000000000(8) type
			0b0000(4) num_arguments
			0b0000000000000000(16) id,
		(var)arg1,
		(var)arg2...
	]

*/
list DFX;

// Converts the first value of a DFX slice to a PID
#define dPid( confInt ) (confInt&0xFFFF)
#define dLen( confInt ) ((confInt>>16)&0xF)
#define dType( confInt ) ((confInt>>20)&0xFF)

#define addDFX( id, type, args ) \
	DFX += \
		(id | (count(args)<<16) | (type << 20)) + \
		args
		
remDFX( int pid ){

	integer _rdfx;
	while( _rdfx < count(DFX) && count(DFX) ){
	
		integer n = l2i(DFX, _rdfx);
		integer len = dLen(n);
		if( dPid(n) == pid )
			DFX = llDeleteSubList(DFX, _rdfx, _rdfx+len);
		else
			_rdfx += len+1;
		
	}
	
}



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

// Returns a slice of dfx data with numElements elements
list getDFXSlice( integer type, integer numElements ){

	list out;
	integer _rdfx;
	if( numElements < 1 )
		numElements = 0;
		
	while( _rdfx < count(DFX) ){
	
		integer n = l2i(DFX, _rdfx);
		integer len = dLen(n);
		
		// this entry has the right type
		if( dType(n) == type ){

			list slice;
			integer i;
			for( ; i<numElements+1; ++i ){
				
				if( len >= i )
					slice+= llList2List(DFX, _rdfx+i, _rdfx+i);
				else
					slice += "";
				
			}
			
			out+= slice;
			
		}
		
		_rdfx += len+1;
		
	}	

	return out;
	
}

#define stat( type ) _st(type, 0)
#define statAdditive( type ) _st(type, 1)
#define statInverse( type ) _st(type, 2)

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



#endif


