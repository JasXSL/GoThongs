#ifndef __gotBanter
#define __gotBanter

// These all share the same index. These are followed by a stringified 0->... And all have the same index.
// Terminated by an empty row.
#define gotTable$banter$evtType db4$0 		// Table name is followed by a non-packed number (stringified 0->...)
#define gotTable$banter$evtScript db4$1		// Name of script that has the event
#define gotTable$banter$evtData db4$2		// json array of event data values that must match
#define gotTable$banter$conds db4$3			// additional conditions (checked last)
	#define gotBanter$cond$sizePenis 0		// (int/str)size - All size type conditions can also prefix size with ">" or "<" for less or greater than
	#define gotBanter$cond$vagina 1			// (int)present
	#define gotBanter$cond$sizeBreasts 2
	#define gotBanter$cond$sizeRear 3		//
	#define gotBanter$cond$sizeTesticles 4	//
	
	#define gotBanter$cond$ofit 40				// (str)outfit - Uses the primary outfit slot. If you want to also specify a tertiary, use something like underpants_thong_tight to check if thong and tight are present. If you only want to check subtags, you can use * for the slot: *_armor checks if any outfit tag has armor set.
	
	#define gotBanter$cond$sex 50				// "male/female" are supported. The rest are up to the community.
	#define gotBanter$cond$spec 51				// (str)species - You can use | for ORing many species. This condition will accept regex later.
	#define gotBanter$cond$subs 52				// (str)species group - You can use | for ORing many species. This condition will accept regex later.
	#define gotBanter$cond$sizeTail 53
	#define gotBanter$cond$sizeHair 54
	#define gotBanter$cond$bdycoat 55			// (str)value
	#define gotBanter$cond$sizeBdyfat 56
	#define gotBanter$cond$sizeBdymscl 57
	#define gotBanter$cond$hasSpec 58			// 0 - Validates to true if spec is set to anything
	
#define gotTable$banter$targs db4$4			// ...
#define gotTable$banter$text db4$5			// ...
#define gotTable$banter$flags db4$6			// (int)flags
	#define gotBanter$flag$ONCE 0x1				// Only allow this event script/type once
#define gotTable$banter$sound db4$7

int _stGotSex( integer s ){
	return
		((s&0xF) > 0) |
		((((s>>sTag$bitoffs$vagina)&0xF) > 0) << 1) |
		((((s>>sTag$bitoffs$breasts)&0xF) > 0) << 2)
	;
}

// Gets JasX sex flags from sTag sex
#define gotBanter$getJasxSexFlags( targ ) _stGotSex(_stib(targ))

str _bCon( key targ, string text ){

	
	// Start with sTag
	list viable = (list)
		"%spec" + // species
		"%subs" + // subspecies
		"%bdycoat" // fur/skin etc
	;
	list spl = llParseString2List(text, [], viable);
	// At least one tag is present
	if( count(spl) > 1 ){
		
		sTag$cache$multi(targ, (list)"spec" + "subs" + "bdycoat");
		integer i = count(spl);
		while( i-- ){
			string tag = l2s(spl, i);
			integer pos = llListFindList(viable, (list)tag);
			if( ~pos ){
				tag = llDeleteSubString(tag, 0, 0);
				spl = llListReplaceList(spl, 
					sTag$cache$get(targ, tag, [], 1),
					i, i
				);
			}
		}
		text = (string)spl;
		
	}
	
	// 2-strided list of (str)tag, (arr)synonyms
	viable = (list)
		"%pussy" + "[\"pussy\",\"vagina\"]" +
		"%cock" + "[\"cock\",\"penis\",\"dick\"]" +
		"%breasts" + "[\"breasts\",\"tits\",\"boobs\"]"
	;
	spl = llParseString2List(text, [], llList2ListStrided(viable, 0,-1, 2));
	integer i = count(spl);
	while( i-- ){
		
		string tag = l2s(spl, i);
		integer pos = llListFindList(viable, (list)tag);
		if( ~pos ){
			list synonyms = llJson2List(l2s(viable, pos+1));
			spl = llListReplaceList(spl, (list)randElem(synonyms), i, i);			
		}
		
	}
	return (string)spl;
	
}
// This relies on stag caching being used
#define gotBanter$convert( targ, text ) _bCon(targ, text)


