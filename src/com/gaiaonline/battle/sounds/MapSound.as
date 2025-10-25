package com.gaiaonline.battle.sounds
{
	import com.gaiaonline.battle.map.IMapRoomManager;
	import com.gaiaonline.battle.newactors.ActorManager;
	import com.gaiaonline.battle.newactors.BaseActor;
	import com.gaiaonline.flexModulesAPIs.globalevent.GlobalEvent;
	import com.gaiaonline.objectPool.ObjectPool;
	import com.gaiaonline.utils.DisplayObjectUtils;
	import com.gaiaonline.utils.FrameTimer;
	
	import flash.events.Event;
	import flash.geom.Point;
	import flash.media.Sound;
	import flash.media.SoundChannel;
	import flash.media.SoundTransform;
	
	public class MapSound
	{
		private var sounds:Array;		
		private var pos:Point;
		private var playing:Boolean = false;
		private var channel:SoundChannel
		private var maxRadius:int = 200;
		private var minRadius:int = 100;
		private var maxVolume:Number = 100;
		
		private var fallOff:Boolean = true;
		private var is3d:Boolean = true;
		private var roomOnly:Boolean = false;
		private var roomId:String;
		private var _mapRoomManager:IMapRoomManager;
		private var masterVolume:int = 100;
		private var minInterval:int = 0;
		private var maxInterval:int = 0;
		private var repeat:int = 0;
		public var autoPlay:Boolean = true;
		public var soundId:String;
		
		private var playCount:int = 0;
		
		private var actor:BaseActor = null;
	
		private var _soundPoolManager:ISoundPoolManager = null;
		private var _currentSoundPool:ObjectPool = null;
		private var _currentSound:Sound = null;		
		
		private var _audioSettings:AudioSettings = null;		

		public function MapSound(audioSettings:AudioSettings, soundPoolManager:ISoundPoolManager, soundId:String, pos:Point, currMapRoomId:String, fallOff:Boolean = true, maxRadius:int = 200, minRadius:int  = 100, 
								 is3d:Boolean = true, maxInterval:int = 0, minInterval:int =0, repeat:int = 0, 
								 roomOnly:Boolean = false, roomId:String= null, mapRoomManager:IMapRoomManager = null, autoplay:Boolean = true)
		{
			this._audioSettings = audioSettings;
			
			_soundPoolManager = soundPoolManager;
			this.soundId = soundId;			
			this.pos = pos;			
			this.sounds =  new Array();	
			this.fallOff = fallOff;
			this.maxRadius = maxRadius;
			this.minRadius = minRadius;
			this.is3d = is3d;
			this.minInterval = minInterval;
			this.maxInterval = maxInterval;
			this.repeat = repeat;			
			this.roomOnly = roomOnly;
			this.roomId = roomId;
			this._mapRoomManager = mapRoomManager;
			this.autoPlay = autoplay;				
			this.playCount = 0;

			this.actor = ActorManager.getInstance().myActor;			
			DisplayObjectUtils.addWeakListener(GlobalEvent.eventDispatcher, GlobalEvent.PLAYER_CREATED, onPlayerCreated);
			
			DisplayObjectUtils.addWeakListener(GlobalEvent.eventDispatcher, AudioSettingsEvent.SOUND_VOLUME_CHANGED, onSoundVolumeChanged);			
		}

		private function onPlayerCreated(e:GlobalEvent):void {
			this.actor = e.data.actor;
		}
		
		private function onSoundVolumeChanged(e:AudioSettingsEvent):void {
				this.setVolume(this.calcVolume());
		}
		
		public function addSound(sound:String, volume:int = 50, startTime:Number = 0, endTime:Number = 24):void{
			this.sounds.push({s:sound, v:volume, st:startTime, et:endTime});	
		}

		static private const FRAME_TIMER:int = 500;		
		private var _volumeAdjustmentTimer:FrameTimer = new FrameTimer(onPeriodicallyCorrectVolume);
		private var _soundQueueTimer:FrameTimer = new FrameTimer(playNext);		
		public function start():void{
			if (!this.playing){				
				this.setInterval(0, this.maxInterval);
				this._volumeAdjustmentTimer.start(FRAME_TIMER);
			}
		}
		public function stop(stopTimer:Boolean = false):void{
			if (this.channel != null && this.playing){
				this.channel.stop();				
			}

			if (stopTimer) {
				this._volumeAdjustmentTimer.stop();
				this._soundQueueTimer.stop();
			}
			checkInCurrentSound();
			this.playing = false;			
		}		
				
		private function setInterval(st:int , et:int):void{			
			var interval:int = Math.floor(st +(Math.random() * (et - st + 1)));						
			interval = Math.max(0, interval);
			
			this._soundQueueTimer.start(interval * 1000, 1);
		}
		
		private var playNextSoundTransform:SoundTransform = new SoundTransform();
		private function playNext():void
		{
			try
			{
				if (this.repeat > 0  && this.playCount >= this.repeat){					
					this.stop();
					this._volumeAdjustmentTimer.stop();
					this.playCount += 1;
					return;
				}
				
				const iRandom:int = this.getRandomSoundIndex(12);				
				
				if (iRandom > -1)
				{	
					const v:Number = this.calcVolume();
					if (v != 0) {
						this.playCount += 1;		
						const soundId:String = sounds[iRandom].s;		
						
						this.maxVolume = sounds[iRandom].v;		
						this.playNextSoundTransform.volume = 0;
						this.playNextSoundTransform.pan = 0;						
						
						_currentSoundPool = _soundPoolManager.getSoundPool(soundId);
						_currentSound = _currentSoundPool.checkOut() as Sound;
						
						this.channel = _currentSound.play(0, 0, this.playNextSoundTransform);
						this.channel.addEventListener(Event.SOUND_COMPLETE, onSoundCompleted, false, 0, true);

						this.playing = true;					
						this.setVolume(v);			
					}
				}
				else{
					this.stop();
				}
			}catch (err:Error){				
				this.stop();
			}		
		}
		
		private function getRandomSoundIndex(hour:Number):int
		{
			// [kja] previously we returned an array of contenders that the caller could randomly choose from - I'm trying to quiet profiler noise
			var nContenders:int = 0;
			for each (var obj:Object in this.sounds)
			{
				if (hour >= obj.st && hour <= obj.et)
				{
					++nContenders;
				}
			}			
			if (nContenders)
			{
				var index:int = 0;
				var iFound:int = 0;
				var iTarget:int = Math.random() * nContenders;
				for each (var obj2:Object in this.sounds)
				{
					if (hour >= obj2.st && hour <= obj2.et)
					{
						if (iFound++ == iTarget)
						{
							return index;
		}		
					}
					++index;
				}
			}
			return -1;
		}		
		
		private function onSoundCompleted(evt:Event):void{
			checkInCurrentSound();
			this.setInterval(this.minInterval, this.maxInterval);								
		}
		
		private function checkInCurrentSound():void{
			if(_currentSoundPool && _currentSound){
				_currentSoundPool.checkIn(_currentSound);
				_currentSoundPool = null;
				_currentSound = null;
			}
		}
		
		private function calcVolume():Number {
			if (this.roomOnly && this._mapRoomManager != null  && this.roomId != null){
				if (this._mapRoomManager.getCurrentMapRoom().serverRoomId != this.roomId){
					return 0;
				}
			}
			
			if (this.actor){				
				const maxVolPct:Number = this.maxVolume/100; 
				if (this.fallOff){
					const dx:Number = this.pos.x - this.actor.x;
					const dy:Number = this.pos.y - this.actor.y;
					const dist:Number = Math.sqrt(dx*dx + dy*dy);

					var v:Number = maxVolPct * (1 - ((dist - this.minRadius)/(this.maxRadius - this.minRadius)) );
					
					// tansfer back to masterVolume
					v *= (this._audioSettings.soundVolume/100);
					
					// range check it, 0 <= v <= maxVolPct
					return Math.min(Math.max(0, v), maxVolPct);						
				}
				return maxVolPct;
			}
			return 0;
		}
		
		private function setVolume(v:Number):void{
			if (v == 0 && this.playing) {
				this.stop();
				return;
			}

			/*setting sound volume according to slider position*/
			const sliderVolume:Number = v * this._audioSettings.soundVolume/100;
			if (this.channel != null && this.playing && sliderVolume > 0){
				var soundTransform:SoundTransform = this.channel.soundTransform;
				soundTransform.volume = sliderVolume;
				var dx:Number = this.pos.x - this.actor.x;
				soundTransform.pan = this.is3d ? dx/this.maxRadius : 0; 
				this.channel.soundTransform = soundTransform;
			} else if (v > 0 && !this.playing){
				this.playing = true;
				this.setInterval(0, this.maxInterval);
			} 
		}

		private function onPeriodicallyCorrectVolume():void{
			this.setVolume(this.calcVolume());
		}
		
		public function resetPlayCount():void{
			this.playCount = 0;
		}
		
		public function dispose():void{
			if (this.channel != null){
				this.channel.stop();
				this.channel.removeEventListener(Event.SOUND_COMPLETE, onSoundCompleted);
			}
			this._volumeAdjustmentTimer.stop();
			this._soundQueueTimer.stop();

			for (var s:int = 0 ; s < this.sounds.length; s++){
				this.sounds[s] = null;					
				delete this.sounds[s];
			}
			
			this.sounds = null;
			this.channel = null;
		}
	}
}
