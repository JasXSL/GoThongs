Spell effects sent FROM a player can use string "$MATH$formula" instead of a number anywhere in the effect object
Built in variables:
	D = damage_done_modifier
	
	
In the spell builder visual section it's an array:
	0. Rezzable(s) - 
		Can be either an array of strings or 
		a string of a single object to be rezzed from the HUD or an array of sub-arrays which contain 
		[name, posOffset, rotOffset, flags]
	1. Finish Anim(s) - Can be either an array of strings or a single string of an animation to be started. Should not loop.
	2. Finish Sound(s) - Can be either an array of keys or a single key of a sound to be played. Can also contain an array of sub-arrays with [(key)sound, (float)vol]
	3. Particles - An array consisting of 
		(thongMan) [(float)timeout(should be 0),(str/int)target,(arr)particle_system] | If target is int, use thongMan
		(classAtt/Weapon) 
		[
			-2, 
			(arr)[castID, finishID], 
			(opt arr)[[
				int generator(0-2)=0, 
				int age_100ths=50, 
				vec color=<1,.5,.5>, 
				int scale_100ths=30, 
				int alpha_10ths=5, 
				int glow_10ths=3, 
				int duration_100ths=70, 
				int predelay_100ths=30
			]...]
		]
	4. Cast Anim(s) - Animation(s) to play when casting. Will be stopped when casting is stopped.
	5. Cast Sound - A sound that will loop while casting - If list it's [sound, vol] optionally you can add integer 0 at the start like [0, sound, vol] to make the sound not loop
