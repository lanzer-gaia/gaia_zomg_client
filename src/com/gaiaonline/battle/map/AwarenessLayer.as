package com.gaiaonline.battle.map
{
	import com.gaiaonline.battle.gateway.BattleEvent;
	import com.gaiaonline.battle.gateway.BattleGateway;
	import com.gaiaonline.battle.newactors.ActorManager;
	import com.gaiaonline.battle.newactors.ActorMoveEvent;
	import com.gaiaonline.battle.newactors.BaseActor;
	import com.gaiaonline.battle.utils.BattleUtils;
	import com.gaiaonline.flexModulesAPIs.globalevent.GlobalEvent;
	import com.gaiaonline.objectPool.ObjectPool;
	import com.gaiaonline.utils.DisplayObjectUtils;
	import com.gaiaonline.utils.FrameTimer;
	
	import flash.display.Sprite;
	import flash.geom.Point;

	public class AwarenessLayer extends Sprite
	{
		public static const ROOM_WIDTH:Number = 780;
		public static const ROOM_HEIGHT:Number = 505;
		
		public static const NORTH:String = "NORTH";
		public static const EAST:String = "EAST";
		public static const SOUTH:String = "SOUTH";
		public static const WEST:String = "WEST";
		private static const NONE:String = "NONE";
		
		private var _awareOfMonsters:Object = {};
		private var _awareOfTeam:Object = {};
		private var _currentRoom:MapRoom = null;
		
		private var _awareMonsterPool:ObjectPool;
		private var _awareMonsterFactory:AwareMonsterFactory = new AwareMonsterFactory();

		private var _awareTeamPool:ObjectPool;
		private var _awareTeamFactory:AwareTeamFactory = new AwareTeamFactory();
		
		private var _deferredObjectPool:ObjectPool;				
		private var _deferredObjectFactory:DeferredObjectFactory = new DeferredObjectFactory();
				
		private var _mainActor:BaseActor = null;
		
		private var _gateway:BattleGateway = null;
		private var _mapRoomManager:IMapRoomManager = null;
		
		private var _frameTimer:FrameTimer = null;
		
		public function AwarenessLayer(gateway:BattleGateway, mapRoomManager:IMapRoomManager)
		{
			super();
			
			this._gateway = gateway;
			_mapRoomManager = mapRoomManager;
			
			GlobalEvent.eventDispatcher.addEventListener(GlobalEvent.TEAM_UPDATED, onTeamUpdate, false, 0, true);
			
			this._gateway.addEventListener( BattleEvent.TEAM_MEMBER_GONE, onTeamMemberGone, false, 0, true);
			this._gateway.addEventListener( BattleEvent.AWARE_REMOVE, onMonsterRemoveUpdate, false, 0, true);
			this._gateway.addEventListener( BattleEvent.AWARE_ADD, onMonsterPositionUpdate, false, 0, true);
			this._gateway.addEventListener( BattleEvent.AWARE_START, onMonsterPositionUpdate, false, 0, true );
			this._gateway.addEventListener( BattleEvent.AWARE_STOP, onMonsterPositionUpdate, false, 0, true );
			this._gateway.addEventListener( BattleEvent.AWARE_DEATH, onMonsterDeathUpdate, false, 0, true );

			DisplayObjectUtils.addWeakListener(GlobalEvent.eventDispatcher, GlobalEvent.PLAYER_CREATED, onPlayerCreated);			
		}
				
		private function onTeamMemberGone(evt:BattleEvent):void {
			var actorId:String = evt.battleMessage.responseObj.id; 			
			var teamMate:BaseActor = ActorManager.actorIdToActor(actorId);
			if(teamMate) {			
				teamMate.removeEventListener(ActorMoveEvent.MOVE, onTeamMateMove, false);
				removeTeammate(actorId);
			}
		}
		
		private function onTeamUpdate(evt:GlobalEvent):void {
			if(ActorManager.getInstance().myActor.teamList) {
				var list:Array = ActorManager.getInstance().myActor.teamList;
				// [bgh] loop over the team list
				for each(var id:String in list) {

					if(id != ActorManager.getInstance().myActor.actorId) {
						if(!_awareOfTeam[id]) {
							var teamMate:BaseActor = ActorManager.actorIdToActor(id);
							if(teamMate) {
								teamMate.removeEventListener(ActorMoveEvent.MOVE, onTeamMateMove, false);
								teamMate.addEventListener(ActorMoveEvent.MOVE, onTeamMateMove, false, 5, true);
							}
						}
					}
				}
			}
		}
		
		private function onTeamMateMove(evt:ActorMoveEvent):void {
			var teamMember:BaseActor = evt.actor;
			var id:String = teamMember.actorId;
			var awareTeam:AwareTeam = _awareOfTeam[id];
			var roomName:String = teamMember.roomId;
			if(awareTeam) {
				// [bgh] if the team mate 'awareness' already exists the do a check to see if it's in the right place.
				if(roomName != awareTeam.objectRoom.serverRoomId) {
					this.removeTeammate(id);
				}
			}
				   				
			if(!awareTeam) {
				if (_currentRoom) {
					var roomDir:String = getRoomDirection(_currentRoom.roomInfo, roomName)					
					if(NONE != roomDir) {
						this.addTeammate(id, roomDir, roomName);
					}
				}
			}
		}
		
		private function onPlayerCreated(evt:GlobalEvent):void {
			this._mainActor = BaseActor(evt.data.actor);						
			evt.data.actor.addEventListener(ActorMoveEvent.MOVE, onPlayerMove, false, 0, true);			
		}
		
		private var _quadrant:Number = -1;
		private function onPlayerMove(evt:ActorMoveEvent):void {			
			var myRoom:MapRoom = this._mapRoomManager.getRoomById(this._mainActor.roomId);
			var id:String = null;
			var awareObj:AwareMonster = null;
			var deferredMonsterUpdate:DeferredObjectUpdate = null;					
			var deferredTeamUpdate:DeferredObjectUpdate = null;
								
			if (myRoom == null){
				return ;
			}
			if(myRoom != _currentRoom) {
				_currentRoom = myRoom;
				// [bgh] if we change rooms, remove all of the actors and all of the pending adds for those actors
				for(id in _awareOfMonsters) {
					awareObj = _awareOfMonsters[id];
					if(awareObj.playerRoom != _currentRoom) {
						this.removeMonster(id);
					}
				}

				for(id in this._deferredMonsterUpdates) {
					deferredMonsterUpdate = _deferredMonsterUpdates[id];				
					if((deferredMonsterUpdate.state == AwarenessStates.ADD || deferredMonsterUpdate.state == AwarenessStates.MOVE) && 
						deferredMonsterUpdate.room != _currentRoom.serverRoomId) {
						this.getDeferredUpdatePool().checkIn(deferredMonsterUpdate, this._deferredObjectFactory);
						this._deferredMonsterUpdates[id] = null
						delete this._deferredMonsterUpdates[id];
					}
				}
				
				for(id in _awareOfTeam) {
					var awareTeam:AwareTeam;
					awareTeam = _awareOfTeam[id];
					if(awareTeam.playerRoom != _currentRoom) {
						this.removeTeammate(id);
					}
				}
				
				for(id in this._deferredTeamUpdates) {
					deferredTeamUpdate = _deferredTeamUpdates[id];				
					if(deferredTeamUpdate.state == AwarenessStates.ADD &&
						deferredTeamUpdate.room != _currentRoom.serverRoomId) {
						this.getDeferredUpdatePool().checkIn(deferredTeamUpdate, this._deferredObjectFactory);
						this._deferredTeamUpdates[id] = null
						delete this._deferredTeamUpdates[id];
					}
				}				
			} else {
				var currentQuadrant:Number = getCurrentQuadrant(this._mainActor);
				if(_quadrant != currentQuadrant) {
					_quadrant = currentQuadrant;
					var removeQuadrants:Array = [];
					switch(_quadrant) {
						case 0:
							removeQuadrants = [EAST,SOUTH];
						break;
						case 1:
							removeQuadrants = [WEST,SOUTH];
						break;
						case 2:
							removeQuadrants = [EAST,NORTH];
						break;
						case 3:
							removeQuadrants = [WEST,NORTH];
						break;
					}
					for(id in _awareOfMonsters) {
						awareObj = _awareOfMonsters[id];
						if(-1 < removeQuadrants.indexOf(awareObj.direction)) {
							this.removeMonster(id);
						}
					}
					for(id in _deferredMonsterUpdates) {
						deferredMonsterUpdate = _deferredMonsterUpdates[id];
						if((deferredMonsterUpdate.state == AwarenessStates.ADD || deferredMonsterUpdate.state == AwarenessStates.MOVE) && 
							 -1 < removeQuadrants.indexOf(deferredMonsterUpdate.direction)) {
							this.getDeferredUpdatePool().checkIn(deferredMonsterUpdate, this._deferredObjectFactory);
							this._deferredMonsterUpdates[id] = null							 	
							delete this._deferredMonsterUpdates[id];
						}
					}
				}
			}
		}
		
		private var _deferredTeamUpdates:Object = new Object();
		private function getDeferredTeamUpdate(id:String):DeferredObjectUpdate {
			var deferredTeamUpdate:DeferredObjectUpdate = _deferredTeamUpdates[id];
			if (!deferredTeamUpdate) {
				deferredTeamUpdate = this.getDeferredUpdatePool().checkOut(this._deferredObjectFactory); 
				deferredTeamUpdate.id = id;
				_deferredTeamUpdates[id] = deferredTeamUpdate;
			}
			return deferredTeamUpdate;
		}
		
		private function removeTeammate(id:String):void {
			if (this._awareOfTeam[id] != null || this._deferredTeamUpdates[id] != null) {
				// then we have something to remove			
				var deferredTeamUpdate:DeferredObjectUpdate = this.getDeferredTeamUpdate(id);
				deferredTeamUpdate.state = AwarenessStates.REMOVE;
				this.startFrameTimer();
			}			
		}

		private function addTeammate(id:String, direction:String, room:String):void {
			this.startFrameTimer();			
			var deferredTeamUpdate:DeferredObjectUpdate = getDeferredTeamUpdate(id);
			deferredTeamUpdate.state = AwarenessStates.ADD;
			deferredTeamUpdate.direction = direction;
			deferredTeamUpdate.room = room;
		}
		
		private function getCurrentQuadrant(player:BaseActor):Number {
			var playerPt:Point = player.position;
			var scale:Number = _currentRoom.scale;
			var px:Number = playerPt.x * scale / 100;
			var py:Number = playerPt.y * scale / 100;
			var qx:Number = Math.floor(px / (ROOM_WIDTH / 2));
			var qy:Number = Math.floor(py / (ROOM_HEIGHT / 2));
			
			return (qy * 2 + qx);
		}
		
		private static function getRoomDirection(originRoomInfo:RoomInfoData, room:String):String {
			var direction:String = NONE;
			
			if(originRoomInfo.north && originRoomInfo.exit_north && originRoomInfo.exit_north == room) {
				direction = NORTH;
			} else if(originRoomInfo.east && originRoomInfo.exit_east && originRoomInfo.exit_east == room) {
				direction = EAST;
			} else if(originRoomInfo.south && originRoomInfo.exit_south && originRoomInfo.exit_south == room) {
				direction = SOUTH;
			} else if(originRoomInfo.west && originRoomInfo.exit_west && originRoomInfo.exit_west == room) {
				direction = WEST;
			} else {
				direction = NONE;
			}
			
			return direction;
		}				
		
		private function startFrameTimer():void {
			if (!this._frameTimer) {
				this._frameTimer = new FrameTimer(onFrameTimer);
				this._frameTimer.startPerFrame();
			}
		}
		
		private var _deferredMonsterUpdates:Object = new Object();
		private function getDeferredMonsterUpdate(id:String):DeferredObjectUpdate {
			var deferredMonsterUpdate:DeferredObjectUpdate = _deferredMonsterUpdates[id];
			if (!deferredMonsterUpdate) {
				deferredMonsterUpdate = this.getDeferredUpdatePool().checkOut(this._deferredObjectFactory);
				deferredMonsterUpdate.id = id;
				_deferredMonsterUpdates[id] = deferredMonsterUpdate;
			}
			return deferredMonsterUpdate;
		}

		private function removeMonster(id:String):void {
			if (this._awareOfMonsters[id] != null || this._deferredMonsterUpdates[id] != null) {
				// then we have something to remove
				var deferredMonsterUpdate:DeferredObjectUpdate = this.getDeferredMonsterUpdate(id);
				deferredMonsterUpdate.state = AwarenessStates.REMOVE;
				this.startFrameTimer();
			}
		}
		
		private function addMonster(id:String, direction:String, room:String):void {
			this.startFrameTimer();			
			var deferredMonsterUpdate:DeferredObjectUpdate = getDeferredMonsterUpdate(id);
			deferredMonsterUpdate.state = AwarenessStates.ADD;
			deferredMonsterUpdate.direction = direction;
			deferredMonsterUpdate.room = room;
		}
		
		private function moveMonster(id:String, direction:String, room:String, px:Number, py:Number, dx:Number, dy:Number, spd:Number, conLevel:Number):void {
			this.startFrameTimer();			
			var deferredMonsterUpdate:DeferredObjectUpdate = getDeferredMonsterUpdate(id);
			deferredMonsterUpdate.state = AwarenessStates.MOVE;
			deferredMonsterUpdate.direction = direction;
			deferredMonsterUpdate.room = room;			
			deferredMonsterUpdate.dx = dx;			
			deferredMonsterUpdate.dy = dy;			
			deferredMonsterUpdate.px = px;			
			deferredMonsterUpdate.py = py;			
			deferredMonsterUpdate.spd = spd;																					
			deferredMonsterUpdate.conLevel = conLevel;																								
		}
		
		private function onFrameTimer():void {
			var id:String = null;
			for each(var deferredMonsterUpdate:DeferredObjectUpdate in this._deferredMonsterUpdates) {
				id = deferredMonsterUpdate.id;				
				var monsterActor:AwareMonster = this._awareOfMonsters[id];
				if (deferredMonsterUpdate.state == AwarenessStates.REMOVE) {
					if (monsterActor) {
						this._awareOfMonsters[id] = null;
						delete _awareOfMonsters[id];																
						if (monsterActor.parent == this) {
							this.removeChild(monsterActor);
						}
						this._awareMonsterPool.checkIn(monsterActor, this._awareMonsterFactory);
					}
				} else if (deferredMonsterUpdate.state == AwarenessStates.ADD || deferredMonsterUpdate.state == AwarenessStates.MOVE) {
					if (!monsterActor) {
						monsterActor = this.getAwareMonsterPool().checkOut(this._awareMonsterFactory, 
																	[this._mapRoomManager, deferredMonsterUpdate.direction, deferredMonsterUpdate.room]);
						_awareOfMonsters[id] = monsterActor;
						this.addChild(monsterActor);
					}
					
					if (deferredMonsterUpdate.state == AwarenessStates.MOVE) {
						monsterActor.setConLevelDiff(deferredMonsterUpdate.conLevel - ActorManager.getInstance().myActor.getSuppressedCL());
						monsterActor.setPosition(deferredMonsterUpdate.px, deferredMonsterUpdate.py);
						if(!isNaN(deferredMonsterUpdate.spd)) {
							monsterActor.setSpeed(deferredMonsterUpdate.spd);
						}
						if(!isNaN(deferredMonsterUpdate.dx) && !isNaN(deferredMonsterUpdate.dy)) {
							monsterActor.setDestination(deferredMonsterUpdate.dx, deferredMonsterUpdate.dy);
						}
					}					
				}
				this.getDeferredUpdatePool().checkIn(deferredMonsterUpdate, this._deferredObjectFactory);										
			}
			for each(var deferredTeamUpdate:DeferredObjectUpdate in this._deferredTeamUpdates) {
				id = deferredTeamUpdate.id;								
				var teamActor:AwareTeam = this._awareOfTeam[id];
				if (deferredTeamUpdate.state == AwarenessStates.REMOVE) {
					if (teamActor) {
						this._awareOfTeam[id] = null;
						delete _awareOfTeam[id];																
						if (teamActor.parent == this) {
							this.removeChild(teamActor);
						}
						this._awareTeamPool.checkIn(teamActor, this._awareTeamFactory);
					}
				} else if (deferredTeamUpdate.state == AwarenessStates.ADD) {
					if (!teamActor) {
						var actor:BaseActor = ActorManager.actorIdToActor(id);
						teamActor = this.getAwareTeamPool().checkOut(this._awareTeamFactory, 
																	[this._mapRoomManager, deferredTeamUpdate.direction, actor]);
						_awareOfTeam[id] = teamActor;
						this.addChild(teamActor);
					}
				}
				this.getDeferredUpdatePool().checkIn(deferredTeamUpdate, this._deferredObjectFactory);														
			}
			BattleUtils.cleanObject(this._deferredMonsterUpdates);
			BattleUtils.cleanObject(this._deferredTeamUpdates);			
		}
		
		private function onMonsterRemoveUpdate(evt:BattleEvent):void {
			var msg:Object = evt.battleMessage.responseObj[0];
			var id:String = msg.id;
			var actor:AwareMonster = _awareOfMonsters[id];
			if(actor && _currentRoom && msg.roomName == _currentRoom.serverRoomId) {
				this.removeMonster(id);
			}
		}
		
		private function onMonsterDeathUpdate(evt:BattleEvent):void {
			var msg:Object = evt.battleMessage.responseObj[0];
			this.removeMonster(msg.id);
		}		
		private function onMonsterPositionUpdate(evt:BattleEvent):void {
			if(null!=_currentRoom) {
				var msg:Object = evt.battleMessage.responseObj[0];
				var monsterRoom:String = msg['roomName'];
				var myRoomInfo:RoomInfoData = _currentRoom.roomInfo;
				var id:String = msg.id;
				var actor:AwareMonster = _awareOfMonsters[id];
				var newRoomId:String = actor ? actor.objectRoom.serverRoomId : null;
				var direction:String = getRoomDirection(_currentRoom.roomInfo, monsterRoom);
				if(!actor) {
					if(NONE != direction) {
						this.addMonster(id, direction, monsterRoom);
						newRoomId = monsterRoom;
					}
				}
				if (newRoomId != null) {
					if(monsterRoom != newRoomId) {
						this.removeMonster(id);
					} else {
						if(actor && actor.objectRoom != null) {
						if(monsterRoom == actor.objectRoom.serverRoomId) {
						actor.setConLevelDiff(msg.conLevel - ActorManager.getInstance().myActor.getSuppressedCL());
						actor.setPosition(msg.px, msg.py);
						if(msg.hasOwnProperty("spd")) {
							actor.setSpeed(msg.spd);
						}
						if(msg.hasOwnProperty("dx") && msg.hasOwnProperty("dy")) {
							actor.setDestination(msg.dx, msg.dy);
						}
						}}
						
						var dx:Number = NaN;
						var dy:Number = NaN;						
						var spd:Number = NaN;												
						if(msg.hasOwnProperty("dx") && msg.hasOwnProperty("dy")) {
							dx = msg.dx;
							dy = msg.dy;
							spd = msg.spd;
						}
						this.moveMonster(id, direction, monsterRoom, msg.px, msg.py, dx, dy, spd, msg.conLevel);
					}
				}
			}
		}
		
		private function getAwareMonsterPool():ObjectPool {
			if (this._awareMonsterPool == null) {
				this._awareMonsterPool = new ObjectPool(this._awareMonsterFactory, this._awareMonsterFactory, this._awareMonsterFactory, 10);
			}
			
			return this._awareMonsterPool;
		}
		
		private function getAwareTeamPool():ObjectPool {
			if (this._awareTeamPool == null) {
				this._awareTeamPool = new ObjectPool(this._awareTeamFactory, this._awareTeamFactory, this._awareTeamFactory, 5);
			}
			
			return this._awareTeamPool;
		}

		private function getDeferredUpdatePool():ObjectPool {
			if (this._deferredObjectPool == null) {
				this._deferredObjectPool = new ObjectPool(this._deferredObjectFactory, this._deferredObjectFactory, this._deferredObjectFactory, 20);
			}
			
			return this._deferredObjectPool;
		}
	}
}


