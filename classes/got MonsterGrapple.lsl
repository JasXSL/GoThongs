#ifndef __MonsterGrapple
#define __MonsterGrapple

// Set by LocalConf
#define gotTable$monsterGrapple$flags db4$0				// int - Flags sent to QTE. See got Events. Default 0.
#define gotTable$monsterGrapple$duration db4$1			// float - Max grapple duration in seconds. Default 300.
#define gotTable$monsterGrapple$predelay db4$2			// float - Time in seconds before QTE starts. Default 0.	
#define gotTable$monsterGrapple$buttonDelay db4$3		// float - Min time between pressing buttons in tap arrows mode. Default 0	
#define gotTable$monsterGrapple$stages db4$4			// int - Stages for QTE. Default 30 (which is good for left/right mode).	
#define gotTable$monsterGrapple$monsterFlags db4$5		// int - Monster flags to set and clear when grapple starts and ends. Default Monster$RF_IMMOBILE|Monster$RF_PACIFIED|Monster$RF_NOROT|Monster$RF_NO_SPELLS
#define gotTable$monsterGrapple$strip db4$6				// bool - If true, strips players during the grapple.
#define gotTable$monsterGrapple$noQte db4$7				// bool - Do not use a quicktime event, you must manually call gotMonsterGrapple$end to end it (or wait for duration to time out).
#define gotTable$monsterGrapple$host db4$8				// str - Sets this monster's ID for tag team grapples
#define gotTable$monsterGrapple$failTimeout db4$9		// float - Timeout in seconds after failing a QTE before ending the grapple.
#define gotTable$monsterGrapple$needsTest db4$10		// bool - Used in hookups. When set. We will run LocalConf$canHookup(hupClientIndexes). Use grappleOnHupClientTest( poseIndexes ) with the template to automate this flag. hupClientIndexes are indices for gotTable$monsterGrappleHup


// Set at runtime
#define gotTable$monsterGrapple$HUP_TARG db4$50			// key - The other NPC involved in a HUP
#define gotTable$monsterGrapple$HUP_HOSTNAME db4$51		// str - Hookup hostname
#define gotTable$monsterGrapple$GRAPPLE_TARGS db4$52	// key player1, key player2... - Players involved in a grapple
#define gotTable$monsterGrapple$DUMMY_MODE db4$53		// bool - Do not do damage, and allow manual unsit
#define gotTable$monsterGrapple$ANIM_NPC db4$54			// str - Idle anim for the NPC (HUP_A_NPC)
#define gotTable$monsterGrapple$ANIM_PC db4$55			// arr - Idle anim(s) for the PC
#define gotTable$monsterGrapple$GRAPPLE_ACTIVE db4$56	// bool - Grapple is active

#define gotMonsterGrapple$getTargs() \
	llJson2List(db4$fget(gotTable$monsterGrapple, gotTable$monsterGrapple$GRAPPLE_TARGS))
#define gotMonsterGrapple$isDebug() \
	((int)db4$fget(gotTable$monsterGrapple, gotTable$monsterGrapple$DUMMY_MODE))
#define gotMonsterGrapple$getHupTarg() db4$fget(gotTable$monsterGrapple, gotTable$monsterGrapple$HUP_TARG)
#define gotMonsterGrapple$getHupHostname() db4$fget(gotTable$monsterGrapple, gotTable$monsterGrapple$HUP_HOSTNAME)
#define gotMonsterGrapple$getAnimNPC() db4$fget(gotTable$monsterGrapple, gotTable$monsterGrapple$ANIM_NPC)
#define gotMonsterGrapple$getAnimPC() llJson2List(db4$fget(gotTable$monsterGrapple, gotTable$monsterGrapple$ANIM_PC))
#define gotMonsterGrapple$isGrappleActive() ((int)db4$fget(gotTable$monsterGrapple, gotTable$monsterGrapple$GRAPPLE_ACTIVE))

