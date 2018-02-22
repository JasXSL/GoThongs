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
    for(i=0; i<count(data); i+=2)
		CACHE_FLAGS = CACHE_FLAGS|l2i(data,i+1);
	data = getDFXSlice(fx$UNSET_FLAG, 1);
    for(i=0; i<count(data); i+=2)
		CACHE_FLAGS = CACHE_FLAGS&~l2i(data,i+1);
	#ifndef IS_NPC
	if(~pre&fx$F_NO_PULL && CACHE_FLAGS&fx$F_NO_PULL)llStopMoveToTarget();
	#endif
	
}

// Returns a slice of dfx data with numElements elements
list getDFXSlice( integer type, integer numElements ){

	list out;
	integer _rdfx;
	if( numElements < 1 )
		numElements = 0;
		
	while( _rdfx < count(DFX) ){
	
		list slice;
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

		out+= slice;
		
		_rdfx += len+1;
		
	}	

	return out;
	
}

float stat( integer type, integer multiplication ){
	
	list check = getDFXSlice( type, 1 ); // The value we want to add should be the first value
	float out = multiplication;
	
	integer i;
	for( ; i<count(check); i+=2 ){
		
		int stacks = getStacks(dPid(l2i(check, i)), FALSE);
		if( multiplication )
			out *= (1+l2f(check, i+1)*stacks);
		else
			out += l2f(check, i+1)*stacks;
		
	}	
	
	return out;

}

