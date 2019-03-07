#define RapeMethod$start 1				// (arr)data - Data fetched from server
#define RapeMethod$end 2				// Stop rape
#define RapeMethod$assetSpawned 3		// void - Raised when rape asset has spawned
#define RapeMethod$remInventory 4		// [(arr)assets]
#define RapeMethod$setTemplates 5		// (arr)rapes - Allows something like an arena to set a template rape to trigger when a player goes down.
#define RapeMethod$activateTemplate 6	// void - Activates a template
#define RapeMethod$addFXAttachments 7	// attachment1, attachment2...
#define RapeMethod$remFXAttachments 8	// attachment1, attachment2...

#define Rape$start(data) runMethod((string)LINK_ALL_OTHERS, "got Rape", RapeMethod$start, data, TNN)
#define Rape$end() runMethod((string)LINK_ALL_OTHERS, "got Rape", RapeMethod$end, [], TNN)
#define Rape$assetSpawned() runMethod(llGetOwner(), "got Rape", RapeMethod$assetSpawned, [], TNN)
#define Rape$remInventory(assets) runMethod((str)LINK_ALL_OTHERS, "got Rape", RapeMethod$remInventory, [mkarr(assets)], TNN)
#define Rape$setTemplates(targ, templates) runMethod(targ, "got Rape", RapeMethod$setTemplates, (list)templates, TNN)
#define Rape$activateTemplate() runMethod((str)LINK_ALL_OTHERS, "got Rape", RapeMethod$activateTemplate, [], TNN)
#define Rape$addFXAttachments(attachments) runMethod((str)LINK_ALL_OTHERS, "got Rape", RapeMethod$addFXAttachments, attachments, TNN)
#define Rape$remFXAttachments(attachments) runMethod((str)LINK_ALL_OTHERS, "got Rape", RapeMethod$remFXAttachments, attachments, TNN)


#define RapeEvt$onStart 1		//
#define RapeEvt$onEnd 2			//


