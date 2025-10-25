package com.gaiaonline.battle.musicapi
{
	import com.adobe.serialization.json.JSON;
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import flash.events.TimerEvent;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.net.URLRequestMethod;
	import flash.utils.Timer;
	
	public class DSGaiaService extends EventDispatcher
	{
		public static const LOADED:String = "MusicListLoaded";		
	
		private const staticSrvr:Array = ["maple.directsong.com", "mustard.directsong.com", "redwood.directsong.com", "cypress.directsong.com", "eucalyptus.directsong.com"];
 
		private const gatewayURLend:String = "/flashservices/json.php";
		
		private var _serverIndex:Number = NaN;		
		private var _gatewayURL:String;		
		
		private var _servers:Array = new Array();
		private var _zones:Array = new Array();
		private var _tracks:Array = new Array();	
		
		private var _loader:URLLoader= null;
		
		public function DSGaiaService() {
		}					
		
		public function loadMusicList():void{
			this.getServerList();
		}
		
		// Get server list (server_ip)
		private function getServerList():void{
			this._serverIndex = Math.floor(Math.random() * staticSrvr.length);
			this._gatewayURL = "http://" + (staticSrvr[this._serverIndex]) + this.gatewayURLend;

			_loader = new URLLoader();
            _loader.addEventListener(Event.COMPLETE, onServerList, false, 0, true);
            _loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, securityErrorHandler,false, 0, true);
            _loader.addEventListener(IOErrorEvent.IO_ERROR, ioErrorHandler, false, 0, true);
			var urlRequest:URLRequest = new URLRequest(this._gatewayURL +  "/gaia.getServers");
			urlRequest.method = URLRequestMethod.POST;
			_loader.load(urlRequest);
		}
		
		private function securityErrorHandler(e:SecurityErrorEvent):void {
			_loader = null;
			tryNextServerSoon();
		}
		
		private function ioErrorHandler(e:IOErrorEvent):void {
			_loader = null;
			tryNextServerSoon();
		}
		
		private function tryNextServerSoon():void {
			// For some reason, we sometimes get an http failure when connecting;
			// If we wait and try again, it's usually okay.  It might also be due to a bad server.
			if (this.staticSrvr.length > 0) {
				// let's guess it's a bad server
				trace("!!!!! Removing server ip: " + staticSrvr[this._serverIndex]);					
				this.staticSrvr.splice(this._serverIndex, 1);
				var timer:Timer = new Timer(250, 1);
				timer.addEventListener(TimerEvent.TIMER_COMPLETE, onTryAgainTimerComplete, false, 0, true);
				timer.start();
			} 
		}
		
		private function onTryAgainTimerComplete(e:TimerEvent):void {
			if (this.staticSrvr.length > 0) {
				this.getServerList();
			}
		}
		
		private function onServerList(e:Event):void{
			
			var jsonString:String = String(e.target.data);
			var result:Object = JSON.decode(jsonString);

			for (var i:Number = 0; i < result.length; i++) {				
				this._servers.push(result[i].server_ip);				
			}

			if(this._servers.length > 0)
			{
				this.getZones();
			}
		}
		
		
		// Get Zones (zone_id, zone_name)
		private function getZones():void{
			var urlRequest:URLRequest = new URLRequest(this._gatewayURL +  "/gaia.getZones");
			urlRequest.method = URLRequestMethod.POST;
			_loader.removeEventListener(Event.COMPLETE, onServerList);
            _loader.addEventListener(Event.COMPLETE, onZones, false, 0, true);			
			_loader.load(urlRequest);			
		}
		
		private function onZones(e:Event):void{
			var jsonString:String = String(e.target.data);
			var result:Object = JSON.decode(jsonString);			

			for (var i:Number = 0; i < result.length; i++) {				
				this._zones[result[i].zone_id] =  {id:result[i].zone_id, name:result[i].zone_name, music:new Array(), combat:new Array()};				
			}			
			this.getTrackList();	
		}
		
		
		// Get Tracklist (track_id, track_title, track_file_name)
		private function getTrackList():void{
			var urlRequest:URLRequest = new URLRequest(this._gatewayURL +  "/gaia.getTrackList");
			urlRequest.method = URLRequestMethod.POST;
			_loader.removeEventListener(Event.COMPLETE, onZones);
            _loader.addEventListener(Event.COMPLETE, onTrackList, false, 0, true);			
			_loader.load(urlRequest);						
		}
		
		private function onTrackList(e:Event):void{
			var jsonString:String = String(e.target.data);
			var result:Object = JSON.decode(jsonString);			
			
			for (var i:Number = 0; i < result.length; i++) {				
				this._tracks[result[i].track_id] = {id:result[i].track_id, title:result[i].track_title, file:result[i].track_file_name};		
			}	
			this.getZoneTrackKeys();
		}
		public function get trackList():Array {
			return this._tracks;	
		}		
		
		// Get the Zone Track Key Lookup Data (zoneTrack_id, track_id, zone_id, rack_style);
		private function getZoneTrackKeys():void{
			var urlRequest:URLRequest = new URLRequest(this._gatewayURL +  "/gaia.getZoneTrackKeys");
			urlRequest.method = URLRequestMethod.POST;
			_loader.removeEventListener(Event.COMPLETE, onTrackList);
            _loader.addEventListener(Event.COMPLETE, onZoneTrackKeys, false, 0, true);			
			_loader.load(urlRequest);									
		}	
		
		private function onZoneTrackKeys(e:Event):void{
			var jsonString:String = String(e.target.data);
			var result:Object = JSON.decode(jsonString);			
			
			for (var i:Number = 0; i < result.length; i++) {				
				var r:Object = result[i];
				if (this._zones[r.zone_id] != null && this._tracks[r.track_id] != null){
					if (r.track_style == 1){
						this._zones[r.zone_id].music.push(this._tracks[r.track_id]);
					}else if(r.track_style == 2){
						this._zones[r.zone_id].combat.push(this._tracks[r.track_id]);
					}
				}	
			}

			finish();
		}
		private function finish():void {
			_loader = null;						
			this.dispatchEvent(new Event(LOADED));	
		}
			
								
		public function getZoneMusic(zoneId:String):Array{
			var music:Array = new Array();
			//--- finde zoneId
			for each(var z:Object in this._zones){
				if (z.name == zoneId){
					music = z.music;
					break;
				}
			}			
			return music;
		}
		public function getZoneCombat(zoneId:String):Array{
			var music:Array = new Array();
			//--- finde zoneId
			for each(var z:Object in this._zones){
				if (z.name == zoneId){
					music = z.combat;
					break;
				}
			}			
			return music;
		}
		
		public function getServerIp():String{			
			var srv:String = this._servers[Math.floor(Math.random() * this._servers.length)];
			return srv;
		}
	}
}
