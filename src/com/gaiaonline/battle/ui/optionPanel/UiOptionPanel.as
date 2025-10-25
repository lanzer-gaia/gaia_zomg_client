package com.gaiaonline.battle.ui.optionPanel
{
	import com.gaiaonline.assets.*;
	import com.gaiaonline.battle.ApplicationInterfaces.ILinkManager;
	import com.gaiaonline.battle.ApplicationInterfaces.IUIFramework;
	import com.gaiaonline.battle.gateway.BattleGateway;
	import com.gaiaonline.battle.gateway.BattleMessage;
	import com.gaiaonline.battle.sounds.AudioSettings;
	import com.gaiaonline.battle.sounds.AudioSettingsEvent;
	import com.gaiaonline.battle.sounds.MusicState;
	import com.gaiaonline.battle.ui.events.UiEvents;
	import com.gaiaonline.battle.utils.BattleUtils;
	import com.gaiaonline.flexModulesAPIs.globalevent.GlobalEvent;
	import com.gaiaonline.utils.VisManagerSingleParent;
	
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.display.Stage;
	import flash.events.*;
	import flash.geom.Rectangle;
	import flash.text.*;
	import flash.utils.Timer;

	public class UiOptionPanel extends MovieClip
	{
		private var initObject:Object;
		private var tabsBtns:Array;
		private var tabContainers:Array;
		private var controlItems:Array;
		private var stageQualityItems:Array;
		public var keyControlsData:Array;
		private var _defaultKeyControlsData:Array;
		private var keyTabId:int;
		private var activeTab:Number;
		private var scrollTimer:Timer;
		private var scrollButtonPressed:String;
		private var resetKeysDefaultBtn:UiBasicButton;
		
		/*variable to store key code*/
		public var keyPressed:Number;
		public var oldKeyPressed:Number;
		public var nums:Array;

		private var volumeSliders:Object = new Object();
		
		private var tabVisManager:VisManagerSingleParent = null;
		
		private var _uiFramework:IUIFramework = null;
		private var _linkManager:ILinkManager = null;
		private var _gateway:BattleGateway = null;	
		private var _stage:Stage = null;
		private var _uiGraphicOptions:UiGraphicOptions	
		private var _uiGameSettigns:UiGameSettings;
		
		public var oContainer:MovieClip;
		public var optionBg:MovieClip;
		public var scrollBar:MovieClip;
		public var oMask:MovieClip;		
								
		public function UiOptionPanel(uiFramework:IUIFramework, linkManager:ILinkManager, gateway:BattleGateway, stage:Stage, initObject:Object):void {	
			
			this.initObject = initObject;			
			this._uiFramework = uiFramework;
			this._linkManager = linkManager;
			this._gateway = gateway;
			this._stage = stage;
			
			this.controlItems = new Array();
			this.activeTab = 0;			

			// Had to take this out because it was preventing the event listeners
			// on the key bindings panel from working.  I'm sure there's a way to get
			// that working again and to trurn off the tabbing otherwise, but it's not
			// worth the time right now.  -- Mark Rubin

			// this.tabChildren = false;
				
			this.addTabs();
			this.createResetButton();

			this.addEventListener(Event.ADDED_TO_STAGE,afterAddToStage,false,0,true);
			
			uiFramework.volumes.addEventListener(AudioSettingsEvent.SOUND_VOLUME_CHANGED, onVolumeChanged, false, 0, true);			
			uiFramework.volumes.addEventListener(AudioSettingsEvent.MUSIC_VOLUME_CHANGED, onVolumeChanged, false, 0, true);			
			uiFramework.volumes.addEventListener(AudioSettingsEvent.MUSIC_MUTE_CHANGED, onMusicPlaybackChanged, false, 0, true);			
			uiFramework.volumes.addEventListener(AudioSettingsEvent.MUSIC_PLAYBACK_CHANGED, onMusicPlaybackChanged, false, 0, true);			
		}  

		private function afterAddToStage(evt:Event):void{
			this.scrollBar.dragBtn.stage.addEventListener(MouseEvent.MOUSE_UP,stopListDrag,false,0);
			this.scrollBar.scrUp.stage.addEventListener(MouseEvent.MOUSE_UP,stopListDrag,false,0,true);
			this.scrollBar.scrDown.stage.addEventListener(MouseEvent.MOUSE_UP,stopListDrag,false,0,true);
			
			BattleUtils.enableScrollMouseEvents(this.scrollBar);				
		}
	
		private function addScrollBar():void{
			this.scrollButtonPressed = "";
			this.scrollBar.layout.height = this.optionBg.height;
			this.scrollBar.scrollBg.height = this.optionBg.height-20;
			this.scrollBar.scrDown.y = this.optionBg.height-6;
			this.scrollBar.scrUp.buttonMode = true;
			this.scrollBar.scrUp.addEventListener(MouseEvent.MOUSE_DOWN,scrollButtonDown,false,0,true);
			this.scrollBar.scrDown.buttonMode = true;
			this.scrollBar.scrDown.addEventListener(MouseEvent.MOUSE_DOWN,scrollButtonDown,false,0,true);
			var containerHeight:Number = this.tabContainers[this.activeTab].height+10;
			if (containerHeight > this.oMask.height){
				this.scrollBar.visible = true;
				this.scrollBar.dragBtn.y = 10;
				this.oContainer.y = 50;
				var showProc:Number = (this.oMask.height)/(containerHeight/100);
				this.scrollBar.dragBtn.height = Math.round((this.scrollBar.scrollBg.height/100)*showProc);
				this.scrollBar.dragBtn.buttonMode = true;
				this.scrollBar.dragBtn.addEventListener(MouseEvent.MOUSE_DOWN,startListDrag,false,0,true);			
				this.scrollTimer = new Timer(1/this.stage.frameRate * 1000 + 1);
				this.scrollTimer.addEventListener(TimerEvent.TIMER, checkScrolling,false,0,true);
			} else {
				this.scrollBar.visible = false;
			}
		}
		
		private function scrollButtonDown(evt:MouseEvent):void {
			var evtTrgt:Object = evt.target;
			if (evtTrgt.name == "scrDown")	this.scrollButtonPressed = "down";
			else if (evtTrgt.name == "scrUp")	this.scrollButtonPressed = "up";
			this.scrollTimer.start();
		}
		
		private function startListDrag(evt:MouseEvent):void{
			this.scrollBar.dragBtn.onDrag = true;
			var dragLimit:Rectangle = new Rectangle(2,10,0,this.scrollBar.scrollBg.height-this.scrollBar.dragBtn.height);
			this.scrollBar.dragBtn.startDrag(false,dragLimit);
			this.scrollTimer.start();
		}

		private function stopListDrag(evt:MouseEvent):void{
			
			if (this.scrollBar.dragBtn.onDrag){
				this.scrollBar.dragBtn.onDrag = false;
				this.scrollBar.dragBtn.stopDrag();	
				this.scrollTimer.stop();
			}
			if (this.scrollButtonPressed != ""){
				this.scrollButtonPressed = "";
				this.scrollTimer.stop();
			}
		}		
		private function checkScrolling(evt:TimerEvent):void {
			var scrVal:Number = 3;
			var bottomLimit:Number = 10+(this.scrollBar.scrollBg.height-this.scrollBar.dragBtn.height);
			if (this.scrollButtonPressed == "up"){
				this.scrollBar.dragBtn.y = this.scrollBar.dragBtn.y-scrVal;
				if (this.scrollBar.dragBtn.y < 10) this.scrollBar.dragBtn.y = 10;
			} else if (this.scrollButtonPressed == "down"){
				this.scrollBar.dragBtn.y = this.scrollBar.dragBtn.y+3;
				if (this.scrollBar.dragBtn.y > bottomLimit) this.scrollBar.dragBtn.y = bottomLimit;
			}
			var scrollPos:Number = (this.scrollBar.dragBtn.y-10)/((this.scrollBar.scrollBg.height-10)/100);
			this.oContainer.y = 50-Math.round((((this.tabContainers[this.activeTab].height+10))/100)*scrollPos);
		}
		
		private function addTabs():void{			
			GlobalEvent.eventDispatcher.dispatchEvent(new GlobalEvent(GlobalEvent.KEY_CONTROL_TAB_ACTIVE, {active:false}));
			this.tabsBtns = new Array();
			this.tabContainers = new Array();
			for (var t:int=0;t<this.initObject.tabs.length;t++){
				var isAct:Boolean = false;
				if (t==this.activeTab) isAct = true;
				this.tabsBtns[t] = new UiTabButton(this.initObject.tabs[t].title,false,isAct);
				this.tabsBtns[t].name = "tab_"+t
				this.tabsBtns[t].addEventListener(MouseEvent.CLICK,changeTab,false,0,true);
				this.tabsBtns[t].tabId = t;
				this.tabsBtns[t].y = 31;
				if (t==0) {
					this.tabsBtns[t].x = 15;
				} else {
					this.tabsBtns[t].x = this.tabsBtns[t-1].x+this.tabsBtns[t-1].width+4;
				}				

				this.tabContainers[t]= new MovieClip;
				this.tabContainers[t].name = "tabContainer_"+t;
				this.tabContainers[t].x = 10;				
				this.oContainer.addChild(this.tabContainers[t]);		
				if (t == 0) this.tabContainers[t].visible = true;
				else this.tabContainers[t].visible = false;

				if (this.initObject.tabs[t].controls != undefined){
					switch (this.initObject.tabs[t].controls.typ){
						case "volume":
							this.tabContainers[t].y = 20;
							this.tabContainers[t].resetFunction = resetVolume;
							this.insertVolumeSliders(this.tabContainers[t], this.initObject.tabs[t].controls.data);
							break;
						case "key_controls":
							this.keyTabId = t;
							this.tabContainers[t].y = 15;
							this.tabContainers[t].resetFunction = resetKeyControls; 														
							this.keyControlsData = this.initObject.tabs[t].controls.data;
							this._defaultKeyControlsData = this.initObject.tabs[t].controls.defaultData;						
							this.buildKeyControls(this.initObject.tabs[t].controls.data);
							GlobalEvent.eventDispatcher.addEventListener(GlobalEvent.KEY_BINDING_CHANGE, onKeyBindingChangeStart,false,0,true);
							GlobalEvent.eventDispatcher.addEventListener(GlobalEvent.KEY_BINDING_CHANGE_CANCEL, onKeyBindingChangeCancel,false,0,true);							
							break;			
						 case "graphicOptions":			
							this.tabContainers[t].y = 15;							
							this.tabContainers[t].resetFunction = resetGraphicOptions; 																					
							this.graphicOptionsInit(t);
							break;
						  case "gameSettings":
						  	this.tabContainers[t].y = 15;							
							this.tabContainers[t].resetFunction = resetGameSettings;
							this.gameSettingInit(t);
						  	break;
						  
						   
						default:
							break;
					}
				}
				this.addChild(this.tabsBtns[t]);				
			}
			this.addScrollBar();

			// do this at the end because the vis manager is easier to use if the children have already been attached
			if (!tabVisManager) {
				tabVisManager = new VisManagerSingleParent(this);				
			}
			for each (var tab:DisplayObject in this.tabContainers) {
				this.setTabVisible(tab, tab.visible);
			}			
			
			
		}

		private function setTabVisible(tab:DisplayObject, visible:Boolean):void {
			this.tabVisManager.setVisible(tab, visible);
		}

		///////////////////////////////
		//**** GAME OPTIONS ********//
		/////////////////////////////

		private function graphicOptionsInit(id:Number):void {
			
			this._uiGraphicOptions = new UiGraphicOptions();
			this._uiGraphicOptions.setStage(this._stage);
			this.tabContainers[id].addChild(this._uiGraphicOptions);			
			
		}
		private function resetGraphicOptions():void {
			this._uiGraphicOptions.resetDefault();			
		}
		
		private function gameSettingInit(id:Number):void{
			this._uiGameSettigns = new UiGameSettings();			
			this.tabContainers[id].addChild(this._uiGameSettigns);
		}
		private function resetGameSettings():void{
			this._uiGameSettigns.resetDefault();
		}
		
		
		
		private function resetDefaultLayout(evt:MouseEvent):void{
			var reset_layout_event:UiEvents = new UiEvents(UiEvents.LAYOUT_RESET, "");
			reset_layout_event.value = new Object();			
			this.dispatchEvent(reset_layout_event);	
		}
		
		private function createResetButton():void{
			this.resetKeysDefaultBtn = new UiBasicButton("",true,true);
			this.resetKeysDefaultBtn.addEventListener(MouseEvent.CLICK, onResetButtonClick,false,0,true);
			this.resetKeysDefaultBtn.y = 298;							
			this.addChild(this.resetKeysDefaultBtn);
			this.setResetButton();
		}
		
		private function setResetButton():void {
			this.resetKeysDefaultBtn.setText(this.initObject.tabs[this.activeTab].resetButtonText);
			this.resetKeysDefaultBtn.setWidth(TextField(resetKeysDefaultBtn.caption).textWidth + 30);
			this.resetKeysDefaultBtn.checkCenterAlign();
			this.resetKeysDefaultBtn.x = this.optionBg.width + this.scrollBar.width - this.resetKeysDefaultBtn.width;				
		}
		
		private function onResetButtonClick(e:MouseEvent):void {
			this.tabContainers[this.activeTab].resetFunction();
		}
		
		///////////////////////////////
		//**** KEY CONTROLS ********//
		/////////////////////////////		
		
		
		private function saveKeyControls():void{
			var saveKeyMap:Object = new Object();
			// makes a copy; don't know if this is necessary, but Symblaze had it that way, and they have all sorts of crazy side-effects
			// in their code, usuall, so I preserved this. 						
			var keysData:Array = this.keyControlsData.concat(); 
			for each (var keyMap:Object in keysData) {
				var mapToSave:Object = {k:keyMap.kcodes,c:keyMap.charcodes};
				saveKeyMap[keyMap.codeName] = mapToSave;
			}

			var msg:BattleMessage = new BattleMessage("putNkvp", saveKeyMap);
			this._gateway.sendMsg(msg);
		}

		private function resetKeyControls():void{
			this.buildKeyControls(this._defaultKeyControlsData);			
		}
		
		public function buildKeyControls(dataArr:Array):void {
			if (this.controlItems.length > 0){
				for (var ci:int=0;ci<this.controlItems.length;ci++){
					this.tabContainers[this.keyTabId].removeChild(this.controlItems[ci]);
					this.controlItems[ci] = null;
				}
			}
			this.controlItems = new Array();						
			for (var c:int=0;c<dataArr.length;c++){
				this.controlItems[c]  = new UiKeyControl();
				this.controlItems[c].init(this, this._uiFramework, this._linkManager, c, dataArr[c]);
				this.controlItems[c].y = 24*c;
				this.tabContainers[this.keyTabId].addChild(this.controlItems[c]);
			}						
		}
		
		private var currKeyControl:UiKeyControl = null;
		private var currOptionIndex:int = -1;
		private function onKeyBindingChangeStart(e:GlobalEvent):void {
			this._uiFramework.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyBindingChangeKeyDown, false, 0,true);			
			this._uiFramework.stage.addEventListener(KeyboardEvent.KEY_UP, onKeyBindingChangeKeyUp, false, 0,true);						
			currKeyControl = e.data.keyControl;
			currOptionIndex = e.data.optionIndex;
		}

		public function onOptionPanelClose():void {
			saveKeyControls();						
			onKeyBindingChangeCancel(null);
			this.dispatchEvent(new Event("optionPanelClosing"));						
			this.dispatchEvent(new Event("resetKeyControl"));			
		}
		
		private function onKeyBindingChangeCancel(e:GlobalEvent):void {
			this._uiFramework.stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyBindingChangeKeyDown, false);
			this._uiFramework.stage.removeEventListener(KeyboardEvent.KEY_UP, onKeyBindingChangeKeyUp, false);
			this.currKeyControl = null;
			this.currOptionIndex = -1;			
		}	
			
		private function onKeyBindingChangeKeyUp(e:KeyboardEvent):void {
		}	
				
		private function onKeyBindingChangeKeyDown(e:KeyboardEvent):void {
			if (currKeyControl != null) {
				currKeyControl.reportKeyDown(currKeyControl["opt"+this.currOptionIndex], e.keyCode, e.charCode);
			}
		}
		
		public function reassignKeys():void{			
			for (var c:int=0;c<this.keyControlsData.length;c++){
				this.controlItems[c].initObject = this.keyControlsData[c];
				for (var kc:int=0; kc<this.keyControlsData[c].kcodes.length;kc++){
					this.controlItems[c].initKey(this.controlItems[c]["opt"+(kc+1)],this.keyControlsData[c].kcodes[kc],this.keyControlsData.charcodes[c],true,false);
				}
			}	
		}
		
		public function keyAlreadyAssigned(codeName:String, keyVal:Number):Array {
			var alreadyAssignedKeysInfo:Array = new Array();
			for (var c:int=0;c<this.keyControlsData.length;c++){	
				if (codeName == this.keyControlsData[c].codeName) {
					continue;
				}		
				for (var kc:int=0; kc<this.keyControlsData[c].kcodes.length;kc++){
					if (this.keyControlsData[c].kcodes[kc] == keyVal){
						var obj:Object = {keyControl:this.keyControlsData[c], btn:controlItems[c],kcodeindex:kc};
						alreadyAssignedKeysInfo.push(obj);
					}
				}
			}
			
			return alreadyAssignedKeysInfo.length > 0 ? alreadyAssignedKeysInfo : null;
		}		
		
		///////////////////////////////
		//**** VOLUME SLIDERS ******//
		/////////////////////////////
		
		private var _playerLink:TextField;
		private function insertVolumeSliders(tab:DisplayObjectContainer, dataArr:Array):void
		{
			for (var c:int=0;c<dataArr.length;c++)
			{
				var data:Object = dataArr[c];
				var vs:UiVolumeSlider = new UiVolumeSlider(); 
				vs.init(data);
				vs.y = 80*c;
				vs.addEventListener(UiEvents.SET_MUSIC_VOLUME, onSetVolume,false,0,true);
				vs.addEventListener(UiEvents.SET_SFX_VOLUME, onSetVolume,false,0,true);

				this.volumeSliders[data.event] = vs;
				tab.addChild(vs);

				if (data.addPlayerLink)
				{
					_playerLink = new TextField();
					_playerLink.x = 5;
					_playerLink.y = vs.y + 45;
					_playerLink.autoSize = TextFieldAutoSize.LEFT;
					_playerLink.cacheAsBitmap = true;

					var fmt:TextFormat = new TextFormat("Arial", 9, 0xcccccc, true, true);
					_playerLink.defaultTextFormat = fmt;
					
					var parent:Sprite = new Sprite();
					parent.useHandCursor = true;
					parent.buttonMode = true;
					parent.mouseChildren = false;
					parent.mouseEnabled = true;
					parent.addChild(_playerLink);
					
					parent.addEventListener(MouseEvent.CLICK, onPlayerLinkClick, false, 0, true);

					tab.addChild(parent);
					
					updatePlayerLink(_uiFramework.volumes);
				}
			}
		}

		private function resetVolume():void {
			for each (var v:UiVolumeSlider in this.volumeSliders) {
				v.resetToDefault();
			}
		}
		
		private function onSetVolume(evt:UiEvents):void{
			var event:UiEvents = new UiEvents(evt.type, evt.command);
			event.value = evt.value;			
			this.dispatchEvent(event);
		}

		private function onVolumeChanged(ve:AudioSettingsEvent):void {
			// [kja] all kinds of dirty.  "it was like this when i got here" - Homer Simpson
			this.volumeSliders[UiEvents.SET_MUSIC_VOLUME].setVolume(AudioSettings(ve.target).musicVolume);
			this.volumeSliders[UiEvents.SET_SFX_VOLUME].setVolume(AudioSettings(ve.target).soundVolume);
		}		
				
		private function onMusicPlaybackChanged(e:AudioSettingsEvent):void
		{
			updatePlayerLink(AudioSettings(e.target));
		}		

		static private var s_stateToDescription:Object;
		private function updatePlayerLink(settings:AudioSettings):void
		{
			if (!s_stateToDescription)
			{
				s_stateToDescription = {};
				s_stateToDescription[MusicState.PAUSED] = "PAUSED";
				s_stateToDescription[MusicState.STOPPED] = "STOPPED";
				s_stateToDescription[MusicState.PLAYING] = "playing";
			}
			
			var state:String = "";
			if (settings.musicMuted)
			{
				state = "MUTED";
			}
			else
			{
				state = s_stateToDescription[settings.musicState];
			}
			
			_playerLink.text = "Music is currently " + state + ". Click here to go to player.";
		}
		private function onPlayerLinkClick(e:Event):void
		{
			dispatchEvent(new UiEvents(UiEvents.MUSIC_PLAYER_LINK_CLICK, null));
		}
		private function changeTab(evt:MouseEvent):void{
			if (this.activeTab != evt.target.tabId) this.oContainer.y = 50;
			this.activeTab = evt.target.tabId;			

			var keyControlTabActive:Boolean = false;
			
			for (var t:int=0;t<this.initObject.tabs.length;t++){
				if (t==this.activeTab) {
					this.tabsBtns[t].changeState("onState",true);
					this.tabContainers[t].yscale = 100;
					this.setTabVisible(this.tabContainers[t], true);
					setResetButton();	
				} else {
					this.tabsBtns[t].changeState("offState");		
					this.setTabVisible(this.tabContainers[t], false);
					this.tabContainers[t].yscale = 0;
				}
				if (this.initObject.tabs[t].controls != undefined){
					if (this.initObject.tabs[t].controls.typ == "key_controls"){						
						if (t==this.activeTab) {	
							keyControlTabActive = true;							
							GlobalEvent.eventDispatcher.addEventListener(GlobalEvent.KEY_BINDING_CHANGE, onKeyBindingChangeStart,false,0,true);
							GlobalEvent.eventDispatcher.addEventListener(GlobalEvent.KEY_BINDING_CHANGE_CANCEL, onKeyBindingChangeCancel,false,0,true);														
						}
					}
				}
			}			
			this.addScrollBar();
			this.stage.focus = null;			
			GlobalEvent.eventDispatcher.dispatchEvent(new GlobalEvent(GlobalEvent.KEY_CONTROL_TAB_ACTIVE, {active:keyControlTabActive}));			
		}
	}
}