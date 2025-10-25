package com.gaiaonline.battle.map
{
	import com.gaiaonline.flexModulesAPIs.globalevent.GlobalEvent;
	import com.gaiaonline.platform.gateway.IActorRelocateConnector;
	import com.gaiaonline.platform.gateway.IActorRelocateHandler;
	
	import flash.events.Event;
	
	public class GameTransitionManager implements ITransitionEventHandler, IActorRelocateHandler
	{
		
		private var _instanceId:String = null;
		
		private var _map:Map = null;
		private var _mapMover:MapMover = null;
		
		private var defaultMapEffect:IMapEffect = null;
		private var _mapWarpInEffect:IMapEffect;
		private var _mapWarpOutEffect:IMapEffect;
		
		private var _newMapFile:Boolean = false;
		private const _roomDataHolder:RoomDataHolder = new RoomDataHolder();
		
		public function GameTransitionManager(map:Map, gateway:IActorRelocateConnector){
			_map = map;
			gateway.registerForRelocationEvents(this);
			
			
			_mapMover = new MapMover(_map);
			_mapMover.addEventListener(MapMover.MAP_SLIDE_DONE, onMapSlideDone, false, 0, true);
			_map.addEventListener(Map.MAP_INITIALIZED, onMapInitialized, false, 0, true);
			
			defaultMapEffect = new Iris(_map);
			defaultMapEffect.registerForTransitionEvents(this);
			_mapWarpInEffect = defaultMapEffect;
			_mapWarpOutEffect = defaultMapEffect;
		}

		private function get newMapRoomId():String{
			return _roomDataHolder.newMapRoomId;
		}
		
		private function set newMapRoomId(value:String):void{
			_roomDataHolder.newMapRoomId = value;
		}
		
		private function get _previousRoomId():String{
			return _roomDataHolder.previousRoomId;
		}
		
		private function get newInstanceId():String{
			return _instanceId;
		}
		
		private function set newInstanceId(value:String):void{
			_instanceId = value;
		}

		public function onActorRelocate(data:Object):void{
			if (data.forceRefresh == null){
				data.forceRefresh = false;
			}
			handleActorRelocate(String(data.roomName), String(data.instanceId), data.transition, data.forceRefresh, data.x, data.y);
		}

		private function getNewMapZone():String{
			return newMapRoomId.split("_")[0];
		}
		
		private function getPreviousMapZone():String{
			if(_previousRoomId){
				return _previousRoomId.split("_")[0];
			}
			return null;
		}

		private function handleActorRelocate(roomName:String, instanceId:String, transitionNum:Number, forceRefresh:Boolean, xPos:Number, yPos:Number):void{
			this.newMapRoomId = roomName;
			this.newInstanceId = instanceId;
			
			_newMapFile = (getNewMapZone() != getPreviousMapZone());
			
			// Sliding room
			if (transitionNum >= 1 && transitionNum <= 4 && !forceRefresh){
				slideToRoom(transitionNum, xPos, yPos)
			} else {			
				// Iris --
				if ( newMapRoomId != _previousRoomId || forceRefresh){
					
					var irisX:Number = 0
					var irisY:Number = 0
					
					var currentRoom:MapRoom = _map.getRoomById(_previousRoomId);

					if(currentRoom){
						irisX = currentRoom.layoutPos.x * 780;
						irisY = currentRoom.layoutPos.y * 505;
					}
					
					_mapWarpOutEffect.out(irisX + 390, irisY + 252.5);
					
					if (this._newMapFile){
						GlobalEvent.eventDispatcher.dispatchEvent(new GlobalEvent(GlobalEvent.MAP_WARP_OUT_TRANSITION_START, {x:xPos, y:yPos, transition:transitionNum}));
					}else{
						GlobalEvent.eventDispatcher.dispatchEvent(new GlobalEvent(GlobalEvent.MAP_WARP_WITHIN_ROOM, {x:xPos, y:yPos, transition:transitionNum}));
					}
				}
				//warping within the same room.
				else{							
					GlobalEvent.eventDispatcher.dispatchEvent(new GlobalEvent(GlobalEvent.MAP_WARP_WITHIN_ROOM, {x:xPos, y:yPos, transition:transitionNum}));
				}
			}				
		}

		private function slideToRoom(transitionNum:Number, xPos:Number, yPos:Number):void{
			dispatchRoomLeave();
			GlobalEvent.eventDispatcher.dispatchEvent(new GlobalEvent(GlobalEvent.MAP_SLIDE_START, {roomId:this.newMapRoomId, transition:transitionNum, x:xPos, y:yPos}));
			_mapMover.slideToRoom(_map.getRoomById(newMapRoomId));
		}

		private function onMapSlideDone(event:Event):void{
			GlobalEvent.eventDispatcher.dispatchEvent(new GlobalEvent(GlobalEvent.MAP_SLIDE_COMPLETE, {newRoomId:newMapRoomId}));
			dispatchNewRoomEnter();
		}
		
		private function tryToPlayWarpInTransition():void{
			if(_waitArray.length <= 0){
				
				var currentRoom:MapRoom = _map.getRoomById(newMapRoomId);
				var irisX:Number = currentRoom.layoutPos.x * 780;
				var irisY:Number = currentRoom.layoutPos.y * 505;
				
				_mapWarpInEffect.int(irisX + 390, irisY + 252.5);
				GlobalEvent.eventDispatcher.dispatchEvent(new GlobalEvent(GlobalEvent.MAP_WARP_IN_TRANSITION_START, {}));
				
			}
		}
		
		
		public function onWarpOutTransitionComplete():void{
			GlobalEvent.eventDispatcher.dispatchEvent(new GlobalEvent(GlobalEvent.MAP_WARP_OUT_TRANSITION_COMPLETE, {}));
			
			if(_mapWarpOutEffect != defaultMapEffect){
				_mapWarpOutEffect.unregisterForTransitionEvents(this);
				_mapWarpOutEffect = defaultMapEffect;
			}
			dispatchRoomLeave();
			
			var zone:String = newMapRoomId.substring(0, newMapRoomId.lastIndexOf("_"));
			
			if(_newMapFile){
				loadNewMap(newMapRoomId, newInstanceId, zone);
			}
			else{
				/**
				 * This is up for some discussion.  Should we dispatch a MAP_WARP_WITHIN_MAP event?  Should we dispatch a LOAD_MAP event?
				 * Or can we just go straight to Map_Loaded?
				 * */
				
				onMapInitialized();
			}
			
		}
		public function onWarpInTransitionComplete():void{
			GlobalEvent.eventDispatcher.dispatchEvent(new GlobalEvent(GlobalEvent.MAP_WARP_IN_TRANSITION_COMPLETE, null));
			if(_mapWarpInEffect != defaultMapEffect){
				_mapWarpInEffect.unregisterForTransitionEvents(this);
				_mapWarpInEffect = defaultMapEffect;
			}
		}

		public function loadMap(room:String, instance:String, actorXPos:Number, actorYPos:Number, warpOutEffect:IMapEffect=null):void{
			if(warpOutEffect){
				warpOutEffect.registerForTransitionEvents(this);
				_mapWarpOutEffect = warpOutEffect;
			}
			
			handleActorRelocate(room, instance, 5, true, actorXPos, actorYPos);
		}

		private function loadNewMap(room:String, instance:String, zone:String):void{
			GlobalEvent.eventDispatcher.dispatchEvent(new GlobalEvent(GlobalEvent.MAP_LOAD_ZONE, {zone:zone, room:room, instance:instance}));
		}
		
		private function onMapInitialized(event:Event=null):void{
			GlobalEvent.eventDispatcher.dispatchEvent(new GlobalEvent(GlobalEvent.MAP_DONE, {transitionManager:this, previousRoomId:_previousRoomId, roomId:this.newMapRoomId, isNullChamber:_map.isNullChamber()}));
			_mapMover.moveToRoom(_map.getRoomById(newMapRoomId));
			dispatchNewRoomEnter();	
			tryToPlayWarpInTransition();
		}
		
		private var _waitArray:Array = [];
		
		public function haltWarpInTransition(objectToWaitFor:Object):void{
			_waitArray.push(objectToWaitFor);
		}
		
		public function resumeWarpInTransition(objectToWaitFor:Object):void{
			var num:int = _waitArray.indexOf(objectToWaitFor);
			if(num >= 0){
				
				//if num is the last one in the array
				if(num+1 == _waitArray.length){
					//pop() is nice because it doesn't create a new array while splice does.
					_waitArray.pop();
				}
				else{
					_waitArray.splice(num, 1);
				}
				tryToPlayWarpInTransition();
			}
			else{
				throw new Error("Invalid resumeWarpIn object");
			}
		}
		
		private function dispatchRoomLeave():void{
			GlobalEvent.eventDispatcher.dispatchEvent(new GlobalEvent(GlobalEvent.MAP_ROOM_LEAVE, {previousRoomId:_previousRoomId, newRoomId:newMapRoomId, newInstanceId:newInstanceId}));			
		}
		
		private function dispatchNewRoomEnter():void{
			GlobalEvent.eventDispatcher.dispatchEvent(new GlobalEvent(GlobalEvent.TRACKING_EVENT, "room_change_" + newMapRoomId));
			GlobalEvent.eventDispatcher.dispatchEvent(new GlobalEvent(GlobalEvent.NEW_ROOM_ENTERED, {previousRoomId:_previousRoomId, newRoomId:newMapRoomId}));
		}
		
	}
}

/**
 * This is a little paranoid, but I wanted to be sure that it would be difficult to edit _roomId and _previousRoomId directly, so I made an internal
 * class just for them.  That way you can't accidently set _roomId/_previousRoomId which could be a difficult error to trace.
 * [jtn]
 * */

internal class RoomDataHolder{
	
	private var _previousRoomId:String = null;
	private var _roomId:String = null;
	
	public function get newMapRoomId():String{
		return _roomId;
	}
	
	public function set newMapRoomId(value:String):void{
		_previousRoomId = _roomId;
		_roomId = value;
	}
	
	public function get previousRoomId():String{
		return _previousRoomId;
	}
	
}
