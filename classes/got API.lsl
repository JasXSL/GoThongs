/*
	
	Start by listening to GotAPI$chan(llGetOwner()) or the agent you want to listen to
	Example listen event:
	listen(integer chan, string name, key id, string message){
        idOwnerCheck
        
        if(llGetSubString(message, 0, 2) == "AA|"){
            list data = llJson2List(llGetSubString(message, 3, -1));
            integer action = llList2Integer(data, 0);
            data = llDeleteSubList(data, 0, 0);
            
            // Action is now the action received and data is the task data
            if(action == GotAPI$actionIni){
                // This action is sent when the Game of Thongs API script is reset
                // Here we can subscribe to all the actions:
                GotAPI$bindThis(id);
            }
            
            // All game of thongs HUD events are received
            else if(action == GotAPI$actionEvt){
                // This is basically just the onEvt event received as JSON array
                string script = llList2String(data, 0);
                integer evt = llList2Integer(data, 1);
                data = llJson2List(llList2String(data, 2));
                
                
                
            }
            
        }
        
    }

*/

#define GotAPIEvt$bound 1			// Reply once an API listener has been bound
#define GotAPIEvt$unbound 2	

#define GotAPIMethod$list 0			// Owner only, outputs currently bound APIs in chat

// output actions
#define GotAPI$actionIni 1			// void | Sent to everyone
#define GotAPI$actionEvt 2			// (str)script, (int)event, (var)data | Send when an event is received

// input commands
#define GotAPI$cmdBind 1			// (key)id OR empty | Binds a key to receive events from the HUD
#define GotAPI$cmdUnbind 2			// (key)id OR emtpy | Unbinds a key from receiving events from the HUD
#define GotAPI$cmdEmulateEvent 3	// (str)script, (int)evt, (arr)data | Owner only, emulates an event

#define GotAPI$chan(owner) (playerChan(owner)+4000)

#define GotAPI$buildCommand(task, data) "GA|"+llList2Json(JSON_ARRAY, [task]+data)
#define GotAPI$buildAction(task, data) "AA|"+llList2Json(JSON_ARRAY, [task]+data)

// Sends a command to to an API
#define GotAPI$sendCommand(apiKey, command, data) llRegionSayTo(apiKey, GotAPI$chan(llGetOwnerKey(apiKey)), GotAPI$buildCommand(command, data))


// Targ is the API, recipient is the key of who should receive the events
#define GotAPI$bind(targ, recipient) GotAPI$sendCommand(targ, GotAPI$cmdBind, [recipient])
#define GotAPI$bindThis(targ) GotAPI$bind(targ, "")
#define GotAPI$unbind(targ, recipient) GotAPI$sendCommand(targ, GotAPI$cmdUnbind, [recipient])
#define GotAPI$unbindThis(targ) GotAPI$unbind(targ, "")
#define GotAPI$emulateEvent(targ, script, evt, data) GotAPI$sendCommand(targ, GotAPI$cmdEmulateEvent, ([script, evt, mkarr(data)]))
