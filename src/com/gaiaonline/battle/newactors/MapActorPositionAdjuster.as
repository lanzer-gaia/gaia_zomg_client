package com.gaiaonline.battle.newactors
{
	import com.gaiaonline.battle.map.IMapRoomManager;
	import com.gaiaonline.battle.map.MapRoom;
	
	import flash.geom.Point;
	
	final public class MapActorPositionAdjuster
	{
		private static const DEFAULT_SCALE:Number = 0.75;
		private var _mapRoomManager:IMapRoomManager = null;
		
		
		public function MapActorPositionAdjuster(mapRoomManager:IMapRoomManager){
			_mapRoomManager = mapRoomManager;
		}
		
		public function adjustX(x:Number):Number{
			return adjustValue(x, true);
		}
		
		public function adjustY(y:Number):Number{
			return adjustValue(y, false);
		}
		
		public function getScale():Number{
			var room:MapRoom = _mapRoomManager.getCurrentMapRoom();
			if(room){
				return _mapRoomManager.getCurrentMapRoom().scale / 100;
			}
			return DEFAULT_SCALE;
		}
		
		private function adjustValue(value:Number, thisIsX:Boolean):Number{
			var room:MapRoom = _mapRoomManager.getCurrentMapRoom()
			if(room){
				var scale:Number = getScale();
				var offset:Point = room.getRoomOffset();
				
				if(thisIsX){
					return Math.round(value * scale) + offset.x; 
				}
				return Math.round(value * scale) + offset.y;
			}
			return value;
		}
	}
}