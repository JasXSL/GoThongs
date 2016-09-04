#define ModInstallMethod$reset 0		// void - Updates the script and re-validates
#define ModInstallMethod$fetch 1		// void - Causes the mod installer to send the assets.

#define ModInstall$fetch(targ) runMethod(targ, "got ModInstall", ModInstallMethod$fetch, [], TNN)