// gotTable$monsterGrappleHup is an indexed table that stores JSON arrays with client data for tag teams where this NPC is a client
#define gotMonsterGrappleConst$hup$hostname 0			// str - Unique name for the pose
#define gotMonsterGrappleConst$hup$pos 1				// vec - Position relative to host
#define gotMonsterGrappleConst$hup$rot 2				// rot - Rotation relative to host
#define gotMonsterGrappleConst$hup$clientIdleAnim 3		// str - base animation for this NPC
#define gotMonsterGrappleConst$hup$pcIdleAnim 4			// str - base animation for the PC victim
#define gotMonsterGrappleConst$hup$hostIdleAnim 5		// str - base animation for the host NPC
#define gotMonsterGrappleConst$hup$resync_time 6		// float - Will restart the animation after this nr of seconds. Useful if the host and victim use the same animation for the original grapple and the hookup.
#define gotMonsterGrappleConst$hup$camPos 7				// vec - Camera position. Or ZERO_VECTOR to leave undefined.
#define gotMonsterGrappleConst$hup$camTarg 8			// vec - Camera position. Requires pos to not be ZERO_VECTOR
#define gotMonsterGrappleConst$hup$numTargs 9			// int - Sets the number of targets that this pose supports. Defaults to 1
#define gotMonsterGrappleConst$hup$conditions 10		// cond0, cond0data, cond0Inverse, cond1, cond1data, cond1inverse... - 3-strided array of pose conditions. See below:
	#define gotMonsterGrappleHupCond$sex 0					// int - Genital flags required for the pose, checked against all targets.
	#define gotMonsterGrappleHupCond$fxFlags 1				// int - FX flags must have these set. Checked against all targets.
	
#define gotMonsterGrapple$getHupClientPosePose(idx) llJson2List(db4$get(gotTable$monsterGrappleHup, idx))

#define gotMonsterGrappleEvt$start 0						// Note: Players will probably not be seated in this event. Use it to turn off custom NPC logic.
#define gotMonsterGrappleEvt$end 1							// void
#define gotMonsterGrappleEvt$qteComplete 2					// (bool)succes - QTE completed for all players
#define gotMonsterGrappleEvt$onButton 3						// (key)victim_hud, (bool)success - Used in classic QTEs when a victim clicks a button
#define gotMonsterGrappleEvt$onClientAnim 4					// (str)npcAnim, (str/arr)playerAnims - Raised by the client in hookup mode when the client triggers an animation on the host
#define gotMonsterGrappleEvt$hookupStart 5					// (str)hostName - Raised on hookup start. Hostname is empty if we are hosting.
#define gotMonsterGrappleEvt$seated 6						// Players have been seated now.
#define gotMonsterGrappleEvt$onHookupClientReq 7			// void - Raised we request to hook up to a host

// METHODS
#define gotMonsterGrappleMethod$grappleClosestConal 1		// float arc, float range, int grappleFlags, int minPlayers, int maxPlayers, bool debug - Attempts to grapple players that are inside of a cone in front of the monster
#define gotMonsterGrappleMethod$start 2						// (arr)huds, (int)fxFlags, (bool)debug - Force starts a grapple
#define gotMonsterGrappleMethod$enable 3					// bool enable - Enable or disable grapples
#define gotMonsterGrappleMethod$end 4						// void - Ends any ongoing grapple
#define gotMonsterGrappleMethod$seqAnim 5					// (str)npc_anim, (arr)pc_anims, (float)resync_dly, (bool)is_looping - Runs an animation. If npc_anim is empty it is ignored. If resync_dly is set, it stops all animation, sleeps for resync_dly and restarts them.
#define gotMonsterGrappleMethod$cam 6						// [vec player0_cam_pos, vec player0_cam_targ], [p1camPos, p1camTarg]... - Updates camera for one or more players. If only one entry is received, it is set for ALL victims.
#define gotMonsterGrappleMethod$reqte 7						// int numButtons, int preDelay, int buttonDelay, int flags - Restarts quick time event

// hookups
#define gotMonsterGrappleMethod$hup$end 100					// Ends a hookup for all NPCs that are hooked to us
#define gotMonsterGrappleMethod$hup$hostStart 101			// str hostname, (arr)victim_huds, (int)debug - A host has announced that they have started a hookup
#define gotMonsterGrappleMethod$hup$hostAck 102				// str hostname, (arr)victim_huds - Sent in response to clientAck
#define gotMonsterGrappleMethod$hup$clientAck 103			// void - Sent in response to hostStart
#define gotMonsterGrappleMethod$hup$clientStart 104			// void - Client is aligned and has started
#define gotMonsterGrappleMethod$hup$viablePoses 105			// (arr)indexes - Replied after sending LocalConf$canHookup and includes viable indexes mapping to gotTable$monsterGrappleHup

