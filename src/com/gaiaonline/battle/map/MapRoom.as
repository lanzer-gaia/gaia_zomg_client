package com.gaiaonline.battle.map
{
	import com.gaiaonline.battle.utils.AnimationStore;
	import com.gaiaonline.battle.utils.BattleUtils;
	import com.gaiaonline.platform.actors.ISilhouetteable;
	import com.gaiaonline.platform.gateway.ICollisionConnector;
	import com.gaiaonline.utils.DisplayObjectUtils;
	
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.EventDispatcher;
	import flash.geom.Point;
	import flash.utils.Dictionary;
	import flash.utils.Timer;
	
	public class MapRoom extends EventDispatcher
	{
		private var myServerRoomId:String;
		private var myLayoutPos:Point;
		private var _myRoomOffset:Point = null;
		private var myScale:int = 75;	
		private var myTint:int = 0;
		private var myTintAlpha:int = 0;
		private var myTintBackground:Boolean = true;
		
		private var myMapObjs:Array = [];
		private var mapIt:MapIt;
		public var roomInfo:RoomInfoData;		
		
		private var mcBack:MovieClip;
		private var _mapRoomManager:IMapRoomManager = null; 
		
		public function MapRoom(mapRoomManager:IMapRoomManager, collisionConnector:ICollisionConnector, serverRoomId:String, layoutPos:Point, roomInfo:RoomInfoData){
			this._mapRoomManager = mapRoomManager;
			this.myServerRoomId = serverRoomId;	
			this.myLayoutPos = layoutPos;
						
			this.myScale = int(roomInfo.room_scale);
			this.myTint = roomInfo.roomTint;
			this.myTintAlpha = roomInfo.roomTintAlpha;
			this.myTintBackground = roomInfo.tintBackground;
			
			this.roomInfo = roomInfo;
						
			this.mapIt = new MapIt(this.myServerRoomId, collisionConnector);
		}

		private var _animations:AnimationStore;
		public function setBack(mcBack:MovieClip):void{
			this.mcBack = mcBack;
			if (this.mcBack) {
				var anims:AnimationStore = new AnimationStore(mcBack);
				if (anims.size) { 
					_animations = anims;
				}
			}
		}
		public function getBack():MovieClip{
			return this.mcBack;
		}
		
		public function set inScope(b:Boolean):void {
			if (_animations) {
			  if (b) {
					_animations.playAll();
				}
			  else {
					_animations.stopAll();
				}
			}
		}
			
		public function addMapObject(mapObj:MapObject):void{
			
			var add:Boolean = true
			var name:String = mapObj.name;					
			for each(var m:MapObject in this.myMapObjs){
				if (m.name == name){
					add = false;
					break;
				}
			}
					
			if (add){				
				this.myMapObjs.push(mapObj);
//				_notSilhouettedObjects[mapObj] = true;
			}
		}		
				
		public function containMapObj(mapObj:MapObject):Boolean{
			var r:Boolean = this.myMapObjs.indexOf(mapObj) >= 0;		
			return r;
		}
	 
		public function dipose():void{
			for (var i:int =0 ; i < this.myMapObjs.length; i++){			
				MapObject(this.myMapObjs[i]).dispose();
				delete this.myMapObjs[i];
			}			
			this.myMapObjs.length = 0;
			
			if (this.mcBack != null){
				if (this.mcBack.parent != null){
					this.mcBack.parent.removeChild(this.mcBack);
				}				
				DisplayObjectUtils.ClearAllChildrens(this.mcBack);			
				this.mcBack = null;
			}
			
			this.mapIt = null;
			this._animations = null;
		}
		
		private function get myRoomOffset():Point {
			if (this._myRoomOffset == null) {
				this._myRoomOffset = new Point(this.myLayoutPos.x * 780, this.myLayoutPos.y * 505);
			}
			return this._myRoomOffset;
		}

		public function getRoomOffset():Point{
			return myRoomOffset;
		}		
		
		public function setShadowForTint(v:Boolean):void{
			for (var i:int = 0; i < this.myMapObjs.length; i++){
				var mObj:MapObject = this.myMapObjs[i] as MapObject;
				var shadow:Sprite = mObj.getShadow() as Sprite;
				if (shadow != null){
					if (v){
						shadow.visible = true;
					}else{
						shadow.visible = mObj.displayShadow;
					}
				}
			}
		}
		
		public function setGroundLightForTint(v:Boolean):void{
			for (var i:int = 0; i < this.myMapObjs.length; i++){
				var mObj:MapObject = this.myMapObjs[i] as MapObject;
				var groundLight:Sprite = mObj.getGroundLight() as Sprite;
				if (groundLight != null){
					groundLight.visible = mObj.displayGroundLight;
					/*
					if (v){
						groundLight.visible = true;
					}else{
						groundLight.visible = mObj.displayGroundLight;
					}
					*/
				}
			}
		}
		
		//--- mapIt ------------------
		private var mapItInfoLayer:Sprite;
		private var mapItCollisionLayer:Sprite;
		private var mapItTimer:Timer;
		
		//---- Collsion Map
		
		public function getCollisionData():void{
			if (!this.mapIt.isCollisionMapOk()){				
				this.mapIt.getMapDataFromServer();
			}				
		}
		
		public function getCollisionTypeAt(x:Number,y:Number):uint
		{
			if (this.mapIt.isCollisionMapOk())
			{
				const cm:CollisionMap = this.mapIt.getCollisionMap();
				const o:Point = this.myRoomOffset;
				
				const resolution:Number = cm.getResolution();
				const px:Number = Math.floor((x-o.x)/resolution);
				const py:Number = Math.floor((y-o.y)/resolution);
				if (px >= 0 && py >= 0)
				{
					return cm.getNode(px, py);
				}
			}
			return CollisionMap.SLOT_NULL;
		}

		private function testEdgeOpen(x:Number, y:Number):Boolean
		{
			if (x >= 0 && y >= 0)
			{
				var cm:CollisionMap = this.mapIt.getCollisionMap();	
				
				//-- incorect way to match current server math (testing 1 point only)
				const resolution:Number = cm.getResolution();
				const nx:int = Math.floor( (x)/ resolution );
				const ny:int = Math.floor( (y) / resolution );
				const node:uint = cm.getNode(nx, ny);
				if ((node & CollisionMap.TRIGGER_BITMASK) != 0)
				{
					// it's a portal
					return true;
				} 
				
				return (node & CollisionMap.TYPE_WALL) == 0;  //KAI: add a 'hasflag'?
			}
			return false;
		}

		//---- Test edge for sliding
		private static const MARGIN:Number = 20;
		public function testEastEdgeOpen(y:Number):Boolean
		{
			var o:Point = this.getRoomOffset();
			return testEdgeOpen(780 - MARGIN, y-o.y);
		}
		public function testSouthEdgeOpen(x:Number):Boolean
		{
			var o:Point = this.getRoomOffset();
			return testEdgeOpen(x-o.x, 505 - MARGIN);
		}
		public function testWestEdgeOpen(y:Number):Boolean
		{
			var o:Point = this.getRoomOffset();
			return testEdgeOpen(MARGIN, y-o.y);
		}
		public function testNorthEdgeOpen(x:Number):Boolean
		{
			var o:Point = this.getRoomOffset();
			return testEdgeOpen(x-o.x, MARGIN);
		}
		
		public function getExits():Object{
			var exits:Object = new Object();
								
			exits.north = this.roomInfo.north;
			exits.south = this.roomInfo.south;
			exits.west = this.roomInfo.west;
			exits.east = this.roomInfo.east;	
			
			return exits;
		}
				
		public function DrawCollisionMap(mc:Sprite):void{
			var p:Point = this.getRoomOffset();			
			mc.x = p.x;
			mc.y = p.y;			
			this.mapIt.getCollisionMap().draw(mc);
		}
		
		//--------------------------
		public function get layoutPos():Point{
			return this.myLayoutPos;
		}
		
		public function get serverRoomId():String{
			return this.myServerRoomId;
		}
		
		public function get mapObjs():Array{
			return this.myMapObjs;
		}
		
		public function getMapObj(name:String):MapObject{
			var mobj:MapObject;
			for (var i:int = 0; i <this.mapObjs.length; i++){
				if (this.mapObjs[i].name == name){					
					mobj = this.mapObjs[i];
					break;
				}
			}
			
			return mobj;
		}
		
		public function getRoomTint():Object{
			
			var r:int = this.myTint >> 16;
			var g:int = this.myTint >> 8 & 0xFF;
			var b:int = this.myTint & 0xFF;
			
			return {r:r, g:g, b:b, a:this.myTintAlpha};	
		}
	
		public function get scale():int{
			return this.myScale;
		}
		
		public function get zoneId():int{
			var z:int = 0;
			if (this.roomInfo != null && this.roomInfo.zoneId != -1){
				z = this.roomInfo.zoneId;
			}
			return z;
		}
		
		public function get isDummyRoom():Boolean{
			var r:Boolean = false;
			if (this.roomInfo.dummyRoom) {
				r = this.roomInfo.dummyRoom;
			}
			return r;
		}
		
		public function get tintBackground():Boolean{
			return this.myTintBackground;
		} 
		
		public function removeAllObjectSilhouettes():void {
			// [bgh] loop over every obj telling it to remove it's silhouettes
			for each(var mapObj:MapObject in myMapObjs) {
				mapObj.removeAllObjectSilhouettes();
			}
			
			BattleUtils.cleanDictionary(_invalidSilhouetteables);
			BattleUtils.cleanDictionary(_silhouetteablesToMapObjects);
		}
		
		private var _silhouetteablesToMapObjects:Dictionary = new Dictionary(true);
		private var _invalidSilhouetteables:Dictionary = new Dictionary(true);
		
		public function runObjectSilhouette(silhouetteable:ISilhouetteable):void {
			for (var obj:Object in _silhouetteablesToMapObjects[silhouetteable]){	
				if (MapObject(obj).displaySilhouette){					
					MapObject(obj).updateSilhouette(silhouetteable, silhouetteable.scalingDirty);										
				}				
			}
			silhouetteable.scalingDirty = false;
			
			_invalidSilhouetteables[silhouetteable] = true;
		}
		
		
		//check for new mapobjects to silhouette
		//delete silhouettes that no longer are necessary.
		public function checkInvalidSilhouettables():void{
			var silhouetteable:ISilhouetteable
			for(var obj:Object in _invalidSilhouetteables){
				silhouetteable = ISilhouetteable(obj)
				
				for each(var mapObj:MapObject in myMapObjs) {
					if (MapObject(mapObj).displaySilhouette){
						var objMc:Sprite = mapObj.getStageMc();
						
						if(mapObj.checkSilhouettes(silhouetteable)){
							if(!_silhouetteablesToMapObjects[silhouetteable]){
								_silhouetteablesToMapObjects[silhouetteable] = new Dictionary(true);
							}
							_silhouetteablesToMapObjects[silhouetteable][mapObj] = true;
						}
						else{
							if(_silhouetteablesToMapObjects[silhouetteable] && _silhouetteablesToMapObjects[silhouetteable][mapObj]){
								delete _silhouetteablesToMapObjects[silhouetteable][mapObj];
								
								if(!hasKeys(_silhouetteablesToMapObjects[silhouetteable])){
									delete _silhouetteablesToMapObjects[silhouetteable];
								}
								
							}
						}
					}
						
				}
				
			}
			
			BattleUtils.cleanDictionary(_invalidSilhouetteables);
			
		}
		
		private function hasKeys(dict:Dictionary):Boolean{
			for(var obj:Object in dict){
				return true;
			}
			return false;
		}
		
		public function removeSilhouette(silhouetteable:ISilhouetteable):void{
			for each(var mapObj:MapObject in myMapObjs) {
				mapObj.removeObjectSilhouette(silhouetteable);
			}
		}
		
		public function setBackParam(obj:Object):void{
			if (this.mcBack != null && this.mcBack.hasOwnProperty("setParam")){
				this.mcBack.setParam(obj);
			}
			
		}
		
	}
}
