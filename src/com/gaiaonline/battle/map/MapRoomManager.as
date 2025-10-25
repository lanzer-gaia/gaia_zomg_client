package com.gaiaonline.battle.map
{
	import com.gaiaonline.flexModulesAPIs.globalevent.GlobalEvent;
	import com.gaiaonline.platform.gateway.ICollisionConnector;
	import com.gaiaonline.utils.DisplayObjectUtils;
	
	import flash.display.Sprite;
	import flash.events.ProgressEvent;
	import flash.geom.Point;
	
	public class MapRoomManager implements IMapRoomManager{
	
		private var rooms:Object = null; 
		private var _currentRoomId:String;
		private var _collisionConnector:ICollisionConnector = null;
		
		public function MapRoomManager(collisionConnector:ICollisionConnector){
			_collisionConnector = collisionConnector;
			DisplayObjectUtils.addWeakListener(GlobalEvent.eventDispatcher, GlobalEvent.MAP_ROOM_LEAVE, onMapRoomLeave);
			DisplayObjectUtils.addWeakListener(GlobalEvent.eventDispatcher, GlobalEvent.MAP_LOAD_ZONE, onLoadZone);
		}
	
		private function onLoadZone(event:GlobalEvent):void{
			disposeAllRooms();
		}
		
		public function initRoomsFromInfoLayer(infoLayer:Sprite):void{
			GlobalEvent.eventDispatcher.dispatchEvent(new ProgressEvent(GlobalEvent.MAP_INIT_PROGRESS,false,false,40,100));
	
			this.rooms = new Object();			
			
			var childCount:uint = infoLayer.numChildren;
			for (var ri:uint; ri < childCount; ++ri){
				
				var roomInfo:Object = infoLayer.getChildAt(ri);
				var fileCol:int = Math.floor(roomInfo.x/780);
				var fileRow:int = Math.floor(roomInfo.y/505);
				
				if (roomInfo == "[object RoomInfo]"){
					
					var fileRoomNum:int = (fileRow*100)+fileCol+1;
					var serverRoomId:String;
					
					if (roomInfo.room_name == null || String(roomInfo.room_name).length == 0){						
						serverRoomId = this.zone + "_" + fileRoomNum;
						roomInfo.room_name = serverRoomId;
					}else{
						serverRoomId = String(roomInfo.room_name);
					}	
					
					// true Layout info
					var lCol:int = fileCol;
					var lRow:int = fileRow;
					
					this.rooms[serverRoomId] = new MapRoom(this, _collisionConnector, serverRoomId, new Point(lCol, lRow), new RoomInfoData(roomInfo));
				}
				else if (roomInfo == "[object Target]"){
					roomInfo.target_name = roomInfo.name;
				}
			}
			
			// [bgh] set the n,e,s,w on the rooms. needed for awareness
			for(var roomId:String in rooms) {
				setRoomExits(roomId);
			}
		}
		
		
		private function setRoomExits(roomId:String):void {
			var mRoom:MapRoom = this.rooms[roomId];
			var roomInfoData:RoomInfoData = mRoom.roomInfo;
			var north:MapRoom = this.getRoomAtLayoutPos(mRoom.layoutPos.x, mRoom.layoutPos.y-1);
			if (north && !north.isDummyRoom){
				roomInfoData.exit_north = north.serverRoomId;
			}
			
			var south:MapRoom = this.getRoomAtLayoutPos(mRoom.layoutPos.x, mRoom.layoutPos.y+1);
			if (south && !south.isDummyRoom){
				roomInfoData.exit_south = south.serverRoomId;
			}
			
			var east:MapRoom = this.getRoomAtLayoutPos(mRoom.layoutPos.x+1, mRoom.layoutPos.y);
			if (east && !east.isDummyRoom){
				roomInfoData.exit_east = east.serverRoomId;
			}
			
			var west:MapRoom = this.getRoomAtLayoutPos(mRoom.layoutPos.x-1, mRoom.layoutPos.y);
			if (west && !west.isDummyRoom){
				roomInfoData.exit_west = west.serverRoomId;
			}
		}
		
		public function getRoomById(id:String):MapRoom{
			if(rooms && id){
				return rooms[id] as MapRoom;
			}
			return null;
		}
		
		public function getCurrentRoomId():String{
			return this._currentRoomId;
		}
		
		public function getCurrentMapRoom():MapRoom{
			return getRoomById(_currentRoomId);
		}
	
			//---room helpers---------------	
		public function getRoomAtLayoutPos(col:int, row:int):MapRoom {
							
			for (var roomId:String in this.rooms){
				var r:MapRoom = this.rooms[roomId];
				if (r.layoutPos.x == col && r.layoutPos.y == row){
					return r;						
				}
			};	
			
			return null;		
		}
		
		
		private function disposeAllRooms():void{
			for (var r:String in this.rooms){			
				var mRoom:MapRoom = this.rooms[r];
				mRoom.dipose();							
			}
			this.rooms = null;
		}
		
		public function get zone():String{
			return _currentRoomId.split("_")[0];
		}

		private static var s_sizePoint:Point = new Point(NaN, NaN);		
		public function getSize():Point{
				
			var minX:int = 1000;
			var maxX:int = 0;
			
			var minY:int = 1000;
			var maxY:int = 0;
						
			for (var r:String in this.rooms){				
				var mr:MapRoom = this.rooms[r];
				
				if (!mr.isDummyRoom){
					var lp:Point = mr.layoutPos;
					
					if (lp.x < minX){
						minX = lp.x;
					}
					if (lp.x > maxX){
						maxX = lp.x;					
					}
					
					
					if (lp.y < minY){
						minY = lp.y;
					}
					if (lp.y > maxY){
						maxY = lp.y;					
					}
				}
			}
						
			var px:Number = (maxX - minX +1) * 780;
			var py:Number = (maxY - minY +1) * 505;
			
			s_sizePoint.x = px;
			s_sizePoint.y = py;
			
			return s_sizePoint;
		}
		
		private function onMapRoomLeave(event:GlobalEvent):void{
			var data:Object = event.data;
			_currentRoomId = data.newRoomId;
		}
		
		public function setBackParamForAllRooms(obj:Object):void{
			for (var rid:String in this.rooms){
				getRoomById(rid).setBackParam(obj);
			}
		}
			
	}


}