#define gotMonsterGrapple$start(targ, huds, fxFlags, debug) runMethod((str)targ, "got MonsterGrapple", gotMonsterGrappleMethod$start, (list)mkarr((list)huds) + (fxFlags) + (debug), TNN)
#define gotMonsterGrapple$grappleClosestConal(targ, arc, range, grappleFlags, minPlayers, maxPlayers, debug) \
	runMethod((str)targ, "got MonsterGrapple", gotMonsterGrappleMethod$grappleClosestConal, (list)(arc) + (range) + (grappleFlags) + (minPlayers) + (maxPlayers) + (debug), TNN)
#define gotMonsterGrapple$seqAnim(targ, npc_anim, pc_anims, resync, is_looping) runMethod((str)targ, "got MonsterGrapple", gotMonsterGrappleMethod$seqAnim, (list)(npc_anim) + (pc_anims) + (resync) + (is_looping), TNN)
#define gotMonsterGrapple$enable(targ, enable) runMethod((str)targ, "got MonsterGrapple", gotMonsterGrappleMethod$enable, (list)(enable), TNN)
#define gotMonsterGrapple$end(targ) runMethod((str)targ, "got MonsterGrapple", gotMonsterGrappleMethod$end, [], TNN)
#define gotMonsterGrapple$cam(targ, cams) runMethod((str)targ, "got MonsterGrapple", gotMonsterGrappleMethod$cam, (list)mkarr(cams), TNN)
#define gotMonsterGrapple$camSingle(targ, camPos, camTarg) runMethod((str)targ, "got MonsterGrapple", gotMonsterGrappleMethod$cam, (list)mkarr((list)(camPos)+(camTarg)), TNN)
#define gotMonsterGrapple$reqte(targ, numButtons, preDelay, buttonDelay, flags) runMethod((str)targ, "got MonsterGrapple", gotMonsterGrappleMethod$reqte, (list)(numButtons) + (preDelay) + (buttonDelay) + (flags), TNN)


#define gotMonsterGrapple$hup$end() runOmniMethod("got MonsterGrapple", gotMonsterGrappleMethod$hup$end, [], TNN)
#define gotMonsterGrapple$hup$hostStart(hostname, victimHuds, debug) runOmniMethod("got MonsterGrapple", gotMonsterGrappleMethod$hup$hostStart, (list)hostname + mkarr(victimHuds) + (debug), TNN)
#define gotMonsterGrapple$hup$clientAck(host) runMethod(host, "got MonsterGrapple", gotMonsterGrappleMethod$hup$clientAck, [], TNN)
#define gotMonsterGrapple$hup$hostAck(client, hostname, victim_huds) runMethod(client, "got MonsterGrapple", gotMonsterGrappleMethod$hup$hostAck, (list)(hostname) + mkarr((list)victim_huds), TNN)
#define gotMonsterGrapple$hup$clientStart(host) runMethod(host, "got MonsterGrapple", gotMonsterGrappleMethod$hup$clientStart, [], TNN)
#define gotMonsterGrapple$hup$viablePoses(poses) runMethod((str)LINK_THIS, "got MonsterGrapple", gotMonsterGrappleMethod$hup$viablePoses, (list)mkarr(poses), TNN)



#define cf$hup$addClientPose( hostName, posOffs, rotOffs, myIdleAnim, pcIdleAnim, hostIdleAnim, resync_time, camPos, camTarg, numTargs, conditions ) \
	db4$insert(gotTable$monsterGrappleHup, mkarr((list)(hostName) + (posOffs) + (rotOffs) + (myIdleAnim) + (pcIdleAnim) + (hostIdleAnim) + (resync_time) + (camPos) + (camTarg) + (numTargs) + mkarr((list)conditions)))
// quick macro for animating that can be used as a direct drop-in for legacy method hup$clientAnim
#define gotMonsterGrapple$hostAnim(pcAnim, hostAnim) \
	gotMonsterGrapple$seqAnim(gotMonsterGrapple$getHupTarg(), hostAnim, pcAnim, 0, FALSE)
// Quick macro to get the first grappled player
#define gotMonsterGrapple$firstPlayer() llGetOwnerKey(l2k(gotMonsterGrapple$getTargs(), 0))
#define gotMonsterGrapple$firstHud() l2k(gotMonsterGrapple$getTargs(), 0)


#endif