//******** Pool Factories
	
import com.gaiaonline.objectPool.IObjectPoolFactory;
import com.gaiaonline.objectPool.IObjectPoolDeconstructor;
import com.gaiaonline.objectPool.IObjectPoolCleanUp;
import com.gaiaonline.objectPool.IObjectPoolInitializer;

import com.gaiaonline.battle.map.AwareMonster;
import com.gaiaonline.battle.newactors.BaseActor;
import com.gaiaonline.battle.map.AwareTeam;

class AwareMonsterFactory implements IObjectPoolFactory, IObjectPoolDeconstructor, IObjectPoolCleanUp, IObjectPoolInitializer {
	public function AwareMonsterFactory(){
	}		
	public function create():* {
		return new AwareMonster();
	}
	public function deconstruct(obj:*):void{
		if (obj != null){			
			obj.dispose();
		}
	}		
	public function objectPoolCleanUp(obj:*):void{
		if (obj != null){			
			obj.reset();
		}
	}
	public function initializeObjectPool(obj:*, args:Array = null):void {
		if (obj != null) {
			obj.initialize(args);
		}
	}	
}

class AwareTeamFactory implements IObjectPoolFactory, IObjectPoolDeconstructor, IObjectPoolCleanUp, IObjectPoolInitializer{
	public function AwareTeamFactory() {
	}		
	public function create():* {
		return new AwareTeam();	
	}
	public function initializeObjectPool(obj:*, args:Array = null):void {
		if (obj != null) {
			obj.initialize(args);
		}
	}		
	public function deconstruct(obj:*):void{
		if (obj != null){			
			obj.dispose();
		}
	}		
	public function objectPoolCleanUp(obj:*):void{
		if (obj != null){			
			obj.reset();
		}		
	}
}

