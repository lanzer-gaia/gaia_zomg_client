package com.gaiaonline.battle.ItemLoadManager
{
	import com.gaiaonline.battle.ApplicationInterfaces.ILinkManager;
	import com.gaiaonline.battle.ApplicationInterfaces.IUIFramework;
	import com.gaiaonline.battle.ItemManager.ItemManager;
	import com.gaiaonline.battle.ItemManager.ItemManagerEvent;
	import com.gaiaonline.battle.gateway.BattleEvent;
	import com.gaiaonline.battle.gateway.BattleGateway;
	import com.gaiaonline.battle.gateway.BattleMessage;
	import com.gaiaonline.battle.newactors.ActorManager;
	import com.gaiaonline.battle.ui.AlertTypes;
	import com.gaiaonline.flexModulesAPIs.globalevent.GlobalEvent;
	
	import flash.events.EventDispatcher;
	
	public class ConsumableManager extends EventDispatcher
	{
		private var _loaders:Object = new Object();
		private var _itemManager:ItemManager; 
		
		private var _itemCount:int = -1;
		private var _firstUpdate:Boolean = true;
		
		private var _gateway:BattleGateway = null;
		private var _uiFramework:IUIFramework = null;
		private var _linkManager:ILinkManager = null;
		
		private var _allowConsumableUse:Boolean = true;
		
		public function ConsumableManager(itemManager:ItemManager, linkManager:ILinkManager, gateway:BattleGateway, uiFramework:IUIFramework)
		{
			this._gateway = gateway;
			this._uiFramework = uiFramework;
			this._linkManager = linkManager;
						
			this._itemManager = itemManager;			
			this._itemManager.addEventListener(ItemManagerEvent.ITEM_MOVE, onItemMove, false, 0, true);
			this._itemManager.addEventListener(ItemManagerEvent.STOP_CHARGE, onStopCharge, false, 0, true);
			this._itemManager.addEventListener(ItemManagerEvent.SELECTION_CHANGE, onSelectionChange, false, 0, true);
			
			this._gateway.addEventListener(BattleEvent.CONSUMABLE_INVENTORY, onConsumableInv, false, 0, true);
			this._gateway.addEventListener(BattleEvent.CONSUMABLE_INFO, onConsumableInfo, false, 0, true);
			
			GlobalEvent.eventDispatcher.addEventListener(GlobalEvent.ALLOW_CONSUMABLE_USE, onAllowConsumableUse, false, 0, true);
			GlobalEvent.eventDispatcher.addEventListener(GlobalEvent.PLAYER_LOCKED_SLOTS_CHANGED, onPlayerLockSlotsChanged, false, 0, true);
			GlobalEvent.eventDispatcher.addEventListener(GlobalEvent.PLAYER_STATUS_CHANGED, onPlayerStatusChanged);
		}
		
		
		public function update():void{
			if (this._uiFramework.loadUserItems) {				
				var msg:BattleMessage = new BattleMessage("getConsumableInventory", null);					
				this._gateway.sendMsg(msg);				
			}
		}
		private function onConsumableInv(evt:BattleEvent):void{
			if (this._uiFramework.loadUserItems) {
				var list:Array = evt.battleMessage.responseObj[0].consumableData;
				for (var i:int = 0; i< list.length; i++){
					var obj:Object = list[i];
					var cl:ConsumableLoader; 
					if (this._loaders[obj.id] == null){
						cl = new ConsumableLoader(obj.id, this._gateway, this._uiFramework.loaderContextFactory);					
						this._loaders[obj.id] = cl;			
						cl.load();	
					}else{
						cl = this._loaders[obj.id];
					}

					if (this._itemManager.hasItem(obj.slot))
					{
						this._itemManager.updateItem(obj.slot, obj.id, obj.count, obj.soulbound ? obj.soulbound : false, cl); 
					}
					else
					{
						var ic:ItemIcon = new ItemIcon(this._uiFramework, ConsumableItemIconCustomization.getInstance(), obj.id, obj.slot, cl);
						ic.quantity = obj.count;						
						if (obj.soulbound != null){
							ic.SoulBound = obj.soulbound;
						}
						this._itemManager.addItem(ic);
					}
				}
				
				//---- Remove item that are not in the list anymore
				var itemHash:Object = {}
				for each (var item:Object in list)
				{
					itemHash[item.slot] = true;
				}
				for each(var iic:ItemIcon in this._itemManager.itemIconList)
				{
					if (!itemHash[iic.slot])
					{
						this._itemManager.removeItem(iic.slot);
					}
				}	
				
							
				//---- If we've gained a consumable, pop open the consumables action bar
				if (!this._firstUpdate && list.length > this._itemCount){
					GlobalEvent.eventDispatcher.dispatchEvent(new GlobalEvent(GlobalEvent.NEW_CONSUMABLE, {}));
				}
				
				this._firstUpdate = false;			
				this._itemCount = list.length;
			}
		}
		
		private function onConsumableInfo(evt:BattleEvent):void{
			var obj:Object = evt.battleMessage.responseObj[0];	

			var imagesUrl:String = this._linkManager.getLink("images");
			if (this._loaders[obj.id] != null){
				ConsumableLoader(this._loaders[obj.id]).setInfo(obj, imagesUrl);
			}else{
				this._loaders[obj.id] = new ConsumableLoader(obj.id, this._gateway, this._uiFramework.loaderContextFactory);
				ConsumableLoader(this._loaders[obj.id]).setInfo(obj, imagesUrl);
			}		
			for each(var ic:ItemIcon in this._itemManager.itemIconList){
				if (ic.itemId == obj.id){
					var cl:ConsumableLoader = this._loaders[obj.id] as ConsumableLoader;
					if (cl != null && cl.timeUsedAtLoadTime > 0){
						var timeUsedAtLoadTime:Number = cl.timeUsedAtLoadTime;
						var rechargeTime:Number = cl.timeTotalAtLoadTime;
						
						ic.startTimer(rechargeTime/1000, timeUsedAtLoadTime/1000);
						
						GlobalEvent.eventDispatcher.dispatchEvent(new GlobalEvent(GlobalEvent.CONSUMABLE_USED, {id:obj.id, time:rechargeTime-timeUsedAtLoadTime}));
					}	
					
					var uwd:Boolean = cl.itemUsableWhenDazed && ActorManager.getInstance().myActor.lockSlotCount() <= 0;
					var cure:Boolean = cl.itemCanCure && ActorManager.getInstance().myActor.curableStatusCount <= 0;					
					ic.disable = uwd || cure;		
					ic.displayNum = obj.showChargeCount;
				}
			}
		}
		
		private var _currItemLoader:IItemLoader = null;
		private function onSelectionChange(evt:ItemManagerEvent):void{
			var params:Object = evt.params;
			if (params.selectionChanged) {
				if (this._currItemLoader && this._currItemLoader.hasEventListener(ItemLoadEvent.ITEM_LOADED)) { // reset which one we're listening for
					this._currItemLoader.removeEventListener(ItemLoadEvent.ITEM_LOADED, onItemLoaded);
				}
				var obj:Object = null;
				if (evt.itemIcon != null && evt.itemIcon.itemLoader != null) {					
					this._currItemLoader = evt.itemIcon.itemLoader;
					obj = new Object();				
					obj.name = this._currItemLoader.itemName;
					obj.desc = this._currItemLoader.itemDescription;
					obj.ico = this._currItemLoader.getNewItemDisplay();
					if (!obj.ico) {						
						this._currItemLoader.addEventListener(ItemLoadEvent.ITEM_LOADED, onItemLoaded, false, 0, true);
					}
				}
				GlobalEvent.eventDispatcher.dispatchEvent(new GlobalEvent(GlobalEvent.CONSUMABLE_SELECTION_CHANGE, obj));
				}
			}
		
		private function onItemLoaded(e:ItemLoadEvent):void {
			var obj:Object = new Object();				
			obj.name = this._currItemLoader.itemName;
			obj.desc = this._currItemLoader.itemDescription;
			obj.ico = this._currItemLoader.getNewItemDisplay();

			this._currItemLoader.removeEventListener(ItemLoadEvent.ITEM_LOADED, onItemLoaded);
			GlobalEvent.eventDispatcher.dispatchEvent(new GlobalEvent(GlobalEvent.CONSUMABLE_SELECTION_CHANGE, obj));			
		}
				
		//--- MoveItem
		private function onItemMove(evt:ItemManagerEvent):void{
			var msg:BattleMessage = new BattleMessage("moveConsumable", {slot1:evt.params.startSlot, slot2:evt.params.endSlot});
			msg.addEventListener(BattleEvent.CALL_BACK, onMoveCallBack);
			this._gateway.sendMsg(msg);
		}
		private function onMoveCallBack(evt:BattleEvent):void{
			//this.debug.log("OnMoveCallBack")
			//this.debug.traceObject(evt.battleMessage.responseObj);
			if (evt.battleMessage.responseObj[0].success != true){				
				this._itemManager.clearAll();
				this.update();
			}
			
			BattleMessage(evt.target).removeEventListener(BattleEvent.CALL_BACK, onMoveCallBack);
		}
		
		//-- UseItem
		private function onStopCharge(evt:ItemManagerEvent):void{
			this.useItem(evt.itemIcon.slot);
		}
		
		
		private function onAllowConsumableUse(event:GlobalEvent):void{
			_allowConsumableUse = event.data;
		}
		private function onPlayerLockSlotsChanged(event:GlobalEvent):void{
			updateItemsDisable();
		}
		
		private function onPlayerStatusChanged(evt:GlobalEvent):void{			
			updateItemsDisable();	
		}
		
		private function updateItemsDisable():void{
			for each(var ic:ItemIcon in this._itemManager.itemIconList){
				var cl:ConsumableLoader = this._loaders[ic.itemId] as ConsumableLoader;	
				if (cl.itemUsableWhenDazed || cl.itemCanCure){			
					var uwd:Boolean = cl.itemUsableWhenDazed && ActorManager.getInstance().myActor.lockSlotCount() <= 0;
					var cure:Boolean = cl.itemCanCure && ActorManager.getInstance().myActor.curableStatusCount <= 0;					
					ic.disable = uwd || cure;	
				}	
			}
		}
		
		
		private function useItem(slot:int):void{
			
			var cl:ConsumableLoader = this._loaders[this._itemManager.getItemAt(slot).itemId] as ConsumableLoader;			
			if (!(_allowConsumableUse || cl.itemCanCure)){
				return; 
			}
			
			if (cl != null){
				//this._itemManager.startTimer(slot, cl.rechargeTime/1000)				
				for each (var ic:ItemIcon in this._itemManager.itemIconList){
					if (this._uiFramework.getBaseItemId(ic.itemId) ==  this._uiFramework.getBaseItemId(cl.itemId)){
						trace("[ConsumableManger useItem]",ic.itemId, cl.itemId, " -- " , this._uiFramework.getBaseItemId(ic.itemId) , this._uiFramework.getBaseItemId(cl.itemId));
						ic.startTimer(cl.rechargeTime/1000);
					}
				}			
												
				var msg:BattleMessage = new BattleMessage("useConsumable", {slot:slot});
				var me:ConsumableManager = this;
				msg.addEventListener(BattleEvent.CALL_BACK, function(bm:BattleEvent):void {
					// [bgh] check to see if the server let us use it
					if(bm.gwMessage.responseObj[0].success == false) {
						for each (var ic:ItemIcon in _itemManager.itemIconList){
							if (me._uiFramework.getBaseItemId(ic.itemId) == me._uiFramework.getBaseItemId(cl.itemId)){
								ic.resetTimer();
								GlobalEvent.eventDispatcher.dispatchEvent(new GlobalEvent(GlobalEvent.ALERT, {type:AlertTypes.GENERIC_FAIL}));															
							}
						}
					}
					else
					{
						// [bgh] we were able to use the item, play the sound
						GlobalEvent.eventDispatcher.dispatchEvent(new GlobalEvent(GlobalEvent.ALERT, {type:AlertTypes.ITEM_SPECIFIC, extraId:me._uiFramework.getBaseItemId(cl.itemId)}));
						GlobalEvent.eventDispatcher.dispatchEvent(new GlobalEvent(GlobalEvent.CONSUMABLE_USED, {id:cl.itemId, time:cl.rechargeTime}));
					}
					
					BattleMessage(bm.target).removeEventListener(BattleEvent.CALL_BACK, arguments.callee);
				});
				
				this._gateway.sendMsg(msg);
			}
		}
	}
}
