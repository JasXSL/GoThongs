#ifndef __stag_extensions
#define __stag_extensions

// These must be prefixed with got

#define sTag$gotHud( targ ) (string)sTagAv(targ, "gothud", [], 1) // Stores the UUID of the GoT HUD
#define sTag$gotThongVis( targ ) l2i(sTagAv(targ, "gottv", [], 1),0) // Visual of the current thong (such as dirty, frozen etc)




#endif
