package com.gaiaonline.battle.newactors
{
	import com.gaiaonline.battle.ApplicationInterfaces.ILinkManager;
	import com.gaiaonline.battle.ApplicationInterfaces.IUIFramework;
	import com.gaiaonline.battle.Globals;
	import com.gaiaonline.battle.ItemLoadManager.ItemIcon;
	import com.gaiaonline.battle.ItemLoadManager.RingItemIconCustomization;
	import com.gaiaonline.battle.ItemManager.ItemManager;
	import com.gaiaonline.battle.ItemManager.ItemManagerEvent;
	import com.gaiaonline.battle.ItemManager.RingItemManager;
	import com.gaiaonline.battle.Loot.Orbs;
	import com.gaiaonline.battle.gateway.BattleEvent;
	import com.gaiaonline.battle.gateway.BattleGateway;
	import com.gaiaonline.battle.gateway.BattleMessage;
	import com.gaiaonline.battle.newcollectibles.Collectible;
	import com.gaiaonline.battle.newcollectibles.CollectiblesLoadManager;
	import com.gaiaonline.battle.newrings.Ring;
	import com.gaiaonline.battle.newrings.RingAnim;
	import com.gaiaonline.battle.newrings.RingLoadManager;
	import com.gaiaonline.battle.ui.AlertTypes;
	import com.gaiaonline.battle.ui.DialogWindow;
	import com.gaiaonline.battle.ui.uiactionbar.UiItemBar;
	import com.gaiaonline.battle.userServerSettings.IGameSettings;
	import com.gaiaonline.flexModulesAPIs.globalevent.GlobalEvent;
	import com.gaiaonline.utils.DisplayObjectUtils;
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.ProgressEvent;
	import flash.utils.clearTimeout;
	import flash.utils.setTimeout;
	
	public class RingManager extends EventDispatcher
	{
		
		private const MIN_ALLrings_TIMEOUT:Number = 30000; // 30 seconds		
		private const MIN_RING_FINGER_TIMEOUT:Number = 30000; // 30 seconds
		private const MAX_ALLrings_TIMEOUT:Number = 240000; // 240 seconds == 4 minutes
		private const MAX_RING_FINGER_TIMEOUT:Number = 240000; // 240 seconds == 4 minutes		
	
		public static const RING_LOADED:String = "RingLoaded";
		
		private var _gateway:BattleGateway = null;
		private var _maxRingCL:Number = 0;
		private var allRingsTimeout:Number = MIN_ALLrings_TIMEOUT;
		private var getRingFingerTimeout:Number = MIN_RING_FINGER_TIMEOUT;
		private var ringLoadCount:int = 0;
		private var ringLoadTimeOut:int = 0;
		private var _selectedRingSlot:int = -1;
		private var tempRingsArray:Array = new Array();
		private var _isPointTarget:int = -1;
		private var _allowRingUse:Boolean = true;
		
		private var _uiFramework:IUIFramework = null;
		private var _linkMaager:ILinkManager = null;
		private var _actor:BaseActor = null;
		
		private var _ringAutoSelect:Boolean = true;
		private var _autoMoveInRange:Boolean = true
		
		private var _isPassiveRing:Boolean = false;
		
		public function RingManager(gateway:BattleGateway, uiFramework:IUIFramework, linkManager:ILinkManager, actor:BaseActor){
			_gateway = gateway;
			_uiFramework = uiFramework;
			_linkMaager = linkManager;
			_actor = actor;
			init();
		}

		private function get rings():Object {
			return _actor.rings;
		}

		private function init():void{
			_gateway.addEventListener(BattleEvent.MOVE_RING, onMoveRing, false, 0, true);
			_gateway.addEventListener(BattleEvent.RING_UPDATE, onRingUpdate, false, 0, true);
			
			GlobalEvent.eventDispatcher.addEventListener(GlobalEvent.USER_SETTINGS_LOADED, onGraphicsOptionChanged, false, 0, true);
			GlobalEvent.eventDispatcher.addEventListener(GlobalEvent.GRAPHIC_OPTIONS_CHANGED, onGraphicsOptionChanged, false, 0, true);
			
			DisplayObjectUtils.addWeakListener(GlobalEvent.eventDispatcher, GlobalEvent.ALLOW_RING_USE, onAllowRingUse);
			DisplayObjectUtils.addWeakListener(GlobalEvent.eventDispatcher, GlobalEvent.ACTOR_SELECTED, onActorSelected);
			
			DisplayObjectUtils.addWeakListener(GlobalEvent.eventDispatcher, GlobalEvent.ACTOR_MOUSE_DOWN, onActorMouseDown);
			DisplayObjectUtils.addWeakListener(GlobalEvent.eventDispatcher, GlobalEvent.ACTOR_MOUSE_UP, onActorMouseUp);
			
			DisplayObjectUtils.addWeakListener(GlobalEvent.eventDispatcher, GlobalEvent.RING_KEY_DOWN, onRingKeyDown);
			DisplayObjectUtils.addWeakListener(GlobalEvent.eventDispatcher, GlobalEvent.RING_KEY_UP, onRingKeyUp);
			
			DisplayObjectUtils.addWeakListener(GlobalEvent.eventDispatcher, GlobalEvent.RING_AUTO_FIRE_DOWN, onRingAutoFireDown);
			DisplayObjectUtils.addWeakListener(GlobalEvent.eventDispatcher, GlobalEvent.RING_AUTO_FIRE_UP, onRingAutoFireUp);
			
			RingItemManager.getInstance().addEventListener(ItemManagerEvent.START_CHARGE, onRingStartCharge, false, 0, true);
			RingItemManager.getInstance().addEventListener(ItemManagerEvent.STOP_CHARGE, onRingStopCharge, false, 0, true);
			RingItemManager.getInstance().addEventListener(ItemManagerEvent.CANCEL_CHARGE, onRingCancelCharge, false, 0, true);	
		}
		
		private function onGraphicsOptionChanged(evt:GlobalEvent):void{
			var data:IGameSettings = evt.data as IGameSettings;
			if (data){
				this._ringAutoSelect = data.getRingAutoSelect();
			}
			var data2:IGameSettings = evt.data as IGameSettings;
			if (data2){
				this._autoMoveInRange = data2.getAutoMoveInRange()
			}
		}
		
		private function onAllowRingUse(event:GlobalEvent):void{
			_allowRingUse = event.data.allow;
		}

		private function onTimeOut():void{
			var msg:BattleMessage = null;
			switch(arguments[0]){
				case "allRings":
					//trace("allRings Server call timeout", 8);
					this.allRingsTimeout = Math.min(this.allRingsTimeout * 2, this.MAX_ALLrings_TIMEOUT);
					msg = arguments[1] as BattleMessage;
					if (msg != null) {
						msg.removeEventListener(BattleEvent.CALL_BACK, onUserRings);					
					}								
					this.doneLoadingRing();
					this.updateRings();					
					break;
				
				case "getRingFingerInfos":
					//trace("getRingFingerInfos Server call timeout", 8);
					this.getRingFingerTimeout= Math.min(this.getRingFingerTimeout * 2, this.MAX_RING_FINGER_TIMEOUT);										
					msg = arguments[1] as BattleMessage;
					if (msg != null) {
						msg.removeEventListener(BattleEvent.CALL_BACK, onRingsCallBack);					
					}
					this.tempRingsArray.length = 0;
					this.ringLoadCount = 0;
					this.doneLoadingRing();					
					this.updateRings();
					break;
				
				case "LoadRing":
					//trace("LoadRing time out", 8);
					this.loadPlayerRings();	
					break;
					
				default:
					//trace(arguments[0] + " timeout", 8);					
					break;
			}
		}

		private function addRing(slot:int, ringId:String, chargeLevel:Number, soulbound:Boolean = false, bonusDesc:String = null):void{				
			this.rings[slot] = {ringSlot:slot, ringId:ringId, chargeLevel:chargeLevel, soulbound:soulbound, bonusDesc:null, isUpdating:false};
			if (slot < 8){
				this.updateMaxCL();
			}
		}
				
		public function moveRing(fromSlot:int, toSlot:int):void{	
			
			//trace("MOVE RING" , fromSlot, toSlot)	
			var r1:Object = this.rings[fromSlot];
			var r2:Object = this.rings[toSlot];
						
			this.rings[toSlot] = r1;
			if (r2 != null){
				this.rings[fromSlot] = r2;
			}else{
				delete this.rings[fromSlot];
			}
			var obj:Object = {slot1:fromSlot, slot2:toSlot};
												
			var msg:BattleMessage = new BattleMessage("moveRing", obj );
			msg.addEventListener(BattleEvent.CALL_BACK, onRingMoveCallBack);
			this._gateway.sendMsg(msg);

			if (toSlot <= UiItemBar.MAX_BAR_SLOT_INDEX  && fromSlot > UiItemBar.MAX_BAR_SLOT_INDEX ){
				GlobalEvent.eventDispatcher.dispatchEvent(new GlobalEvent(GlobalEvent.ALERT, {type:AlertTypes.LOOT_RARE, volume:0.6}));																																											
			}else if (fromSlot <= UiItemBar.MAX_BAR_SLOT_INDEX  && toSlot > UiItemBar.MAX_BAR_SLOT_INDEX ){
				GlobalEvent.eventDispatcher.dispatchEvent(new GlobalEvent(GlobalEvent.ALERT, {type:AlertTypes.LOOT_COMMON, volume:0.6}));																																															
			}
			
			this.updateMaxCL();				
			
		}
		private function onRingMoveCallBack(evt:BattleEvent):void{
			
			//--- set Bonus Sets
			//this.debug.traceObject(evt.battleMessage.responseObj[0]);
			//this.debug.traceObject(evt.battleMessage.responseObj[0].ringBonuses.ringBonusSets);
			
			if (evt.battleMessage.responseObj[0].ringBonuses != null){
				this.setBonusSets(evt.battleMessage.responseObj[0].ringBonuses.ringBonusSets);
			}
				
			//---- 
			BattleMessage(evt.target).removeEventListener(BattleEvent.CALL_BACK, onRingMoveCallBack);		
			if (!evt.battleMessage.responseObj[0].success){	
				RingItemManager.getInstance().clearAll();			
				this.updateRings();
			}else{
				///--- Hard code test for SouldBound Animation	
				if (evt.battleMessage.responseObj[0].ringSlotsBound != null){
					var slots:Array = evt.battleMessage.responseObj[0].ringSlotsBound;
					for (var i:int = 0; i < slots.length; i++){
						var ic:ItemIcon = RingItemManager.getInstance().getItemAt(slots[i]);
						if (ic != null){
							ic.SoulBound = true;
							RingItemManager.getInstance().playSoulBound(slots[i]);
						} 
					} 
				}
				
			}	
			
									
			//@@@ RIGHT NOW, WE HAVE TO DO THIS BECAUSE THE RINGS DON'T COME IN THROUGH THE ACTORUPDATE.
			// WE CAN REMOVE THIS EVENT DISPATCH FROM HERE WHEN WE DO GET THE RINGS THROUGH THE ACTORUPDATE
			// -- Mark Rubin
			this._actor.dispatchEvent(new Event(BaseActor.PAPER_DOLL_STATS_UPDATED));
		}
		
		public function updateBonusSet():void{
			var msg:BattleMessage = new BattleMessage("getBonusRingInfo", null);
			msg.addEventListener(BattleEvent.CALL_BACK, onBonusSetUpdate);
			this._gateway.sendMsg(msg);
		}
		private function onBonusSetUpdate(evt:BattleEvent):void{
			//this.debug.traceObject(evt.battleMessage.responseObj);
			this.setBonusSets(evt.battleMessage.responseObj[0].ringBonusSets);
			BattleMessage(evt.target).removeEventListener(BattleEvent.CALL_BACK, onBonusSetUpdate);
		}
		
		private function setBonusSets(ringBonusSets:Array):void{
			var bs1:Boolean = false;
			var bs2:Boolean = false;
			if (ringBonusSets != null){
				for (var i:int = 0; i < ringBonusSets.length; i++){
					var rbs:Object = ringBonusSets[i];
					if(rbs.ringBonusID == 0){
						bs1 = true;
					}else if(rbs.ringBonusID == 1){
						bs2 = true;
					}				
					for (var s:int = 0; s < rbs.ringBonusSlots.length; s++){					
						rings[rbs.ringBonusSlots[s].ringSlot].bonusDesc = rbs.ringBonusDescription;
					}			
				}
			}
			
			if (!bs1){
				for (var si1:int = 0; si1 < 4; si1++){
					if (this.rings[si1] != null){
						rings[si1].bonusDesc = null;
					}
				}	
			}
			if (!bs2){
				for (var si2:int = 4; si2 <= UiItemBar.MAX_BAR_SLOT_INDEX ; si2++){
					if (this.rings[si2] != null){
						rings[si2].bonusDesc = null;
					}
				}			
			}
			if (Globals.uiManager != null && Globals.uiManager.actionBar != null){	
				Globals.uiManager.actionBar.setRingset(bs1, bs2);			
				if (this.selectedRingSlot >= 0 && rings[this.selectedRingSlot] != null){		
					Globals.uiManager.ringInventory.setRingInfo(rings[this.selectedRingSlot].ringId, this.selectedRingSlot);
				}
			}			
		}
		
		public function onMoveRing(evt:BattleEvent):void{
			this.updateRings();
		}
				
		//---  ring Load 
		public function updateRings():void{
			if (this._uiFramework.loadUserItems) {
				var msg:BattleMessage = new BattleMessage("allRings",null);						
				this.ringLoadTimeOut = setTimeout(onTimeOut, this.allRingsTimeout, "allRings", msg);					
				msg.addEventListener(BattleEvent.CALL_BACK, onUserRings);
				this._gateway.sendMsg(msg);
			} else { // short circuit for testing purposes
				this.dispatchEvent(new Event(RING_LOADED));
			}		
		}
		
		private function onUserRings(evt:BattleEvent):void{
			clearTimeout(this.ringLoadTimeOut);
			this.allRingsTimeout = this.MIN_ALLrings_TIMEOUT;
					
//			this.rings = new Object();
			this.selectedRingSlot = -1;
			
			var ringIds:Object = new Object();
			if (evt.battleMessage.responseObj) {
				for (var i:int = 0; i < evt.battleMessage.responseObj.length; i++){				
					var r:Object = evt.battleMessage.responseObj[i];
					var cl:Number = r.ringLevel + r.chargeStep/10;								
					ringIds[r.rid] = r.ringSlot;
					var sb:Boolean = false;
					if (r.soulbound != null){
						sb = r.soulbound;						
					}					
					this.addRing(r.ringSlot, r.rid, cl, sb);
				}
			}
			
			var slotArray:Array = new Array();
			for (var rid:String in ringIds){
				slotArray.push(ringIds[rid]);				
			}
			
			if (slotArray.length > 0){	
				var msg:BattleMessage = new BattleMessage("getRingFingerInfos", {ringSlot:slotArray});
				this.ringLoadTimeOut = setTimeout(onTimeOut, this.getRingFingerTimeout, "getRingFingerInfos", msg);				
				msg.addEventListener(BattleEvent.CALL_BACK, onRingsCallBack);
				this._gateway.sendMsg(msg);
			}else{
				this.doneLoadingRing();
			}	
			
			BattleMessage(evt.target).removeEventListener(BattleEvent.CALL_BACK, onUserRings);										
		}
		
		private function onRingsCallBack(evt:BattleEvent):void{
			clearTimeout(this.ringLoadTimeOut);
			this.getRingFingerTimeout = this.MIN_RING_FINGER_TIMEOUT;

			this.tempRingsArray = evt.battleMessage.responseObj[0].ringInfoList;										
			this.ringLoadCount = 0;
			this.loadPlayerRings();	
		}
		
		private function loadPlayerRings():void{
			dispatchEvent(new ProgressEvent(ProgressEvent.PROGRESS, false, false, ringLoadCount, tempRingsArray.length));
			if (this.ringLoadCount < this.tempRingsArray.length){	
				if (this.tempRingsArray[this.ringLoadCount] != null){	
					var obj:Object = this.tempRingsArray[this.ringLoadCount];				
					var r:Ring;
					if (RingLoadManager.containFull(obj.rid)){
						this.ringLoadCount += 1;
						this.loadPlayerRings();	
					}else{										
						this.ringLoadTimeOut = setTimeout(onTimeOut, 10000, "LoadRing", obj);
						r = RingLoadManager.createFullRing(this._linkMaager.baseURL, obj.rid, obj);																
						r.addEventListener(Ring.LOADED, onRingLoaded);
						this.ringLoadCount += 1;
						if (!CollectiblesLoadManager.contain(r.ringId)) {
							var collData:Object = {icon:r.itemThumbNail, id:r.ringId, name:r.name};						
							var collectible:Collectible = CollectiblesLoadManager.loadCollectible(this._uiFramework, this._linkMaager, collData);
							collectible.addEventListener(Collectible.LOADED, onNewCollectibleLoaded);												
						}										
					} 
				}else{
					this.ringLoadCount += 1;
					this.loadPlayerRings();	
				}				
			}else{
				// next step
				this.tempRingsArray.length = 0;
				this.ringLoadCount = 0;
				this.doneLoadingRing();
			}
		}
		
		private function onNewCollectibleLoaded(e:Event):void {
			Collectible(e.target).removeEventListener(Collectible.LOADED, onNewCollectibleLoaded);
			GlobalEvent.eventDispatcher.dispatchEvent(new GlobalEvent(GlobalEvent.COLLECTIBLES_LOADED, {}));						
		}
		
		private function onRingLoaded(evt:Event):void{
			clearTimeout(this.ringLoadTimeOut);
			Ring(evt.target).removeEventListener(Ring.LOADED, onRingLoaded);
			this.loadPlayerRings();			
		}
		
		private function doneLoadingRing():void{
			clearTimeout(this.ringLoadTimeOut);

			if (Globals.uiManager != null && RingItemManager.getInstance() != null ){				
				for each (var obj:Object in this.rings)
				{
					if (obj)
					{					
						var ring:Ring = RingLoadManager.getRing(obj.ringId);
						var ic:ItemIcon = new ItemIcon(this._uiFramework, RingItemIconCustomization.getInstance(), obj.ringId, obj.ringSlot, ring, obj.soulbound);
						//trace("add Ring ", ic.itemId, ic.slot)
						RingItemManager.getInstance().addItem(ic);
						if (ring.timeUsedAtLoadTime > 0){
							RingItemManager.getInstance().startTimer(obj.ringSlot, ring.rage[0].recharge/1000, true, ring.timeUsedAtLoadTime/1000);
						}
					}
				}													
			}
						
			
			this.dispatchEvent(new Event(RING_LOADED));
			
			var mxCL:Number = this.maxRingCL;		
		}

	
	
	//-----		
		public function getRingAt(slot:int):Ring{
			var r:Ring;			
			if (this.rings[slot])
			{
				r = RingLoadManager.getRing(this.rings[slot].ringId);
				if (r != null){
					r.chargeLevel = this.rings[slot].chargeLevel;				
				}
			}
			return r;
			
		}
		

		private function setIsPointTarget(isPointTarget:int):void {
			this._isPointTarget = isPointTarget;
			GlobalEvent.eventDispatcher.dispatchEvent(new GlobalEvent(GlobalEvent.MOUSE_OVER_STATE_CHANGED, {isPointTarget:isPointTarget}));																																	
		}
		
		public function enableDisableRings():void{
			if (this._actor != null){				
				var ex:Number = this._actor.maxExhaustion - this._actor.exhaustion;				
				for (var i:int = 0 ; i <= UiItemBar.MAX_BAR_SLOT_INDEX ; i++){
					if (this.rings[i])
					{	
						var r:Ring = RingLoadManager.getRing(this.rings[i].ringId);							
						if (r !=  null && ex >= r.exhaustion){							
							RingItemManager.getInstance().enableSlot(i);
						}else{
							RingItemManager.getInstance().disableSlot(i);
						}
					}
				}			
			}		 		
		}
		
		public function unlockSlot(slot:int):Boolean{
			var changed:Boolean = false;
			var rm:RingItemManager = RingItemManager.getInstance();
			if (rm.isSlotLock(slot)){
				RingItemManager.getInstance().unLockSlot(slot);
				changed = true;
			}					
			return changed;
		}
		public function lockSlot(slot:int):Boolean{
			var changed:Boolean = false;
			var rm:RingItemManager = RingItemManager.getInstance();
			if (!rm.isSlotLock(slot)){
				RingItemManager.getInstance().lockSlot(slot);
				changed = true;
			}					
			return changed;			
		}
		
		public function lockSlotCount():int{
			var count:int = 0;
			for (var i:int = 0; i < 8; i++){
				if (RingItemManager.getInstance().isSlotLock(i)){
					count ++;
				}
			}
			return count;
		}
		
		
		public function get maxRingCL():Number{
			return this._maxRingCL
		}
		
		public function updateMaxCL():void{
			var cl:Number = 0;
			for (var i:int = 0; i < 8; i++){
				if (this.rings[i]){
					cl = Math.max(cl, this.rings[i].chargeLevel);
				}
			}
			if (cl != this._maxRingCL){				
				this._maxRingCL = cl;
				GlobalEvent.eventDispatcher.dispatchEvent(new GlobalEvent(GlobalEvent.MAX_RING_CL_CHANGE, this._maxRingCL));
			}			
		}
		
		private function onRingUpdate(evt:BattleEvent):void{
			if (evt == null || evt.battleMessage == null || evt.battleMessage.responseObj == null){
				return ;
			}
			
			//this.debug.traceObject(evt.battleMessage.responseObj);
			
			for each (var r:Object in evt.battleMessage.responseObj){
				
				
				
				if (r != null){
					if (r.orbs != null){
						ActorManager.getInstance().myActor.totalOrbs = Orbs.fromMap(r.orbs);
					}
										
					var ringId:String = null;
					var slot:int = ItemManager(RingItemManager.getInstance()).selectedSlot;														
					var type:String = r.ringMergeType; // [bgh] can be: STEP, LEVEL, SALVAGE
					//trace("[RingManager] onRingUpdate ",r.ringSlot, r.ringLevel);
					switch(type)
					{
						case "SALVAGE":
							if (this.rings[r.ringSlot])
							{
								if (r.success){
									this.rings[r.ringSlot] = null;							
									Globals.uiManager.ringInventory.clearRingInfo();							
									RingItemManager.getInstance().removeItem(r.ringSlot);
									
									// [bgh] FS#21505 after salvage, update ring sets
									if(Globals.uiManager.actionBar && Globals.uiManager.actionBar.hasRingSet())
									{			
										updateBonusSet();
									}	
								}else{
									this.rings[r.ringSlot].isUpdating = false;
									// [bgh] dispatch the ring update event for the server ui listeners
									GlobalEvent.eventDispatcher.dispatchEvent(new GlobalEvent(GlobalEvent.RING_UPDATE, this.rings[r.ringSlot].ringId));
									ringId = this.rings[slot].ringId;
									
									var dw:DialogWindow = new DialogWindow(this._uiFramework, this._linkMaager, Globals.uiManager.mcDragLayer, 200);
									dw.autoSize = true;
					 				dw.keepOnStage = true;
					 				var txt:String = r.errorMessage;
									dw.setHtmlText("<h1><b>Error</b></h1><p>" + txt + "</p>");				
									dw.setPos(Globals.uiManager.mcDragLayer.mouseX - 100, Globals.uiManager.mcDragLayer.mouseY - 20);								
																	
								}																
							}					
							break;
						default:					
							if (this.rings[r.ringSlot])
							{
								//-- check if upgrade a level
								if (r.success && this.rings[r.ringSlot].chargeLevel < r.ringLevel && Math.floor(r.ringLevel) == r.ringLevel){								
									RingItemManager.getInstance().playUpgrade(r.ringSlot);																
								}
								
								if (r.ringLevel != null && !isNaN(r.ringLevel)){
									this.rings[r.ringSlot].chargeLevel = Math.round(r.ringLevel*10)/10;
								}
								this.rings[r.ringSlot].isUpdating = false;
								// [bgh] dispatch the ring update event for the server ui listeners
								GlobalEvent.eventDispatcher.dispatchEvent(new GlobalEvent(GlobalEvent.RING_UPDATE, this.rings[r.ringSlot].ringId));
								
								
								///---- Check if ring soulBound changes
								if (r.soulbound != null && r.soulbound == true){
									var ic:ItemIcon = RingItemManager.getInstance().getItemAt(r.ringSlot);
									if (ic != null && !ic.SoulBound){
										ic.SoulBound = true;
										RingItemManager.getInstance().playSoulBound(r.ringSlot);
									}
								}	
							}
							ringId = this.rings[slot].ringId;						
							break;
					}				
					if (slot == r.ringSlot){
						Globals.uiManager.ringInventory.setRingInfo(ringId, slot, type=="STEP");					
					}
					
					var bm:BattleMessage = new BattleMessage(BattleEvent.INVENTORY_INFO, null);
					this._gateway.sendMsg(bm);
	
					if (type != "SALVAGE" && type != "ORBSWAP") {
						GlobalEvent.eventDispatcher.dispatchEvent(new GlobalEvent(GlobalEvent.RING_UPDATE_DONE, {slot:r.ringSlot, ring:this.rings[r.ringSlot]}));
					}
					
					this.updateMaxCL();
				}
					
			}		
		}
		
		public function isSlotLock(slot:int):Boolean
		{
			return this.rings[slot] && this.rings[slot].isUpdating; 
		}
				
		private var _isCharging:Boolean = false;
		private var _selectedActor:BaseActor;
				
		public function set selectedRingSlot(slot:int):void {
			//--- check for power meter
									
			this._selectedRingSlot = slot;			
					
			//-- check if PointTarget and/or passive ring
			var r:Ring = null;
			if(this.rings[slot]) {
				r = RingLoadManager.getRing(this.rings[slot].ringId);
				this._isPassiveRing = r.type == 0;							
			}else{
				this._isPassiveRing = false;
			}
						
			if (UiItemBar.isBarSlot(slot) && null!=r && r.isPointTarget){
				var enabled:Boolean = RingItemManager.getInstance().isSlotValide(slot);						
				if (enabled && this._isPointTarget != slot && _allowRingUse){
					this.setIsPointTarget(slot);
				}else{
					this.setIsPointTarget(-1);					
				}						
			}else{
				this.setIsPointTarget(-1);					
			}
			
			//trace("[RingManager seletedRingSlot]", this._selectedRingSlot, this._isPointTarget);			
						
		}
		public function get selectedRingSlot():int {
			return _selectedRingSlot;
		}
		
		private function onActorSelected(evt:GlobalEvent):void{
			//trace("[Ringmanager onActorSelected] ", evt.data.actor);		
			this._selectedActor = evt.data.actor as BaseActor;
			
			if (this._ringAutoFireDown && this._actorMouseDown && !this._isCharging && this._selectedActor == evt.data.actor){				
				if (this._allowRingUse){
					autoSelectRing();					
					var v:String = this.validateAttack(true);
					validationRules(v, false);
				}			
			}
			
		}

		private var _actorMouseDown:Boolean = false;
		private function onActorMouseDown(evt:GlobalEvent):void{
			//trace("[Ringmanager onActorMouseDown]", evt.data.actor);
			this._actorMouseDown = true;
			if (!this._isCharging && this._selectedActor == evt.data.actor){				
				if (this._allowRingUse){								
					autoSelectRing();					
					//var v:String = this.validateAttack(true);
					//validationRules(v, false);
					if (!this._isPassiveRing){
						Globals.uiManager.startCharging();
						this._isCharging = true;
					}
				}
			}
		}		
		private function onActorMouseUp(evt:GlobalEvent):void{
			this._actorMouseDown = false;
			if (this._isCharging && this._selectedActor != null){			
				//trace("[RingManager onActorMouseUp]");
				var v:String = this.validateAttack(true);	
				validationRules(v, true);
			}			
		}
		
		private function onRingStartCharge(evt:ItemManagerEvent):void{
			//trace("[RingManager onRingStartCharge]");
			onRingKeyDown(null);
		}
		private function onRingStopCharge(evt:ItemManagerEvent):void{
			//trace("[RingManager onRingStopCharge]");
			onRingKeyUp(null);
		}
		private function onRingCancelCharge(evt:ItemManagerEvent):void{
			//trace("[RingManager onRingCancelCharge]" , evt.itemIcon);
			Globals.uiManager.stopCharging();
			this._isCharging = false;			
		}
		
		private function onRingKeyDown(evt:GlobalEvent):void{
			var r:Ring = this.getRingAt(this._selectedRingSlot);
			if (this._allowRingUse && !this._isCharging && !this._isPassiveRing){
				//trace("[RingManager onRingKeyDown]");				
				Globals.uiManager.startCharging();
				this._isCharging = true;		
			}	
		}
		private function onRingKeyUp(evt:GlobalEvent):void{
			if (this._allowRingUse && this._isCharging){
				//trace("[RingManager onRingKeyUp]" );
				var v:String = this.validateAttack(false);
				validationRules(v, true);
			}			
		}
		
		private var _ringAutoFireDown:Boolean = false;
		private function onRingAutoFireDown(evt:GlobalEvent):void{
			this._ringAutoFireDown = true;
		}
		private function onRingAutoFireUp(evt:GlobalEvent):void{
			this._ringAutoFireDown = false;			
		}
		
		private function autoSelectRing():void{
			if (!this._ringAutoSelect){
				return;
			}
			
			
			var r:Ring = this.getRingAt(this._selectedRingSlot);
			
			if (this._selectedActor == null && !r.usesTargets()){				
				return;
			}else{
				var isMe:Boolean = ActorManager.getInstance().myActor == this._selectedActor;
				if( r != null && this._selectedActor != null && this.validateTargetType(r.targetType, this._selectedActor.targetType, isMe) ){					
					return;
				}else{
					for (var i:int = 0; i < 8; i++){
					 	var nr:Ring = this.getRingAt(i);
					 	if( nr != null && this._selectedActor != null && this.validateTargetType(nr.targetType, this._selectedActor.targetType, isMe) ){					 		
					 		RingItemManager.getInstance().selectedSlot = i;
					 		this.selectedRingSlot = i;
					 		return;
					 	}
					}
				}
			}
			
			
		}
		
		private function validationRules(type:String, cast:Boolean = true):void{
			if (type == "passiveRing"){
				return;
			}else if (type == "invalidSlot"){
				//trace(" - dry fire");
				Globals.uiManager.stopCharging();
				this._isCharging = false;
				GlobalEvent.eventDispatcher.dispatchEvent(new GlobalEvent(GlobalEvent.ALERT, {type:AlertTypes.GENERIC_FAIL}));		
			}else if (type == "invalidTarget"){
				//trace(" - invalideTarget")				
				Globals.uiManager.stopCharging();
				this._isCharging = false;
				if (this._selectedActor != null){
					this._selectedActor.playInvalidTarget();
				}
			}else if (type == "outOfRange"){
				//trace(" - outOfRange");
				var ragLv:int = Globals.uiManager.stopCharging();
				this._isCharging = false;				
				if (this._autoMoveInRange){
					this.cast(ragLv, false);
				}else if (this._selectedActor != null){
					this._selectedActor.playOutOfRange();					
				}
				
			}else if (type == "valid"){				
				if (cast){				
					var ragLv2:int = Globals.uiManager.stopCharging();
					this._isCharging = false;	
					this.cast(ragLv2);					
				}else if (!this._isPassiveRing){					
					Globals.uiManager.startCharging();
					this._isCharging = true;				
				}
			}	
		}	
		
		private function validateAttack(isMouse:Boolean = false):String{
			var isSlotValid:Boolean = RingItemManager.getInstance().isSlotValide(this._selectedRingSlot);
			var r:Ring = this.getRingAt(this._selectedRingSlot);
			if (r != null && r.targetType == -1){
				return "passiveRing";
			}			
			if (!isSlotValid || r == null){
				return "invalidSlot";
			}
									
			var isMe:Boolean = false;
			if (this._selectedActor != null &&  ActorManager.getInstance().myActor != null){
				isMe = (this._selectedActor.actorId == ActorManager.getInstance().myActor.actorId);
			}
			
			
			var valideTarget:Boolean = false;
			if (r.usesTargets() || isMouse){				
				valideTarget = (this._selectedActor != null && validateTargetType(r.targetType, this._selectedActor.targetType, isMe));
			}else{
				valideTarget = true;
			}			
			if (!valideTarget){
				return "invalidTarget";
			}
			/*
			if ( (this._selectedActor == null && r.usesTargets()) || 
				 (this._selectedActor != null && !validateTargetType(r.targetType, this._selectedActor.targetType, isMe)) ){
				return "invalidTarget";
			}
			*/
			
			if (r.usesTargets() && this._selectedActor != null && !ActorManager.getInstance().myActor.checkRange(this._selectedActor, r.range) ){
				return "outOfRange";
			}
						
			return "valid";
		}

		private function validateTargetType(ringTargetType:int, actorTargetType:int, actorIsMe:Boolean = false):Boolean{
			if (ringTargetType != BaseActor.TARGETTYPE_NONE && actorTargetType != BaseActor.TARGETTYPE_NONE){
				if (ringTargetType == BaseActor.TARGETTYPE_SELF){
					return actorIsMe;
				}else if(ringTargetType == BaseActor.TARGETTYPE_FRIEND){
					return (actorTargetType == BaseActor.TARGETTYPE_SELF && !actorIsMe);
				}else if(ringTargetType == BaseActor.TARGETTYPE_FRIENDSELF){
					return (actorTargetType == BaseActor.TARGETTYPE_SELF);
				}else if(ringTargetType == BaseActor.TARGETTYPE_ENEMY){
					return (actorTargetType == BaseActor.TARGETTYPE_FRIEND);
				}
			}
			return false;
		}
		
		private function cast(ragLv:int, playAnim:Boolean = true):void{			
			var actorManager:ActorManager = ActorManager.getInstance();
			actorManager.resetNextTargetTime();
			var r:Ring = this.getRingAt(this._selectedRingSlot);			
			var myActor:BaseActor = actorManager.myActor;
			myActor.stopMove();
			
			
			var msgObj:Object = {ringSlot:this._selectedRingSlot, ringRageLevel:ragLv};
			if (r.usesTargets() && this._selectedActor != null){
				msgObj.targetID = this._selectedActor.actorId;
				if (this._selectedActor != myActor){
					myActor.setDirection(this._selectedActor.position);
				}	
			}
			
			if (playAnim){
				RingItemManager.getInstance().startTimer(this._selectedRingSlot, r.rage[ragLv].recharge/1000);
				var ra:RingAnim = myActor.playRingAnimation(r.ringId, ragLv, "caster", this._selectedActor);			
			}		
			var msg:BattleMessage = new BattleMessage("act",msgObj);
			msg.addEventListener(BattleEvent.CALL_BACK, onActCallBack);						
			this._gateway.sendMsg(msg);	
			
		}
		
		private function onActCallBack(evt:BattleEvent):void{
			//trace("[RingManager onActCallBack] ============");
			BattleMessage(evt.target).removeEventListener(BattleEvent.CALL_BACK, onActCallBack);	
			var rObj:Object = evt.battleMessage.responseObj;
					
			
			
			if (rObj != null && rObj.er != null && rObj.er == 1 && rObj.ercode != null){
				switch(parseInt(rObj.ercode)){
					case 301:
						//log("  Ivalide Actor...  Delete this actor", rObj.tid);
						ActorManager.getInstance().removeActor(rObj.tid);
						break;
					case 201:
						//log("  Out Of Range  ", rObj.tid)
						if (ActorManager.actorIdToActor(rObj.tid) != null){
							ActorManager.actorIdToActor(rObj.tid).playOutOfRange();							
							ActorManager.getInstance().requestRoomActorInfo();
						}
				}				
			}
			 
			for each (var response:Object in rObj) {
				
				if (response.hasOwnProperty("error") && response.error != null) {
					var error:uint = response.error;
				}
					
				if (error){
					var requestObj:Object = evt.battleMessage.requestObjUnsafeForModifying; 
					if (requestObj.targetID){
						var actor:BaseActor = ActorManager.actorIdToActor(requestObj.targetID);
						if (actor) {
							switch(error){
								case 201: //Out Of Range
									actor.playOutOfRange();
									break;
								default:
									actor.playInvalidTarget();
									break;
							}
							
						}					
					}
			    }else if (response.success != null && response.success == true && response.rid != null && response.rageRank != null){
			    	for (var i:int = 0; i< 8; i++){
			    		if (this.rings[i] != null && this.rings[i].ringId == response.rid){			    			
			    			var r:Ring = getRingAt(i);
			    			RingItemManager.getInstance().startTimer(i, r.rage[response.rageRank].recharge/1000);			    			
			    			break;
			    		}
			    	}
			    }
			}
			
			
			
			// ******** Server ErrorCodes
			/*
			public static final int ERROR_GENERAL = 200;
			public static final int ERROR_OORANGE = 201;
			public static final int ERROR_NORING = 202;
			public static final int ERROR_YOUKTFO = 203;
			public static final int ERROR_TARGKTFO = 204;
			public static final int ERROR_BADSLOT = 205;
			public static final int ERROR_NEEDRAGE = 206;
			public static final int ERROR_BADRING = 207;
			public static final int ERROR_TARGGONE = 208;
			public static final int ERROR_NOCHARGE = 209;
			public static final int ERROR_BADTARG = 210;
			public static final int ERROR_EXHAUSTION = 211;
			public static final int ERROR_DISABLEDSLOT = 211;
			public static final int ERROR_DUPICATEENABLED = 212;
			public static final int ERROR_MAXCL = 213;
			public static final int ERROR_NOTOWNED = 214;
			*/
			
		}	
	}
}