package com.gaiaonline.battle.map
{
	import com.gaiaonline.battle.musicapi.DSGaiaService;
	import com.gaiaonline.battle.utils.BattleUtils;
	import com.gaiaonline.platform.map.IMapFiles;
	import com.gaiaonline.platform.map.IMapFilesLoadHandler;
	import com.gaiaonline.utils.RegisterUtils;
	
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.geom.Point;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	
	public class MapFiles implements IMapFiles
	{
		private var _xml:XML;
		private var _dependecies:XML;
		private var _playList:XML;
		private var _rooms:Object = new Object();
		private var _baseUrl:String = null;
		//public var dsGaiaService:DSGaiaService = new DSGaiaService();
		
		private var _globalXScale:Number = 0.0125;
		private var _globalYScale:Number = 0.0250;
		
		public function MapFiles() {
		}
		
		private var _loadHandlers:Array = [];
		
		public function registerForLoadEvents(handler:IMapFilesLoadHandler):void{
			RegisterUtils.register(_loadHandlers, handler);
		}
		
		public function unregisterForLoadEvents(handler:IMapFilesLoadHandler):void{
			RegisterUtils.unregister(_loadHandlers, handler);
		}
		
		public function load(baseUrl:String):void{
			this._baseUrl = baseUrl;			
			var l:URLLoader = new URLLoader();
			l.dataFormat = URLLoaderDataFormat.TEXT;
			l.addEventListener(Event.COMPLETE, onXmlLoaded);		
			l.load(new URLRequest(this._baseUrl + "maps/mapConfig.xml"));			
		}
		
		private function onXmlLoaded(evt:Event):void{
			try{
				this._xml = new XML( evt.target.data );	
				
				this._globalXScale = this._xml.GlobalMapInfo.@xscale/100;
				this._globalYScale = this._xml.GlobalMapInfo.@yscale/100;
				this.parseRooms();					
			} catch (e:TypeError) {
				trace("Could not parse XML: " + e.message, 9)
			}		
			
			//this.dsGaiaService.addEventListener(DSGaiaService.LOADED, onPlayListLoaded, false, 0, true);
			//this.dsGaiaService.loadMusicList();
						
			URLLoader(evt.target).removeEventListener(Event.COMPLETE, onXmlLoaded);
			
			
			this.loadDependencies();
						
		}
		
		public function onPlayListLoaded(evt:Event):void{
			/* try{
				this._playList = new XML( evt.target.data );						
			} catch (e:TypeError) {
				trace("Could not parse XML: " + e.message, 9)
			} */
		}
		
		private function parseRooms():void{
			for each(var Rooms:XML in this._xml.Rooms){
				var zoneId:String = Rooms.@zoneId;
				var miniMapId:String = Rooms.@miniMapId;
				var musicZoneId:String = Rooms.@musicZoneId;
				var scale:int = parseInt(Rooms.@scale);				
				for each( var rid:String in String(Rooms).split(",")){										
					this._rooms[rid.replace(" ","")] = {zoneId:zoneId, miniMapId:miniMapId, musicZoneId:musicZoneId, scale:scale};
				}
			}
		}
		
		public function getZoneFile(zoneId:String):String{
			return this._xml..Zone.(@id == zoneId).@swf;			
		}
		
		public function getZoneImgs(zoneId:String):Array{
			var list:Array = new Array();
			for each (var sp:XML in this._xml..Zone.(@id == zoneId)..SplashScreen){
				list.push(sp.@url);
			}
			
			if (this._xml..Zone.(@id == zoneId).@useSharedSplashScreen != "false"){			
				for each (var ssp:XML in  this._xml..SharedSplashScreen.SplashScreen){
					list.push(ssp.@url);
				}
			}
			return list;
		}
		
		public function getZoneTitleImg(zoneId:String):String{
			return this._xml..Zone.(@id == zoneId).@titleImgUrl;
		}
		
		public function isNullchamber(zoneId:String):Boolean{
			if (this._xml..Zone.(@id == zoneId).@nullChamber == "1"){
				return true
			}else{
				return false;
			}			
		}
		
		public function getZoneNameFromRoomId(roomId:String):String {
			var zoneId:String = BattleUtils.getZoneIdFromRoomId(roomId);
			return getZoneName(zoneId);			
		}
		
		public function getZoneName(zoneId:String):String{
			return this._xml..Zone.(@id == zoneId).@name;
		}
		
		public function getRoomsInfo(zoneId:String):Object{
			var a:Object = new Object();						
			for each (var Rooms:XML in this._xml..Rooms.(@zoneId == zoneId)){
				var scale:int = parseInt(Rooms.@scale);
				for each( var rid:String in String(Rooms).split(",")){
					var roomId:String = rid.replace(" ", "");
					var rnum:int = BattleUtils.getRoomNumFromRoomId(roomId);
					var row:int = Math.floor(rnum/100);
					var col:int = rnum - (row * 100) - 1;			
					var localPos:Point = new Point( (col * 780), (row*505));
					a[roomId] = {roomId:roomId, scale:scale, col:col, row:row, pos:localPos};	 
				}			
			}			
			return a;									
		}
		
		public function getZonesStartRoom():Array{
			var list:Array = new Array();
			for each (var z:XML in this._xml..Zone){
				list.push(String(z.@startRoom));
			}
			return list;
		}
		
		public function getActorFilters(roomId:String):Array{
			var zoneId:String = BattleUtils.getZoneIdFromRoomId(roomId);				
			return String(this._xml..Zone.(@id == zoneId).@actorFilters).split(",");	
		}
		//--- Shared Lib Dependencies
		private function loadDependencies():void{
			trace("Load Dependencies XML")
			var l:URLLoader = new URLLoader();
			l.dataFormat = URLLoaderDataFormat.TEXT;
			l.addEventListener(Event.COMPLETE, onXmlDependenciesLoaded);
			l.addEventListener(IOErrorEvent.IO_ERROR, onXmlDependenciesError);			
			l.load(new URLRequest(this._baseUrl + "maps/mapDependencies.xml"));
									
		}
		private function onXmlDependenciesLoaded(evt:Event):void{
			trace("Dependencies Loaded")
			try{
				this._dependecies = new XML( evt.target.data );					
			} catch (e:TypeError) {
				trace("Could not parse Dependecies XML: " + e.message, 9)
			}		
						
			for each (var area:XML in this._dependecies..Map){
				var a:Array = String(area.@fileName).split("/");
				area.@fileName = a[a.length-1];				
			}
						
			for each (var handler:IMapFilesLoadHandler in _loadHandlers){
				handler.onMapFilesLoaded();
			}
		}
		private function onXmlDependenciesError(evt:IOErrorEvent):void{
			for each (var handler:IMapFilesLoadHandler in _loadHandlers){
				handler.onMapFilesLoaded();
			}
		}
		
		public function getDependencies(fileName:String):Array{
					
			var result:Array = new Array();
			if (this._dependecies != null){			
				for each(var dep:XML in this._dependecies.Map.(@fileName == fileName).Dependency){
					result.push(dep.@url);
				}
			}
			return result;
		}
		
		
		//-- MiniMap
		private static var miniMapInfo:Object = {};
		public function getMiniMap(roomId:String):Object{
			var cachedObj:Object = miniMapInfo[roomId]; 
			if (cachedObj) {
				return cachedObj;
			} else {
				return reallyGetMiniMap(roomId);
			}
		}
		
		private function reallyGetMiniMap(roomId:String):Object {			
			if (this._xml == null || this._rooms[roomId] == null){
				return null;
			}			
			var m:XMLList = this._xml..MiniMap.(@id == this._rooms[roomId].miniMapId) as XMLList;
			if (m == null){
				return null;
			}
			
			var roomScale:Number = this._rooms[roomId].scale/100;									
			var id:String = m.@id;	
			var scale:Number = m.@scale/100;
			var showGlobal:Boolean = false;
			if (m.@showGlobal == "1"){
				showGlobal = true;
			}			
			var showLocal:Boolean = false;
			if(m.@showLocal == "1"){
				showLocal = true;
			} 
						
			//--- get room x, y, on minimap
			var rnum:int = BattleUtils.getRoomNumFromRoomId(roomId);
			var lRow:int = (Math.floor(rnum/100));
			var lCol:int = (rnum - (lRow * 100) - 1);
			var rx:Number = ((780/roomScale) * (lCol-m.StartPos.@col));
			var ry:Number = ((505/roomScale) * (lRow-m.StartPos.@row));			
			var localPos:Point = new Point(rx *scale, ry*scale);		
			
			//-- get toom x, y, on Global map
			var gpx:Number = m.GlobalPos.@x;
			var gpy:Number = m.GlobalPos.@y;				
			var gx:Number = (rx * this.globalXScale) + gpx;
			var gy:Number = (ry * this.globalYScale) + gpy;			
			var globalPos:Point = new Point(gx, gy);
					
			var obj:Object = {id:id, scale:scale, showGlobal:showGlobal, showLocal:showLocal, globalPos:globalPos, localPos:localPos, roomScale:roomScale}
			miniMapInfo[roomId] = obj;
			return obj;
		}
		public function getMiniMapId(roomId:String):String{
			var s:String = "";
			if (this._rooms[roomId] != null){
				s = this._rooms[roomId].miniMapId
			}
			return s; 
		}	
		public function getMiniMapUrl(mapId:String):String{
			var url:String
			if (this._xml != null){
				url = this._baseUrl+"maps/minimaps/"+ this._xml..MiniMap.(@id == mapId).@file;
			}
			return url;
		}
		
		//--- Music
		public function getMusicZone(roomId:String):String{
			var s:String = "";
			if (this._rooms[roomId] != null){
				s = this._rooms[roomId].musicZoneId;
			}
			return s;
		}
										
		public function getMusic(musicZoneId:String):Array{
			
			var a:Array = new Array();
			var trackNum:uint = 1;
			var mm:XMLList = this._xml.MusicZones.Zone.(@id == musicZoneId).Normal;
			for each (var Song:XML in this._xml.MusicZones.Zone.(@id == musicZoneId).Normal.Song){
				var trackData:Object = getTrackData(Song);
				if(null!=trackData)
				{
					trackData.trackNum = trackNum++;			
					trackData.trackEnvironment = "Normal";			
					
					a.push(trackData);
				}					
			}
			
			return a;
		}
		
		/**
		 * Do not call this function if dsGaiaService.isReady() == false!
		 **/
		private function getTrackData(song:XML):Object {
			var trackData:Object = null;
			
			trackData = new Object();
			trackData.trackId =  "http://s3.cdn.gaiaonline.com/zomg_music/" + song.@file;
			trackData.trackTitle = String(song.@title[0].valueOf());
			
			//[fred] DSonic not hosting anymore no need for dsGaiaService
			/*
			var ip:String = this.dsGaiaService.getServerIp();			
			if(null!=ip)
			{
				trackData = new Object();
				trackData.trackId = "http://" + ip + "/gaia/" + song.@file;
				trackData.trackTitle = String(song.@title[0].valueOf());
			}
			*/
			return trackData;
		}
		
//		public function getCombatMusic(musicZoneId:String):Array{
//			// PROBABLY NEEDS TO BE REWRITTEN TO BE LIKE getMusic ABOVE 
//			// -- Mark Rubin
//			var a:Array = new Array();
//			
//			var m:Array = this.dsGaiaService.getZoneCombat(musicZoneId);
//			for (var i:int = 0; i < m.length; i++){			
//				var ff:String = "http://" + this.dsGaiaService.getServerIp() + "/gaia/" + 	m[i].file;
//				a.push(ff);				
//			}
//			
//			return a;
//		}
		
		public function get globalXScale():Number {
			return this._globalXScale;
		}
		
		public function get globalYScale():Number {
			return this._globalYScale;
		}
		
	}
}