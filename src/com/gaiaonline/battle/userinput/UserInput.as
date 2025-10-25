package com.gaiaonline.battle.userinput
{
	import com.gaiaonline.battle.ApplicationInterfaces.IUIFramework;
	import com.gaiaonline.battle.Globals;
	import com.gaiaonline.battle.ItemManager.RingItemManager;
	import com.gaiaonline.battle.gateway.BattleEvent;
	import com.gaiaonline.battle.gateway.BattleGateway;
	import com.gaiaonline.battle.gateway.BattleMessage;
	import com.gaiaonline.battle.map.CollisionMap;
	import com.gaiaonline.battle.map.MapIt;
	import com.gaiaonline.battle.map.MapRoom;
	import com.gaiaonline.battle.newactors.ActorManager;
	import com.gaiaonline.battle.newactors.BaseActor;
	import com.gaiaonline.battle.newrings.Ring;
	import com.gaiaonline.battle.ui.uiactionbar.UiItemBar;
	import com.gaiaonline.flexModulesAPIs.globalevent.GlobalEvent;
	import com.gaiaonline.utils.DisplayObjectUtils;
	import com.gaiaonline.utils.FrameTimer;
	import com.gaiaonline.utils.KeyDownLimiter;
	
	import flash.display.InteractiveObject;
	import flash.events.EventDispatcher;
	import flash.events.KeyboardEvent;
	import flash.geom.Point;
		
	public class UserInput extends EventDispatcher
	{		
		private var keys:Array;

		private var navigationKeys:ActionKeys = new ActionKeys;		

		public static const NULL_MOVEDIR:Number = -1000;
		private var _moveDir:Number = NULL_MOVEDIR;
		
		private var _selectedActor:BaseActor = null;
		
		public static const MOVE_LEFT:String = "Move Left";
		public static const MOVE_RIGHT:String = "Move Right";
		public static const MOVE_UP:String = "Move Up";
		public static const MOVE_DOWN:String = "Move Down";
		public static const MOVE_TO_TARGET:String = "Move to Target";
		public static const SELECT_RING_SLOT_1:String = "Use / Select Ring Slot 1";
		public static const SELECT_RING_SLOT_2:String = "Use / Select Ring Slot 2";
		public static const SELECT_RING_SLOT_3:String = "Use / Select Ring Slot 3";
		public static const SELECT_RING_SLOT_4:String = "Use / Select Ring Slot 4";
		public static const SELECT_RING_SLOT_5:String = "Use / Select Ring Slot 5";
		public static const SELECT_RING_SLOT_6:String = "Use / Select Ring Slot 6";
		public static const SELECT_RING_SLOT_7:String = "Use / Select Ring Slot 7";
		public static const SELECT_RING_SLOT_8:String = "Use / Select Ring Slot 8";
		public static const SELECT_SELF:String = "Select Self";
		public static const SELECT_CREW_MEMBER_2:String = "Select Crew Member 2";
		public static const SELECT_CREW_MEMBER_3:String = "Select Crew Member 3";
		public static const SELECT_CREW_MEMBER_4:String = "Select Crew Member 4";
		public static const SELECT_CREW_MEMBER_5:String = "Select Crew Member 5";
		public static const SELECT_CREW_MEMBER_6:String = "Select Crew Member 6";
		public static const SELECT_NEXT_ENEMY:String = "Select Next Enemy";
		public static const OPEN_CLOSE_RING_INVENTORY:String = "Open / Close Ring Inventory";
		public static const OPEN_CLOSE_PDA:String = "Open / Close PDA";
		public static const OPEN_GLOBAL_MINIMAP:String = "Open Global MiniMap";
		public static const OPEN_LOCAL_MINIMAP:String = "Open Local MiniMap";		
		public static const OPEN_ACTIVE_TASK_PANEL:String = "Open Active Task Panel";				
		public static const OPEN_COMPLETED_TASK_PANEL:String = "Open Completed Task Panel";						
		public static const KNEEL_STAND:String = "Kneel / Stand Up";
		public static const REPLY_TO_WHISPER:String = "Reply To Whisper";	
		
		public static const RING_AUTO_FIRE:String = "Ring Auto Fire";	
				
		private var _gateway:BattleGateway = null;
		private var _uiFramework:IUIFramework = null;
		private var _actorManager:ActorManager = null;		
		
		private var _isCharging:Boolean = false;
		private var _keyControlTabActive:Boolean = false;
		private var _optionPanelOpen:Boolean = false;		
		
		private var _allowRingUse:Boolean = true;
		
		public function UserInput(gateway:BattleGateway, uiFramework:IUIFramework, actorManager:ActorManager):void{
			this._gateway = gateway;
						
			this._uiFramework = uiFramework;
			this._actorManager = actorManager;

			DisplayObjectUtils.addWeakListener(GlobalEvent.eventDispatcher, GlobalEvent.GLOBAL_FLAGS_LOADED, onGlobalFlagsLoaded);						
		}

		private var _keyLimiter:KeyDownLimiter;		
		public function init():void{
			this._keyLimiter = new KeyDownLimiter(this._uiFramework.stage, 1);
			this._keyLimiter.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown, false, 0, true);			
			this._keyLimiter.addEventListener(KeyboardEvent.KEY_UP, onKeyUp, false, 0, true);

			DisplayObjectUtils.addWeakListener(GlobalEvent.eventDispatcher, GlobalEvent.ACTOR_SELECTED, onActorSelected);
			DisplayObjectUtils.addWeakListener(GlobalEvent.eventDispatcher, GlobalEvent.START_CHARGING, onStartCharging);
			DisplayObjectUtils.addWeakListener(GlobalEvent.eventDispatcher, GlobalEvent.STOP_CHARGING, onStopCharging);											 			
			DisplayObjectUtils.addWeakListener(GlobalEvent.eventDispatcher, GlobalEvent.MAP_SLIDE_COMPLETE, onMapSlideDone);	
			DisplayObjectUtils.addWeakListener(GlobalEvent.eventDispatcher, GlobalEvent.TUTORIAL_CLOSED, onTutorialClosed);
			DisplayObjectUtils.addWeakListener(GlobalEvent.eventDispatcher, GlobalEvent.KEY_CONTROL_TAB_ACTIVE, onKeyControlTabActive);
			DisplayObjectUtils.addWeakListener(GlobalEvent.eventDispatcher, GlobalEvent.OPTION_PANEL_OPEN_STATE_CHANGE, onOptionPanelOpenStateChange);
			DisplayObjectUtils.addWeakListener(GlobalEvent.eventDispatcher, GlobalEvent.ALLOW_RING_USE, onAllowRingUse);
		}
		
		private function onAllowRingUse(event:GlobalEvent):void{
			_allowRingUse = event.data.allow;
		}	

		private function onKeyControlTabActive(evt:GlobalEvent):void{
			var data:Object = evt.data;
			this._keyControlTabActive = data.active;						
		}

		private function onOptionPanelOpenStateChange(evt:GlobalEvent):void{
			var data:Object = evt.data;
			this._optionPanelOpen = data.open;						
		}
		
		private function onStartCharging(e:GlobalEvent):void {
			this._isCharging = true;
		}
		private function onStopCharging(e:GlobalEvent):void {
			this._isCharging = false;
		}
				
		private function onActorSelected(e:GlobalEvent):void {
			this._selectedActor = e.data.actor;
		}
		
		private function onGlobalFlagsLoaded(e:GlobalEvent):void {
			this.loadKeys();
		}

		//*** Keyboard Events
		
		private function getDefaultKeys():Array{
			// This was originally written only using keycodes (kcodes), which is fine as a way to uniquely determine
			// which key is mapped to what.  But it's not sufficient for figuring out what to display in a UI to indicate
			// the assigned key. 
			// So I glommed on charcodes, which we use as a default for rendering if we don't know what to do based
			// on keycode.  Look at KeyCode.as to see how this is used.
			// -- Mark Rubin
			
			// codeName is ourn internal name, so we can change the display name in a release, and still be able
			// to map their previous keyboard bindings that they saved from a previous session.
			// index is the display order for the item, so we can change the sort order if they've saved bindings
			// out from a previous session
			var dk:Array = [
				 {index:0,codeName:"MoveLeft",name:MOVE_LEFT,kcodes:[37,65,-1],charcodes:[0,65,-1]},
				 {index:1,codeName:"MoveRight",name:MOVE_RIGHT,kcodes:[39,68,-1],charcodes:[0,68,-1]},
				 {index:2,codeName:"MoveUp",name:MOVE_UP,kcodes:[38,87,-1],charcodes:[0,87,-1]},
				 {index:3,codeName:"MoveDown",name:MOVE_DOWN,kcodes:[40,83,-1],charcodes:[0,83,-1]},					 
				 {index:4,codeName:"SelectRingSlot1",name:SELECT_RING_SLOT_1,kcodes:[49,-1,-1],charcodes:[49,-1,-1]},
				 {index:5,codeName:"SelectRingSlot2",name:SELECT_RING_SLOT_2,kcodes:[50,-1,-1],charcodes:[50,-1,-1]},
				 {index:6,codeName:"SelectRingSlot3",name:SELECT_RING_SLOT_3,kcodes:[51,-1,-1],charcodes:[51,-1,-1]},
				 {index:7,codeName:"SelectRingSlot4",name:SELECT_RING_SLOT_4,kcodes:[52,-1,-1],charcodes:[52,-1,-1]},
				 {index:8,codeName:"SelectRingSlot5",name:SELECT_RING_SLOT_5,kcodes:[53,-1,-1],charcodes:[53,-1,-1]},
				 {index:9,codeName:"SelectRingSlot6",name:SELECT_RING_SLOT_6,kcodes:[54,-1,-1],charcodes:[54,-1,-1]},
				 {index:10,codeName:"SelectRingSlot7",name:SELECT_RING_SLOT_7,kcodes:[55,-1,-1],charcodes:[55,-1,-1]},
				 {index:11,codeName:"SelectRingSlot8",name:SELECT_RING_SLOT_8,kcodes:[56,-1,-1],charcodes:[56,-1,-1]},
				 // UGH!  I goofed up and we released with my having the codeName for selecting self as SelectRingSlot9
				 // -- Mark Rubin	
				 {index:12,codeName:"SelectRingSlot9",name:SELECT_SELF,kcodes:[32,-1,-1],charcodes:[32,-1,-1]},				 
				 {index:13,codeName:"SelectCrew2",name:SELECT_CREW_MEMBER_2,kcodes:[-1,-1,-1],charcodes:[-1,-1,-1]},
				 {index:14,codeName:"SelectCrew3",name:SELECT_CREW_MEMBER_3,kcodes:[-1,-1,-1],charcodes:[-1,-1,-1]},
				 {index:15,codeName:"SelectCrew4",name:SELECT_CREW_MEMBER_4,kcodes:[-1,-1,-1],charcodes:[-1,-1,-1]},
				 {index:16,codeName:"SelectCrew5",name:SELECT_CREW_MEMBER_5,kcodes:[-1,-1,-1],charcodes:[-1,-1,-1]},
				 {index:17,codeName:"SelectCrew6",name:SELECT_CREW_MEMBER_6,kcodes:[-1,-1,-1],charcodes:[-1,-1,-1]},
				 				 
				 {index:18,codeName:"SelectNextEnemy",name:SELECT_NEXT_ENEMY,kcodes:[192,81,-1],charcodes:[96,113,-1]},				 				 
				 {index:19,codeName:"OpenCloseRingInv",name:OPEN_CLOSE_RING_INVENTORY,kcodes:[82,-1,-1],charcodes:[82,-1,-1]},
				 {index:20,codeName:"OpenClosePDA",name:OPEN_CLOSE_PDA,kcodes:[80,-1,-1],charcodes:[80,-1,-1]},
				 {index:21,codeName:"OpenCloseMiniMap",name:OPEN_GLOBAL_MINIMAP,kcodes:[77,-1,-1],charcodes:[77,-1,-1]},
				 {index:22,codeName:"OpenCloseLocalMiniMap",name:OPEN_LOCAL_MINIMAP,kcodes:[76,-1,-1],charcodes:[76,-1,-1]},
				 {index:23,codeName:"OpenCloseActiveTaskPanel",name:OPEN_ACTIVE_TASK_PANEL,kcodes:[84,-1,-1],charcodes:[84,-1,-1]},
				 {index:24,codeName:"OpenCloseCompletedTaskPanel",name:OPEN_COMPLETED_TASK_PANEL,kcodes:[67,-1,-1],charcodes:[67,-1,-1]},				 				 
				 {index:26,codeName:"KneelStand",name:KNEEL_STAND,kcodes:[75,-1,-1],charcodes:[75,-1,-1]},	
				 {index:27,codeName:"ReplyToWhisper",name:REPLY_TO_WHISPER,kcodes:[8,-1,-1],charcodes:[8,-1,-1]},					 

				 {index:28,codeName:"MoveToTarget",name:MOVE_TO_TARGET,kcodes:[71,-1,-1],charcodes:[71,-1,-1]},
				 {index:29,codeName:"RingAutoFire",name:RING_AUTO_FIRE,kcodes:[16,-1,-1],charcodes:[16,-1,-1]}	 
				];
			dk.sortOn("index", Array.NUMERIC);				

			return dk;
		}
		
		private var _moveTimer:FrameTimer = new FrameTimer(onMoveTimer);
		private function tryToMove(keyBit:int):void {
			if (this._isCharging) {
				return;
			}	

			this.navigationKeys.setKeyDown(keyBit);
			this.updateMove();	

			this._moveTimer.start(125);
		}
		
		private function moveToTarget():void
		{
			if (this._selectedActor)
			{
				ActorManager.getInstance().myActor.moveToTarget(this._selectedActor);
			}				
		}

		private function get isKeyMappingsPanelOpen():Boolean {
			return this._optionPanelOpen && this._keyControlTabActive;
		}
		
		private function onKeyDown(evt:KeyboardEvent):void{
			if (this.isKeyMappingsPanelOpen) {	
				return;
			}
			if (this.getFocusObject() == null){				
				switch (this.getKeyFunction(evt.keyCode)){ // No Focus	
					case REPLY_TO_WHISPER:
						GlobalEvent.eventDispatcher.dispatchEvent(new GlobalEvent(GlobalEvent.WHISPER_AUTOFILL, {}));
						break;					
					case MOVE_LEFT:
						tryToMove(ActionKeys.LEFT);
						break;
						
					case MOVE_RIGHT:			
						tryToMove(ActionKeys.RIGHT);
						break;
						
					case MOVE_UP:
						tryToMove(ActionKeys.UP);											
						break;
						
					case MOVE_DOWN:
						tryToMove(ActionKeys.DOWN);																
						break;
						
					case MOVE_TO_TARGET:
						moveToTarget();
						break;
					
					case SELECT_RING_SLOT_1: // 1
						selectRing(0);
						break;	
					case SELECT_RING_SLOT_2: // 2
						selectRing(1);
						break;
					case SELECT_RING_SLOT_3: // 3
						selectRing(2);
						break;
					case SELECT_RING_SLOT_4: // 4
						selectRing(3);
						break;
					case SELECT_RING_SLOT_5: // 5
						selectRing(4);
						break;	
					case SELECT_RING_SLOT_6: // 6
						selectRing(5);
						break;
					case SELECT_RING_SLOT_7: // 7
						selectRing(6);
						break;
					case SELECT_RING_SLOT_8: // 8
						selectRing(7);
						break;
					case SELECT_NEXT_ENEMY: // tab	(tab 9,  ~192)														
						this._actorManager.selectNextTarget(!evt.shiftKey);
						break;	
					case RING_AUTO_FIRE:
						GlobalEvent.eventDispatcher.dispatchEvent(new GlobalEvent(GlobalEvent.RING_AUTO_FIRE_DOWN,null));
						break;
									
					default:
//						trace(evt.keyCode, this.getKeyFunction(evt.keyCode));
						break;							
				}		
				
			}			
		}
		
		public function getKeyFunction(keyCode:int):String{
			
			var f:String = "na";
			if (Globals.uiManager.optionPanel) {
				var keys:Array = Globals.uiManager.optionPanel.keyControlsData;
				
				for (var i:int = 0; i < keys.length; i++){
					if (keys[i].kcodes[0] == keyCode || keys[i].kcodes[1] == keyCode || keys[i].kcodes[2] == keyCode){
						f = keys[i].name;
						break;
					}
				}
			}
			
			/*if (keyCode == 16){
				f = RING_AUTO_FIRE;
			}*/
			return f;
			
		}
		
		private var combat:Boolean = false;
		private function selectRing(slot:int):void{
			if (!this._allowRingUse) {
				return;
			}
											
			var r:Ring = ActorManager.getInstance().myActor.getRingAt(slot);
			if ( r != null){				
				RingItemManager.getInstance().selectedSlot = slot;
				GlobalEvent.eventDispatcher.dispatchEvent(new GlobalEvent(GlobalEvent.RING_KEY_DOWN, null));
					
			}
		}

		private static const ENTER_KEY:uint = 13;
		private static const FWDSLASH_KEY:uint = 191;
		private static const F12_KEY:uint = 123;
		public function onKeyUp(evt:KeyboardEvent):void{
			if (this.isKeyMappingsPanelOpen || !Globals.uiManager.optionPanel) {				
				return;			
			}			
			
			if (this.getFocusObject() == null){	
				
				/*optionPanel key codes, keycodes*/
				var optionKeys:Object = Globals.uiManager.optionPanel.keyControlsData;
			
				
				/*checking if correct key was pressed to use ring*/
				for(var i:int = 0; i<= UiItemBar.MAX_BAR_SLOT_INDEX ; i++){
					for(var n:int = 0; n<3; n++){
						if(evt.keyCode == optionKeys[i+4].kcodes[n]){
							GlobalEvent.eventDispatcher.dispatchEvent(new GlobalEvent(GlobalEvent.RING_KEY_UP, null));
							//[fred] DELETE --- now done in Ring Manager
							//GlobalEvent.eventDispatcher.dispatchEvent(new GlobalEvent(GlobalEvent.CAST_RING, null));							
						}
					}
				}
			
				switch(evt.keyCode) {
					case ENTER_KEY:
						GlobalEvent.eventDispatcher.dispatchEvent(new GlobalEvent(GlobalEvent.CHAT_PANE_OPEN, {}));						
						break;
					case FWDSLASH_KEY:
						GlobalEvent.eventDispatcher.dispatchEvent(new GlobalEvent(GlobalEvent.CHAT_PANE_OPEN, {leadingText:"/", setFocus:true}));
						break; 					
				}
						
				
				switch (this.getKeyFunction(evt.keyCode)){
					case MOVE_LEFT:
						this.navigationKeys.clearKeyDown(ActionKeys.LEFT);
						this.stopMove();
						break
						
					case MOVE_RIGHT:
						this.navigationKeys.clearKeyDown(ActionKeys.RIGHT);						
						this.stopMove();
						break;
						
					case MOVE_UP:
						this.navigationKeys.clearKeyDown(ActionKeys.UP);						
						this.stopMove();
						break;
						
					case MOVE_DOWN:
						this.navigationKeys.clearKeyDown(ActionKeys.DOWN);						
						this.stopMove();
						break;
					
					case KNEEL_STAND:
						Globals.uiManager.sitStand();
						break;		

					case OPEN_CLOSE_RING_INVENTORY:
						Globals.uiManager.openCloseInventory();
						break;
						
					case OPEN_CLOSE_PDA:
						Globals.uiManager.openClosePDAWidget();
						break;					
					case OPEN_GLOBAL_MINIMAP:
						Globals.uiManager.openGlobalMiniMap();
						break;
					case OPEN_LOCAL_MINIMAP:
						Globals.uiManager.openLocalMiniMap();
						break;
					case OPEN_ACTIVE_TASK_PANEL:
						Globals.uiManager.openActiveQuestLog();
						break;
					case OPEN_COMPLETED_TASK_PANEL:
						Globals.uiManager.openCompetedQuestLog();
						break;										
					case SELECT_SELF: // Space bar  (selecte my self) _
						this._actorManager.selectActor(ActorManager.getInstance().myActor.actorId); 
						break;
					case SELECT_CREW_MEMBER_2: // n (select first teamate)
						this._actorManager.selectActor(ActorManager.getInstance().myActor.teamList[1]);
						break;
					case SELECT_CREW_MEMBER_3: // m (select first teamate)
						this._actorManager.selectActor(ActorManager.getInstance().myActor.teamList[2]);
						break;					
					case SELECT_CREW_MEMBER_4: // < (select first teamate)
						this._actorManager.selectActor(ActorManager.getInstance().myActor.teamList[3]);
						break;
					case SELECT_CREW_MEMBER_5: // > (select first teamate)
						this._actorManager.selectActor(ActorManager.getInstance().myActor.teamList[4]);
						break;
					case SELECT_CREW_MEMBER_6: // ? (select first teamate)
						this._actorManager.selectActor(ActorManager.getInstance().myActor.teamList[5]);												
						break;
					
					case RING_AUTO_FIRE:
						GlobalEvent.eventDispatcher.dispatchEvent(new GlobalEvent(GlobalEvent.RING_AUTO_FIRE_UP,null));
						break;	
					
					default:
						if (evt.keyCode == F12_KEY)  // special dev key, leave it down here in case user overrides it
						{
							Globals.uiManager.toggleAdminPanel();
						}
						break;
				}
			}
			else{
				if (evt.charCode == 13){
					if (this.getFocusObject() == null){
						GlobalEvent.eventDispatcher.dispatchEvent(new GlobalEvent(GlobalEvent.CHAT_PANE_OPEN, {}));
					}else{
						this.clearFocus();
					}	
				}
			}
		}
		
		private function loadKeys():void{
			this.keys = this.getDefaultKeys();

			GlobalEvent.eventDispatcher.dispatchEvent(new GlobalEvent(GlobalEvent.DEFAULT_KEY_BINDINGS_LOADED, {keys:this.keys}));			

			var keyMapValues:Array = new Array();
			for each (var keyMap:Object in this.keys) {
				keyMapValues.push(keyMap.codeName);
			}
			var msg:BattleMessage = new BattleMessage("getNkvp", {keys:keyMapValues});
			msg.addEventListener(BattleEvent.CALL_BACK, onKeysLoaded);
			this._gateway.sendMsg(msg);
		}
		
		private function onKeysLoaded(evt:BattleEvent):void{
			var responseObj:Object = evt.battleMessage.responseObj[0].values;
			var restoredKeys:Array = new Array(); // we'll build our new keys array into this array
			var defaultKeys:Array = this.getDefaultKeys().concat(); // here's a copy of the defaults
			// we'll store arrays of all the kcodes and charcodes we've seen when we restore; we'll use this later
			// to make sure any new key bindings don't conflict with any changes the user has made and saved out
			var kcodesList:Array = new Array();
			var charcodesList:Array = new Array();
			if (responseObj != null) {
				for (var codeName:String in responseObj) { 
					var keyMap:Object = responseObj[codeName];
					if (keyMap == null) { // this could happen if we've added a new key that was never saved out before
						continue;
					}
					var rehydratedMap:Object = new Object();
					rehydratedMap.codeName = codeName;
					// We used to save out the kcodes and charcodes with the full strings "kcodes" and "charcodes", but
					// then changed to the abbreviated "k" and "c".
					var kcodes:Object = keyMap.kcodes || keyMap.k;
					var charcodes:Object = keyMap.charcodes || keyMap.c;
					rehydratedMap.kcodes = kcodes;					
					rehydratedMap.charcodes = charcodes;
					kcodesList = kcodesList.concat(rehydratedMap.kcodes);
					charcodesList = charcodesList.concat(rehydratedMap.charcodes);					
					
					
					// now remove it from the default key map copy; when we're done, any left
					// in the default key map copy will be concatenated, so we pick up new or unsaved default key mappings
					var len:uint = defaultKeys.length;
					var j:int = 0; // weird AS bug; if I initialize and declare in the for statement, j's value is not resetting to 0 each time through the outer loop
					for (j = 0; j < len; ++j) {
						if (defaultKeys[j].codeName == rehydratedMap.codeName) {
							// this allows us to change the display name for our key bindings
							rehydratedMap.name = defaultKeys[j].name;
							// this allows us to change the index for our key bindings
							rehydratedMap.index = defaultKeys[j].index;
							defaultKeys.splice(j, 1);
							break;
						}
					}
					// add each key map we've saved and add it
					restoredKeys.push(rehydratedMap);						
				}
			}
			// What remains in defaultKeys are any key bindings that have been added to the default list since the last time
			// we serialize d out this user's bindings.  We want to add them, but we have to make sure that any new key bindings from
			// new keys have not been used by the user as alternate bindings for the previously existing entries.
			len = defaultKeys.length;
			for (var k:int = 0; k < len; ++k) {
				// kcodes and charcodes
				var tempMap:Object = defaultKeys[k];
				var kcodeslen:int = tempMap.kcodes.length;
				for (var index:int = 0; index < kcodeslen; ++index) {
					var kcode:int = tempMap.kcodes[index];
					var charcode:int = tempMap.charcodes[index];
					if (kcode > -1 && kcodesList.indexOf(kcode) > -1) {
						tempMap.kcodes[index] = -1;
					}
					if (charcode > -1 && charcodesList.indexOf(charcode) > -1) {
						tempMap.charcodes[index] = -1;
					}					
				}
			}
						
			// combine our restored keys with any remaining default keys
			this.keys = restoredKeys.concat(defaultKeys);
			
			this.keys.sortOn("index", Array.NUMERIC);
							
			if (this.keys != null){
				if (Globals.uiManager.optionPanel) {
					Globals.uiManager.optionPanel.buildKeyControls(this.keys);
				}
			}
			
			
			GlobalEvent.eventDispatcher.dispatchEvent(new GlobalEvent(GlobalEvent.KEY_BINDINGS_LOADED, {keys:this.keys}));
			BattleMessage(evt.target).removeEventListener(	BattleEvent.CALL_BACK, onKeysLoaded );	
		}
				
		///  keyboard move
		private function onMoveTimer():void{
			this.updateMove();
		}
		
		private function updateMove():void{
			if (this.getFocusObject() != null || !this._uiFramework.map.isMapLoaded() ){
				if(this.moveDir != NULL_MOVEDIR ){
					this.navigationKeys.clearAll();
					
					this.moveDir = NULL_MOVEDIR;
					if (this._uiFramework.map.isMapLoaded()){
						this.stopMove();
					}
				}
				return;
			}
								
			if (this.navigationKeys.isAnyKeyDown()){
				var dx:Number = 0;
				var dy:Number = 0;
				if (this.navigationKeys.isKeyDown(ActionKeys.LEFT)) dx -= 1;
				if (this.navigationKeys.isKeyDown(ActionKeys.RIGHT)) dx += 1;
				if (this.navigationKeys.isKeyDown(ActionKeys.UP)) dy -= 1;
				if (this.navigationKeys.isKeyDown(ActionKeys.DOWN)) dy += 1;
				
				if (dx == 0 && dy == 0){
					if (this.moveDir != NULL_MOVEDIR){
						this.stopMove();
					}
				}
				else{
					var dir:Number = Math.atan2(dy, dx) * 180/Math.PI;
					if (dir != this.moveDir){
						this.moveDir = dir;						
						moveToPointInDirection( dx, dy );
					}
				}
				
			}else if (this.moveDir != NULL_MOVEDIR){
					this.stopMove();
			}
		}
		
		private function moveToPointInDirection( dx:Number, dy:Number ):void
		{
			if( 0 == dx && 0 == dy)
			{
				// [bgh] ssssssh, you messed up!
				return;
			}
			
			// this._uiFramework.map.getColliionTypeAt(tx, ty)
			var mr:MapRoom = this._uiFramework.map.getCurrentMapRoom();
			var offset:Point =  mr.getRoomOffset();
			var scale:Number = mr.scale/100;
		 	var x:int = _actorManager.myActor.x;
			var y:int = _actorManager.myActor.y;
			
			var maxWidth:int = MapIt.gameWidth + offset.x;
			var maxHeight:int = MapIt.gameHeight + offset.y;
			
			var lastGoodPoint:Point = new Point(x, y);
			var changePoint:Point = new Point(dx * 8, dy * 8);
			
			for(;;)
			{
				var newPoint:Point = lastGoodPoint.add(changePoint);
				
				if( offset.x > newPoint.x || offset.y > newPoint.y || maxWidth < newPoint.x || maxHeight < newPoint.y )
				{
					// [bgh] scanned until we were out of the room
					break;
				}
				
				var collisionType:uint = this._uiFramework.map.getColliionTypeAt(newPoint.x, newPoint.y);
				if( CollisionMap.isTerrianTypeOffLimitsToNonFly( collisionType ) )
				{
					// [bgh] found a bad one, keep the last good one.
					break;
				}

				lastGoodPoint = newPoint;
			}
			
			ActorManager.getInstance().myActor.moveTo(Math.round( (lastGoodPoint.x - offset.x) / scale), Math.round( (lastGoodPoint.y - offset.y) / scale) );
		}
		
		public function stopMove():void{
			
			if(!this.navigationKeysDown()){
				this._moveTimer.stop();
				this.moveDir = NULL_MOVEDIR;				

				ActorManager.getInstance().myActor.moveStop();
			}
		}
		
		public function navigationKeysDown():Boolean{
			return this.navigationKeys.isAnyKeyDown();
		}
				
		private function onMapSlideDone(e:GlobalEvent):void {
			this.updateKeyMove();
		}
		
		private function updateKeyMove():void{
			this.moveDir = NULL_MOVEDIR;
		}		
		
		private function get moveDir():Number {
			return this._moveDir;
		}
		
		private function set moveDir(dir:Number):void {
			this._moveDir = dir;
			GlobalEvent.eventDispatcher.dispatchEvent(new GlobalEvent(GlobalEvent.MOVE_DIR_CHANGED, {moveDir:this._moveDir}));
		}
		
		//** Focus *****
		private function getFocusObject():InteractiveObject{
			var focusObj:InteractiveObject = null;
			try {
				focusObj = this._uiFramework.stage.focus;
			} catch(e:Error) {
				// returning null then				
			} 
			
			return focusObj;
		}
		
		private function clearFocus():void{
			//trace("CLEAR FOCUS ", this.getFocusObject())						
			this._uiFramework.stage.focus = null;
		}
		
		private function onTutorialClosed(e:GlobalEvent):void {
			this.clearFocus();	
		}				
	}
}

