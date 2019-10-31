#ifndef _SharedMedia
#define _SharedMedia

#define SharedMediaMethod$toggleBrowser 1		// NULL/(str)token - If token is set. Auto login. Otherwise just toggle
#define SharedMediaMethod$setBook 2				// (int)book_id
#define SharedMediaMethod$bookBrowser 3			// (str)token

#define SharedMedia$toggleBrowser(url) runMethod((string)LINK_ROOT, "got SharedMedia", SharedMediaMethod$toggleBrowser, [url], TNN)
#define SharedMedia$setBook(id) runMethod((string)LINK_ROOT, "got SharedMedia", SharedMediaMethod$setBook, [id], TNN)
#define SharedMedia$bookBrowser(token) runMethod((string)LINK_ROOT, "got SharedMedia", SharedMediaMethod$bookBrowser, [token], TNN)

#endif
