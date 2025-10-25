package com.gaiaonline.battle.ui.actorInfo
{
	import com.gaiaonline.battle.ConColors;
	import com.gaiaonline.battle.newactors.ActorDisplay;
	import com.gaiaonline.battle.newactors.ActorManager;
	import com.gaiaonline.battle.newactors.BaseActor;
	import com.gaiaonline.battle.newactors.BaseActorEvent;
	import com.gaiaonline.battle.newactors.TeamManager;
	import com.gaiaonline.battle.newrings.RingIconFactory;
	import com.gaiaonline.battle.ui.IFlexUiManager;
	import com.gaiaonline.controls.BuffEntry;
	import com.gaiaonline.flexModulesAPIs.FlexMenuItem;
	import com.gaiaonline.flexModulesAPIs.IMenuListener;
	import com.gaiaonline.flexModulesAPIs.actorInfo.ActorTypes;
	import com.gaiaonline.flexModulesAPIs.actorInfo.ITargetInfo;
	import com.gaiaonline.flexModulesAPIs.globalevent.GlobalEvent;
	import com.gaiaonline.platform.map.MapFilesFactory;
	import com.gaiaonline.utils.DisplayObjectUtils;
	
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.Sprite;
	import flash.events.Event;
	
	import mx.collections.ArrayCollection;
	
	public class TargetInfoController implements IMenuListener
	{
		private var _view:ITargetInfo = null;
		
		private var _colorCon:uint = 0x000000;				
		private var _currTarget:BaseActor = null;
		private var _currName:String = null;
		private var _currId:String = null;
		private var _currRoomId:String = null;		
		private var _actorImage:Sprite = null;	
		private var _currHealth:Number = NaN;	
		private var _maxHealth:Number = NaN;
		private var _currStamina:Number = NaN;	
		private var _maxStamina:Number = NaN;		
		private var _currRage:Number = NaN;	
		private var _suppressedCL:Number = NaN;
		private var _conLevel:Number = NaN;		
		private var _currKtfo:Boolean = false;
		private var _currRank:Number = NaN;
		private var _currZoneName:String = null;
		private var _currCrewState:String = BaseActor.CREW_STATE_NOT_KNOWN;

		private var _highlighted:Boolean = false;				
		private var _visible:Boolean = true;
		private var _isUsingRawData:Boolean = false;
		private var _viewParent:DisplayObjectContainer = null;
				
		private var _canShowMuteButton:Boolean = true;
		private var _menuData:Object = null;
		private var _conColors:ConColors = null;		
		
		private var _targetMode:Boolean = false;
		private var _flexUiManangerImpl:IFlexUiManager = null;
		
		private var _ignoreItem:FlexMenuItem = null;
		
		public function TargetInfoController(flexUiManagerImpl:IFlexUiManager, targetMode:Boolean) {
			this._flexUiManangerImpl = flexUiManagerImpl;
			this._targetMode = targetMode;
			this._conColors = ConColors.getInstance();
			this._menuData = this._flexUiManangerImpl.getArrayCollection();
															
			DisplayObjectUtils.addWeakListener(GlobalEvent.eventDispatcher, GlobalEvent.TEAM_UPDATED, onTeamUpdated);
			DisplayObjectUtils.addWeakListener(GlobalEvent.eventDispatcher, GlobalEvent.IN_CREW_STATE_UPDATE, onInCrewStateUpdate);
			DisplayObjectUtils.addWeakListener(GlobalEvent.eventDispatcher, GlobalEvent.SUPPRESSED_CL_CHANGE, onSuppressedCLChange);
			DisplayObjectUtils.addWeakListener(GlobalEvent.eventDispatcher, GlobalEvent.NEW_ROOM_ENTERED, onMeChangedRoom);
		}
		
		public function onMenuItemClick(menuItem:FlexMenuItem):void {
			this._currTarget.handleMenuItemClick(menuItem.label, menuItem.data);
			
			// swap out ignore/remove ignore on click - we don't wait for GSI confirmation when we add to ignore list so can do this here
			if (menuItem.label == FlexMenuItem.ADD_IGNORE || menuItem.label == FlexMenuItem.REMOVE_IGNORE) {
				var idx:int = (_menuData as ArrayCollection).getItemIndex(_ignoreItem);
				var oldText:String = (_menuData as ArrayCollection).getItemAt(idx).label;
				var newText:String = (menuItem.label == FlexMenuItem.ADD_IGNORE) ? FlexMenuItem.REMOVE_IGNORE : FlexMenuItem.ADD_IGNORE;
				(_menuData as ArrayCollection).getItemAt(idx).label = newText;
				(_menuData as ArrayCollection).itemUpdated(_menuData[idx], _menuData[idx].label, oldText, newText);
			}			
		}
		 
		public function addView(view:ITargetInfo):void {
			//@@@ REALLY ONLY HANDLE ONE VIEW NOW, SO SHOULD COMPLAIN IF ANOTHER IS SET
			this._view = view;
			this._viewParent = DisplayObject(view).parent;
			if (!this._isUsingRawData) {
				this.setActorInfo(this._currTarget, true);
			} else {
				this.setRawData(this._currName, this._currId, this._currRoomId);
			}
		}

		public function hasView(view:ITargetInfo):Boolean {
			return view == this._view;
		}
		
		private const _listeners:Array =
		[
			{ evt: BaseActorEvent.HEALTH_UPDATED,		fn: onHealthUpdated },
			{ evt: BaseActorEvent.STAMINA_UPDATED,		fn: onStaminaUpdated },								
			{ evt: BaseActorEvent.RAGE_UPDATED,			fn: onRageUpdated },
			{ evt: BaseActorEvent.RANK_UPDATED,			fn: onRankUpdated },
			{ evt: BaseActorEvent.KTFO_STATUS_CHANGED,	fn: onKtfoStatusChanged },
			{ evt: BaseActorEvent.ZONE_CHANGED,			fn: onCurrTargetZoneChanged },
			{ evt: BaseActorEvent.BUFFS_UPDATED,		fn: onBuffsUpdated },
			{ evt: BaseActorEvent.NAME_UPDATED,			fn: onNameUpdated },			
			{ evt: BaseActorEvent.IGNORE_LIST_CHANGED,  fn: onIgnoreListChange }
		];
		private function addActorListeners(actor:BaseActor):void{
			for each (var obj:Object in _listeners) {
				actor.addEventListener(obj.evt, obj.fn, false, 0, true);
			}			
		}
		private function removeActorListeners(actor:BaseActor):void{
			for each (var obj:Object in _listeners) {
				actor.removeEventListener(obj.evt, obj.fn);
			}			
		}

		public function setActorInfo(target:BaseActor, forceUpdate:Boolean = false):void{
			this.setVisible(target != null);

			this._isUsingRawData = false;
			this._canShowMuteButton = true;
			
			if (!target || target.targetType == BaseActor.TARGETTYPE_POWERUSABLE) {
				return;
			}						
	
			if (!forceUpdate && target == this._currTarget) {
				return;
			}									

			if (this._currTarget) {
				removeActorListeners(this._currTarget);			
			}

			if (ActorManager.getInstance().myActor) {
				ActorManager.getInstance().myActor.addEventListener(BaseActorEvent.ACTOR_CON_LEVEL_UPDATED, onActorConLevelUpdated, false, 0, true);
			}
			
			addActorListeners(target);

			var prevTarget:BaseActor = this._currTarget;
			this._currTarget = target;
			
			if (target) {
				target.getActorDisplay().removeEventListener(ActorDisplay.LOADED, onActorDisplayLoaded);
				if (this._view || prevTarget != target){
					if (prevTarget != null) {
						prevTarget.removeEventListener(BaseActorEvent.ACTOR_CON_LEVEL_UPDATED, onActorConLevelUpdated);
					}
					this._currTarget.addEventListener(BaseActorEvent.ACTOR_CON_LEVEL_UPDATED, onActorConLevelUpdated, false, 0, true);					
					loadActorInfo();
					if (!target.getActorDisplay().isLoaded) {
						// then listen for the LOADED event so we can update the UI
						target.getActorDisplay().addEventListener(ActorDisplay.LOADED, onActorDisplayLoaded, false, 0, true);
					}					
					this.checkIfConColorChanged();
				} 
				
				this._currName = target.actorName;
				this._currId = target.actorId;				
				this._currRoomId = target.roomId;
				this._currHealth = target.hp;
				this._maxHealth = target.maxHp;
				this._currStamina = target.exhaustion;
				this._maxStamina = target.maxExhaustion;
				this._currRage = target.rage;
				this._suppressedCL = target.suppressedCL;
				this._conLevel = target.conLevel;
				this._currKtfo = target.isKtfo;
				this._currRank = target.rankCategory;
				this._currZoneName = MapFilesFactory.getInstance().mapFiles.getZoneNameFromRoomId(this._currTarget.roomId);				
				// don't set _currCrewState; let it update via events naturally
				
				this.updateAll(forceUpdate);	
			}				
		}		

		private function updateAll(force:Boolean = false):void {
			if (this._view) {
				this.updateActorType();
				this.updateName();
				this.updateHealth();
				this.updateStamina();
				this.updateRage();
				this.updateConColor();
				this.updateConLevel();
				this.toggleKtfo();
				this.updateTeamLeader();
				this.updateBuffBarAndZoneName();
				this.updateBuffs();
				this.updateRank();
				this.updateShowPendingResponse();
				this.updateHighlight();
				
				this.buildMenu();					
			}			
		}	

		private function updateBuffBarAndZoneName():void {
			if (!this.updateShowZoneName()) { // the decision to show the zone name dominates
				this.updateShowBuffBar();
			}			
		}
		
		private function updateHighlight():void {
			if (this._view) {
				this._view.setHighlighted(this._highlighted);
			}
		}
		public function setRawData(actorName:String, actorId:String, roomId:String):void {
			this._isUsingRawData = true;
			this._canShowMuteButton = false;
			this._currName = actorName;
			this._currId = actorId;
			this._currRoomId = roomId;

			this.updateAll();
			this.setVisible(true);
		}
						
		private function setVisible(visible:Boolean):void {
			if (this._visible != visible) {
				this._visible = visible;
				this.updateVisibility();
			}				
		}

		public function setHighlighted(highlighted:Boolean):void {
			if (this._highlighted != highlighted) {
				this._highlighted = highlighted;

				if (this._view) {
					this._view.setHighlighted(this._highlighted);
				}
			}
		}		
		public function getActor():BaseActor {
			return this._currTarget;
		}
		
		public function getActorId():String {
			return this._currId;
		}
		
		public function showZoneName(zoneName:String):void {
			if (this._view) {
				this._view.showZoneName(zoneName);
				this._view.showBuffBar(zoneName == null);
			}
		}
		
		public function onKtfoStatusChanged(e:BaseActorEvent):void {
			if (this._currTarget && this._currKtfo != this._currTarget.isKtfo) {
				this._currKtfo = this._currTarget.isKtfo;
				this.updateKtfo();
			}
		}
		
		private function onMeChangedRoom(e:GlobalEvent):void {
			this.updateShowZoneName();
		}
		
		private function onCurrTargetZoneChanged(e:BaseActorEvent):void {
			this._currRoomId = e.actor.roomId;
			this.updateShowZoneName();
		}
		
		private function onBuffsUpdated(e:BaseActorEvent):void {
			this.updateBuffs();
		}		
		
		private function onNameUpdated(e:BaseActorEvent):void {
			if (e.actor.actorName != this._currName) {
				this._currName = e.actor.actorName;
				this.updateName();
			}
		}		

		private function onIgnoreListChange(event:BaseActorEvent):void{
			if (this._currTarget){
				buildMenu();
			}
		}
		
		private function buildMenu():void {
			if (this._currTarget && !this._isUsingRawData) {
				var me:Boolean = (ActorManager.getInstance().myActor.actorId == this._currId);
				var meLeader:Boolean = ActorManager.getInstance().myActor.isTeamLeader;
				var isTeammate:Boolean = this._currTarget.isTeammate();
				var recrewt:Boolean = false;
				var teamCount:int = ActorManager.getInstance().myActor.teamCount();
				var guestUser:Boolean = this._currTarget.isGuestUser();
						
				var invite:Boolean = false;
				var leave:Boolean = false;
				var promote:Boolean = false;
				var kick:Boolean = false;
				
				if (this._currTarget.isInvitableToCrew()) {
					invite = true;
				}
				if (me && teamCount > 1){
					leave = true;
				}
				if (!me && meLeader && isTeammate){
					promote = kick = true;
				}
				if (me && meLeader && teamCount < TeamManager.TEAM_MAX) {
					recrewt = true;
				}
				
				// Because of 				            
            	// http://bugs.adobe.com/jira/browse/SDK-17302
            	// we can't reuse the same array collection; we have to create a new one each time						
				this._menuData = this._flexUiManangerImpl.getArrayCollection();
				
				// This is supposed to be the first menu item, when valid
				if (recrewt) {
					this.addMenuItem(FlexMenuItem.RECREWT, "left", "alt");
				}
				
				//---- Team		
				if (invite) {
					if (invite && !this._currTarget.isLinkDead){
						this.addMenuItem(FlexMenuItem.INVITE, "left", "alt");									
					}					
				}
				
				if (!this._targetMode) {
					if (leave || kick || promote){
						if (leave){
							this.addMenuItem(FlexMenuItem.LEAVE, "left", "alt");															
						}
						if (kick){
							this.addMenuItem(FlexMenuItem.KICK, "left", "alt");																					
						}
						if (promote && !this._currTarget.isLinkDead){
							this.addMenuItem(FlexMenuItem.PROMOTE, "left", "alt");																					
						}					
					}				
				}
				
				//--- Chat
				if (!me) {
					this.addMenuItem(FlexMenuItem.WHISPER);						
					
					var i:int = ActorManager.getInstance().myActor.ignoreList.indexOf(this._currId);
					_ignoreItem =  (i < 0) ? this.addMenuItem(FlexMenuItem.ADD_IGNORE) : this.addMenuItem(FlexMenuItem.REMOVE_IGNORE);																					
				}

				// social stuff				
				this.addMenuItem(FlexMenuItem.CHARACTER_INFO);

				if (!me && !guestUser){
					this.addMenuItem(FlexMenuItem.ADD_FRIEND);									
				}
				
				this.addMenuItem(FlexMenuItem.VIEW_PROFILE);			
				
				if (!me && !guestUser) {		
					this.addMenuItem(FlexMenuItem.REPORT_ABUSE);
				}
				
				if (this._menuData.length > 0) {
					var lastItem:FlexMenuItem = FlexMenuItem(this._menuData.getItemAt(this._menuData.length - 1));
					if (lastItem.type == "separator") {
						this._menuData.removeItemAt(this._menuData.length - 1);
					}
				}				
			}			
			if (this._view) {
				this._view.setMenu(this._menuData, this);
			}			
		}

		private function addMenuItem(label:String, alignment:String = "right", skinType:String = "main"):FlexMenuItem {
			var flexMenuItem:FlexMenuItem = new FlexMenuItem(label);
			this._menuData.addItem(flexMenuItem);
			flexMenuItem.alignment = alignment;
			flexMenuItem.skinType = skinType;
			this._menuData.addItem(new FlexMenuItem("none", "separator"));
			return flexMenuItem;
		}		
		
		private function onActorDisplayLoaded(evt:Event):void {
			if (this._currTarget) {
				this._currTarget.getActorDisplay().removeEventListener(ActorDisplay.LOADED, onActorDisplayLoaded);						
			}
			loadActorInfo();
		}

		private function loadActorInfo():void {
			var target:BaseActor = this._currTarget;
			var levelColor:Number = this.getConColor();
								
			if (target != null) {
				this._colorCon = levelColor;
				this._currTarget = target;
				this._actorImage = target.getActorDisplay().getTargetInfoPortrait();
				this.updateImage();				
				this.checkIfConColorChanged();
			}	
		}
		
		private function getConColor():int{	
			
			if (this._currTarget) {				
				  var conColor:int = 0xFFFFFF;			  
				  if (this._currTarget.conLevel){					  
					  conColor = this._conColors.getConColorForDiff(this._currTarget.getSuppressedCL() - ActorManager.getInstance().myActor.getSuppressedCL());					  
				  }
				  return conColor;
			}			
			return -1;
		}
		
		private function onInCrewStateUpdate(e:GlobalEvent):void {
			if (this._currTarget && e.data.actorId == this._currId && this._currCrewState != e.data.inCrewState) {
				this._currCrewState = e.data.inCrewState;
				this.buildMenu();
			}
		}
		
		private function onTeamUpdated(e:GlobalEvent):void {
			if (this._currTarget) {
				this.buildMenu();
				this.updateTeamLeader();
			}
		}								
		
		private function onHealthUpdated(e:BaseActorEvent):void {
			var actor:BaseActor = e.actor;
			var doUpdateHealth:Boolean = false;
			if (this._currTarget && this._currId == actor.actorId){
				if (this._currHealth != actor.hp) {
					this._currHealth = actor.hp;
					doUpdateHealth = true;
				}				
				if (this._maxHealth != actor.maxHp) {
					this._maxHealth = actor.maxHp;
					doUpdateHealth = true;
				}				
				if (doUpdateHealth) {
					this.updateHealth();
				}
			}		
		}		

		private function onStaminaUpdated(e:BaseActorEvent):void {
			var actor:BaseActor = e.actor;
			var doUpdateStamina:Boolean = false;			
			if (this._currTarget && this._currId == actor.actorId){
				if (this._currStamina != actor.exhaustion) {
					this._currStamina = actor.exhaustion;
					doUpdateStamina = true;
				}
				if (this._maxStamina != actor.maxExhaustion) {
					this._maxStamina= actor.maxExhaustion;
					doUpdateStamina = true;
				}
				if (doUpdateStamina) {
					this.updateStamina();
				}
			}		
		}		

		private function onRageUpdated(e:BaseActorEvent):void {
			if (this._currTarget && this._currId == e.actor.actorId){
				if (this._currRage != e.actor.rage) {
					this._currRage = e.actor.rage;
					this.updateRage();
				}
			}		
		}		

		private function onRankUpdated(e:BaseActorEvent):void {
			if (this._currTarget && this._currId == e.actor.actorId){
				if (this._currRank != e.actor.rankCategory) { 
					this._currRank = e.actor.rankCategory;
					this.updateRank();
				}
			}		
		}		

		private function onActorConLevelUpdated(e:BaseActorEvent):void {
			this.checkIfConLevelChanged();			
			this.checkIfConColorChanged();
		}
		
		private function onSuppressedCLChange(e:GlobalEvent):void {
			if (this._currTarget == ActorManager.getInstance().myActor) {
				this._suppressedCL = e.data as Number;
				this.updateConLevel();					
			}			
			this.checkIfConLevelChanged();						
			this.checkIfConColorChanged();
		}

		private function checkIfConColorChanged():void {
			if (this._currTarget) {
				var levelColor:Number = this.getConColor();									
				if (this._colorCon != levelColor){				
					this._colorCon = levelColor;
					this.updateConColor();
				}
			}			
		}

		private function checkIfConLevelCapChanged():void {
			
		}	
				
		private function checkIfConLevelChanged():void {			
			if (this._currTarget) {
				var conLevel:Number = this._currTarget.suppressedCL;
				if (this._suppressedCL != conLevel){		
					this._suppressedCL = this._currTarget.suppressedCL;				
					this.updateConLevel();
				}
			}			
		}

		private function updateConColor():void{
			if (this._view && !this._isUsingRawData) {
				this._view.updateConColor(this._colorCon);
			}
		}

		private function updateConLevel():void{
			if (this._view) {	
				var isCap:Boolean = !isNaN(this._suppressedCL) && this._suppressedCL < this._conLevel;			
				if (this._currTarget) {
					var cl:Number = this._currTarget.conLevel;
					if (isCap){cl = this._currTarget.suppressedCL};
					this._view.updateConLevel(cl, isCap);
				} else if (this._isUsingRawData) {
					this._view.updateConLevel(NaN, isCap);
				}
			}
		}

		private function updateName():void {
			if (this._view) {
				this._view.updateName(this._currName);
			}
		}

		private function updateShowPendingResponse():void {
			if (this._view) {
				this._view.showPendingResponse(this._isUsingRawData);
			}
		}

		private function updateImage():void {
			if (this._view && this._actorImage) {
				this._view.updateImage(this._actorImage);
			}
		}
		
		private function updateHealth():void {
			if (this._view && !this._isUsingRawData) {
				this._view.updateHealth(this._currHealth, this._maxHealth);
			}
		}

		private function updateStamina():void {
			if (this._view && !this._isUsingRawData) {
				this._view.updateStamina(this._currStamina, this._maxStamina);
			}
		}
		
		private function updateRage():void {
			if (this._view && !this._isUsingRawData) {
				this._view.updateRage(this._currRage);					
			}
		}

		private function updateVisibility():void {
			if (this._view) {
				var displayObject:DisplayObject = DisplayObject(this._view);
				if (displayObject.parent && !this._visible) {
					this._viewParent = displayObject.parent;
					this._viewParent.removeChild(displayObject);
				} else if (!displayObject.parent && this._visible) {						
					this._viewParent.addChild(displayObject);
				}
			}
		}		

		private function updateRank():void {
			if (this._view && this._currTarget && !this._isUsingRawData) {
				this._currRank = this._currTarget.rankCategory;
				this._view.showRank(this._currRank);
			}
		}
		
		private function updateKtfo():void {
			if (this._view && !this._isUsingRawData) {
				this.toggleKtfo();
			}
		}
		
		private function toggleKtfo():void {
			if (this._currTarget && !this._isUsingRawData) {
				var ktfo:Boolean = this._currTarget.isKtfo;
				this._currKtfo = ktfo;
				this._view.setIsKtfo(ktfo);
			}
		}
		
		private function updateActorType():void {
			if (this._view && this._currTarget) {
				this._view.updateActorType(this._currTarget.actorType);
			}
		}
		
		private function updateTeamLeader():void {
			if (!this._targetMode && this._view && !this._isUsingRawData) {
				var showTargetAsTeamLeader:Boolean = ActorManager.getInstance().myActor.myTeam[this._currId]								
				var me:BaseActor = ActorManager.getInstance().myActor;
				if (me == this._currTarget) {
					showTargetAsTeamLeader = ActorManager.getInstance().myActor.isTeamLeader && me.teamCount() > 1;					
				} 								
				this._view.showAsLeader(showTargetAsTeamLeader);
				if (!showTargetAsTeamLeader) {
					this.updateConColor();
				}
			}
		}
		
		private static const BUFF_CAPACITY:int = 16;
		private var _buffCache:Object = {};
		private function updateBuffs():void {
			if (this._view && this._currTarget && !this._isUsingRawData)
			{
				// [kja] we could do better than this.  The server's sending us add/remove style updates, there's
				// no reason to have to determine add/removes all over again like we are below...

				//
				// First, build a map of the new buffs (re-using exiting Bitmaps if we have 'em)
				var newLookup:Object = {};
				var buffsChanged:Boolean = false;
				var nBuffs:int = 0;

				for each (var buff:Object in this._currTarget.buffs)
				{
					if (!buff.ghi)
					{
						if (buff.url) {
							if (_buffCache[buff.url]) {
								newLookup[buff.url] = _buffCache[buff.url];
								if (buff.rageRank && buff.rageRank != BuffEntry(newLookup[buff.url]).rageRank)
								{
									buffsChanged = true;
								}
							}
							else {
								var isMe:Boolean = this._currTarget == ActorManager.getInstance().myActor;
								newLookup[buff.url] = new BuffEntry(buff.name, RingIconFactory.getBitmap(buff.url), isMe);						
								buffsChanged = true;
							}
							BuffEntry(newLookup[buff.url]).rageRank = buff.rageRank ? buff.rageRank : NaN; 
							if (++nBuffs == BUFF_CAPACITY) {
								break;
							}
						}
					}
				}
						
				//
				// Next, see if any of our previous buffs have expired
				for (var existingBuffUrl:Object in this._buffCache) {
					if (!newLookup[existingBuffUrl]) {
						buffsChanged = true;
						break;
					}
				}

				if (buffsChanged) {
					_buffCache = newLookup;
					this._view.updateBuffs(_buffCache);
				}
			}
		}

		private function updateShowBuffBar():Boolean {
			var showBuffBar:Boolean = false;
			if (this._currTarget && this._view && !this._isUsingRawData) {
				showBuffBar = (this._currTarget.actorType == ActorTypes.PLAYER || this._currTarget.actorType == ActorTypes.MONSTER);
				this._view.showBuffBar(showBuffBar);
				if (showBuffBar) {
					this._view.showZoneName(null);
				}
			}
			return showBuffBar;
		}		
		private function updateShowZoneName():Boolean {
			var showZoneName:Boolean = false;
			if (this._view && this._currTarget && this._currTarget.actorType != ActorTypes.PLAYER) {
				this.showZoneName(null);
			} else {		
				var me:BaseActor = ActorManager.getInstance().myActor;			
				if (me != this._currTarget && this._currRoomId) { // the latter conjunct is just for sanity checking; should always be true
					var myZoneName:String = MapFilesFactory.getInstance().mapFiles.getZoneNameFromRoomId(me.roomId);				
					var teammateZoneName:String = MapFilesFactory.getInstance().mapFiles.getZoneNameFromRoomId(this._currRoomId);
					if (myZoneName != teammateZoneName || this._isUsingRawData) {
						this._currZoneName = teammateZoneName;
						this.showZoneName(teammateZoneName);
						showZoneName = true;
					} else {
						this.showZoneName(null);
					}
				}
			}
			this.updateShowPendingResponse();
			return showZoneName;				
		}		
	}
}
