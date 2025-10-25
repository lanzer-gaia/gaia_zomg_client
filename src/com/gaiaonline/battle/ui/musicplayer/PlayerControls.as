package com.gaiaonline.battle.ui.musicplayer {
	import com.gaiaonline.battle.ApplicationInterfaces.IUIFramework;
	import com.gaiaonline.battle.sounds.AudioSettings;
	import com.gaiaonline.battle.sounds.AudioSettingsEvent;
	import com.gaiaonline.battle.sounds.MusicState;
	import com.gaiaonline.battle.ui.ToolTipOld;
	import com.gaiaonline.battle.ui.events.UiEvents;
	import com.gaiaonline.flexModulesAPIs.globalevent.GlobalEvent;
	import com.gaiaonline.utils.DisplayObjectUtils;
	
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.events.TimerEvent;
	import flash.geom.Rectangle;
	import flash.utils.Timer;

	public class PlayerControls {
		private var controlItems:MovieClip;
		private var miniPlayer:MovieClip;
		private var timeDrag:Boolean = false;
		private var seekTimer:Timer = new Timer(1 * 1000);
		private var tm:TrackManager;

		// Closes the music channel after some period of inaudibility (i.e. mute, volume 0, pause), to avoid all those CPU cycles spent in the [tincan] stack.
		// Set this timer to null to deactivate the feature - kja
		private var _inaudibilityTimer:Timer = new Timer(27 * 1000);  // because 27 is easy to grep ;)
		
		private var _uiFramework:IUIFramework = null;

		public function PlayerControls(uiFramework:IUIFramework, mPlayerControls:MovieClip,MiniPlayer:MovieClip){
			this._uiFramework = uiFramework;
			this.controlItems = mPlayerControls;
			this.miniPlayer = MiniPlayer;

			//CONTROLS EVENTS
			this.controlItems.playBtn.addEventListener(MouseEvent.CLICK,onPlayTrack, false, 0, true);
			this.miniPlayer.playBtnMini.addEventListener(MouseEvent.CLICK,onPlayTrack, false, 0, true);
			this.controlItems.backBtn.addEventListener(MouseEvent.CLICK,onPrevTrack, false, 0, true);
			this.controlItems.fwdBtn.addEventListener(MouseEvent.CLICK,onNextTrack, false, 0, true);
			this.controlItems.stopBtn.addEventListener(MouseEvent.CLICK,onStopTrack, false, 0, true);
			this.controlItems.muteBtn.addEventListener(MouseEvent.CLICK,onMute, false, 0, true);			
			this.miniPlayer.muteBtnMini.addEventListener(MouseEvent.CLICK,onMute, false, 0, true);			
			this.controlItems.muteBtn.gotoAndStop(1);
			this.miniPlayer.muteBtnMini.gotoAndStop(1);
			this.miniPlayer.restoreBtn.addEventListener(MouseEvent.CLICK,restorePlayerView, false, 0, true);

			//TIME POSITION BTN
			this.controlItems.dragTime.buttonMode = true;
			this.controlItems.dragTime.addEventListener(MouseEvent.MOUSE_DOWN,startDragTime, false, 0, true);
			this.controlItems.addEventListener(Event.ADDED_TO_STAGE,onAddedStage, false, 0, true);
			
			//VOLUME SETTING
			this.setVolumeTo(uiFramework.volumes.musicVolume);
			this.controlItems.volumeOptions.buttonMode = true;
			this.controlItems.volumeOptions.addEventListener(MouseEvent.MOUSE_DOWN, onStartSetVolume, false, 0, true);

			uiFramework.volumes.addEventListener(AudioSettingsEvent.MUSIC_VOLUME_CHANGED, onMusicVolumeChanged, false, 0, true);
			uiFramework.volumes.addEventListener(AudioSettingsEvent.MUSIC_MUTE_CHANGED, onMusicMuteChanged, false, 0, true);
			uiFramework.volumes.addEventListener(AudioSettingsEvent.MUSIC_PLAYBACK_CHANGED, onMusicPlaybackChanged, false, 0, true);

			updatePlayBtnState();
			
			this.seekTimer.start();
			this.controlItems.playTime.text = "0:00";
			this.controlItems.timeBar.scaleX = 0;

			GlobalEvent.eventDispatcher.addEventListener(GlobalEvent.MUSIC_PLAYER_STATE_CHANGED, onMusicPlayerStateChanged);
			
			var tooltipManager:ToolTipOld = this._uiFramework.tooltipManager;
			tooltipManager.addToolTip(this.controlItems.playBtn, "Play/Pause");
			tooltipManager.addToolTip(this.miniPlayer.playBtnMini, "Play/Pause");
			tooltipManager.addToolTip(this.controlItems.backBtn, "Previous Track");
			tooltipManager.addToolTip(this.controlItems.fwdBtn, "Next Track");
			tooltipManager.addToolTip(this.controlItems.stopBtn, "Stop");
			tooltipManager.addToolTip(this.controlItems.muteBtn, "Toggle Mute");
			tooltipManager.addToolTip(this.miniPlayer.muteBtnMini, "Toggle Mute");
			tooltipManager.addToolTip(this.miniPlayer.restoreBtn, "Restore Full Player");
			tooltipManager.addToolTip(this.controlItems.dragTime, "Set Track Position");

			if (this._inaudibilityTimer) {
				this._inaudibilityTimer.addEventListener(TimerEvent.TIMER, onInaudibleTimeout, false, 0, true);
			}
		}

		static private const BUTTON_STATE_PLAY:int = 1;
		static private const BUTTON_STATE_PAUSE:int = 2;
		private function updatePlayBtnState():void
		{
			const state:int = this._uiFramework.volumes.musicState == MusicState.PLAYING ? BUTTON_STATE_PAUSE : BUTTON_STATE_PLAY; 

			this.controlItems.playBtn.gotoAndStop(state);
			this.miniPlayer.playBtnMini.gotoAndStop(state);
		}
		private function onMusicPlaybackChanged(e:Event):void
		{
			updatePlayBtnState();
		}
		private function onMusicPlayerStateChanged(e:GlobalEvent):void
		{
			var state:String = e.data.state;
			if (state == "mini" || state == "full") {
				DisplayObjectUtils.addWeakListener(this.seekTimer, TimerEvent.TIMER, setStreamSeek);
			} else {
				this.seekTimer.removeEventListener(TimerEvent.TIMER, setStreamSeek);				
			}
		}

		// [kja] this might have a better home in AudioSettings.
		private function onAudibilityChange(e:MPEvents):void
		{
			if (this._inaudibilityTimer) {
				if (e.value.audible) {
					this._inaudibilityTimer.stop();
				}
				else {
					this._inaudibilityTimer.reset();
					this._inaudibilityTimer.start();
				}
			}
		}

		private function onInaudibleTimeout(e:Event):void {
			this._inaudibilityTimer.stop();
			onStopTrack(null);
		}
		
		public function setTrackManager(trackManager:TrackManager):void{

			this.tm = trackManager;
			this.tm.addEventListener(MPEvents.AUDIBILITY_CHANGE, onAudibilityChange, false, 0, true); 
		}
		
		private function onAddedStage(e:Event):void{
			//TIME SLIDER
			this.controlItems.dragTime.addEventListener(MouseEvent.MOUSE_UP,stopTimeDrag, false, 0, true);			
			this.controlItems.dragTime.stage.addEventListener(MouseEvent.MOUSE_UP,stopTimeDrag, false, 0, true);
		}

		private function startDragTime(e:MouseEvent):void{
			var dragLimit:Rectangle = new Rectangle(35,57.5,130,0);
			this.controlItems.dragTime.startDrag(false,dragLimit);
			this.timeDrag = true;
		}
		
		private function restorePlayerView(e:MouseEvent):void{
			var r:MPEvents = new MPEvents(MPEvents.RESTORE_VIEW,"");
			this.miniPlayer.dispatchEvent(r);			
		}
			
		private function stopTimeDrag(e:MouseEvent):void{
			if (this.timeDrag){
				this.timeDrag = false;
				this.controlItems.dragTime.stopDrag();
				var sX:Number = this.controlItems.dragTime.x-30;
				var positionProc:Number = sX/1.3;
				if (this.tm != null) this.tm.setSeekPosition(positionProc);
			}
		}
		
		private function setStreamSeek(se:TimerEvent):void{
			var sX:Number = this.controlItems.dragTime.x-30;
			var positionProc:Number = sX/1.3;
			if (this.tm != null) {
				var seekPos:Number = this.tm.getSeekPosition();
				var streamDuration:Number = this.tm.getStreamDuration();
				if (seekPos == 0){
					this.controlItems.playTime.text = "0:00";
					this.miniPlayer.playTime.text = "0:00";
					this.controlItems.timeBar.scaleX = 0;
					this.controlItems.dragTime.x = 35;
				} else {
					var timeVal:String = this.parseTimeValue(seekPos);
					this.controlItems.playTime.text = timeVal;
					this.miniPlayer.playTime.text = timeVal;
					var timeProcPosition:int = Math.floor(seekPos/(streamDuration/100));
					if (!this.timeDrag){
						this.controlItems.timeBar.scaleX = timeProcPosition/100;
						this.controlItems.dragTime.x = 35+(1.3*timeProcPosition);
					} else {
						this.controlItems.timeBar.scaleX = ((this.controlItems.dragTime.x-35)/1.3)/100;
					}
				}
			}
		}
		
		private function parseTimeValue(seekPos:Number):String{
			var minutes:int = Math.floor(seekPos/60000);
			var second:int = Math.round((seekPos-(minutes*60000))/1000);
			var output:String = String(minutes)+":";
			if (second< 10)
				output += "0"+String(second);
			else
				output += String(second);
			return output;
		}

		private function onPlayTrack(evt:MouseEvent):void
		{
			var btn:MovieClip = MovieClip(evt.currentTarget);
			if (this.tm)
			{
				switch (this._uiFramework.volumes.musicState) {
				case MusicState.PLAYING:
					this.tm.pauseTrack();
					break;
				case MusicState.STOPPED:
				case MusicState.PAUSED:
					this.tm.playTrack();
					break;
				}
			}			
		}
		
		private function onPrevTrack(evt:MouseEvent):void{
			if (this.tm != null) {
				this.tm.prevTrack();				
			}
		}
		
		private function onNextTrack(evt:MouseEvent):void{			
			if (this.tm != null) {
				this.tm.nextTrack();
			}
		}

		static private const UNMUTED_FRAME:int = 1;
		static private const MUTED_FRAME:int = 2;		
		private function onMute(evt:MouseEvent):void
		{
			var btn:MovieClip = MovieClip(evt.currentTarget);
			this._uiFramework.volumes.musicMuted = btn.currentFrame == UNMUTED_FRAME;  // toggle!				
		}

		private function onMusicMuteChanged(e:AudioSettingsEvent):void
		{
			const frame:int = AudioSettings(e.target).musicMuted ? MUTED_FRAME : UNMUTED_FRAME; 

			this.controlItems.muteBtn.gotoAndStop(frame);
			this.miniPlayer.muteBtnMini.gotoAndStop(frame);
		}

		private function onStopTrack(_unused:MouseEvent):void{
			if (this.tm != null) this.tm.stopTrack();
		}
		
		// slider implementation
		private static const FUDGE:int = 18;
		private static const MAX_VOLUME_X:Number = 19;
		private function get draggedVolumeX():Number
		{
			return Math.min(Math.max(this.controlItems.volumeOptions.mouseX, 0), MAX_VOLUME_X);
		}
		private function setSliderPositionFromMouse():void
		{
			this.controlItems.volumeOptions.volumeLevel.x = draggedVolumeX - FUDGE;

			const volumeValue:Number = draggedVolumeX * 100 / MAX_VOLUME_X;

			var event:UiEvents = new UiEvents(UiEvents.SET_MUSIC_VOLUME, null);
			event.value = volumeValue;
			this.controlItems.dispatchEvent(event);
		}		
		private function onStartSetVolume(e:MouseEvent):void
		{
			this._uiFramework.stage.addEventListener(MouseEvent.MOUSE_MOVE, onDragVolume, false, 0, true);			
			this._uiFramework.stage.addEventListener(MouseEvent.MOUSE_UP, onEndSetVolume, false, 0, true);
			setSliderPositionFromMouse();			
		}
		private function onDragVolume(e:Event):void
		{
			setSliderPositionFromMouse();
		}
		private function onEndSetVolume(e:MouseEvent):void
		{			
			this._uiFramework.stage.removeEventListener(MouseEvent.MOUSE_MOVE, onDragVolume);			
			this._uiFramework.stage.removeEventListener(MouseEvent.MOUSE_UP, onEndSetVolume);			
			setSliderPositionFromMouse();
		}
		
		// events from AudioSettings
		private function onMusicVolumeChanged(ve:AudioSettingsEvent):void
		{
			setVolumeTo(AudioSettings(ve.target).musicVolume);
		}		
		private function setVolumeTo(volValue:Number):void
		{
			const xM:Number = MAX_VOLUME_X * (volValue/100);
			this.controlItems.volumeOptions.volumeLevel.x = xM - FUDGE;
		}
	}
}