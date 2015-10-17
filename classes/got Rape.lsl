#define RapeMethod$start 1			// (arr)data - Data fetched from server
#define RapeMethod$end 2				// Stop rape

#define Rape$start(data) runMethod((string)LINK_ALL_OTHERS, "got Rape", RapeMethod$start, data, TNN)
#define Rape$end() runMethod((string)LINK_ALL_OTHERS, "got Rape", RapeMethod$end, [], TNN)

#define RapeEvt$onStart 1		//
#define RapeEvt$onEnd 2			//


