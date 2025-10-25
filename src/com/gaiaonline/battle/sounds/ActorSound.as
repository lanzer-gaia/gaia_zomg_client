package com.gaiaonline.battle.sounds
{
	import com.gaiaonline.battle.newactors.ActorManager;
	import com.gaiaonline.battle.newactors.BaseActor;
	import com.gaiaonline.utils.FrameTimer;
	
	import flash.events.Event;
	import flash.media.Sound;
	import flash.media.SoundChannel;
	import flash.media.SoundTransform;
	
	public class ActorSound
	{		
		private var actorRef:BaseActor;
		private var sounds:Object;
		private var soundRef:Object;
		private var channel:SoundChannel
		private var frame:String;
		private var sid:String;
		
		//public var masterVolume:Number = 100;		
				
		private var isPlaying:Boolean = false;
		
		private var minRadius:Number = 30;
		private var maxRadius:Number = 200;			
		private var maxVolume:Number = 00;	
		private var repeat:int = 0;	
		private var isInit:Boolean = false;	
		private var lastLoop:String;
		private var stop:Boolean = false;
		private var overrideSound:Boolean = false;
		private var _curSound:Sound;
		
		private var _audioSettings:AudioSettings = null;
	
		
		private var _actorSoundManager:ActorSoundManager;
			
		public function ActorSound(audioSettings:AudioSettings){
			_audioSettings = audioSettings;
		}
		
		private var _frameTimer:FrameTimer = new FrameTimer(onTimer);
		public function initSound(actorRef:BaseActor, soundRef:Object):void{
			this.actorRef = actorRef;
			this.soundRef = soundRef;			
			this._actorSoundManager = ActorSoundManager.getInstance();
				
			if (this.soundRef != null && this.soundRef.soundList != null){				
				if (this.soundRef.maxRadius != null){
					this.maxRadius = this.soundRef.maxRadius;					
				}
				if (this.soundRef.minRadius != null){
					this.minRadius = this.soundRef.minRadius;					
				}												
				
				var soundList:Array = this.soundRef.soundList;
				this.sounds = new Object();
						
				if (soundList != null && soundList.length > 0){
					for (var i:int = 0; i< soundList.length; i++){
						var frame:String = soundList[i].frame;
						var vol:int = soundList[i].vol;
						var repeat:int = soundList[i].repeat;
						var list:Array = soundList[i].sounds;					
						this.sounds[frame] = {list:list, vol:vol, repeat:repeat};
					}
					
					this._frameTimer.startPerFrame(2);
					
					this.isInit = true;
					if (this.frame != null){
						this.playFrame(this.frame);
					}		
								
				}			
			
				
			}
			
		}
				
		public function playFrame(frame:String, stop:Boolean = false, overrideSound:Boolean = false):void{
			this.stop = stop;			
			if (this.overrideSound && !overrideSound){
				if (this.sounds != null && this.sounds[frame] != null){
					this.repeat = this.sounds[frame].repeat;						
					if (this.repeat <=0 ){
						this.lastLoop = this.getSoundId(frame);
					}
				}				
				return;
			}	
			
			this.overrideSound = overrideSound;			
									
			if (this.isInit){
				
				// stop anny sound playing 
				this.stopSound();				
				
				var n:String = "NA";
				if (this.actorRef != null){
					n = this.actorRef.actorName;
				}				
				
				// pick a soudn Id			
				if (this.sounds != null && this.sounds[frame] != null){						
					this.sid = this.getSoundId(frame);					
					if (this.sid != null){							
						this.maxVolume = this.sounds[frame].vol;					
						this.repeat = this.sounds[frame].repeat;						
						if (this.repeat <=0 ){
							this.lastLoop = this.sid;
							this.repeat = 100000;						
						}								
							
					}else{
						this.stopSound();						
						this.sid = null;
						this._curSound = null;
					}
									
				}else{				
					this.stopSound();
					this.sid = null;
					this._curSound = null;		
				}
				
			}else{
				this.frame = frame;
			}
				
						
		}
		private function getSoundId(frame:String):String{						
			var min:int = 0;
			var max:int = this.sounds[frame].list.length - 1;				
			var i:int = Math.floor(min +(Math.random() * (max - min + 1)));						
			var sid:String = this.sounds[frame].list[i];						
			return sid;
		}
			
		private function startSound():void{
			try{
				if (this.sid != null && this.soundRef != null){
					this._curSound = this._actorSoundManager.checkout(this.soundRef, this.sid);
					if (this._curSound != null){									
						this.channel = this._curSound.play(0, this.repeat, new SoundTransform(0,0));					
						if (this.channel != null){
							//trace("add listener onSoundCompleted")
							this.channel.addEventListener(Event.SOUND_COMPLETE, onSoundCompleted);
						}
					}else{
						this.stopSound();
						this.sid = null;	
						this._curSound = null;							
					}
				}
			}catch(err:Error){
				this.stopSound();
				this.sid = null;
				this._curSound = null;				
			}
			
			
		}
		
		private function stopSound():void{
			if (this.channel != null){				
				this.channel.stop();				
				//trace("STOP SOUND Remove listener onSoundCompleted")
				this.channel.removeEventListener(Event.SOUND_COMPLETE, onSoundCompleted);
				if (this.sid != null && this.soundRef != null && this._curSound != null){
					//trace("CheckIn Sound", this.sid, this.soundRef);
					this._actorSoundManager.checkin(this.soundRef, this.sid, this._curSound);			
				}											
			}		
			this.channel = null;
		}
				
		private function onSoundCompleted(evt:Event):void{
			//trace("ON SOUND COMPLETED")
			this.overrideSound = false;
			this.stopSound();			
			if (this.lastLoop != null && !this.stop){
				this.sid = this.lastLoop;
				this.startSound();
			}else{
				this.sid = null;
				this._curSound = null;
			}			
		}

		public function onTimer():void{
			if (ActorManager.getInstance().myActor == null || ActorManager.getInstance().myActor.position == null){
				if (this.channel == null && this.sid != null){ // if not playing start playing				  
					this.startSound();
				}else if(this.channel != null) {
					var trans1:SoundTransform = new SoundTransform();
					trans1.volume = 1;
					this.channel.soundTransform = trans1;   
				}
				return;
			}			   
			//--- Get distance..
			var dx:Number = 0;
			var dy:Number = 0;
			var dist:Number = 0;
			if (this.actorRef != null){				 
				dx = this.actorRef.position.x - ActorManager.getInstance().myActor.position.x;
				dy = this.actorRef.position.y - ActorManager.getInstance().myActor.position.y;
				dist = Math.sqrt(dx*dx + dy*dy);
			}
											
			if (dist <= this.maxRadius){ // if in range 

				var v:Number = (this.maxVolume/100) - ( ( (dist - this.minRadius) / (this.maxRadius - this.minRadius) ) * (this.maxVolume/100) );
				
				v = v * (this._audioSettings.soundVolume/100)						 
				if (v > (this.maxVolume/100)){
					v = (this.maxVolume/100);						   
				}else if (v <= 0){					  
					v = 0;									  
				}				   
		
				if (v > 0){
					if (this.channel == null && this.sid != null){ // if not playing start playing
						this.startSound();
					}
					
					if (this.channel != null && this.sid != null){
						// set volume base on dist	
	
						var trans:SoundTransform = new SoundTransform();
						trans.volume = v;
						trans.pan = dx/this.maxRadius;
						this.channel.soundTransform = trans;							
					}
				}	   
			
			}else{ // if out of range			   
				this.stopSound();
			}	   
			
		}

		
		public function dispose():void
		{
			this._frameTimer.stop();
			this._frameTimer = null; // shouldn't have to do this

			if (this.sid != null && this.soundRef != null && this._curSound != null){
				//trace("dispose CheckIn", this.sid, this.soundRef);
				this._actorSoundManager.checkin(this.soundRef, this.sid, this._curSound);			
			}	
			if (this.channel != null && (this.repeat >= 100000 || this.repeat <= 0)){
				this.channel.stop();
			}
			
			this._actorSoundManager = null;	
			this._curSound = null;
			this.actorRef = null;
			this.soundRef = null;
			this.sounds = null;
			this.channel = null;
		}
		
	}
}
