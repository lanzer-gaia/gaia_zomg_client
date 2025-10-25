package com.gaiaonline.battle.newghibuffs
{
	import com.gaiaonline.battle.ApplicationInterfaces.ILinkManager;
	import com.gaiaonline.battle.ApplicationInterfaces.IUIFramework;
	import com.gaiaonline.battle.gateway.BattleEvent;
	import com.gaiaonline.battle.gateway.BattleGateway;
	import com.gaiaonline.battle.gateway.BattleMessage;
	import com.gaiaonline.flexModulesAPIs.globalevent.GlobalEvent;
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	
	public class GhiBuffsUpdater extends EventDispatcher
	{
		private var _gateway:BattleGateway = null;
		private var _uiFramework:IUIFramework = null;
		private var _linkMaager:ILinkManager = null;
		
		private var tempGhiBuffsArray:Array = new Array();
		private var ghiBuffsLoadCount:Number = 0;
		private var ghiBuffsInited:Boolean = false;
		
		public function GhiBuffsUpdater(gateway:BattleGateway, uiFramework:IUIFramework, linkManager:ILinkManager)
		{
			_gateway = gateway;
			_uiFramework = uiFramework;
			_linkMaager = linkManager;
		}


				//*********************
		//* Ghi Buffs Update
		// THIS IS IDENTICAL IN STRUCTURE TO THE GHI BUFFS UPDATE, WHICH IS VERY SIMILAR TO HE RING UPDATE; THIS SHOULD REALLY BE
		// REFACTORED INTO COMMON LOGIC, BUT NO TIME RIGHT NOW AS WE GET READY FOR BETA LAUNCH -- Mark Rubin
		//*********************
		public function updateGhiBuffs():void {
			if (this._uiFramework.loadUserItems) {
				var msg:BattleMessage = new BattleMessage("getGhiInfo", null);
				msg.addEventListener(BattleEvent.CALL_BACK, onGhiBuffsCallback);
				this._gateway.sendMsg(msg);
			} else {
				doneLoadingGhiBuffs();
			}
		}
		
		private function onGhiBuffsCallback(evt:BattleEvent):void {
			BattleMessage(evt.target).removeEventListener(BattleEvent.CALL_BACK, onGhiBuffsCallback);

			// Our logic was originally written with the idea that we remember which buffs we've seen previously in our
			// login session, and they accrue over time.  However, currently, we actualy replace buffs with newer ones as time goes
			// on.  But, we'd like to go back to the accrual model.  So for now, I'm just adding in this
			// call to blow away our cache of what buffs we've already seen when we get this update call; when we want to
			// go back to the accrual model, we just have to remove this line to blow away the cache.
			GhiBuffsLoadManager.clearCache();
						
			if (evt.battleMessage.responseObj) {
				this.tempGhiBuffsArray = evt.battleMessage.responseObj as Array;
			} else {
				this.tempGhiBuffsArray.length = 0;
			}	
			this.ghiBuffsLoadCount = 0;
			this.loadPlayerGhiBuffs();
		}
			
		public function loadPlayerGhiBuffs():void {
			if (this.ghiBuffsLoadCount < this.tempGhiBuffsArray.length) {
				var obj:Object = this.tempGhiBuffsArray[this.ghiBuffsLoadCount];
				if (obj != null) {	
					if (GhiBuffsLoadManager.contain(obj.rid)) {
						this.ghiBuffsLoadCount += 1;
						this.loadPlayerGhiBuffs();	
					} else {	
						var ghiBuff:GhiBuff = GhiBuffsLoadManager.loadBuff(obj);
						ghiBuff.addEventListener(GhiBuff.LOADED, onGhiBuffLoaded);
						this.ghiBuffsLoadCount += 1;					
					}
				} else {
					this.ghiBuffsLoadCount += 1;
					this.loadPlayerGhiBuffs();	
				}												
			} else {
				this.tempGhiBuffsArray.length = 0;
				this.ghiBuffsLoadCount = 0;
				this.ghiBuffsInited = true;
				this.doneLoadingGhiBuffs();
			}
		}
		
		private function onGhiBuffLoaded(e:Event):void {
			GhiBuff(e.target).removeEventListener(GhiBuff.LOADED, onGhiBuffLoaded);
			this.loadPlayerGhiBuffs();
		}
		
		private function doneLoadingGhiBuffs():void {
			GlobalEvent.eventDispatcher.dispatchEvent(new GlobalEvent(GlobalEvent.GHI_BUFFS_LOADED, {}));		
		}
	}
}