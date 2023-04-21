1. Decide the following things:
 - Should it affect PC?
 - Should it affect NPC?
 - Should it only be passive?
 
2. Add an FXCUpd$ id for your effect in the "got FXCompiler" header file.
	- Active: Also map it to add to FXCMap in got Passives package file

3. ACTIVE effect only:
If BOTH NPC and PC: 
	Add to FXCompiler header file. If an instant effect (such as add HP), add to dumpFxInstants - Otherwise add to dumpFxAddsShared AND dumpFxRemsShared
Else: 
	Add to FXCompiler_PC or FXCompiler_NPC in the locations mentioned above. See the other effects for examples.

4. DURATION & Passive effects only: Go to FXCompiler_NPC AND FXCompiler_PC and find updateGame. 

5. DURATION & Passive effects only: Go to got Passives, add to the end of the index of the compiled_actives global AND parse it in LM_PRE

6. Implement your effect in any affected other script.
