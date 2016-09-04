#define ThongEvt$bricked 1			// Raised if you reset the script
#define ThongEvt$ini 2				// Thong ready to be created
#define ThongEvt$touchInfo 3		// (int)id, (key)clicker
#define ThongEvt$createFail 4		// Thong failed to be created
#define ThongEvt$id 5				// [(int)id]
#define ThongEvt$createSuccess 6	// (arr)server_data

#define ThongMethod$create 1		// Create
#define ThongMethod$refresh 2		// Outputs the ini id

#define Thong$create() runMethod((string)LINK_THIS, "got Thong", ThongMethod$create, [], TNN)
#define Thong$refresh() runMethod((string)LINK_THIS, "got Thong", ThongMethod$refresh, [], TNN)

