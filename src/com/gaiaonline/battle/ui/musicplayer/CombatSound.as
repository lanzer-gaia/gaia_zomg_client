package com.gaiaonline.battle.ui.musicplayer {
	import flash.display.Sprite;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.net.NetConnection;
	import flash.net.NetStream;
	import flash.events.*;	
	import flash.media.SoundTransform;
	import com.gaiaonline.battle.ui.musicplayer.MPEvents;
	import flash.media.Sound;
	import flash.media.SoundChannel;
	import flash.net.URLRequest;
	import fl.transitions.Tween;
	import fl.transitions.easing.Regular;
	import fl.transitions.TweenEvent;


	public class CombatSound extends Sprite{
		private var trackStream:Sound;
		private var trackVolume:Number;
		private var trackChannel:SoundChannel;
		private var soundData:SoundTransform = new SoundTransform(0);
		private var fadeTime:int = 3;
		private var fadeTween:Tween;

		public function CombatSound(urlTrack:String,baseVolume:Number=20,fadetime:int=3){
			//trace("[Music Widget] Combat track");
			this.fadeTime = fadetime;
			this.trackVolume = baseVolume;
			this.trackStream = new Sound();
			this.trackStream.load(new URLRequest(urlTrack));
			this.trackStream.addEventListener(Event.COMPLETE,onSoundLoaded, false, 0, true);
			this.trackStream.addEventListener(IOErrorEvent.IO_ERROR, errorHandler, false, 0, true);
		}
		
		private function onSoundLoaded(e:Event):void{
			//trace("[Music Widget] Combat track: Loaded");
			var se:MPEvents = new MPEvents(MPEvents.COMBAT_LOADED);
			this.dispatchEvent(se);
		}
		
		private function errorHandler(e:IOErrorEvent):void{
			//trace("[Music Widget] Combat track: Loading error");			
		}
		
		public function fadeIn():void{
			this.soundData = new SoundTransform(0);
			this.trackChannel = this.trackStream.play();
			this.trackChannel.soundTransform = this.soundData
			//trace(this.trackVolume,this.trackChannel.soundTransform.volume);
			//trace("Time: "+this.fadeTime);
			this.fadeTween = new Tween(this.soundData,"volume",Regular.easeInOut,0,this.trackVolume/100,this.fadeTime,true);			
			this.fadeTween.addEventListener(TweenEvent.MOTION_CHANGE,onFadeChange, false, 0, true);
			this.fadeTween.start();
		}
		
		private function onFadeChange(e:TweenEvent):void{
			this.trackChannel.soundTransform = this.soundData;
		}
		
		private function onFadeEnd(e:TweenEvent):void{
			//trace("cross end");
			this.dispose();
		}
		
		public function fadeOut():void{
			if (this.trackChannel != null){
				this.fadeTween = new Tween(this.soundData,"volume",Regular.easeInOut,this.soundData.volume,0,this.fadeTime,true);
				this.fadeTween.addEventListener(TweenEvent.MOTION_CHANGE,onFadeChange, false, 0, true);
				this.fadeTween.addEventListener(TweenEvent.MOTION_FINISH,onFadeEnd, false, 0, true);
				this.fadeTween.start();
			}
		}
		
		public function dispose():void{
			if (this.trackChannel != null){
				this.trackChannel.stop();
				this.trackChannel = null;
			}
			if (this.trackStream != null){
				this.trackStream = null;
			}
			this.fadeTween = null;			
		}
		
		public function set _fadetime(val:Number):void{
			this.fadeTime = val;			
		}



	}
}