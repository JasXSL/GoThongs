#define GameMethod$buildGame 1		// NULL - Spawn a monster and start the game
#define GameMethod$exitGame 2		// (bool)victory - Game completed!
#define GameMethod$startGame 3		// [(arr)turns], Sent from host
#define GameMethod$setTurn 4		
#define GameMethod$loss 5			// 

#define GameEvt$gameStarted 1		
#define GameEvt$gameEnded 2
#define GameEvt$flags_changed 3			// (int)flags
#define GameEvt$my_turn 4				// (bool)my_turn

#define GameFlag$STARTED 1			// 
#define GameFlag$LOST 2				// 
#define GameFlag$myTurn 0x4			// 

#define GameShared$FLAGS "a"				// (int)
#define GameShared$TURNS "b"				// (arr)players
#define GameShared$CURRENT_TURN "c"			// (int)turn
