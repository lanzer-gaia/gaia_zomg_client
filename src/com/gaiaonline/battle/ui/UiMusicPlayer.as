package com.gaiaonline.battle.ui{
	import com.gaiaonline.assets.UiBasicButton;
	import com.gaiaonline.battle.ApplicationInterfaces.IUIFramework;
	import com.gaiaonline.battle.gateway.BattleGateway;
	import com.gaiaonline.battle.sounds.AudioSettings;
	import com.gaiaonline.battle.sounds.AudioSettingsEvent;
	import com.gaiaonline.battle.sounds.MusicState;
	import com.gaiaonline.battle.ui.events.UiEvents;
	import com.gaiaonline.battle.ui.musicplayer.*;
	import com.gaiaonline.battle.utils.BattleUtils;
	import com.gaiaonline.flexModulesAPIs.globalevent.GlobalEvent;
	import com.gaiaonline.platform.map.IMapFiles;
	import com.gaiaonline.platform.map.MapFilesFactory;
	import com.gaiaonline.utils.factories.ILoaderContextFactory;
	
	import flash.display.MovieClip;
	import flash.display.SimpleButton;
	import flash.display.Stage;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.net.URLRequest;
	import flash.net.navigateToURL;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;	
	
	public class UiMusicPlayer extends MovieClip {
		private var petManager:PetManager;
		private var trackManager:TrackManager;
		private var playerControls:PlayerControls;
		private var MiniPlayer:MovieClip;
		private var miniDrag:Boolean;		
		private var trackList:MovieClip;
		private var trackListOpen:Boolean = false;
		private var minimized:Boolean = false;
		private var minizeBtn:UiBasicButton;
		private var cSound:CombatSound;

		private var _stage:Stage = null;
		
		private var justHereSoCompilerWontRemoveTextFields:TextField;
		private var justHereSoCompilerWontRemoveSimpleButton:SimpleButton;
				
		
		private var _gateway:BattleGateway = null;
		private var _uiFramework:IUIFramework = null;

		private const DIRECT_SONG_LINK:String = "https://www.directsong.com/index.php#/shop/product/GAIA101";
		
		public var miniPlayer:MovieClip;
		public var trackInfo:TextField;						
		public var trackNumber:TextField;		
		public var controlItems:MovieClip;
		public var directSong:SimpleButton;		
		public var trackHighlight:MovieClip;						
		public var trackListBtn:MovieClip;		
		public var petBg:MovieClip;

		private const SHOW_PLAYLIST_TT:String = "Show Playlist";
		private const HIDE_PLAYLIST_TT:String = "Hide Playlist";
		
		public function UiMusicPlayer(gateway:BattleGateway, uiFramework:IUIFramework, baseURL:String) {			
			this._gateway = gateway;			
			this._uiFramework = uiFramework;
			
			uiFramework.volumes.addEventListener(AudioSettingsEvent.MUSIC_PLAYBACK_CHANGED, onInitialMusicStateLoaded, false, 0, true);
			
			this.trackNumber.text = "[0]";
			this.trackNumber.mouseEnabled = this.trackInfo.mouseEnabled = false;
			this.trackInfo.selectable = false;
			this.trackInfo.autoSize = TextFieldAutoSize.LEFT;
			this.trackInfo.text = "--- initializing track list ---";
			this.MiniPlayer = this.miniPlayer;
			this.MiniPlayer.trackInfo.text = "--- initializing track list ---";
			this.MiniPlayer.playTime.text = "0:00";
			this.MiniPlayer.addEventListener(MouseEvent.MOUSE_DOWN,startMiniDrag, false, 0, true);
			this.MiniPlayer.addEventListener(Event.ADDED_TO_STAGE,onMiniAddedStage, false, 0, true);
			this.removeChild(this.MiniPlayer);			
			this.playerControls = new PlayerControls(this._uiFramework, this.controlItems,this.MiniPlayer);
			this.controlItems.addEventListener(UiEvents.SET_MUSIC_VOLUME,onSetVolume, false, 0, true);			
			
			this.trackHighlight.buttonMode = this.trackListBtn.buttonMode = true;
			
			this.trackListBtn.addEventListener(MouseEvent.MOUSE_OVER,trOver, false, 0, true);
			this.trackHighlight.addEventListener(MouseEvent.MOUSE_OVER,trOver, false, 0, true);
			this.trackListBtn.addEventListener(MouseEvent.MOUSE_OUT,trOut, false, 0, true);
			this.trackHighlight.addEventListener(MouseEvent.MOUSE_OUT,trOut, false, 0, true);
			this.trackListBtn.addEventListener(MouseEvent.CLICK,trOpen, false, 0, true);
			this.trackHighlight.addEventListener(MouseEvent.CLICK,trOpen, false, 0, true);

			updateTrackListTooltips();
			
			
			this.directSong.addEventListener(MouseEvent.CLICK, onDirectSongClick, false, 0, true);
			this._uiFramework.tooltipManager.addToolTip(this.directSong, "Visit www.directsong.com");
			
			//MINIZE BUTTON
			this.setMinize();
			
			this.tabChildren = false;
			this.miniPlayer.tabChildren = false;
			
			this.initPet(baseURL + "anim-pets/rockpuppy.swf", this._uiFramework.loaderContextFactory);
			GlobalEvent.eventDispatcher.addEventListener(GlobalEvent.NEW_ROOM_ENTERED, onNewRoomEntered, false, 0, true);			
		}
		
		private var musicZoneId:String = null;
		private function onNewRoomEntered(event:GlobalEvent):void{
			var mapFiles:IMapFiles = MapFilesFactory.getInstance().mapFiles;
			var nMusicZone:String = mapFiles.getMusicZone(event.data.newRoomId);
			if (nMusicZone != this.musicZoneId){
				this.musicZoneId = nMusicZone;
				initTracks(mapFiles.getMusic(this.musicZoneId));
			}
		}
		
		private function onAddedStage(e:Event):void{
			this.stage.addEventListener(MouseEvent.MOUSE_DOWN,clickOutsideList, false, 0, true);
		}
		
		private function onMiniAddedStage(e:Event):void{
			this.MiniPlayer.addEventListener(MouseEvent.MOUSE_UP,stopMiniDrag, false, 0, true);
			this.MiniPlayer.stage.addEventListener(MouseEvent.MOUSE_UP,stopMiniDrag, false, 0, true);
			this.stage.addEventListener(Event.RESIZE, onStageResize, false, 0, true);						
		}
		
		private function onSetVolume(e:UiEvents):void{			
			this.dispatchEvent(e.clone());			
		}		
		
		private function setMinize():void{
			this.minizeBtn = new UiBasicButton("MINIMIZE",true,true,76);
			this.minizeBtn.x = 120;
			this.minizeBtn.y = 200;			
			this.addChild(this.minizeBtn);
			this.minizeBtn.addEventListener(MouseEvent.CLICK,minizePlayerView, false, 0, true);
		}
		
		private function minizePlayerView(me:MouseEvent):void{
			var e:MPEvents = new MPEvents(MPEvents.MINIMIZE_VIEW,"");
			this.dispatchEvent(e);
		}
		
		//TRACK LIST FUNCTIONS
		private function clickOutsideList(e:MouseEvent):void{
			if ((e.target != this.trackHighlight) && (e.target != this.trackListBtn) && (e.target != this.trackList)){
				this.closeTrackList();
			}
		}
		
		private function trOver(e:MouseEvent):void{
			if (!this.trackListOpen) {
				this.trackListBtn.gotoAndStop(2);
				this.trackHighlight.alpha = 0.75;
			}
		}
		
		private function trOut(e:MouseEvent):void{
			if (!this.trackListOpen) {
				this.trackListBtn.gotoAndStop(1);
				this.trackHighlight.alpha = 1;
			}
		}
		
		private function trOpen(e:MouseEvent):void{
			if (this.trackManager != null){
				if (!this.trackListOpen) {
					this.trackListBtn.gotoAndStop(2);
					this.trackHighlight.alpha = 0.5;
					this.trackListOpen = true;
					if (this.trackList != null)
						if (this.contains(this.trackList)) this.removeChild(this.trackList);
					this.trackList = this.buildTrackList();
					this.trackList.x = 10;
					this.trackList.y = 173;
					this.addChild(this.trackList)

					updateTrackListTooltips();			
				} else {
					this.closeTrackList();
				}
			}
		}

		private function buildTrackList():MovieClip{
			var trackList:MovieClip = new UiTrackList();
			var count:int = 0;
			
			var trackObjectList:Array = this.trackManager.trackList;
			for (var t:int=0;t<trackObjectList.length; ++t){
				++count;

				var trackItem:UiTrackListItem = new UiTrackListItem();
				trackItem.buttonMode = true;
				trackItem.mouseChildren = false;					
				trackItem.trackNum.text = "["+ (t+1) +"]";
				trackItem.trackName.autoSize = TextFieldAutoSize.LEFT;
				trackItem.trackName.text = trackObjectList[t].trackTitle;
				trackItem.id = t;
				if (count%2 == 1){
					trackItem.frm = 2;
					trackItem.gotoAndStop(2);
				} else {
					trackItem.frm = 1;
					trackItem.gotoAndStop(1);										
				}
				trackItem.y = (count-1)*22;
				trackItem.addEventListener(MouseEvent.MOUSE_OVER,trackItemOver,false,0,true);
				trackItem.addEventListener(MouseEvent.MOUSE_OUT,trackItemOut,false,0,true);
				trackItem.addEventListener(MouseEvent.MOUSE_DOWN,trackItemClick,false,0,true);
				trackList.tiContainer.addChild(trackItem);
			}
			if (count < 5) trackList.scrollBar.visible = false;
			return trackList;
		}
		
		private function trackItemOver(e:MouseEvent):void{
			var t:Object = e.currentTarget;
			t.gotoAndStop(3);
		}
		
		private function trackItemOut(e:MouseEvent):void{
			var t:Object = e.currentTarget;
			t.gotoAndStop(t.frm);
		}
		
		private function trackItemClick(e:MouseEvent):void{
			this.closeTrackList();
			this.trackManager.setNewTrack(e.currentTarget.id);
		}

		private function closeTrackList():void{
			this.trackListBtn.gotoAndStop(1);
			this.trackHighlight.alpha = 1;
			this.trackListOpen = false;
			if (this.trackList != null){
				if (this.contains(this.trackList)) this.removeChild(this.trackList);
				this.trackList = null;
			}
			updateTrackListTooltips();			
		}

		private function updateTrackListTooltips():void
		{
			const tt:String = this.trackListOpen ? HIDE_PLAYLIST_TT : SHOW_PLAYLIST_TT;

			var ttm:ToolTipOld = this._uiFramework.tooltipManager;
			ttm.addToolTip(this.trackListBtn, tt);			
			ttm.addToolTip(this.trackHighlight, tt);						
		}

		private function startMiniDrag(e:MouseEvent):void{
				this.MiniPlayer.startDrag(false);
				this.miniDrag = true;
		}
		
		private function stopMiniDrag(e:MouseEvent):void{
			if (this.miniDrag){				
	 			BattleUtils.keepItemOnStage(this.MiniPlayer.stage, this.MiniPlayer);
				this.miniDrag = false;
				this.MiniPlayer.stopDrag();
				this.MiniPlayer.dispatchEvent(new Event("MOVE"));
			}
		}

		private function onStageResize(e:Event):void {
			BattleUtils.keepItemOnStage(this.MiniPlayer.stage, this.MiniPlayer);	
		}
		
		private var _firstTrackForcePlayed:Boolean = false;
		private var _initiallyStopped:Boolean = false;
		public function initTracks(trackList:Array, fade:Boolean = false):void
		{
			this.closeTrackList();

			if (trackList.length == 0) {
 				this.trackNumber.text = "[0]";
				this.trackInfo.text = "No track list found";
				this.MiniPlayer.trackInfo.text = this.trackInfo.text;
				this.MiniPlayer.playTime.text = "0:00";				
			}

			if (this.trackManager == null) {
				this.trackManager = new TrackManager(this._gateway, this._uiFramework.volumes);
				this.playerControls.setTrackManager(this.trackManager);
				this.trackManager.addEventListener(MPEvents.NEW_TRACK_INIT, setTrackInfo, false, 0, true);
			}
			
			this.trackManager.trackList = trackList;
			this.trackManager.nextTrack(true);

			// you have to force the track manager to play the first time
			if (!_firstTrackForcePlayed && !_initiallyStopped) {
				_firstTrackForcePlayed = true;

				this.trackManager.playTrack();
			}							
		}

		// this event could arrive before or after the track list, or may not arrive at all - hence the weaselly logic
		public function onInitialMusicStateLoaded(ae:AudioSettingsEvent):void
		{
			const settings:AudioSettings = AudioSettings(ae.target);
			settings.removeEventListener(ae.type, arguments.callee);

			_initiallyStopped = settings.musicState == MusicState.STOPPED;

			if (_firstTrackForcePlayed && _initiallyStopped)
			{
				this.trackManager.stopTrack();
				_initiallyStopped = false;
			}
		}

		public function initPet(petAnimation:String, loaderContextFactory:ILoaderContextFactory):void{
			this.petManager = new PetManager();
			this.petManager.initPet(petAnimation, loaderContextFactory.getLoaderContext());
			this.addChild(this.petManager);
		}
		
		private function setTrackInfo(e:MPEvents):void{
			//trace("SET TRACK INFO")
			var trackData:Object = e.value;
			if (trackData != null){
				this.trackNumber.text = "["+String(trackData.trackNum)+"]";
				this.trackInfo.text = trackData.trackTitle;
				this.MiniPlayer.trackInfo.text = trackData.trackTitle;
			}	
		}
		
		private function getControlsAction(evt:Event):void{
			//trace(evt.type);
		}
		
		public function getMiniPlayer():MovieClip{
			return this.MiniPlayer;
		}
		
		public function setMini(state:Boolean):void{
			this.minimized = state;			
		}
		
		public function isMini():Boolean{
			return this.minimized;
		}
		
		public function playCombatMusic(urlTrack:String,fadetime:int=3):void{
			if (this.trackManager != null){
				if (cSound != null){
					cSound.dispose();
					cSound = null;		
				} 
				this.trackManager.fadetime = fadetime;
				cSound = new CombatSound(urlTrack, this._uiFramework.volumes.musicVolume, fadetime);
			}
		}	
		
		private function onDirectSongClick(e:MouseEvent):void {
			navigateToURL(new URLRequest(DIRECT_SONG_LINK), "_blank");			
		}
	}
}
	