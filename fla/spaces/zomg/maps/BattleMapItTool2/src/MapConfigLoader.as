package {
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.HTTPStatusEvent;
	import flash.events.IOErrorEvent;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	
	import mx.controls.Alert;

	public class MapConfigLoader extends EventDispatcher
	{
		private var _xml:XML;
		private var _rooms:Object;
		
		public function MapConfigLoader() {
		
		}
		
		public function LoadMapConfig(url:String):void{
			var mapConfigFile:File = new File(url);
		    var stream:FileStream = new FileStream();
			stream.open(mapConfigFile, FileMode.READ);
			var fileData:String = stream.readUTFBytes(stream.bytesAvailable);
		    try {
		    	this._xml = XML(fileData);
				this.dispatchEvent(new Event(Event.COMPLETE));
		    } catch (err:Error) {
		    	Alert.show(mapConfigFile.nativePath + " does not contain valid XML.");
		    } 
			
		}
				
		public function getAreaName(zoneId:String):String {
			return this._xml..Zone.(@id == zoneId).@areaname;						
		}	
		
		public function getZoneFile(zoneId:String):String{
			return this._xml..Zone.(@id == zoneId).@swf;			
		}
		public function getZoneName(zoneId:String):String{
			return this._xml..Zone.(@id == zoneId).@name;
		}
		
		public function getZoneIds():Array{
			var list:Array = new Array();
			for each (var zone:XML in this._xml.ZonesInfo.Zone){				
				list.push({prefix:zone.@id, swf:zone.@swf, areaname:zone.@areaname});
			}
			return list
		}

		public function getZoneNodes():XMLList {
			return this._xml.ZonesInfo.Zone;
		}
		
		public function getRoomsForZone(zoneId:String):String {
			var roomsString:String = null;
			var roomsList:XMLList = this._xml.Rooms.(@zoneId == zoneId);
			if (roomsList && roomsList.length() > 0) {
				roomsString = XML(roomsList[0]).text();	
			} 
			
			return roomsString; 
		}
	}
}
