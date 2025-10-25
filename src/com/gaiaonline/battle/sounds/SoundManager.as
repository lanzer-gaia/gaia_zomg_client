package com.gaiaonline.battle.sounds
{
	import com.gaiaonline.battle.StepLoader;
	import com.gaiaonline.battle.map.IMapRoomManager;
	import com.gaiaonline.battle.utils.BattleUtils;
	import com.gaiaonline.flexModulesAPIs.globalevent.GlobalEvent;
	import com.gaiaonline.objectPool.LoaderFactory;
	import com.gaiaonline.platform.map.IMapSoundLoader;
	import com.gaiaonline.platform.map.IMapSoundLoaderHandler;
	import com.gaiaonline.platform.map.IMapSoundManager;
	import com.gaiaonline.utils.DisplayObjectUtils;
	import com.gaiaonline.utils.RegisterUtils;
	import com.gaiaonline.utils.factories.LoaderContextFactory;
	
	import flash.display.Loader;
	import flash.display.LoaderInfo;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.geom.Point;
	import flash.net.URLRequest;
	
	
	public class SoundManager implements IMapSoundManager, IMapSoundLoader
	{				
		private var _mapSounds:Array = [];
		private var soundFile:Object = new Object();
		private var mapRef:IMapRoomManager;
		private var _soundPoolManager:SoundPoolManager = null;
		private var _audioSettings:AudioSettings = null;
		
		public function SoundManager(mapRef:IMapRoomManager, audioSettings:AudioSettings){
			this._audioSettings = audioSettings;
			this.mapRef = mapRef;		
			
			DisplayObjectUtils.addWeakListener(GlobalEvent.eventDispatcher, GlobalEvent.MAP_SOUND_PLAY, playSound);
			DisplayObjectUtils.addWeakListener(GlobalEvent.eventDispatcher, GlobalEvent.MAP_SOUND_SETAUTOPLAY, setAutoPlay);
			DisplayObjectUtils.addWeakListener(GlobalEvent.eventDispatcher, GlobalEvent.MAP_SOUND_STOP, stopSound);
			DisplayObjectUtils.addWeakListener(GlobalEvent.eventDispatcher, GlobalEvent.MAP_LOAD_ZONE, clear);
		}
		
		private var _handlers:Array = [];
		
		public function registerForLoadEvents(handler:IMapSoundLoaderHandler):void{
			RegisterUtils.register(_handlers, handler);
		}
		
		public function unregisterForLoadEvents(handler:IMapSoundLoaderHandler):void{
			RegisterUtils.unregister(_handlers, handler);
		}
		
		
		
		
		// loading
		public function loadSoundFile(url:String):void
		{
			GlobalEvent.eventDispatcher.dispatchEvent(new GlobalEvent(GlobalEvent.MAP_SOUND_LOAD_START, null));
			var fileName:String = url;
			var l:Loader = LoaderFactory.getInstance().checkOut()
			l.contentLoaderInfo.addEventListener(Event.COMPLETE, onSoundLoaded);
			l.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, onIoError);			
			l.contentLoaderInfo.addEventListener(ProgressEvent.PROGRESS, onProgress);
			StepLoader.add(l, new URLRequest(fileName), LoaderContextFactory.getInstance().getLoaderContext());
		}
		
		private function onIoError(evt:IOErrorEvent):void{
			for each(var handler:IMapSoundLoaderHandler in _handlers){
				handler.onSoundIOError();
			}

		}
		
		private function onSoundLoaded(evt:Event):void{
			LoaderInfo(evt.target).loader.contentLoaderInfo.removeEventListener(ProgressEvent.PROGRESS, onProgress);
			LoaderInfo(evt.target).loader.contentLoaderInfo.removeEventListener(Event.COMPLETE, onSoundLoaded);
			LoaderInfo(evt.target).loader.contentLoaderInfo.removeEventListener(IOErrorEvent.IO_ERROR, onIoError);			
			this.soundFile = (LoaderInfo(evt.target).content);		
				
			for each(var handler:IMapSoundLoaderHandler in _handlers){
				handler.onSoundLoadComplete();
			}

			
			_soundPoolManager = new SoundPoolManager(soundFile);
			
			LoaderFactory.getInstance().checkIn(LoaderInfo(evt.target).loader)
		}
		
		private function onProgress(evt:ProgressEvent):void{
//			dispatchEvent(evt);
			for each(var handler:IMapSoundLoaderHandler in _handlers){
				handler.onSoundProgress(evt);
			}
		}
		
		//----------
		
		public function addMapSound(fileMapSound:Object, pos:Point, roomId:String, currMapRoomId:String):void {
			var autoPlay:Boolean = true;			
			if (fileMapSound.autoPlay != null){
				autoPlay = fileMapSound.autoPlay;
			}
			var msObj:MapSound = new MapSound(this._audioSettings, _soundPoolManager, fileMapSound.name, pos, currMapRoomId, fileMapSound.fallOff, fileMapSound.maxRadius, fileMapSound.minRadius,
											  fileMapSound.is3d, fileMapSound.maxInterval, fileMapSound.minInterval, 
											  fileMapSound.repeat, fileMapSound.roomOnly, roomId, this.mapRef, autoPlay);
											  
			var soundIdsLength:int = fileMapSound.soundIds.length
			for (var sid:int = 0 ; sid < soundIdsLength; sid++){
				var soundIds:Array = fileMapSound.soundIds[sid].split(",");
				var soundId:String = soundIds[0];	
				if(soundId) {
					var volume:* = soundIds[1];
					if (volume == null){
						volume = 100;
					}
					msObj.addSound(soundId,volume);
				}					
			}			
			if (msObj.autoPlay){
				msObj.start();	
			}
			this._mapSounds.push(msObj);
		}
		
		private function clear(event:GlobalEvent):void{
			for (var ms:int = 0; ms < this._mapSounds.length; ms++){
				MapSound(this._mapSounds[ms]).dispose();	
				delete this._mapSounds[ms];			
			}
			
			this._mapSounds.length = 0;
			BattleUtils.cleanObject(this.soundFile);
		}
		
		private function playSound(event:GlobalEvent):void {
			var soundId:String = String(event.data);
			for (var i:int = 0; i< this._mapSounds.length; i++){
				if (this._mapSounds[i].soundId == soundId){
					var ms:MapSound = this._mapSounds[i] as MapSound;
					if (ms != null){
						ms.resetPlayCount();
						ms.start();
					}
				}
			}
		}
		private function stopSound(event:GlobalEvent):void{
			var soundId:String = String(event.data);
			for (var i:int = 0; i<this._mapSounds.length; i++){
				if (this._mapSounds[i].soundId == soundId){
					var ms:MapSound = this._mapSounds[i];																
					ms.stop(true);								
				}
			}
		}
		private function setAutoPlay(event:GlobalEvent):void
		{
			var soundId:String = event.data.id;
			var autoPlay:Boolean = event.data.autoPlay;
			
			for (var i:int = 0; i<this._mapSounds.length; i++){
				if (this._mapSounds[i].soundId == soundId){
					var ms:MapSound = this._mapSounds[i];										
					ms.autoPlay = autoPlay;						
				}
			}
		}
		
		private function hasSoundFile():Boolean{
			return (this.soundFile != null);
		}
		
		
	}
}