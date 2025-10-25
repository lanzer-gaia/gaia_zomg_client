package com.gaiaonline.battle.ui
{
	import com.gaiaonline.battle.ApplicationInterfaces.IUIFramework;
	import com.gaiaonline.battle.gateway.BattleGateway;
	import com.gaiaonline.battle.newactors.ActorManager;
	import com.gaiaonline.battle.ui.components.TabEvent;
	import com.gaiaonline.battle.ui.components.TabManager;
	import com.gaiaonline.battle.ui.events.UiEvents;
	import com.gaiaonline.flexModulesAPIs.globalevent.GlobalEvent;
	import com.gaiaonline.utils.DisplayObjectUtils;
	
	import flash.display.MovieClip;
	import flash.display.SimpleButton;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.ColorTransform;

	public class UiPDA extends MovieClip
	{
		
		public var tabQuestLog:UiQuestLog;
		public var tabMiniMap:UiMiniMap;
		public var mcFooter:MovieClip;
		public var mcHeader:MovieClip;	
		
		private var tabManager:TabManager;
		private var _width:Number = 150;
		private var _height:Number = 200;
		
		private var _win:*;
		
		private var _recrewtButton:SimpleButton = null;
		
		private var _isOpen:Boolean = false;
		
		private var _newActiveQuest:Boolean = false;
		private var _newCompletedQuest:Boolean = false;
		
		private var _activeQuestTabIndex:int = -1;
		private var _completedQuestTabIndex:int = -1;
		private var _localMapTabIndex:int = -1;
		private var _globalMapTabIndex:int = -1;
		
		private var _uiFramework:IUIFramework = null;
		private var _gateway:BattleGateway = null;
		private var _miniMapManager:MiniMapManager = null;
		private var _questManager:QuestManager = null;		

		public function UiPDA(uiFramework:IUIFramework, gateway:BattleGateway, minimapManager:MiniMapManager)
		{			
			super();
			
			this._uiFramework = uiFramework;
			this._gateway = gateway;

			this.mcFooter.mouseEnabled = false;
			
			this.tabMiniMap.init(this._uiFramework);
			this._miniMapManager = minimapManager;				
			this._miniMapManager.addView(this.tabMiniMap.tabGlobal, false);
			this._miniMapManager.addView(this.tabMiniMap.tabLocal, true);
			
			this.tabQuestLog.visible = true;
			this.tabMiniMap.visible = false;			
			this.tabManager = new TabManager(true);
			this.mcHeader.mcActiveOverlay.visible = this.mcHeader.mcCompletedOverlay.visible = false;
			this.mcHeader.mcActiveOverlay.mouseChildren = this.mcHeader.mcCompletedOverlay.mouseChildren = false;
			this.mcHeader.mcActiveOverlay.mouseEnabled = this.mcHeader.mcCompletedOverlay.mouseEnabled = false;
			this.mcHeader.tabEnabled = this.mcHeader.tabChildren = false;

			_activeQuestTabIndex = this.tabManager.addTabs(this.mcHeader.btnActiveQuest, this.tabQuestLog.tabActive, true);
			_completedQuestTabIndex = this.tabManager.addTabs(this.mcHeader.btnCompletedQuest, this.tabQuestLog.tabCompleted, false);
			_localMapTabIndex = this.tabManager.addTabs(this.mcHeader.btnLocalMap, this.tabMiniMap.tabLocal, false);
			_globalMapTabIndex = this.tabManager.addTabs(this.mcHeader.btnGlobalMap, this.tabMiniMap.tabGlobal, false);
			
			this.activeTab = this._localMapTabIndex;
			
			this.tabManager.addEventListener(TabManager.SELECTED_TAB_CHANGE, onSelectedTabChange, false, 0, true);
				
			MovieClip(this.mcHeader.btnActiveQuest).addEventListener(MouseEvent.CLICK, onBtnActiveClick);
			MovieClip(this.mcHeader.btnCompletedQuest).addEventListener(MouseEvent.CLICK, onBtnCompletedClick);
			MovieClip(this.mcHeader.btnGlobalMap).addEventListener(MouseEvent.CLICK, onBtnGlobalClick);
			MovieClip(this.mcHeader.btnLocalMap).addEventListener(MouseEvent.CLICK, onBtnLocalClick);	
			
			this.tabEnabled = false;
			this.tabChildren = false;
			
			var tooltipManager:ToolTipOld = this._uiFramework.tooltipManager;					
			tooltipManager.addToolTip(this.mcHeader.btnActiveQuest, "Active Tasks");
			tooltipManager.addToolTip(this.mcHeader.btnCompletedQuest, "Completed Tasks");			
			tooltipManager.addToolTip(this.mcHeader.btnLocalMap, "Local Map");
			tooltipManager.addToolTip(this.mcHeader.btnGlobalMap, "Global Map");		

			DisplayObjectUtils.addWeakListener(this.recrewtButton, MouseEvent.CLICK, onRecrewtClick);
			
			DisplayObjectUtils.addWeakListener(GlobalEvent.eventDispatcher, GlobalEvent.TEAM_UPDATED, onTeamUpdated);
			DisplayObjectUtils.addWeakListener(GlobalEvent.eventDispatcher, GlobalEvent.LEFT_TEAM, onLeftTeam);
			DisplayObjectUtils.addWeakListener(GlobalEvent.eventDispatcher, GlobalEvent.WIDGET_SHOW, onWidgetShow);			
			DisplayObjectUtils.addWeakListener(GlobalEvent.eventDispatcher, GlobalEvent.NEW_ROOM_ENTERED, onNewRoomEntered);				
			DisplayObjectUtils.addWeakListener(GlobalEvent.eventDispatcher, GlobalEvent.GST_UPDATE, onGstUpdate);							
			DisplayObjectUtils.addWeakListener(GlobalEvent.eventDispatcher, GlobalEvent.QUEST_ALERT, onQuestAlert);			

			this._questManager = new QuestManager(this._gateway, this.tabQuestLog);

			this.resize();
		}
		private function onWidgetShow(evt:GlobalEvent):void {
			var widgetName:String = evt.data.widgetName;
			var show:Boolean = evt.data.widgetShow;

			switch (widgetName) {
				case "PDARecrewtButton":
					setRecrewtButtonVisible(show);
					break;
				default: // do nothing
					break;
			}			
		}									
		private function onSelectedTabChange(evt:TabEvent):void{
			onSelectedTabChangeImpl(evt.lastIndex, evt.newIndex);				
		}		
		private function onSelectedTabChangeImpl(lastIndex:int, newIndex:int):void
		{
			var mapVisibility:Boolean = true;
			switch(this.tabManager.activeTabIndex){
				case 0: // active quest					
				case 1: // completed quest
					this.tabQuestLog.visible = true;
					mapVisibility = false;					
					break;
				
				case 2: // local map
				case 3: // global map
					this.tabQuestLog.visible = false;
					break;
					
			}	
			this.tabMiniMap.visible = mapVisibility;
			setMapVisibilities(mapVisibility);

			if (lastIndex == 0 && newIndex != 0){
				this.mcHeader.mcActiveOverlay.visible = false;			
				this._newActiveQuest = false;	
				this.tabQuestLog.tabActive.clearNotification();	
				if (this._questManager) {
					this._questManager.clearActiveNotification();
				}									
			}
			if (lastIndex == 1 && newIndex != 1){
				this.mcHeader.mcCompletedOverlay.visible = false;	
				this._newCompletedQuest = false;
				this.tabQuestLog.tabCompleted.clearNotification();
				if (this._questManager) {				
					this._questManager.clearCompletedNotification();
				}
			}
			
			this.dispatchEvent(new Event(TabManager.SELECTED_TAB_CHANGE));			
		} 
		private function get recrewtButton():SimpleButton {
			if (_recrewtButton == null) {
				_recrewtButton = this.mcFooter.recrewtBtn.btn;
			}
			
			return _recrewtButton;
		}
		
		private function onNewRoomEntered(e:GlobalEvent):void {
			var newRoomId:String = e.data.newRoomId;
			
			// [kja] there should really only be one way that this ever gets called on the minimap manager;  internally
			// it also repeatedly calls this.
			this._miniMapManager.updateLocalMap(newRoomId);
		}
			
		private function onTeamUpdated(e:GlobalEvent):void {
			if (e.data != null && e.data.isTeamLeader != null) {
				if (e.data.isTeamLeader) {
					setRecrewtButtonEnabled(true);
				} else {
					setRecrewtButtonEnabled(false);
				}
			}
		}

		private function onLeftTeam(e:GlobalEvent):void {
			var actorId:String = e.data.actorId;
			if (actorId == ActorManager.getInstance().myActor.actorId) {			
				setRecrewtButtonEnabled(true);
			}
		}
		
		private function setRecrewtButtonVisible(show:Boolean):void {
			this.mcFooter.recrewtBtn.visible = show;			
		}
				
		private static const s_disabledColorTransform:ColorTransform = new ColorTransform(0.4, 0.4, 0.4);
		private static const s_emptyColorTransform:ColorTransform = new ColorTransform();						
		private function setRecrewtButtonEnabled(enabled:Boolean):void {
			if (enabled != recrewtButton.enabled) {
				var colorTransform:ColorTransform = null;
				if (enabled) {
					colorTransform = s_emptyColorTransform;
					recrewtButton.addEventListener(MouseEvent.CLICK, onRecrewtClick, false, 0, true);
				} else {
					colorTransform = s_disabledColorTransform;
					recrewtButton.removeEventListener(MouseEvent.CLICK, onRecrewtClick);					
				}
				recrewtButton.enabled = enabled;
				recrewtButton.parent.transform.colorTransform = colorTransform;
				
			}
		} 
		
		private function onRecrewtClick(evt:MouseEvent):void{
			this.dispatchEvent(new UiEvents("DPA_RECREWT_CLICK", null));
		}
		
		
		private function onBtnActiveClick(evt:MouseEvent):void{
			this.mcHeader.mcActiveOverlay.visible = false;			
			this._newActiveQuest = false;	
		}
		
		private function onBtnCompletedClick(evt:MouseEvent):void{
			this.mcHeader.mcCompletedOverlay.visible = false;	
			this._newCompletedQuest = false;		
		}
		
		private function onBtnGlobalClick(evt:MouseEvent):void{
			
		}
		private function onBtnLocalClick(evt:MouseEvent):void{
			
		}
		
		public function init(win:*):void{
			this._win = win;
			if (this._win.isWinLoaded()){
				this._win.addChildAt(this.mcHeader, this._win.numChildren + 1);
				
				var s:Object = this._win.getSize()
				this._height = s.height - 4;
				this._width = s.width - 4;
				this.resize();			
			}else{
				this._win.addEventListener(Event.COMPLETE, onWinLoaded, false, 0, true);		
			}
			this._win.addEventListener(Event.RESIZE, onWinResize, false, 0, true);
		}
		private function onWinLoaded(evt:Event):void{
			this._win.removeEventListener(Event.COMPLETE, onWinLoaded);
			this._win.addChildAt(this.mcHeader, this._win.numChildren);
						
			var s:Object = this._win.getSize()
			this._height = s.height - 4;
			this._width = s.width - 4;
			this.resize();			
		}
		private function onWinResize(evt:Event):void{
			var s:Object = this._win.getSize()
			this._height = s.height - 4;
			this._width = s.width - 4;
			this.resize();
		}
		
		
		private function resize():void{
			
			const tmpHeight:Number = this._height - this.mcFooter.height - 34;

			this.tabQuestLog.height = tmpHeight;
			this.mcFooter.y = this._height - this.mcFooter.height;
			
			this.tabQuestLog.width = this._width;
			this.mcFooter.line.width = this._width;
			this.mcFooter.txtGst.x = this._width - 80;

			this.tabMiniMap.setSize(this._width, tmpHeight);
		}
		
		private function onGstUpdate(e:GlobalEvent):void{
			var date:Date = e.data.gst;
			//trace(date);
			var localTime:String = getUSClockTime(date.getHours(), date.getMinutes());
			//trace(localTime);
			this.mcFooter.txtGst.text = "GST: " + localTime;
		}

		private function getUSClockTime(hrs:uint, mins:uint):String {
		    var modifier:String = "PM";
		    var minLabel:String = doubleDigitFormat(mins);
		
		    if(hrs > 12) {
		        hrs = hrs-12;
		    } else if(hrs == 0) {
		        modifier = "AM";
		        hrs = 12;
		    } else if(hrs < 12) {
		        modifier = "AM";
		    }
		
		    return (String(hrs) + ":" + minLabel + " " + modifier);
		}
		
		private function doubleDigitFormat(num:uint):String {
		    if(num < 10) {
		        return ("0" + num);
		    }
		    return String(num);
		}			
		
		public override function set width(v:Number):void{
			this._width = v;
			this.resize();		
					
		}
		public override function set height(v:Number):void{
			this._height = v;
			this.resize();			
		}	
		
		private function isUpdatableTab(tab:int):Boolean {
			return (tab == _localMapTabIndex || tab == _globalMapTabIndex);
		}
		private function setMapVisibilities(v:Boolean):void
		{
			this._miniMapManager.setViewVisible(this.tabMiniMap.tabGlobal, v);
			this._miniMapManager.setViewVisible(this.tabMiniMap.tabLocal, v);
		}
		public function set activeTab(v:int):void{
			
			const lastIndex:int = this.tabManager.activeTabIndex;
			this.tabManager.setActive(v);
	
			setMapVisibilities(isUpdatableTab(v) && !isUpdatableTab(lastIndex));

			//
			// because the tab manager won't fire the event when the active tab's set programmatically
			onSelectedTabChangeImpl(lastIndex, this.tabManager.activeTabIndex);
		}
		public function get activeTab():int{
			return this.tabManager.activeTabIndex;			
		}

		private function setPDAAlert(ActiveQuest:Boolean, CompletedQuest:Boolean):void {
			this._newActiveQuest = (this._newActiveQuest || ActiveQuest);
			this._newCompletedQuest = (this._newCompletedQuest || CompletedQuest);
					
			if (ActiveQuest) {
				this.mcHeader.mcActiveOverlay.visible = true;
			}
			if (CompletedQuest) {
				this.mcHeader.mcCompletedOverlay.visible = true;
			}	
		}

		public function onQuestAlert(e:GlobalEvent):void {
			var data:Object = e.data;
			DisplayObjectUtils.addWeakListener(GlobalEvent.eventDispatcher, GlobalEvent.QUEST_ALERT, onQuestAlert);						
			setPDAAlert(e.data.activeQuest, e.data.completedQuest);
		}
		
		public function setPDAOpen(open:Boolean):void
		{
			this._isOpen = open;

			if (!open)
			{
				setMapVisibilities(false);
			}
			else if (isUpdatableTab(this.tabManager.activeTabIndex))
			{
				setMapVisibilities(true);
			}	
		}
		
		public function get activeQuestTabIndex():int {
			return this._activeQuestTabIndex;
		}
		public function get completedQuestTabIndex():int {
			return this._completedQuestTabIndex;
		}
		public function get localMapTabIndex():int {
			return this._localMapTabIndex;
		}
		public function get globalMapTabIndex():int {
			return this._globalMapTabIndex;
		}

		
		public function loadQuest():void {
			this._questManager.loadQuest();
		}		
	}
}
