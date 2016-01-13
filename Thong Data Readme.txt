Thong naming conventions:

Create an invisible box and keep it as a root prim.
Name the root prim anything you like.

Name the thong itself "main1"
Name any part you DON'T want toggled on rape to "DISREGARD"

Drop the ton MeshAnim, got ThongVisual and got ThongMan scripts into the root prim.
Edit the got ThongVisual script for more info


In ThongMan you probably want to use:
ThongMan$set((string)LINK_THIS, data)
Otherwise the shine will be overridden. Please note that only the prims with names starting with "main" will be affected by visual effects.
If you wish to affect other prims, you have to script that yourself in got ThongVisual using the events from got ThongMan

Data for ThongMan$set is
[
	(vec)default_color,
	(float)default_glow,
	(arr)diffuse,
	(arr)bump,
	(arr)specular
]

Diffuse: [(key)texture, (vec)repeats, (vec)offsets, (float)rotation]
Bump: [(key)texture, (vec)repeats, (vec)offsets, (float)rotation]
Shine: [(key)texture, (vec)repeats, (vec)offsets, (rot)rotation, (vec)shine_color, (float)gloss, (float)world]

Basically prim params for PRIM_TEXTURE etc



