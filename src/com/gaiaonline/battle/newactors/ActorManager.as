package com.gaiaonline.battle.newactors
{
	import com.gaiaonline.battle.ApplicationInterfaces.IFileVersionManager;
	import com.gaiaonline.battle.ApplicationInterfaces.ILinkManager;
	import com.gaiaonline.battle.ApplicationInterfaces.IUIFramework;
	import com.gaiaonline.battle.GlobalTexts;
	import com.gaiaonline.battle.Globals;
	import com.gaiaonline.battle.ItemLoadManager.ConsumableManager;
	import com.gaiaonline.battle.ItemManager.ConsumableItemManager;
	import com.gaiaonline.battle.ItemManager.RingItemManager;
	import com.gaiaonline.battle.Loot.LootManager;
	import com.gaiaonline.battle.Loot.Orbs;
	import com.gaiaonline.battle.gateway.BattleEvent;
	import com.gaiaonline.battle.gateway.BattleGateway;
	import com.gaiaonline.battle.gateway.BattleMessage;
	import com.gaiaonline.battle.map.GameTransitionManager;
	import com.gaiaonline.battle.map.Map;
	import com.gaiaonline.battle.map.MapObject;
	import com.gaiaonline.battle.map.MapRoom;
	import com.gaiaonline.battle.map.envobjects.BasicSwitch;
	import com.gaiaonline.battle.monsters.MonsterLoadManager;
	import com.gaiaonline.battle.newrings.RingLoadManager;
	import com.gaiaonline.battle.ui.AlertTypes;
	import com.gaiaonline.battle.ui.DialogWindow;
	import com.gaiaonline.battle.ui.DialogWindowFactory;
	import com.gaiaonline.battle.ui.DialogWindowTypes;
	import com.gaiaonline.battle.ui.UiAcceptDecline;
	import com.gaiaonline.battle.userServerSettings.IGameSettings;
	import com.gaiaonline.battle.userServerSettings.IGraphicOptionsSettings;
	import com.gaiaonline.battle.utils.BattleUtils;
	import com.gaiaonline.display.wordbubble.BubbleEvent;
	import com.gaiaonline.events.ProgressEventManager;
	import com.gaiaonline.flexModulesAPIs.actorInfo.ActorTypes;
	import com.gaiaonline.flexModulesAPIs.gatewayInterfaces.IBattleMessage;
	import com.gaiaonline.flexModulesAPIs.globalevent.GlobalEvent;
	import com.gaiaonline.utils.DisplayObjectUtils;
	import com.gaiaonline.utils.queue.QueueHelper;
	
	import flash.display.DisplayObject;
	import flash.display.Stage;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.utils.clearTimeout;
	import flash.utils.getTimer;
	import flash.utils.setTimeout;
	
	public class ActorManager extends EventDispatcher
	{
		private static var actors:Object = new Object();
		public var mapActors:Object = new Object();
		public var mapOffset:Point = new Point(0,0);		

		private var _currentRoomId:String;		
		private var _currentInstanceId:String;		
		
		public var transPos:Point = new Point(0,0);
		
		private var _selectedActor:BaseActor;
		private var _selectedActorId:String;
		private var lastTargetSelect:Number = 0;	
		
		private var _isCharging:Boolean = false;
		//public var isCasting:Boolean = false;
		
		private var lootManager:LootManager;

		private var npcTimeOut:int = -1;
		
		private var _showSpawn:Boolean = false;

		private var _disableDialog:Boolean = false;
		private var _dialogOpen:Boolean = false;
		private var _isMoviePlaying:Boolean = false;			
		
		private var _gateway:BattleGateway = null;
		private var _uiFramework:IUIFramework = null;		
		private var _linkManager:ILinkManager = null;
		private var _fileVersionManager:IFileVersionManager = null;
		private var _ringAnimationDisplay:String = "all";
				
		private var _friendsList:Array = [];
		
		private var _nullParamActorObj:Object = null;
		
		private var _progressManager:ProgressEventManager;
		
		private var _mapActorPositionAdjuster:MapActorPositionAdjuster = null;
		
		private var _monsterLoadManager:MonsterLoadManager;
		
		private var _autoMoveInRange:Boolean = true;
		
		public function ActorManager(singletonEnforcer:SingletonEnforcer, stage:Stage, gateway:BattleGateway, uiFramework:IUIFramework, linkManager:ILinkManager, fileVersionManager:IFileVersionManager, progressManager:ProgressEventManager):void{			
			if(!singletonEnforcer){
				throw new Error("ActorManager is a singleton!  Use ActorManager.getInstance");
			}
			
			this._gateway = gateway;
			this._uiFramework = uiFramework;
			this._linkManager = linkManager;
			this._fileVersionManager = fileVersionManager;
			this._progressManager = progressManager;
			
			this._monsterLoadManager = new MonsterLoadManager(this._uiFramework, this._linkManager.baseURL, this._fileVersionManager, this._gateway);
			
			_mapActorPositionAdjuster = new MapActorPositionAdjuster(_uiFramework.map);
			
			
			this.lootManager = new LootManager(this._gateway, this._uiFramework, this._linkManager);
			
			this._gateway.addEventListener(BattleEvent.IGNORE_LIST, onIgnoreListUpdate, false, 0, true);

			this._nullParamActorObj = new Object();
			this._nullParamActorObj.actorID = null;
			this._nullParamActorObj.params = null;	

			stage.addEventListener(MouseEvent.MOUSE_UP, onActorMouseUp, false, 0, true);						
			
			GlobalEvent.eventDispatcher.addEventListener(GlobalEvent.PLAYER_INFO_RECEIVED, onPlayerInfoReceived, false, 0, true);			
			GlobalEvent.eventDispatcher.addEventListener(GlobalEvent.CONVERSATION_END, onConversationEnd, false, 0, true);
			GlobalEvent.eventDispatcher.addEventListener(GlobalEvent.CREW_LIST_SELECTION_CHANGE, onCrewListSelectionChange, false, 0, true);			
			GlobalEvent.eventDispatcher.addEventListener(GlobalEvent.START_CHARGING, onStartCharging, false, 0, true);			
			GlobalEvent.eventDispatcher.addEventListener(GlobalEvent.STOP_CHARGING, onStopCharging, false, 0, true);
			GlobalEvent.eventDispatcher.addEventListener(GlobalEvent.INSTANCE_CHANGED_FOR_ACTOR, onActorInstanceChanged, false, 0, true);
			GlobalEvent.eventDispatcher.addEventListener(GlobalEvent.SHOW_SPAWN_STATE_CHANGED, onShowSpawnStateChanged, false, 0, true);			
			GlobalEvent.eventDispatcher.addEventListener(GlobalEvent.DIALOG_OPEN_STATUS_CHANGED, onDialogOpenStatusChanged, false, 0, true);						
			GlobalEvent.eventDispatcher.addEventListener(GlobalEvent.DISABLE_DIALOG, onDisableDialog, false, 0, true);
			GlobalEvent.eventDispatcher.addEventListener(GlobalEvent.CLEAR_SELECTED_TARGET, onClearSelectedTarget, false, 0, true);						
									
			// -- Friends list (since the world list fetches this first, and we have the world list before we have other UI,
			// it's convenient and more efficient, although a little ugly, to listen for the friends list before the rest of the UI
			// is created, and to store it somewhere that exists before the rest of the UI is up.)
			DisplayObjectUtils.addWeakListener(GlobalEvent.eventDispatcher, GlobalEvent.FRIENDS_UPDATE, onFriendsUpdate);
			GlobalEvent.eventDispatcher.addEventListener(GlobalEvent.USER_SETTINGS_LOADED, onGraphicsOptionChanged, false, 0, true);
			GlobalEvent.eventDispatcher.addEventListener(GlobalEvent.GRAPHIC_OPTIONS_CHANGED, onGraphicsOptionChanged, false, 0, true);
			
			DisplayObjectUtils.addWeakListener(GlobalEvent.eventDispatcher, GlobalEvent.MAP_SLIDE_START, onMapSlideStart);
			DisplayObjectUtils.addWeakListener(GlobalEvent.eventDispatcher, GlobalEvent.MAP_SLIDE_COMPLETE, onMapSlideDone);
			
			
			DisplayObjectUtils.addWeakListener(GlobalEvent.eventDispatcher, GlobalEvent.MAP_WARP_OUT_TRANSITION_START, onWarpOutTransitionStart);
			DisplayObjectUtils.addWeakListener(GlobalEvent.eventDispatcher, GlobalEvent.MAP_WARP_WITHIN_ROOM, onWarpWithinRoom);
			
			GlobalEvent.eventDispatcher.addEventListener(GlobalEvent.MAP_LOAD_ZONE, onMapLoadZone, false, 0, true);			
			GlobalEvent.eventDispatcher.addEventListener(GlobalEvent.MAP_DONE, onWarp, false, 0, true);
			
			GlobalEvent.eventDispatcher.addEventListener(GlobalEvent.MAP_ROOM_LEAVE, onMapRoomLeave, false, 0, true);
			GlobalEvent.eventDispatcher.addEventListener(GlobalEvent.NEW_ROOM_ENTERED, onNewRoomEnter, false, 0, true);
			
			GlobalEvent.eventDispatcher.addEventListener(GlobalEvent.PLAY_MOVIE, onPlayMovie, false, 0, true);
			GlobalEvent.eventDispatcher.addEventListener(GlobalEvent.MOVIE_DONE, onMovieDone, false, 0, true);
			
			
			///***** Add Friend
			this._gateway.addEventListener(BattleEvent.INVITE_TO_BE_FRIEND, onInviteToBeFriend, false, 0, true);
			this._gateway.addEventListener(BattleEvent.INVITE_TO_FRIEND_COMPLETED, onInviteToFriendCompleted, false, 0, true);
		}	

		private function onMapRoomLeave(event:GlobalEvent):void{
			var data:Object = event.data;			
			_currentRoomId = data.newRoomId;					
			_currentInstanceId = data.newInstanceId;
		}
		
		private function onNewRoomEnter(event:GlobalEvent):void{
			clearActors();
		}

		public function requestRoomActorInfo():void{
			var msg:BattleMessage = new BattleMessage("getRoomActorInfo",null);		
			this._gateway.sendMsg(msg);
		}

		private function onWarpWithinRoom(event:GlobalEvent):void{
			var data:Object = event.data;
			var transition:int = data.transition;
			transPos.x = data.x;
			transPos.y = data.y;
			myActor.playWarpAnimations(	getTransitionOutFrame(transition), 
										getTransitionInFrame(transition), 
										data.x, data.y);
		}

		private function onWarpOutTransitionStart(event:GlobalEvent):void{
			var data:Object = event.data;
			transPos.x = data.x;
			transPos.y = data.y;
			if(myActor){
				myActor.stopMove();
				transitionOut(data.transition, myActor.actorId);
			}
		}

		private function onDialogOpenStatusChanged(e:GlobalEvent):void {
			var data:Object = e.data;
			this._dialogOpen = e.data.open;
		}	

		private function onDisableDialog(e:GlobalEvent):void {
			var data:Object = e.data;
			this._disableDialog = e.data.disable;
		}	
			
		private function onShowSpawnStateChanged(e:GlobalEvent):void {
			this._showSpawn = e.data.show;
		}
		
		private function onFriendsUpdate(e:GlobalEvent):void {
			_friendsList = e.data.friendsList;			
		}
		
		//ingore list logic should probably go in it's own class/manager
		public function onIgnoreListUpdate(evt:BattleEvent):void{
			var queueHelper:QueueHelper = new QueueHelper();
			var l:Array  = evt.battleMessage.responseObj[0].ignoreList;
			if (l != null && l.length > 0){
				myActor.ignoreList = l.concat();
			}
		}
		
		private function onActorInstanceChanged(event:GlobalEvent):void
		{
			var instanceId:String = event.data.instanceId;
			var roomId:String = event.data.roomId;
			var eventActor:BaseActor = event.data.actor;
			
			if(	eventActor == myActor )
			{
				for each(var actor:BaseActor in ActorManager.actors)
				{
					if (actor.instanceId == instanceId && actor.roomId == roomId){
						actor.visible = true;
					} else {
						actor.visible = false;
					}
				}
			}
		}
				
		private function onStartCharging(e:GlobalEvent):void {
			this._isCharging = true;
		}
		private function onStopCharging(e:GlobalEvent):void {
			this._isCharging = false;
		}
		
		private function initListeners():void{
			this._gateway.addEventListener(BattleEvent.ACTOR_UPDATE, onActorUpdate, false, 0, true);
			
			this._gateway.addEventListener(BattleEvent.ACTOR_LEAVE, onActorLeave, false, 0, true);
			this._gateway.addEventListener(BattleEvent.ACTOR_ACTION, onActorAction, false, 0, true);
			this._gateway.addEventListener(BattleEvent.LOOT, onLoot, false, 0, true);
			this._gateway.addEventListener(BattleEvent.QUICK_MOVE, onQuickMove, false, 0, true);
			
		}
		
		
		private function addActor(actorObj:Object):BaseActor{			
//			var txtTrace:String = "Add Actor  Id:" + actorObj.id + " Name: " + actorObj.nm + " Type: " + actorObj.tp + " Url: " + actorObj.url + " Pos: " + actorObj.px + "," +  actorObj.py; 
			
			if (actorObj.instanceId == null){
				actorObj.instanceId = myActor.instanceId;
			}
						
			if (actorObj.display == "avatarMonster"){
				this._monsterLoadManager.addUnloadException(actorObj.url);				
			}
			
			var actor:BaseActor = ActorManager.actorIdToActor(actorObj.id);
			if (actor == null && actorObj.id != null && actorObj.tp != null && actorObj.px != null && actorObj.py != null && actorObj.display != null){	
				actor = new BaseActor(this._gateway, this._uiFramework, this._fileVersionManager, this._linkManager, _mapActorPositionAdjuster, actorObj.id, actorObj.nm, actorObj.url, actorObj.display, ActorTypes.intToType(actorObj.tp), actorObj.aids, actorObj.ownerId, this._monsterLoadManager);											
				ActorManager.hashActorIdToActor(actorObj.id, actor); 
				
				actor.updateActor(actorObj, 0);
				actor.redrawMcPos();			
								
				_uiFramework.map.addActor(actor);
				
				// Events	
				actor.addEventListener(MouseEvent.MOUSE_DOWN, onActorMouseDown, false, 0, true);
				
				actor.addEventListener(BaseActor.ACTOR_GONE, onActorGone, false, 0, true);				
				actor.addEventListener(BaseActor.TEAMMATE_GONE, onTeammateGone, false, 0, true);
				actor.addEventListener(BaseActorEvent.TARGET_UNSET, onActorTargetUnset, false, 0, true);				
								
				actor.updateMcPosition();
				
				//-- Check if in Teamate
				if (myActor && myActor.myTeam != null && myActor.myTeam[actorObj.id] != null){
					GlobalEvent.eventDispatcher.dispatchEvent(new GlobalEvent(GlobalEvent.TEAM_UPDATED, {}));
				}
				
				// Dialog Update
				if (actorObj.aids != null && actorObj.aids.indexOf("NPC") >= 0){											
					this.dialogStat(actorObj.id);
				}
				
				if (myActor != null){				
					if (	(actorObj.roomName != this._currentRoomId) || 
							(actorObj.instanceId != _currentInstanceId) ){
						actor.visible = false;
					}
				}
				
				//-- Chekc if selected actor
				if (this.selectedActorId == actorObj.id){					
					this.selectTarget(actor);
				}																														
				var toPickUp:BaseActor = BaseActor.pickUpArtists[actorObj.id];
				if (toPickUp) {
					toPickUp.tryToBePickedUp(actorObj.id);	
				}		
			}else if ( actor != null ){	
				actor.updateActor(actorObj, this._gateway.pingTimer.lagTime);
			}else if (actorObj.tp == 3 && actorObj.px != null && actorObj.py != null && actorObj.roomName != null){
				log ("  Spawn")
				if (this._showSpawn){				
					actorObj.url = "none";
					actorObj.display = "Spawner";
					var spawnedActor:BaseActor = new BaseActor(this._gateway, this._uiFramework, this._fileVersionManager, this._linkManager, _mapActorPositionAdjuster, actorObj.id, actorObj.nm, actorObj.url, actorObj.display, actorObj.tp, actorObj.aids, actorObj.ownerId, this._monsterLoadManager);									
					ActorManager.hashActorIdToActor(actorObj.id, spawnedActor); 
		
					actor.updateActor(actorObj, 0);

					_uiFramework.map.addActor(actor);
//					GlobalEvent.eventDispatcher.dispatchEvent(new GlobalEvent(GlobalEvent.MAP_ACTOR_ADD, {actor:actor}));
					actor.updateMcPosition();
				}							
			} else {
				requestRoomActorInfo()
			}
			
			return actor;		
		}

		private function dialogStat(actorId:String):void {
			var params:Object = {npc:actorId};
			var msg:BattleMessage = new BattleMessage("dialogStatus", params)
			this._gateway.sendMsg(msg);						
		}

		
		private function onConversationEnd(e:GlobalEvent):void {
			this.updateNpcsDialogStat();
		}
		
		private function updateNpcsDialogStat():void{
			for each (var actor:BaseActor in ActorManager.actors){
				if (actor.actorType == ActorTypes.NPC){
					this.dialogStat(actor.actorId);
				}
			}
		}
		public static function resetAllTargetType():void{
			for each (var actor:BaseActor in ActorManager.actors){
				actor.resetTargetType();
			}
		}
		
		
		///--- Movie PLayer Event
		private function onPlayMovie(evt:GlobalEvent):void{
			this._isMoviePlaying =  evt.data.hideNpcDialog as Boolean;
			if (this._isMoviePlaying){
				resetAllTargetType();
			}
		}
		private function onMovieDone(evt:GlobalEvent):void{
			this._isMoviePlaying = false;
		}
		
			
		//--
		private function addMapActor(actorObj:Object):void{
			//trace("ADD ENV MAP ACTOR : ", actorObj.url);
			if (this._uiFramework.map != null && this._uiFramework.map.isMapLoaded()){		
				var mapRoom:MapRoom = this._uiFramework.map.getRoomById(actorObj.roomName);
				if (mapRoom)
				{
					var mobj:MapObject = mapRoom.getMapObj(actorObj.url);				
					if (mobj != null){		
						var envObj:EnvActor = new EnvActor(actorObj, mobj, this._gateway, this._uiFramework);
						this.mapActors[actorObj.id] = envObj;						
						mobj.updateState(actorObj);			
					}
				}
			}
		}

		private function onMapSlideStart(event:GlobalEvent):void{
			transPos.x = event.data.x;
			transPos.y = event.data.y;
			
			transitionOut(event.data.transition, myActor.actorId);
			requestRoomActorInfo();
		}

		private function onMapSlideDone(evt:GlobalEvent):void{
			myActor.stand();
			myActor.roomId = evt.data.newRoomId;
			myActor.setPosition(this.transPos.x, this.transPos.y);
		}

							
		// Events --------------------------		

		
		private function onActorUpdate(evt:BattleEvent):void{
			this.actorUpdate(evt.battleMessage);
		}						
		
		private var _mapAndNPCReady:Boolean = false;
		private var _monsterPreloadDone:Boolean = true;
		private function onMapAndNPCsReady():void
		{
			DisplayObjectUtils.addWeakListener(GlobalEvent.eventDispatcher, GlobalEvent.MAP_WARP_IN_TRANSITION_COMPLETE, onNpcReadyIrisIn);
			this._mapAndNPCReady = true;
			if (this._monsterPreloadDone){
				_transitionManager.resumeWarpInTransition(this);
			}
		}
		private function onMonsterPreloadDone(evt:GlobalEvent):void{
			this._monsterPreloadDone = true;
			newMapRoomFetchNpcInfo();
			if (this._mapAndNPCReady){
				_transitionManager.resumeWarpInTransition(this);
			}
		}
		
		private function onNpcReadyIrisIn(ignoredEvent:GlobalEvent):void
		{
			GlobalEvent.eventDispatcher.removeEventListener(GlobalEvent.MAP_WARP_IN_TRANSITION_COMPLETE, onNpcReadyIrisIn);
			
			// [bgh] let the server know we finished loading the zone!
			var msg:BattleMessage = new BattleMessage("clientFinishedLoadingZone",null);		
			this._gateway.sendMsg(msg);	
		}
		
		private function getNextLoadPendingNPC():BaseActor{
			for each (var act:BaseActor in ActorManager.actors){
				if (act.actorType == ActorTypes.NPC && !act.getActorDisplay().isLoaded){
					return act;
				}
			}
			return null;
		}
		
		private function onNpcLoaded(evt:Event):void 
		{
			this.monitorNPCLoading();
		}
		
		private function monitorNPCLoading(forced:Boolean = false):void{
			var npc:BaseActor = this.getNextLoadPendingNPC();
			if (npc == null || forced){
				clearTimeout(this.npcTimeOut);
				this.npcTimeOut = -1;
				onMapAndNPCsReady();
			}else{
				if (this.npcTimeOut != -1){
					clearTimeout(this.npcTimeOut);
				}
				this.npcTimeOut = setTimeout(monitorNPCLoading, 10000, true);	
				npc.getActorDisplay().addEventListener(ActorDisplay.LOADED, onNpcLoaded);
			}	
		}
	
		private function actorUpdate(msg:IBattleMessage):void{
			var acs:Array = msg.responseObj as Array;
			var isNewActor:Boolean = false;				
			if(acs) {
				for each (var actorData:Object in acs) {
					if (actorData != null){								
						if (ActorManager.actorIdToActor(actorData.id)== null && this.mapActors[actorData.id] == null){													
							if (actorData.display == "env"){
								this.addMapActor(actorData);								
							}else{
								this.addActor(actorData);
								isNewActor = true;		
							}		
						}else{								
							if (this.mapActors[actorData.id] != null){									
								EnvActor(this.mapActors[actorData.id]).updateState(actorData, true);																	
							}else{																	
								var ba:BaseActor = ActorManager.actorIdToActor(actorData.id);
								ba.updateActor(actorData, this._gateway.pingTimer.lagTime);
								
								// [bgh] if they're in the same room, in the same instance, make them visible
								if (!ba.visible && ba.roomId == this._currentRoomId && ba.instanceId == this._currentInstanceId){										
									ba.visible = true;																		
									ba.setPosition(actorData.px, actorData.py);
									if (ba.actorId == this.selectedActorId){
										this.selectActor(ba.actorId);
									}
									if (myActor.myTeam[ba.actorId] != null){
										ba.isLeaving = false;		
									}
								}									
							}
						} 							
						//--******						
						//------- in or out/in(warp same room) Transition...
						if (actorData.transition != null){							
							if (!isNewActor && actorData.id != ActorManager.getInstance().myActor.actorId){								
								var fOut:String = this.getTransitionOutFrame(actorData.transition);
								var fIn:String = this.getTransitionInFrame(actorData.transition);
								if (fOut != null && fIn != null){
									ActorManager.actorIdToActor(actorData.id).playWarpAnimations(fOut, fIn, actorData.px, actorData.py);
								}								
							}else{
								this.transitionIn(actorData.transition, actorData.id);
							}
						}										
					}						
					
				}
			}
		}
		
		private function newMapRoomFetchNpcInfo():void
		{
			DisplayObjectUtils.addWeakListener(GlobalEvent.eventDispatcher, GlobalEvent.HACK_EVENT_PRE_ACTOR_UPDATE, waitForNpcToLoad);
			
			initListeners();
			
			var clientCanListen:BattleMessage = new BattleMessage("clientCanListen",null);
			this._gateway.sendMsg(clientCanListen);
			requestRoomActorInfo();
		}	
		
		private function waitForNpcToLoad(event:GlobalEvent):void
		{
			GlobalEvent.eventDispatcher.removeEventListener(GlobalEvent.HACK_EVENT_PRE_ACTOR_UPDATE, waitForNpcToLoad);
		
			// [bgh] start the big loop of detecting when NPCs are all loaded.
			this.monitorNPCLoading();
		}
		
		private function onActorLeave(evt:BattleEvent):void{
			//trace("On Actor Leave ", evt.battleMessage.responseObj.id)
			if (ActorManager.actorIdToActor(evt.battleMessage.responseObj.id) != null && evt.battleMessage.responseObj.id != myActor.actorId){								
				this.transitionOut(evt.battleMessage.responseObj.tt, evt.battleMessage.responseObj.id);
			}
		}	
		
		//*********************************************
		//****** used only for fps ring animation test
		//*********************************************
		private var _fpsRingId:String;
		private var _fpsRageLevel:String;
		private var _fpsAutoMoveNegative:Boolean = false;
		private function getRingAnimFps(rid:String, rl:String):void{
			if (rid  != this._fpsRingId || rl != this._fpsRageLevel){
				if (this._fpsRingId != null && this._fpsRageLevel){
					GlobalEvent.eventDispatcher.dispatchEvent(new GlobalEvent(GlobalEvent.FPS_MONITORING_STATE_CHANGED, {on:false}));
				}
				this._fpsRingId = rid;
				this._fpsRageLevel = rl;
				GlobalEvent.eventDispatcher.dispatchEvent(new GlobalEvent(GlobalEvent.FPS_MONITORING_STATE_CHANGED, {on:true, autoUpdate:false}));				
				
				var x:int = myActor.position.x;
				var y:int = myActor.position.y;
				if (this._fpsAutoMoveNegative){
					x -= 10;
					y -= 10;					
				}else{
					x += 10;
					y += 10;
				}
				this._fpsAutoMoveNegative = !this._fpsAutoMoveNegative;
				myActor.moveTo(x, y);
			} 
		}
		//*****************************************************
		
		
		private function onGraphicsOptionChanged(evt:GlobalEvent):void{
			var data:IGraphicOptionsSettings = evt.data as IGraphicOptionsSettings;
			if (data){
				this._ringAnimationDisplay = data.getRingAnimationDisplay();
			}
			var data2:IGameSettings = evt.data as IGameSettings;
			if (data2){
				this._autoMoveInRange = data2.getAutoMoveInRange()
			}
			
		}
		
		private function displayRingAnim(actorId:String, targetId:String = null ):Boolean{
			var result:Boolean = false;						
			if (this._ringAnimationDisplay == "me"){
				var playerId:String = myActor.actorId;
				result = (actorId == playerId || targetId == playerId)
			}else if (this._ringAnimationDisplay == "crew"){
				result = myActor.isOnMyTeam(actorId);
				
			}else{
				result = true;
			}		
			return result;
		}
		
		private function onActorAction(evt:BattleEvent):void{
						
			for (var i:int = 0; i < evt.battleMessage.responseObj.length; i++){
				var obj:Object = evt.battleMessage.responseObj[i];													
				
				if (this._uiFramework.ringAnimFpsTest) {
					this.getRingAnimFps(obj.rid, obj.rl);
				}
								
				if (obj.bmt == "std"){					
					//-- Play point target
					if (obj.point != null && obj.actorID != null){
						var cpa:BaseActor = ActorManager.actorIdToActor(obj.actorID);
						if (cpa != null){							
							if (obj.displayType == "external" && this.displayRingAnim(cpa.actorId) ){																	
								cpa.playRingAnimation(obj.rid, obj.rl, "point", new Point(obj.point.x, obj.point.y));
							}else if (obj.displayType == "internal" && RingLoadManager.contain(obj.rid)){
								cpa.playRingAnimation(obj.rid, obj.rl, "point", new Point(obj.point.x, obj.point.y));
							}
						}
					}			
					
					// Play all Hits Animation
					if (obj.hits != null){
						for (var hitIndex:int = 0; hitIndex < obj.hits.length; hitIndex ++){
							var hta:BaseActor = ActorManager.actorIdToActor(obj.hits[hitIndex]);
							if (hta != null && obj.rid != null && obj.rl != null){
								if (obj.displayType == "external" && this.displayRingAnim(obj.actorID, hta.actorId)){															
									hta.playRingAnimation(obj.rid, obj.rl, "target");
								}else if (obj.displayType == "internal" && RingLoadManager.contain(obj.rid)){
									hta.playRingAnimation(obj.rid, obj.rl, "target");
								}
							}
						}
					}
					if (obj.deflects != null){
						for (var deflectIndex:int = 0; deflectIndex < obj.deflects.length; deflectIndex ++){
							var dta:BaseActor = ActorManager.actorIdToActor(obj.deflects[deflectIndex]);
							if (dta != null){
								if (myActor.actorId == obj.actorID || dta.actorId == myActor.actorId){
									dta.playDeflects();
								}								
							}
						}
					}
					
					if (obj.reflects != null){
						for (var reflectIndex:int = 0; reflectIndex < obj.reflects.length; reflectIndex ++){
							var rfta:BaseActor = ActorManager.actorIdToActor(obj.reflects[reflectIndex]);
							if (rfta != null){
								if (myActor.actorId == obj.actorID || rfta.actorId == myActor.actorId){
									rfta.playReflects();
								}								
							}
						}
					}
					
					// Play Miss Animation 
					if (obj.misses != null){
						for (var missIndex:int = 0; missIndex < obj.misses.length; missIndex ++){
							var mta:BaseActor = ActorManager.actorIdToActor(obj.misses[missIndex]);
							if (mta != null){
								if (myActor.actorId == obj.actorID || mta.actorId == myActor.actorId){
									mta.playMiss();
								}								
							}
						}
					}
					
					// Play Resists Animation					
					if (obj.resists != null){
						for (var resistIndex:int = 0; resistIndex < obj.resists.length; resistIndex ++){
							var rta:BaseActor = ActorManager.actorIdToActor(obj.resists[resistIndex]);
							if (rta != null){
								if (myActor.actorId == obj.actorID || rta.actorId == myActor.actorId){
									rta.playResists();
								}								
							}
						}
					}
									
				}else if (obj.bmt == "action"){					
					if (obj.id != myActor.actorId || obj.delayed){						
						var ca:BaseActor = ActorManager.actorIdToActor(obj.id);
						
						var ta:Object;  // Get the target (actor or  Point )
						if (obj.tid != null){
							ta = ActorManager.actorIdToActor(obj.tid);
						}else{
							ta = new Point(obj.point.x, obj.point.y);
						}
						
						var tp:Point; /// Create the target Point
						if (ta != null && ca != null && ta is BaseActor && ta.actorId != ca.actorId){
							tp = new Point(BaseActor(ta).position.x, BaseActor(ta).position.y);
						}else if (ta != null && ta is Point){
							tp = new Point(ta.x, ta.y);
						}
						if (ca != null && tp != null){						
							ca.setDirection(tp);
						}
																	
						var speed:Number						
						if (obj.speed != null){ speed = obj.speed; }
						if (obj.displayType == "external" && ca != null && obj.rid != null && obj.rl != null && this.displayRingAnim(ca.actorId)){							
							ca.playRingAnimation(obj.rid, obj.rl, "caster" , ta, speed);
						}else if (obj.displayType == "internal" && ca != null && obj.rl != null ){
							//trace("[ActorManager onActorAction] - playAtack", obj.rl, ca.getActorDisplay(), obj.id, obj.tid)
							ca.playAttack(obj.rl, ta, speed);
						}
					}
				}
			}
		}
		
		private function onQuickMove(evt:BattleEvent):void{					
			var obj:Object = evt.battleMessage.responseObj[0];							
			if (ActorManager.actorIdToActor(obj.id) != null){				
				var targetPoints:Array = new Array();
				if (obj.targets != null){
					for each (var p:Object in obj.targets){
						targetPoints.push(new Point(p.x, p.y));						
					}
				}				
				ActorManager.actorIdToActor(obj.id).quickMove(obj.bmt, targetPoints, obj.time); 
			}
		}
		
		// mouse events
		
		private function onActorMouseDown(evt:MouseEvent):void{
			var ba:BaseActor = BaseActor(evt.currentTarget);
			if (ba.targetType != BaseActor.TARGETTYPE_FRIEND){
				var bap:Object = this.getSelectedActorOrSwitchUnderPoint(this._uiFramework.stage.mouseX, this._uiFramework.stage.mouseY);
				if (bap != null) {
					if (bap is BaseActor) {
						ba = bap as BaseActor;
					} else if (bap is BasicSwitch) {
						if (myActor.allowUsableUse){
							_nullParamActorObj.actorID = bap.actorId;
							trace("BASIC SWITCH  ??????   CHECK RADIUS -----------")							
							var msg2:BattleMessage = new BattleMessage("use", _nullParamActorObj);
							this._gateway.sendMsg(msg2);	
						}else if (myActor.isKtfo){
							GlobalEvent.eventDispatcher.dispatchEvent(new GlobalEvent(GlobalEvent.ALERT, {type:AlertTypes.YOU_ARE_DAZED_CANT_DO_THAT}));																																												
						}
						return;
					}
				}
			}
			if (ba != null) {
				if (ba.targetType == BaseActor.TARGETTYPE_POWERUSABLE) {
					onPowerUsableMouseEvent(ba);
				} else {
					GlobalEvent.eventDispatcher.dispatchEvent(new GlobalEvent(GlobalEvent.ACTOR_MOUSE_DOWN, {actor:ba}));					
					//if (evt.shiftKey){				
					//	onActorMouseSelect(ba);
					//	onActorMouseHoldDown(ba);
					//}else{
						onActorMouseHoldDown(ba);
						onActorMouseSelect(ba);
					//}
				}
			}
		}
		
		private function onPowerUsableMouseEvent(ba:BaseActor):void {
		 	if (!ba.isLeaving) {
		 		if (ba != this._selectedActor) {
		 			this.selectTarget(ActorManager.actorIdToActor(ba.actorId)); // moving this here prevents you from attacking the ball
		 		} else {
					GlobalEvent.eventDispatcher.dispatchEvent(new GlobalEvent(GlobalEvent.ACTOR_ATTACKED, {actor:ba}));
				}
				
			}
		}
		
		private function onActorMouseSelect(ba:BaseActor):void{
			var isDialogOpen:Boolean = (this._dialogOpen && !this._disableDialog) || this._isMoviePlaying;
			if (ba.Dialogable){				
				if (!isDialogOpen){							
					
					var e:BubbleEvent = new BubbleEvent(BubbleEvent.BTN_CLICK, ba);			
					GlobalEvent.eventDispatcher.dispatchEvent(e);
					
					// [Fred] Range Check now done on server					
					/*
					//---- Check if in range					
					var range:Number = 250;
					if (ba.range > 0){
						range = ba.range;
					}
					
					if ( myActor.checkRange(ba, range) ){
						var params1:Object = {npc:ba.actorId, opt:-1};
						var msg1:BattleMessage = new BattleMessage("dialog", params1);
						this._gateway.sendMsg(msg1);
					}else{
						var message:String = GlobalTexts.getNpcOutOfRangeText(ba.actorName);
						GlobalEvent.eventDispatcher.dispatchEvent(new GlobalEvent(GlobalEvent.CHATTABLE_MSG, { msg:message, type:"room", actorId:ba.actorId, actorName:ba.actorName}));						
					}	
					*/			
				}			
			}else if (!this._isCharging && !ActorManager.actorIdToActor(ba.actorId).isLeaving
				&& (ActorManager.actorIdToActor(ba.actorId).targetType == BaseActor.TARGETTYPE_SELF|| ActorManager.actorIdToActor(ba.actorId).targetType == BaseActor.TARGETTYPE_FRIEND)){
					this.selectTarget(ActorManager.actorIdToActor(ba.actorId));							
			}else if( ba.targetType == BaseActor.TARGETTYPE_ENEMY ){ // Usable
				var obj:Object = new Object();
				obj.actorID = ba.actorId;
				obj.params = null;			
				
				if (myActor.allowUsableUse){
					
					if (this._autoMoveInRange || myActor.checkRange(ba, ba.range)){	
						var msg:BattleMessage = new BattleMessage("use", obj);
						msg.addEventListener(BattleEvent.CALL_BACK, onUseCallBack);
						this._gateway.sendMsg(msg);
					}else{
						GlobalEvent.eventDispatcher.dispatchEvent(new GlobalEvent(GlobalEvent.ALERT, {type:AlertTypes.YOU_ARE_TOO_FAR}));
					}
					
				}else if (myActor.isKtfo){
					GlobalEvent.eventDispatcher.dispatchEvent(new GlobalEvent(GlobalEvent.ALERT, {type:AlertTypes.YOU_ARE_DAZED_CANT_DO_THAT}));					
				}
			}
		}
		private function onUseCallBack(evt:BattleEvent):void{
			trace("[ActorManager onUseCallBack]");
			BattleMessage(evt.target).removeEventListener(BattleEvent.CALL_BACK, onUseCallBack);	
			var rObj:Object = evt.battleMessage.responseObj;
						 
			for each (var response:Object in rObj) {
				if (response.hasOwnProperty("error") && response.error != null) {
					var error:uint = response.error;
					switch(error){
						case 201: //Out Of Range
							GlobalEvent.eventDispatcher.dispatchEvent(new GlobalEvent(GlobalEvent.ALERT, {type:AlertTypes.YOU_ARE_TOO_FAR}));
							break;								
					}
				}	
			}
		}
		
		private function onDialogCallBack(evt:BattleEvent):void{
			trace("[ActorManager onDialogCallBack]")
			BattleMessage(evt.target).removeEventListener(BattleEvent.CALL_BACK, onDialogCallBack);	
			var rObj:Object = evt.battleMessage.responseObj;
						 
			for each (var response:Object in rObj) {
				
				if (response.hasOwnProperty("error") && response.error != null) {
					var error:uint = response.error;
				}					
				if (error){
					var requestObj:Object = evt.battleMessage.requestObjUnsafeForModifying; 
					if (requestObj.npc){
						var actor:BaseActor = ActorManager.actorIdToActor(requestObj.npc);
						if (actor) {
							switch(error){
								case 201: //Out Of Range
									GlobalEvent.eventDispatcher.dispatchEvent(new GlobalEvent(GlobalEvent.ALERT, {type:AlertTypes.YOU_ARE_TOO_FAR}));
									break;								
							}
							
						}					
					}
			    }
			}					
		}
		
		private function onActorMouseHoldDown(ba:BaseActor):void{	
			
		}
		
		public function isMyActor(actorId:String):Boolean{
			return actorId == _myActorId;
		}
				
		
		//[fred] (GOOF BALL) ---- this is still use by PowerMeter 				
		private function onActCallBack(evt:BattleEvent):void{
			BattleMessage(evt.target).removeEventListener(BattleEvent.CALL_BACK, onActCallBack);	
			var rObj:Object = evt.battleMessage.responseObj;
			
			
			if (rObj != null && rObj.er != null && rObj.er == 1 && rObj.ercode != null){
				switch(parseInt(rObj.ercode)){
					case 301:
						//log("  Ivalide Actor...  Delete this actor", rObj.tid);
						this.removeActor(rObj.tid);
						break;
					case 201:
						//log("  Out Of Range  ", rObj.tid)
						if (ActorManager.actorIdToActor(rObj.tid) != null){
							ActorManager.actorIdToActor(rObj.tid).playOutOfRange();							
							requestRoomActorInfo();
						}
				}				
			}
			 
			for each (var response:Object in rObj) {
				if (response.hasOwnProperty("error") &&  //FS#34281  
				    response.error != null) {
					var error:uint = response.error;
					if (error) {
						var requestObj:Object = evt.battleMessage.requestObjUnsafeForModifying; 
					if (requestObj.ringSlot != null) {						
							var ringSlot:uint = requestObj.ringSlot;
							RingItemManager.getInstance().resetTimer(ringSlot);
							
							var actorId:String = requestObj.targetID;
							if (actorId) { 
								var actor:BaseActor = ActorManager.actorIdToActor(actorId);
								if (actor) {
									actor.playInvalidTarget();
								}					
							}
						}
					}
				}
			}
		}		
		
		private function onActorMouseUp(evt:MouseEvent):void{
			//trace("ActorManager------ ACTOR MOUSE UP -------------------------")
			if (this.selectedActor && this.selectedActor.targetType == BaseActor.TARGETTYPE_POWERUSABLE) {
				handlePowerMeter();
			} else {
				GlobalEvent.eventDispatcher.dispatchEvent(new GlobalEvent(GlobalEvent.ACTOR_MOUSE_UP, null));
				// [fred] DELETE --- now doen in ring Manager
				//this.cast();				
			}				
		}
		
		private function handlePowerMeter():void {
			if (this._isCharging){
				var msgObj:Object = new Object();						
				msgObj.actorID = this.selectedActor.actorId;
				var ragLv:int = Globals.uiManager.actionBar.stopCharging();
				msgObj.useParams = {ringRageLevel:ragLv};
				var useCMD:String = "use";

				var msg:BattleMessage = new BattleMessage(useCMD,msgObj);
				msg.addEventListener(BattleEvent.CALL_BACK, onActCallBack);						
				this._gateway.sendMsg(msg);	
			}
		}
		
		
			
		private var _transitionManager:GameTransitionManager = null;	
		
		private function onMapLoadZone(evt:GlobalEvent):void{
			this._monsterPreloadDone = false;
		}		
		private function onWarp(event:GlobalEvent):void{			
			this._mapAndNPCReady = false;
						
			_transitionManager = event.data.transitionManager;
			_transitionManager.haltWarpInTransition(this);
				
			
			myActor.roomId = this._currentRoomId;	
			myActor.setPosition(this.transPos.x, this.transPos.y);	
			
			if (!this._monsterPreloadDone){
				GlobalEvent.eventDispatcher.addEventListener(GlobalEvent.MONSTER_PRELOAD_DONE, onMonsterPreloadDone);				
				var ed:EventDispatcher = this._monsterLoadManager.preloadMonsters();
				this._progressManager.addProgressObject(ed, "Loading Monsters", 10);				
			}else{
				newMapRoomFetchNpcInfo();
			}	
					
		}
				
		private function clearActors():void{
			
			//log("Clear Actors", playerInfo.actor.roomId, map.getCurrentMapRoom().serverRoomId)
			
			var mRoomId:String = _currentRoomId
			var mInstanceId:String = _currentInstanceId
			for each (var baseActor:BaseActor in ActorManager.actors){					
				var aRoomId:String = baseActor.roomId;
				var aInstanceId:String = baseActor.instanceId;
				if (baseActor.actorId != _myActor.actorId && (mRoomId != aRoomId || mInstanceId != aInstanceId) && baseActor != myActor.pickedUpActor){
					//log("CLEAR ALL ACTOR")
					this.removeActor(baseActor.actorId);					
				}
			}

			GlobalEvent.eventDispatcher.dispatchEvent(new GlobalEvent(GlobalEvent.MAP_CLEAR_PROJECTILES, {}));
					
			//-- Clear env Object (Switch )
			for (var mapActorId:String in this.mapActors){		
				var envActor:EnvActor = EnvActor(this.mapActors[mapActorId]);		
				var mapActorRoomId:String = envActor.roomName;				
				var mapActorInstanceId:String = envActor.instanceId;
				if (mapActorRoomId != mRoomId || mapActorInstanceId != mInstanceId){					
					this.mapActors[mapActorId].dispose();
					delete this.mapActors[mapActorId];
				}				
			}			
		}
				
		public function removeActor(actorId:String):void{
			if (ActorManager.actorIdToActor(actorId) != null){	
				
				var ba:BaseActor = ActorManager.actorIdToActor(actorId);
				
				//---------------------
				//-- Clear target
				if (ba == this.selectedActor){
					this.clearSelectedTarget()
				}	
								
				if (myActor.myTeam[actorId] == null){				
					ba.removeEventListener(MouseEvent.MOUSE_DOWN, onActorMouseDown);
					ba.removeEventListener(BaseActor.ACTOR_GONE, onActorGone);					
					ba.removeEventListener(BaseActor.TEAMMATE_GONE, onTeammateGone);
					ba.removeEventListener(BaseActorEvent.TARGET_UNSET, onActorTargetUnset);
										
					_uiFramework.map.removeActor(ba);					
					
					ba.dispatchEvent(new Event(BaseActor.REMOVING_ACTOR_FROM_LIST));				
					ba.dispose();					
					delete ActorManager.actors[actorId];
					
				}else{				
					ba.visible = false;
					ba.isLeaving = false;
					GlobalEvent.eventDispatcher.dispatchEvent(new GlobalEvent(GlobalEvent.MAP_REMOVE_TEXT, {actor:ba}));
				}
			}
		}
		
		//--- Loot ----------
		private function onLoot(evt:BattleEvent):void{
			var ba:BaseActor = ActorManager.actors[evt.battleMessage.responseObj.id] as BaseActor;
			if (ba != null){
				this.lootManager.addLoots(evt.battleMessage.responseObj, ba);
			}
		}
		
		
		//---- Actor Transition --------
		public function transitionOut(tType:int, actorId:String):void{	
			log ("Transition out: ", tType, actorId)			
			var ba:BaseActor = ActorManager.actorIdToActor(actorId);			
			if (ba != null) {
								
				/// Offcreen Transition 
				if (tType >= 1 && tType <= 4){
					
					//ba.stand();
					
					var xo:int = 0;
					var yo:int = 0;
					var o:int = 20;
					if (actorId != myActor.actorId){						
						o = 140;
						ba.isLeaving = true;
					}
					
					switch (tType){
						case 1:
							yo = -o;
							break
						case 2:
							xo = o;
							break;
						
						case 3:
							yo = o;
							break;
						
						case 4:
							xo = -o;
							break;					
					}	
					
					var p:Point = ba.position;
					//trace("trasition Move to ")				
					ba.move(p, p.x + xo, p.y + yo, 0);											
				}else{
					ba.isLeaving = true;						
					
					ba.stopMove();
					
					var frame:String = this.getTransitionOutFrame(tType);
					if (frame != null){
						ba.playTransition(frame);
					}				
					
				}
			}			
			
		}

		private function onActorGone(evt:Event):void{
			if (BaseActor(evt.target).isLeaving) {
				this.removeActor(BaseActor(evt.target).actorId);
			}
		}
		
		private function onTeammateGone(evt:Event):void{
			this.removeActor(BaseActor(evt.target).actorId);
		}
		
		public function transitionIn(tType:int, actorId:String):void{
						
			var ba:BaseActor = ActorManager.actorIdToActor(actorId);
			//trace(ba.displayType)		
			if (ba != null) {				
				switch (tType){	
					case 1:
					case 2:
					case 3:
					case 4:						
						break;	
										
					case 5:
						if (ba.displayType == "monster"){
							ba.playSpawnAnimation();
						}
						break;
						
					default:	
						var frame:String = this.getTransitionInFrame(tType);
						if (frame != null){
							ba.playTransition(frame);
						}
						break;		
						
				}
			}
			
		}
		
		public function getTransitionInFrame(tType:int):String{
			var result:String;
			switch (tType){
				case 6:
					result = "crystal_in";
					break;
				
				case 0:						
					result = "portal_in";
					break;
					
				case 7:
					result = "warp_in";
					break;
				
				case 8:
					result = "buzz_in";
					break;
			}
			return result;				
		}
		public function getTransitionOutFrame(tType:int):String{
			var result:String;
			switch (tType){
				case 6:
					result = "crystal_out";
					break;
				
				case 0:						
					result = "portal_out";
					break;
					
				case 7:
					result = "warp_out";
					break;
				
				case 8:
					result = "buzz_out";
					break;
			}
			return result;			
		}
							
		//--- TargetSelection		
		public function selectActor(actorId:String):void{
			var actor:BaseActor = ActorManager.actorIdToActor(actorId);
			if (actor != null){
				this.selectTarget(actor);				
			}
		}
		
		private function selectTarget(target:BaseActor):void{
			if(_selectedActor && _selectedActor != myActor){
				_selectedActor.displaySilhouette = false;
			}
			
			
			if (this._selectedActor != null && this._selectedActor != target){
				this.selectedActor.clearTarget();
			}			
			
			this.selectedActor = target;
			if (selectedActor != null) {
				this.selectedActor.setTarget();
				target.displaySilhouette = true;
				GlobalEvent.eventDispatcher.dispatchEvent(new GlobalEvent(GlobalEvent.TARGET_ACTOR, this.selectedActor.actorName));
			}
		}
		
		private function set selectedActor(target:BaseActor):void {
			this._selectedActor = target;
			var id:String = target ? target.actorId : null;
			if (id) {
				this._selectedActorId = id;
			}
			GlobalEvent.eventDispatcher.dispatchEvent(new GlobalEvent(GlobalEvent.ACTOR_SELECTED, {actor:target, actorId:id}));
		}

		private var _cachedTargets:Array = [];
		public function resetNextTargetTime():void{
			this.lastTargetSelect = 0;
		}
			
		public function selectNextTarget(foward:Boolean = true):void{
			var time:int = getTimer();
			var dt:Number = time - this.lastTargetSelect;
			this.lastTargetSelect = time;
			var index:int = 0;

			_cachedTargets.length = 0;
			var targets:Array = _cachedTargets;			
			for each (var baseActor:BaseActor in ActorManager.actors){
				if ((baseActor.targetType == BaseActor.TARGETTYPE_FRIEND || baseActor.targetType == BaseActor.TARGETTYPE_POWERUSABLE) && baseActor.targetCycle && !baseActor.isLeaving){
					targets.push(baseActor);					
				}
			}					
			targets.sortOn("distanceFromPlayer", Array.NUMERIC);			
			if (dt >= 1500){							
				
					if (foward){
						index = 0;
					}else{
						index = targets.length - 1;
					}
					
					if (this.selectedActor != null && targets[index] == this.selectedActor && targets.length > 1){
						if (foward){
							index = 1;
						}else{
							index = targets.length - 2;
						}
					}
				
			}else{
				if (this.selectedActor != null){
					index = targets.indexOf(this.selectedActor);
				}				
				if (foward){
					index ++;
					if (index >= targets.length){
						index = 0;
					}
				}else{
					index --;
					if (index < 0){
						index = targets.length - 1;
					}
				}
				
			}
			
			if (targets[index] != null ){//&& !BaseActor(targets[index]).isLeaving){
				this.selectTarget(targets[index]);
			}
			_cachedTargets.length = 0;
		}
		
		private function onClearSelectedTarget(e:GlobalEvent):void
		{
			clearSelectedTarget();
		}
		
		public function clearSelectedTarget():void{
			if (this.selectedActor != null){
				this.selectedActor.clearTarget();
				if(selectedActor != myActor){
					selectedActor.displaySilhouette = false;
				}
			}
			this.selectedActor = null;
			GlobalEvent.eventDispatcher.dispatchEvent(new GlobalEvent(GlobalEvent.TARGET_ACTOR, {actor:null}));			
		}
		private function onActorTargetUnset(evt:BaseActorEvent):void{
			if (evt.actor == this.selectedActor){
				this.selectedActor = null;
				GlobalEvent.eventDispatcher.dispatchEvent(new GlobalEvent(GlobalEvent.TARGET_ACTOR, {actor:null}));							
			}
		}
		
		private var _getObjectUnderPointPoint:Point = new Point(NaN, NaN);
		public function getSelectedActorOrSwitchUnderPoint(x:int, y:int):Object{
			this._getObjectUnderPointPoint.x = this._uiFramework.stage.mouseX;
			this._getObjectUnderPointPoint.y = this._uiFramework.stage.mouseY;
			var a:Array = this._uiFramework.stage.getObjectsUnderPoint(_getObjectUnderPointPoint);			
			var dpo:DisplayObject;
			var ba:Object = null;
					
			 for (var i:int = 0; i < a.length; i++){			
				dpo = a[i] as DisplayObject;
								
				while( dpo != null && !(dpo is Map) && !(dpo is BaseActor && BaseActor(dpo).actorType != ActorTypes.COMPANION) && !(dpo is BasicSwitch && BasicSwitch(dpo).isUsable) ){								
					dpo = dpo.parent;															
				}				
				if (dpo is BaseActor && dpo == this.selectedActor){
					var pickedUpActor:BaseActor = BaseActor(dpo).pickedUpActor;
					if (pickedUpActor && pickedUpActor.mcHitTestPoint(this._uiFramework.stage.mouseX, this._uiFramework.stage.mouseY)) {
						ba = pickedUpActor;
					} else if (BaseActor(dpo).mcHitTestPoint(this._uiFramework.stage.mouseX, this._uiFramework.stage.mouseY)){
						ba = dpo as BaseActor;
					}					
					break;								
				}
				if (dpo is BasicSwitch){
					if (BasicSwitch(dpo).btnHitTestPoint(this._uiFramework.stage.mouseX, this._uiFramework.stage.mouseY)){
						ba = dpo as BasicSwitch;											
					}
				}
								
			}
				
			return ba;
		}
		
		
		//-----------		
		private function log(...args):void{
			var s:String;			
			for (var p:String in args){				
				if (s == null){
					if (args[p] == null){
						s = "null";
					}else{
						s = args[p];
					}
				}else{
					if (args[p] == null){
						s = s = s + ", null";
					}else{
						s = s + "," + String(args[p]);
					}
				} 
			}									
		
		}
				
		
		//-- Sync
		private var _cachedSyncIds:Array = [];
		private var _cachedRemoveIds:Array = [];
		private function onSync(evt:BattleEvent):void{
			var rObj:Object = evt.battleMessage.responseObj;
			
			_cachedSyncIds.length = 0;
			_cachedRemoveIds.length = 0;			
			var syncIds:Array = _cachedSyncIds;
			var removeIds:Array = _cachedRemoveIds;			 
			
			for (var i:int = 0; i < rObj.length; i++){				
				syncIds.push(rObj[i].id);
			}
			
			for each (var baseActor:BaseActor in ActorManager.actors){				
				var index:int = syncIds.indexOf(baseActor.actorId);				
				if (index < 0){					
					removeIds.push(baseActor.actorId);
				}else{
					baseActor.updateActor(rObj[index], this._gateway.pingTimer.lagTime);	
			}				
				}
			for (var rId:int = 0; rId < removeIds.length; rId++){
				if (ActorManager.actors[rId] != null && !BaseActor(ActorManager[rId]).isLeaving){
					this.removeActor(ActorManager[rId]);
				}
			}
		}
		
		//--- Full CleanUp on Disconect
		//  this is use when connection is lost
		private function clearAll():void{
			for each (var ba:BaseActor in ActorManager.actors){	
				ba.removeEventListener(MouseEvent.MOUSE_DOWN, onActorMouseDown);
				ba.removeEventListener(BaseActor.ACTOR_GONE, onActorGone);				
				ba.removeEventListener(BaseActor.TEAMMATE_GONE, onTeammateGone);				
				ba.removeEventListener(BaseActorEvent.TARGET_UNSET, onActorTargetUnset);
				
				_uiFramework.map.removeActor(ba);				
									
				ba.dispose();
				delete ActorManager.actors[ba.actorId];				
			}
			
			for (var mid:String in this.mapActors){	
				delete this.mapActors[mid];
			}		
						
			this.transPos.x = 0;
			this.transPos.y = 0;
			this._currentRoomId = null;
			BattleUtils.cleanObject(this.mapActors);
			this.mapOffset.x = 0;
			this.mapOffset.y = 0;
			BattleUtils.cleanObject(ActorManager.actors);			
			this.selectedActor = null;
			this._selectedActorId = null;
			//this.isCasting = false;
			this._isCharging = false;	
			this.lootManager = new LootManager(this._gateway, this._uiFramework, this._linkManager);		
			
		}

		private function get selectedActor():BaseActor {
			return this._selectedActor;
		}
		
		//The compiler doesn't permit us having a public getter and a private setter.  Totally lame.
		public function getSelectedActor():BaseActor{
			return selectedActor;
		}
		
		private function get selectedActorId():String {
			return this._selectedActorId;
		}

		public static function actorIdToActor(actorId:String):BaseActor {
			return ActorManager.actors[actorId];
		}
		
		private static function hashActorIdToActor(actorId:String, actor:BaseActor):void {
			ActorManager.actors[actorId] = actor;
		}

		/**
		 * I really hope this myActorId stuff goes away soon.  Ideally we want people to get my actorId by going to
		 * ActorManager.getInstance().myActor.actorId.  However, in the process of creating myActor, a bunch of events are fired as myActor
		 * is being created, and listeners of these events try to access the actorId property off of myActor, which hasn't been set.  So, we
		 * to store it seperately for now.
		 **/
		private var _myActorId:String = null;
		
		private function onPlayerInfoReceived(e:GlobalEvent):void{
			var responseObj:Object = e.data.responseObj;
			
			_myActorId = responseObj.id;
			
			_myActor = this.addActor(responseObj);
			_myActor.setUserLevel(_myActor.userLevel, true);
			_myActor.consumableManager = new ConsumableManager(ConsumableItemManager.getInstance(), this._linkManager, this._gateway, this._uiFramework)
			_myActor.displaySilhouette = true;
			
			GlobalEvent.eventDispatcher.addEventListener(GlobalEvent.ALLOW_USER_MOVE, onAllowUserMove, false, 0, true);
			GlobalEvent.eventDispatcher.addEventListener(GlobalEvent.ALLOW_USABLE_USE, onAllowUsableUse, false, 0, true);
			this._gateway.addEventListener(BattleEvent.ORB, onOrbsUpdate, false, 0, true);
			
			_myActor.addEventListener(BaseActor.RING_LOADED, onPlayerRingsLoaded, false, 0, true);
			
			GlobalEvent.eventDispatcher.dispatchEvent(new GlobalEvent(GlobalEvent.PLAYER_CREATED, {actor:_myActor, playerInfo:responseObj}));
			
			if (responseObj.timeTillOrbSwap != null){		
				GlobalEvent.eventDispatcher.dispatchEvent(new GlobalEvent(GlobalEvent.TIME_TILL_ORB_SWAP, responseObj.timeTillOrbSwap));
			}
							
		}
		
		private function onPlayerRingsLoaded(evt:Event):void{
			myActor.removeEventListener(BaseActor.RING_LOADED, onPlayerRingsLoaded);
			myActor.updateBonusSet();	
		}
		
		private function onOrbsUpdate(evt:BattleEvent):void{
			if (evt.battleMessage.responseObj[0].orbs != null){
				myActor.totalOrbs = Orbs.fromMap(evt.battleMessage.responseObj[0].orbs);			
			}			
		}
		
		private function onAllowUserMove(event:GlobalEvent):void{
			_myActor.allowUserMove = event.data;
		}
		
		private function onAllowUsableUse(event:GlobalEvent):void{
			myActor.allowUsableUse = event.data;
		}
		
		private var _myActor:BaseActor = null;
		
		public function get myActor():BaseActor{
			return _myActor;
		}
		
		private function onCrewListSelectionChange(evt:GlobalEvent):void{
			this.selectActor(evt.data.userId);
		}
	
		public function get friendsList():Array {
			return this._friendsList;
		}
				
		public function get useRasterize():Boolean{
			return this._monsterLoadManager.useRasterize;
		}
		public function set useRasterize(v:Boolean):void{
			this._monsterLoadManager.useRasterize = v;
		}
	
		private static var _instance:ActorManager = null;
		
		public static function initialize(stage:Stage, gateway:BattleGateway, uiFramework:IUIFramework, linkManager:ILinkManager, fileVersionManager:IFileVersionManager, progressManager:ProgressEventManager):void{
			if(_instance){
				throw new Error("ActorManager has already been initialized");
			}
			else{
				_instance = new ActorManager(new SingletonEnforcer(), stage, gateway, uiFramework, linkManager, fileVersionManager, progressManager);
			}
		}
		
		public static function getInstance():ActorManager{
			if(!_instance){
				throw new Error("ActorManager has not been initialized yet!  Please use ActorManager.initialize");
			}
			return _instance;
		}
		
		
		
		//******************************************
		//*** Friend Invite
		//******************************************	
		private function onInviteToBeFriend(evt:BattleEvent):void{
			trace(evt.battleMessage.responseObj);
			
			var txt:String = evt.battleMessage.responseObj[0].name;
			txt += " wants to add you as a friend";
			
			var id:String = evt.battleMessage.responseObj[0].id;				
			var ad:UiAcceptDecline = Globals.uiManager.showAcceptDecline(txt, id);						 
			ad.addEventListener("BtnAcceptClick", onInviteAcceptClick);
			ad.addEventListener("BtnDeclineClick", onInviteDeclineClick);			
		}
		private function onInviteAcceptClick(evt:Event):void{			
			var ad:UiAcceptDecline = evt.target as UiAcceptDecline;
			if (ad != null){			
				var id:String = ad.param.id;		
				var msg:BattleMessage = new BattleMessage("invitedToBeFriendAnswer", {id:ad.param.id, result:true});
				this._gateway.sendMsg(msg);				
				Globals.uiManager.removeAcceptDecline(ad);
				ad.removeEventListener("BtnAcceptClick", onInviteAcceptClick);
				ad.removeEventListener("BtnDeclineClick", onInviteDeclineClick);
			}	
			
		}
		private function onInviteDeclineClick(evt:Event):void{
			var ad:UiAcceptDecline = evt.target as UiAcceptDecline;
			if (ad != null){			
				var id:String = ad.param.id;		
				var msg:BattleMessage = new BattleMessage("invitedToBeFriendAnswer", {id:ad.param.id, result:false});
				this._gateway.sendMsg(msg);				
				Globals.uiManager.removeAcceptDecline(ad);
				ad.removeEventListener("BtnAcceptClick", onInviteAcceptClick);
				ad.removeEventListener("BtnDeclineClick", onInviteDeclineClick);
			}	
		}
		private function onInviteToFriendCompleted(evt:BattleEvent):void{
			//trace("[ActorManager onInviteToFriendCompleted]");
			var success:Boolean = evt.battleMessage.responseObj[0].success;
			var msg:String;
			if (success){
				msg = GlobalTexts.getFriendRequestAccepted(evt.battleMessage.responseObj[0].name);
			}else if (evt.battleMessage.responseObj[0].errorMessage){
				msg = "<br><p>"+evt.battleMessage.responseObj[0].errorMessage + "</p><a href ='event:close'>OK</a>";
					
			}
			
			if (msg != null){
				var resultDialog:DialogWindow = DialogWindowFactory.getInstance().getNewDialogWindow(this._uiFramework, this._linkManager, DialogWindowTypes.NORMAL, 200);										
				resultDialog.autoSize = true;
				resultDialog.autoCenter = true;				
				resultDialog.setHtmlText(msg);
			}
		}
			
		
		
		
	}
}

internal class SingletonEnforcer{}