class DeferredObjectFactory implements IObjectPoolFactory, IObjectPoolDeconstructor, IObjectPoolCleanUp, IObjectPoolInitializer{
	public function DeferredObjectFactory() {
	}		
	public function create():* {
		return new DeferredObjectUpdate()
	}
	public function initializeObjectPool(obj:*, args:Array = null):void {
	}		
	public function deconstruct(obj:*):void{
	}		
	public function objectPoolCleanUp(obj:*):void{
		if (obj != null){			
			obj.reset();
		}		
	}
}

import com.gaiaonline.utils.Enumeration;
	
internal class AwarenessStates extends Enumeration {
	public static var ADD:AwarenessStates  = new AwarenessStates("ADD");	
	public static var REMOVE:AwarenessStates  = new AwarenessStates("REMOVE");
	public static var MOVE:AwarenessStates  = new AwarenessStates("MOVE");						

	public function AwarenessStates(name:String) {
		super(name);
	}		
}

internal class DeferredObjectUpdate {
	public var state:AwarenessStates;
	public var id:String = null;
	public var direction:String = null;
	public var room:String = null;
	public var px:Number = NaN;
	public var py:Number = NaN;
	public var dx:Number = NaN;
	public var dy:Number = NaN;
	public var spd:Number = NaN;
	public var conLevel:Number = NaN;				
	
	
	public function DeferredObjectUpdate():void {
	}
	
	public function reset():void {
		this.id = null;
		this.direction = null;
		this.room = null;
		this.px = NaN;
		this.py = NaN;
		this.dx = NaN;
		this.dy = NaN;
		this.spd = NaN;
		this.conLevel = NaN;										
	}		
}