// Fetches commonly used sTag categories as a JSON object:
/*
{
	"spec" : str,
	"subs" : str,
	"sex" : str,
	"bits" : int,
	// If ext is true, it also fetches these:
	"ofit" : obj,
	"tail" : int,
	"hair" : int,
	"bdyfat" : int,
	"bdymscl" : int,
	"hud" : key
}
*/
str _bGetCommonJson( key targ, integer ext ){
	
	string out = "{}";
	
	list fetch = (list)"spec" + "subs" + "sex" + "gothud" + "bits";
	if( ext )
		fetch += (list)"tail" + "hair" + "bdyfat" + "bdymscl" + "ofit" + gotTag$level + gotTag$role + gotTag$className;
	list all = sTagAv( targ, "", [], 0);
	all = llListSort(all, 1, TRUE);
	integer i; string desc; list pack;
	for(; i <= count(all); ++i ){
		
		list spl = llParseString2List(llList2String(all, i), (list)"_", []);
		string cat = llList2String(spl, 0);
		if( cat != desc || (i == count(all) && pack != []) ){
			
			if( ~llListFindList(fetch, (list)desc) ){
				string v;
				if( desc == "ofit" )
					v = _stotj(pack);
				else if( desc == "bits" )
					v = (string)_stgb(pack);
				else 
					v = l2s(pack, 0);
				out = llJsonSetValue(out, (list)desc, v);
			}
			pack = [];
			desc = cat;
			
		}
		pack += llDumpList2String(llDeleteSubList(spl, 0, 0), "_");
	
	}
	
	return out;
}
#define gotBanter$getCommon(targ) _bGetCommonJson(targ, false)
#define gotBanter$getCommonExt(targ) _bGetCommonJson(targ, true)

// Copy paste to create variables for you
#define gotBanter$commonSplit( id, p,v,b,r,t, spec, subs, sex, ofit, tail, hair, bdyfat, bdymscl, hud, lv, role, class ) \
	string ofit = gotBanter$getCommonExt(id); \
	int _bits = (int)j(ofit, "bits"); \
	int p = sTag$penisSize(_bits); \
	int v = sTag$vagina(_bits); \
	int b = sTag$breastsSize(_bits); \
	int r = sTag$rearSize(_bits); \
	int t = sTag$testiclesSize(_bits); \
	string spec = j(ofit, "spec"); \
	string subs = j(ofit, "subs"); \
	string sex = j(ofit, "sex"); \
	int tail = sTag$sizeToInt(j(ofit, "tail")); \
	int hair = sTag$sizeToInt(j(ofit, "hair")); \
	int bdyfat = sTag$sizeToInt(j(ofit, "bdyfat")); \
	int bdymscl = sTag$sizeToInt(j(ofit, "bdymscl")); \
	int lv = (int)j(ofit, gotTag$level); \
	int role = (int)j(ofit, gotTag$role); \
	string class = j(ofit, gotTag$className); \
	key hud = j(ofit, "gothud"); \
	ofit = j(ofit, "ofit");
	

#define gotBanter$liteSplit( id, p,v,b,r, spec, subs, sex, hud ) \
	string hud = gotBanter$getCommon(id); \
	int _bits = (int)j(hud, "bits"); \
	int p = sTag$penisSize(_bits); \
	int v = sTag$vagina(_bits); \
	int b = sTag$breastsSize(_bits); \
	int r = sTag$rearSize(_bits); \
	string spec = j(hud, "spec"); \
	string subs = j(hud, "subs"); \
	string sex = j(hud, "sex"); \
	hud = j(hud, "gothud");


// Use with ofit from gotBanter$commonSplit
// got Banter Outfit Search. Checks if outfits have these tags, treating subtags as normal tags
int _gbos( string json, list find, integer any ){
	list data = llJson2List(json);
	json = "";
	integer i = count(data);
	while( i > 0 ){
		data = llListReplaceList(data, llJson2List(l2s(data, i-1)), i-1, i-1);
		i -= 2;
	}
	i = count(find);
	while( i-- ){
		int found = ~llListFindList(data, llList2List(find, i,i));
		if( found && any )
			return TRUE;
		else if( !found && any )
			return FALSE;
	}
	return !any;
}
#define gotBanter$hasThong( json ) _gbos(json, ["thong"], TRUE)
#define gotBanter$hasBodysuit( json ) _gbos(json, ["bodysuit"], TRUE)

#endif
