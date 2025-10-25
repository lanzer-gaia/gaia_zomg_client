package com.gaiaonline.battle.ui
{	
	import com.gaiaonline.assets.BackgroundBox;
	import com.gaiaonline.battle.ApplicationInterfaces.IUIFramework;
	import com.gaiaonline.battle.ConColors;
	import com.gaiaonline.battle.newactors.ActorManager;
	import com.gaiaonline.battle.newactors.BaseActor;
	import com.gaiaonline.battle.newactors.BaseActorEvent;
	import com.gaiaonline.battle.newrings.RingIconFactory;
	import com.gaiaonline.battle.ui.UiItemsParts.MemberListItem;
	import com.gaiaonline.battle.ui.components.DefaultButton;
	import com.gaiaonline.battle.ui.components.ScrollBarVer;
	import com.gaiaonline.battle.ui.components.TabButton;
	import com.gaiaonline.battle.ui.events.UiEvents;
	import com.gaiaonline.battle.ui.uiactionbar.UiItemBar;
	import com.gaiaonline.flexModulesAPIs.globalevent.GlobalEvent;
	
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.events.TimerEvent;
	import flash.geom.ColorTransform;
	import flash.geom.Rectangle;
	import flash.text.*;
	import flash.utils.Dictionary;
	import flash.utils.Timer;

	public class UiRecrewt extends MovieClip
	{
		private var initObject:Object;
		private var conColors:Object;
		private var conColorLevelMap:Object;
		private var conFilterArray:Array;
		private var userList:Array = [];
		private var selectedUser:Number;
		private var selectedUserName:String;		
		
		public var chkLFG:MovieClip;
		public var conFilter:MovieClip;
		public var userContainer:MovieClip;
		public var userContainerMask:MovieClip;
		public var userContBg:MovieClip;
		public var inviteBtn:DefaultButton;
		public var refreshBtn:DefaultButton;
		public var ScrollMList:ScrollBarVer;
		public var TBtnUserName:TabButton;
		public var TBtnTotalCharge:TabButton;
		public var TBtnEquippedRings:TabButton;
		public var TBtnCon:TabButton;
		public var friend_icon:MovieClip;
		
		private var _refreshButtonTimer:Timer = new Timer(15000, 1); // 15 seconds
		
		private var _uiFramework:IUIFramework = null;
		
		public function UiRecrewt(uiFramework:IUIFramework){
			this._uiFramework = uiFramework;
			
			this.selectedUser = -1;
			this.conColors = ConColors.getInstance().getConColors(); // Array
			this.conColorLevelMap = ConColors.getInstance().colorLevelMap;
			this.conFilterArray = new Array(this.conColorLevelMap["0"],
											this.conColorLevelMap["1"],
											this.conColorLevelMap["2"],
											this.conColorLevelMap["3"],
											this.conColorLevelMap["4"]);
			
			this.addEventListener(Event.ADDED_TO_STAGE,afterAddToStage, false, 0, true);
			
			//--- LFG Flag..  this may be move to an other panel. not suire yet
			this.chkLFG.addEventListener(MouseEvent.CLICK, onChkLFGClick, false, 0, true);
			this.ScrollMList.visible = false;
			this.ScrollMList.init(this.userContainer, new Rectangle(this.userContainerMask.x,this.userContainerMask.y,this.userContainerMask.width,this.userContainerMask.height),false);
			
			//-- Refresh button timer
			this._refreshButtonTimer.addEventListener(TimerEvent.TIMER_COMPLETE, onRefreshButtonTimerComplete, false, 0, true);
			
			this.tabChildren = false;
			this.conFilter.tabChildren = false;

			//-- Listen for updates so we can possibly toggle the Invite button based on how many people are currently in our crew			
			GlobalEvent.eventDispatcher.addEventListener(GlobalEvent.TEAM_UPDATED, onTeamChanged, false, 0, true);
			GlobalEvent.eventDispatcher.addEventListener(GlobalEvent.LEFT_TEAM, onTeamChanged, false, 0, true);
			GlobalEvent.eventDispatcher.addEventListener(GlobalEvent.PLAYER_CREATED, onPlayerCreated, false, 0, true);			
		}

		private function onPlayerCreated(e:GlobalEvent):void {
			var me:BaseActor = e.data.actor as BaseActor;
			this.setLFG(me.isLfg);			
			me.addEventListener(BaseActorEvent.LFG_UPDATED, this.onLFGUpdated, false, 0, true);			
		}
		
		private function onLFGUpdated(e:BaseActorEvent):void {
			var me:BaseActor = e.target as BaseActor;
			this.setLFG(me.isLfg);
		}				
		
		private function afterAddToStage(evt:Event):void{
			// [kja] this POS broke when I moved Window into a UIComponent.  What's below is a hacked fix and will just go away when the recrewt panel is redone
			//if (this.parent.parent != null){				
			//	this.parent.parent.addChildAt(this.conFilter, this.parent.parent.numChildren);
			//}

			var window:DisplayObjectContainer = this.parent ? this.parent.parent : null;
			if (window)
			{
				if (this.conFilter.parent == window) 
				{
					// because flex can remove the child first and change numChildren on you, see UIComponent.addChildAt()
					window.setChildIndex(this.conFilter, window.numChildren - 1);  
				}
				else
				{
					window.addChildAt(this.conFilter, window.numChildren - 1);
				}
			}
		}
					
		public function init(initObj:Object):void{			
			this.initObject = initObj;
			this.addTabs();
			this.addButtons();
			this.setConFilter();
			this.refresh(this.initObject);
		}
		
		private function onRefreshButtonTimerComplete(e:TimerEvent):void {
			this.refreshBtn.setActive(true);
		}	
			
		public function refresh(initObj:Object):void{
			this.initObject = initObj;
			this.clearUsersList();
			
			_refreshButtonTimer.start();
		}
		
		private function clearUsersList():void{
			if (this.userList && this.userList.length > 0){
				for (var u:int=0;u<this.userList.length;u++){
					var userObj:MovieClip = this.userList[u];
					if (this.userContainer.contains(userObj)){
						this.userContainer.removeChild(userObj);
					}
				}				
			}
			this.selectedUser = -1;
			if (this.initObject.usersList && this.initObject.usersList.length > 0) {
				this.placeUsers();
			}
		}
		
		private function placeUsers():void {
			var friendsList:Array = ActorManager.getInstance().friendsList;
		
			this.userList.length = 0;
			this.calculateConNumbers();
			if (!this.initObject || !this.initObject.usersList) { // shouldn't happen, but to be safe
				return;
			}
			var sortedArray:Array = this.initObject.usersList;
			for (var u:int=0;u<sortedArray.length;u++){
				var uObj:Object = sortedArray[u];
				this.userList.push(new MemberListItem());
				var userObj:MemberListItem = this.userList[u];
				if (userObj) {
					userObj.userId = uObj.userId;

					var userName:TextField = userObj.userName;		
					var totalCharge:TextField = userObj.totalCharge;			
					userName.autoSize = totalCharge.autoSize = TextFieldAutoSize.LEFT;
					userName.wordWrap = totalCharge.wordWrap = false;
					userName.multiline = totalCharge.multiline = false;
					userName.mouseEnabled = false;
					totalCharge.mouseEnabled = false;
					userName.text = (uObj.username||"");
					totalCharge.text = (uObj.totalCharge||"");
					userObj.userSelector.alpha = 0;
					userObj.y = u*30;
					var colorFrm:TextFormat = new TextFormat();
					var conColor:String = uObj.conColor;
					if (this.conColors && conColor) {
						var colorVal:String = this.conColors[conColor].color;		            						
						if (colorVal) {
			            	colorFrm.color = colorVal; 
							userName.setTextFormat(colorFrm);
						}
					}

					userObj.userSelector.addEventListener(MouseEvent.ROLL_OVER,highlightUser, false, 0, true);
					userObj.userSelector.addEventListener(MouseEvent.ROLL_OUT,delightUser, false, 0, true);
					userObj.userSelector.addEventListener(MouseEvent.CLICK,selectUser, false, 0, true);

					userObj.friend_icon.visible = false;
				}
				/*displaying friend_icon*/
				if (friendsList) {
					for(var f:int; f<friendsList.length; f++){
						if(friendsList[f].friendName == uObj.username){
							userObj.friend_icon.visible = true;
						}
					}
				}
				this.addRings(userObj,uObj.rings);
				this.userContainer.addChild(userObj);
			}
			this.TBtnUserName.isActive = true;
			this.TBtnUserName.sortAscending = false;
			this.TBtnTotalCharge.isActive = false;
			this.TBtnTotalCharge.sortAscending = true;
			this.TBtnCon.isActive = false;
			this.TBtnCon.sortAscending = true;
			this.resortField("username");
		}

		private function addRings(userObj:MovieClip,ringList:Array):void{
			var ringContainer:MovieClip = new MovieClip();
			ringContainer.x = this.TBtnEquippedRings.x-15;
			ringContainer.y = 2;

			var pushX:int = 0;
			var chargeLevel:String = "";
			var ring:DisplayObject;
			for (var r:int=0;r<= UiItemBar.MAX_BAR_SLOT_INDEX ;r++){
				if (ringList[r] != null){
					if(ringList[r].chargeLevel != null){
						chargeLevel = " - CL: "+ringList[r].chargeLevel;
					}
					ring = this.addRingItem(ringList[r].ringId,pushX, ringList[r].ringName+chargeLevel,"desc",ringList[r].image);
				}else{
					ring = this.addRingItem(-1,pushX);
				}
				ringContainer.addChild(ring);
				pushX += 28;
			}
			userObj.addChild(ringContainer);
		}
		
		
		private function addRingItem(ringId:Number,sX:Number,ringName:String="",ringDesc:String="",ringUrl:String=""):MovieClip{
			var ringObj:MovieClip = new MovieClip();
			ringObj.ringId = ringId;
			ringObj.name = "ring_"+ringId;
			ringObj.x = sX;
			ringObj.addChild(new BackgroundBox(26,26,1));
			if (ringId != -1)
			{
				ringObj.addChild(RingIconFactory.getBitmap(ringUrl));
				ringObj.buttonMode = true;
				ringObj.mouseChildren = false;
				this._uiFramework.tooltipManager.addToolTip(ringObj, ringName);
				ringObj.addEventListener(MouseEvent.CLICK,getRingInfo, false, 0, true);
			}
			return ringObj;
		}		
		
		private function getRingInfo(evt:MouseEvent):void{
			var ringTarget:Object = evt.target;
			var evnt:UiEvents = new UiEvents(UiEvents.ML_RING_CLICK,"");
			evnt.ringId = ringTarget.ringId;
			this.dispatchEvent(evnt);			
			
		}
		
		private function calculateConNumbers():void{	
			var myCon:Number = this.initObject.userCon;
			for (var u:int=0;u<this.initObject.usersList.length;u++){
				var con:Number = this.initObject.usersList[u].con;
				var diffValue:Number = con - myCon;				
				var conColorValue:int = ConColors.getInstance().getConColorForDiff(diffValue);
				var colorObj:Object = this.getConColorByValue(conColorValue);
				this.initObject.usersList[u].conColor = colorObj.name; 
				this.initObject.usersList[u].conLevel = colorObj.level; 
			}
		}
		
		private function swapKeysAndValues(hash: Object, conversionClassForKey: Class = null): Object {
			var newHash: Dictionary = new Dictionary(true);
			
			for(var k: Object in hash) {
				if(conversionClassForKey) {
					newHash[conversionClassForKey(hash[k])] = k;
				}
				else {
					newHash[hash[k]] = k;	
				}
			}
			
			return newHash;
		}
		
		private function getConColorByValue(colorValue:int):Object{
			var count:int = 0;
			var conColorHash: Object = swapKeysAndValues(this.conColorLevelMap);
			var colorLevelMap: Object = swapKeysAndValues(ConColors.getInstance().conColorsArray, Number);
				
			for (var colorName:Object in this.conColors) {
				count++;
		        if (this.conColors[colorName].color == colorValue){
		          	this.conColors[colorName].level = conColorHash[colorLevelMap[colorValue]];
		        	return this.conColors[colorName];		        	
		        }
   			}
			return null;
		}

		public function resortField(sortBy:String="username",desc:Boolean=false,numeric:Boolean=false):void{
			var pushY:int = 0;
			var sortParams:Object = new Object();
			sortParams = Array.CASEINSENSITIVE;
			if (desc) sortParams = Array.CASEINSENSITIVE | Array.DESCENDING;
			if (numeric) sortParams = Array.CASEINSENSITIVE | Array.NUMERIC;
			if (desc && numeric) sortParams = Array.CASEINSENSITIVE | Array.DESCENDING | Array.NUMERIC;

			var sortedArray:Array = this.initObject.usersList.sortOn(sortBy,sortParams);
			for (var u:int=0;u<sortedArray.length;u++){
				var nextItem:MovieClip = this.getUserRowById(sortedArray[u].userId);
				if (nextItem != null){
				  	if (this.conFilterArray.indexOf(sortedArray[u].conColor) !== -1){
						nextItem.visible = true;
						nextItem.y = pushY;
						pushY += 30;
					} else {
						nextItem.y = 0;
						nextItem.visible = false;
					}
				}
			}
			this.initObject.usersList = sortedArray;
			if (this.userContainer.height >= this.userContainerMask.height)
				this.ScrollMList.update();
			else
				this.ScrollMList.visible = false;
		}
		
		public function filterUsersByCon():void{
			var pushY:int = 0;
			var sortedArray:Array = this.initObject.usersList;
			for (var u:int=0;u<sortedArray.length;u++){
				var nextItem:MovieClip = this.getUserRowById(sortedArray[u].userId);
				if (nextItem != null){
				  	if (this.conFilterArray.indexOf(sortedArray[u].conColor) !== -1){
						nextItem.visible = true;
						nextItem.y = pushY;
						pushY += 30;
					} else {
						nextItem.y = 0;
						nextItem.visible = false;
					}
				}
			}
			this.initObject.usersList = sortedArray;
			if (this.userContainer.height >= this.userContainerMask.height)
				this.ScrollMList.update();
			else {
				this.ScrollMList.update();				
				this.ScrollMList.visible = false;
			}
		}
		
		public function getUserRowById(id:Number):MovieClip{
			var len:int = this.userList.length;
			for (var i:int=0;i < len; i++){
				if (this.userList[i].userId == id){
					return this.userList[i];
					break;
				}
			}
			return null;
		}
		
		private function highlightUser(evt:MouseEvent):void{
			var uSelector:Object = evt.target;
			if (uSelector.parent.userId != this.selectedUser){
				uSelector.alpha = 0.3;
			}
		}
		
		private function delightUser(evt:MouseEvent):void{
			var uSelector:Object = evt.target;
			if (uSelector.parent.userId != this.selectedUser){				
				uSelector.alpha = 0;			
			}
		}
		
		
		private function inviteUserClick(mevt:MouseEvent):void{	
			var uSelector:Object = mevt.target;
			var evt:UiEvents = new UiEvents(UiEvents.ML_INVITE,"");
			evt.userId = uSelector.parent.userId;			
			evt.value = uSelector.parent.userName.text;			
			this.dispatchEvent(evt);			
		}

		private function inviteUser(mevt:MouseEvent):void{
			if (this.selectedUser != -1) {
				var evt:UiEvents = new UiEvents(UiEvents.ML_INVITE,"");
				evt.userId = this.selectedUser;
				evt.value = this.selectedUserName;
				this.dispatchEvent(evt);
			}
		}
		
		private function selectUser(evt:MouseEvent):void{
			var uSelector:Object = evt.target;
			if (uSelector.parent.userId != this.selectedUser){
				uSelector.alpha = 0.8;
				if (this.selectedUser != -1){
					this.getUserRowById(this.selectedUser).userSelector.alpha = 0;
				}
				this.selectedUser = uSelector.parent.userId;
				this.selectedUserName = uSelector.parent.userName.text;
				checkInviteButton();
			} else {
				uSelector.alpha = 0;
				this.selectedUser = -1;
				setInviteButtonActive(false);
			}
		}
		
		private function checkInviteButton():void {
			if (this.selectedUser == -1) {
				this.setInviteButtonActive(false);	
			} else {
				var selectedActor:BaseActor = ActorManager.actorIdToActor(this.selectedUser.toString());
				if (selectedActor) {
					this.setInviteButtonActive(selectedActor.isInvitableToCrew());
				}else{
					this.setInviteButtonActive(true);
				}
			}
		}
		
		private function setInviteButtonActive(active:Boolean):void {
			var myActor:BaseActor = ActorManager.getInstance().myActor;
			if (myActor && myActor.isGuestUser()) {
				active = false;		// let them see the panel but can't invite people
			}
			this.inviteBtn.setActive(active);
			var listenerFunction:Function = active ? this.inviteBtn.addEventListener : this.inviteBtn.removeEventListener;
			listenerFunction(MouseEvent.CLICK, inviteUser);
		}
		
		private function onTeamChanged(e:GlobalEvent):void {
			checkInviteButton();
		}
		
		private function setConFilter():void{
			var tooltipManager:ToolTipOld = this._uiFramework.tooltipManager;
					
			this.conFilter.con1.conColor = this.conColorLevelMap["0"];
			this.conFilter.con1.gotoAndStop(2);
			tooltipManager.addToolTip(this.conFilter.bt1, "Too Easy");
			this.conFilter.bt1.addEventListener(MouseEvent.CLICK,changeCon, false, 0, true);
			this.conFilter.con2.conColor = this.conColorLevelMap["1"];
			this.conFilter.con2.gotoAndStop(2);
			tooltipManager.addToolTip(this.conFilter.bt2, "Easier");
			this.conFilter.bt2.addEventListener(MouseEvent.CLICK,changeCon, false, 0, true);
			this.conFilter.con3.conColor = this.conColorLevelMap["2"];
			this.conFilter.con3.gotoAndStop(2);
			tooltipManager.addToolTip(this.conFilter.bt3, "Average");
			this.conFilter.bt3.addEventListener(MouseEvent.CLICK,changeCon, false, 0, true);
			this.conFilter.con4.conColor = this.conColorLevelMap["3"];
			this.conFilter.con4.gotoAndStop(2);
			tooltipManager.addToolTip(this.conFilter.bt4, "Tougher");
			this.conFilter.bt4.addEventListener(MouseEvent.CLICK,changeCon, false, 0, true);
			this.conFilter.con5.conColor = this.conColorLevelMap["4"];
			this.conFilter.con5.gotoAndStop(2);
			tooltipManager.addToolTip(this.conFilter.bt5, "Very Hard");
			this.conFilter.bt5.addEventListener(MouseEvent.CLICK,changeCon, false, 0, true);
		}
		
		private function changeCon(evt:MouseEvent):void{
			var evtObjName:String = evt.target.name;			
			var evtId:Number = parseInt(evtObjName.replace("bt",""));
			//trace("con: ",evtId);
			var conObj:MovieClip = this.conFilter["con"+evtId];
			if (conObj.currentFrame == 2){
				conObj.gotoAndStop(1);
				var newConArr:Array = new Array();
				for (var c:int=0;c<this.conFilterArray.length;c++){
					if (this.conFilterArray[c] != conObj.conColor){
						newConArr.push(this.conFilterArray[c]);
					}					
				}
				this.conFilterArray = newConArr;
			} else {
				conObj.gotoAndStop(2);
				if (this.conFilterArray.indexOf(conObj.conColor) === -1){
					this.conFilterArray.push(conObj.conColor);
				}
			}
			this.filterUsersByCon();
		}
		
		private function addTabs():void{
			this.TBtnUserName.isActive = true;
			this.TBtnUserName.sortAscending = false;
			this.TBtnUserName.addEventListener(UiEvents.TAB_CLICK,orderByName, false, 0, true);
			this.TBtnUserName.addEventListener(UiEvents.TAB_IS_ACTIVE,nameActivated, false, 0, true);			
			this.TBtnTotalCharge.sortAscending = true;
			this.TBtnTotalCharge.addEventListener(UiEvents.TAB_CLICK,orderByCharge, false, 0, true);
			this.TBtnTotalCharge.addEventListener(UiEvents.TAB_IS_ACTIVE,chargeActivated, false, 0, true);			
			this.TBtnCon.sortAscending = true;
			this.TBtnCon.addEventListener(UiEvents.TAB_CLICK,orderByCon, false, 0, true);
			this.TBtnCon.addEventListener(UiEvents.TAB_IS_ACTIVE,conActivated, false, 0, true);			
			this.TBtnEquippedRings.isDisabled = true;
		}
		
		private function nameActivated(e:UiEvents):void {
			this.TBtnTotalCharge.isActive = false;
			this.TBtnCon.isActive = false;
			this.TBtnUserName.isActive = true;
			
			this.TBtnUserName.sortAscending = !this.TBtnUserName.sortAscending;			
		}
		
		private function orderByName(evt:UiEvents):void{
			var tabObj:TabButton = evt.target as TabButton;
			if (tabObj != null){
				this.resortField("username",tabObj.sortAscending);
			}
		}
		
		private function chargeActivated(e:UiEvents):void {
			this.TBtnUserName.isActive = false;
			this.TBtnCon.isActive = false;
			this.TBtnTotalCharge.isActive = true;
			
			this.TBtnTotalCharge.sortAscending = !this.TBtnTotalCharge.sortAscending;			
		}
		
		private function orderByCharge(evt:UiEvents):void{
			var tabObj:TabButton = evt.target as TabButton;
			if (tabObj != null){
				this.resortField("totalCharge",tabObj.sortAscending,true);
			}
		}
		
		private function conActivated(e:UiEvents):void {
			this.TBtnUserName.isActive = false;
			this.TBtnTotalCharge.isActive = false;
			this.TBtnCon.isActive = true;
			
			this.TBtnCon.sortAscending = !this.TBtnCon.sortAscending;			
		}
		
		private function orderByCon(evt:UiEvents):void{
			var tabObj:Object = evt.target;
			if (tabObj != null){
				this.resortField("conLevel",tabObj.sortAscending,true);			
			}
		}
		
		private function addButtons():void{
			this.inviteBtn.init("",false);
			this.setInviteButtonActive(false);
			this.inviteBtn.x = 15;
			this.inviteBtn.y = 295;			
			this.refreshBtn.init("",false);
			this.refreshBtn.x = 460-this.refreshBtn.width;
			this.refreshBtn.y = 295;
			this.addChild(this.inviteBtn);
			this.addChild(this.refreshBtn);
			this.refreshBtn.addEventListener(MouseEvent.CLICK, refreshList, false, 0, true);
			// set the colors on the buttons
			for (var indexStr:String in this.conColorLevelMap) {
				var conColorMc:MovieClip = this.conFilter["conColor" + indexStr];
				if (conColorMc != null) {
					var ct:ColorTransform = conColorMc.transform.colorTransform;
					ct.color = ConColors.getInstance().getConColorByName(this.conColorLevelMap[indexStr]); 
					conColorMc.transform.colorTransform = ct;
				}
			}
			
		}
		
		
		private function refreshList(me:MouseEvent):void {
			refreshBtn.setActive(false);
			var evt:UiEvents = new UiEvents(UiEvents.LFG_REFRESH,"");
			this.dispatchEvent(evt);	
		}
		
		
		//--- LFG Check
		private function onChkLFGClick(evt:MouseEvent):void{
			var v:Boolean = false;
			if (MovieClip(this.chkLFG).currentFrame >= 2){
				v = true;
			}
			var e:UiEvents = new UiEvents("LFGClick", null);
			e.value = v;
			this.dispatchEvent(e);			
		}
		
	public function setLFG(value:Boolean):void{
			if (value){
				this.chkLFG.gotoAndStop(2);
			}else{
				this.chkLFG.gotoAndStop(1);
			}
			
			if (value) {
				this.checkInviteButton();
			} else {
				this.setInviteButtonActive(false);				
			}
			
		}
		
		
		
		
		
	}
}