import flash.utils.setTimeout;
import flash.utils.clearTimeout;	

internal class ActionKeys  // right now just for cursor keys, could be so much more.  Also should be in the public package under com.gaiaonline.util somewhere
{
	public static const UP:int = 0x01;
	public static const DOWN:int = 0x02;
	public static const LEFT:int = 0x04;
	public static const RIGHT:int = 0x08;
	
	private var _navigationKeys:int = 0;  // a bitmask of zero or more of the above
	private var _keyTimeout:uint = 0;
	public function isAnyKeyDown():Boolean
	{
		return _navigationKeys != 0;  
	}
	public function isKeyDown(keyBit:int):Boolean
	{
		return (_navigationKeys & keyBit) != 0; 
	}
	public function setKeyDown(keyBit:int):void
	{
		_navigationKeys |= keyBit;

		// this helps the bug where losing focus (i.e. alt-tab, system dialog, etc) before getting 
		// a key-up will make the player character keep moving forever.  It exploits how keydown
		// events repeat when a key's held down - a side-effect of GUI key events that can never really 
		// change.  -kja
		// [bgh] it seems this works for most cases but not all. If you hold 
		// up, then add left, then remove left, you still have up pressed but
		// the keydown has stopped firing. This causes problems for people who
		// only use key nav
		// clearTimeout(_keyTimeout);
		// _keyTimeout = setTimeout(clearAll, 500);
	}
	public function clearKeyDown(keyBit:int):void
	{
		_navigationKeys &= ~keyBit;
	}
	public function clearAll():void
	{
		_navigationKeys = 0;
	}
}
