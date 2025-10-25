package com.gaiaonline.battle.ui
{
	import com.gaiaonline.battle.ApplicationInterfaces.ILinkManager;
	import com.gaiaonline.battle.ApplicationInterfaces.IUIFramework;
	import com.gaiaonline.battle.GlobalColors;
	import com.gaiaonline.battle.GlobalTexts;
	import com.gaiaonline.battle.Globals;
	import com.gaiaonline.battle.Loot.Orbs;
	import com.gaiaonline.battle.newactors.ActorManager;
	import com.gaiaonline.battle.newactors.BaseActor;
	import com.gaiaonline.battle.newactors.BaseActorEvent;
	import com.gaiaonline.battle.ui.events.UiEvents;
	import com.gaiaonline.flexModulesAPIs.globalevent.GlobalEvent;
	import com.gaiaonline.utils.DisplayObjectUtils;
	
	import flash.display.MovieClip;
	import flash.display.SimpleButton;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.text.TextField;

	public class UiRingUpgrade extends MovieClip
	{
		public var txtCost:TextField;
		public var txtGainCharge:TextField;
		public var txtGainShadow:TextField;
		public var txtOverallCl:TextField;
		
		public var shadowUpgrade:MovieClip;
		public var chargeUpgrade:MovieClip;
				
		public var btnUpgrade:SimpleButton;
		public var btnSalvage:SimpleButton;
		public var btnSwapOrbs:SimpleButton;
		public var icoCL:MovieClip;
		
		
		private var cl:Number = 10;
		private var preRingUpgradeUserConLevel:Number = NaN;
		
		private var totalOrbs:Orbs = new Orbs(0,0);
		private var _selectedSlot:int = -1;
		private var _cost:Orbs = new Orbs(0,0);
		private var _gain:Orbs = new Orbs(0,0);
		private var _ringName:String;	
		
		private var dwUpgrade:DialogWindow;
		private var dwSalvage:DialogWindow;
		
		private var _ringMaxLevel:Number = NaN;
		
		private var _uiFramework:IUIFramework = null;
		private var _linkManager:ILinkManager = null;		
		private var _uiSwapOrbOpen:Boolean = false;	
		
		public function UiRingUpgrade(){
		}
		
		public function init(uiFramework:IUIFramework, linkManager:ILinkManager):void {
			this._uiFramework = uiFramework;
			this._linkManager = linkManager;
			this.setRingInfo(-1, new Orbs(0,0), new Orbs(0,0), 0, "");
			this.icoCL.gotoAndStop("normal");
			
			//DisplayObjectUtils.addWeakListener(GlobalEvent.eventDispatcher, GlobalEvent.CL_CAP_CHANGE, onCLCapChange);
			DisplayObjectUtils.addWeakListener(GlobalEvent.eventDispatcher, GlobalEvent.RING_MAX_LEVEL_UPDATE, onRingMaxLevelUpdate);											
			DisplayObjectUtils.addWeakListener(GlobalEvent.eventDispatcher, GlobalEvent.MAP_DONE, onMapDone);
			DisplayObjectUtils.addWeakListener(GlobalEvent.eventDispatcher, GlobalEvent.PLAYER_CREATED, onPlayerCreated);																							
			
			this.setButtonEnabled(this.btnSwapOrbs, true);
						
			this._uiFramework.tooltipManager.addToolTip(this.btnSalvage, "Salvage a ring");
			this._uiFramework.tooltipManager.addToolTip(this.btnUpgrade, "Upgrade a ring")
			this._uiFramework.tooltipManager.addToolTip(this.btnSwapOrbs, "Swap CL between two rings \nonce every 24 hours")
						
		}

		private function onPlayerCreated(e:GlobalEvent):void {
			var me:BaseActor = e.data.actor as BaseActor;

			this.setTotal(me.totalOrbs);						
			me.addEventListener(BaseActorEvent.TOTAL_ORBS_UPDATED, this.onActorTotalOrbsUpdated, false, 0, true);									
		}
		
		private function onActorTotalOrbsUpdated(e:BaseActorEvent):void {
			var me:BaseActor = e.target as BaseActor;
			this.setTotal(me.totalOrbs);						
		}

		private function onActorConLevelUpdated(e:BaseActorEvent):void {
			setOveralCl(e.actor.conLevel);
		}

		private function onRingMaxLevelUpdate(e:GlobalEvent):void {
			this._ringMaxLevel = e.data.maxLevel;
		}
		
		public function setRingInfo(slot:int, cost:Orbs, gain:Orbs, cl:Number, ringName:String, upgraded:Boolean = false):void{
			// see if we should broadcast an upgrade to other users
			var upgradedToNextFullLevel:Boolean = upgraded && (Math.floor(this.cl) < Math.floor(cl));
			var announceUpgrade:Boolean = upgradedToNextFullLevel && cl > this.preRingUpgradeUserConLevel;
							
			this.cl = cl;
			
			setGainText(gain);
			setCostText(cost);
			
			this._selectedSlot = slot;
			this._cost = cost;
			this._gain = gain;
			this._ringName = ringName;
			
			if (ActorManager.getInstance().myActor && !ActorManager.getInstance().myActor.isSlotLock(slot)){
				var btnUpgradeEnabled:Boolean = (this.totalOrbs.gte(cost)) && (_cost.darkOrbs > 0 || _cost.chargeOrbs > 0) && (cl < Globals.MAX_LEVEL) && !this._uiSwapOrbOpen;					
				setButtonEnabled(this.btnUpgrade, btnUpgradeEnabled);
				if(this._selectedSlot < 0 || this._cost.lte(Orbs.ZERO)){
					this.txtCost.text = "N/A";
				}
			
				var btnSalvageEnabled:Boolean = (_gain.darkOrbs > 0 || _gain.chargeOrbs > 0) && !this._uiSwapOrbOpen;		
				setButtonEnabled(this.btnSalvage, btnSalvageEnabled);
				setButtonEnabled(this.btnSwapOrbs, true);
			}else{
				disableButtons();
			}
			
			if (announceUpgrade) {
				var msg:String = GlobalTexts.getRingUpgradeBroadcastMessage(this._ringName, cl);
				GlobalEvent.eventDispatcher.dispatchEvent(new GlobalEvent(GlobalEvent.CHAT_SEND, {channel:"team", msg:msg} ));				
			}	
		}		
		
		public function refresh():void{
			this.setRingInfo(this._selectedSlot, this._cost, this._gain, this.cl, this._ringName);
		}
		
		private function setTotal(total:Orbs):void{
			this.totalOrbs = total;
			
			if (!ActorManager.getInstance().myActor.isSlotLock(this._selectedSlot)){
				var btnUpgradeEnabled:Boolean = (this.totalOrbs.gte(_cost)) && (_cost.darkOrbs > 0 || _cost.chargeOrbs > 0)&&(cl < Globals.MAX_LEVEL) && !this._uiSwapOrbOpen;	
				setButtonEnabled(this.btnUpgrade, btnUpgradeEnabled);
				if(this._selectedSlot < 0 || this._cost.lte(Orbs.ZERO)){
					this.txtCost.text = "N/A";
				}
			
				var btnSalvageEnabled:Boolean = (_gain.darkOrbs > 0 || _gain.chargeOrbs > 0) && !this._uiSwapOrbOpen;
				setButtonEnabled(this.btnSalvage, btnSalvageEnabled);
			}else{
				disableButtons();
			}
		}
		
		private function setGainText(gain:Orbs):void
		{
			this.txtGainShadow.text = gain.darkOrbs.toString();
			this.txtGainCharge.text = gain.chargeOrbs.toString();
		}
		
		private function setCostText(orbs:Orbs):void
		{
			var useShadowOrbs:Boolean = 0 < orbs.darkOrbs; 
			this.txtCost.text = (useShadowOrbs ? orbs.darkOrbs : orbs.chargeOrbs).toString();
			this.shadowUpgrade.visible = useShadowOrbs;
			this.chargeUpgrade.visible = !useShadowOrbs;
		}
		
		public function setOveralCl(overallCl:Number):void {
			ActorManager.getInstance().myActor.addEventListener(BaseActorEvent.ACTOR_CON_LEVEL_UPDATED, onActorConLevelUpdated, false, 0, true);						
			this.txtOverallCl.text = UiManager.formatConLevel(overallCl);
		}
		
		private function setButtonEnabled(btn:SimpleButton, enabled:Boolean):void {
			btn.alpha = enabled ? 1.0 : .3;
			btn.enabled = enabled;
			var eventListenerFunction:Function = enabled ? btn.addEventListener : btn.removeEventListener;
			if (btn == this.btnUpgrade){
				this.upgradeEnabledBeforeSalvage = enabled;
				eventListenerFunction(MouseEvent.CLICK, onUpgradeClick);
			}else if (btn == this.btnSalvage){
				eventListenerFunction(MouseEvent.CLICK, onSalvageClick);
			}else if (btn == this.btnSwapOrbs){
				eventListenerFunction(MouseEvent.CLICK, onSwapOrbsClick);
			}
		}
		
		public function disableButtons():void{
			setButtonEnabled(this.btnUpgrade, false);			
			setButtonEnabled(this.btnSalvage, false);
			setButtonEnabled(this.btnSwapOrbs, false);
		}
		
		private function onSwapOrbsClick(evt:MouseEvent):void{
			this.dispatchEvent(new UiEvents(UiEvents.OPEN_UI_SWAP_ORBS, null));	
			this.uiSwapOrbsOpen = true;		
		}
		public function get uiSwapOrbsOpen():Boolean{
			return this._uiSwapOrbOpen;
		}
		public function set uiSwapOrbsOpen(v:Boolean):void{
			this._uiSwapOrbOpen = v;
			if (this._uiSwapOrbOpen){			
				this.setButtonEnabled(this.btnSalvage, false);
				this.setButtonEnabled(this.btnUpgrade, false);
			}
		}
		
		private function onUpgradeClick(evt:MouseEvent):void{
			var ringMaxLevel:Number = isNaN(this._ringMaxLevel) ? ActorManager.getInstance().myActor.ringMaxLevel : this._ringMaxLevel;  
			if (this.cl < ringMaxLevel){
				if (this.btnUpgrade.enabled){
					//trace("UPGRADE");
					this.preRingUpgradeUserConLevel = ActorManager.getInstance().myActor.conLevel;
					this.dispatchEvent(new UiEvents(UiEvents.RING_UPGRADE,null));
				}
			}else{
				this.dwUpgrade= DialogWindowFactory.getInstance().getNewDialogWindow(this._uiFramework, this._linkManager, DialogWindowTypes.NORMAL, 200);									
				this.dwUpgrade.autoSize = true;
				this.dwUpgrade.setPosAtMouse();
				this.dwUpgrade.setHtmlText(GlobalTexts.ringAtMaxLevel);
			}
		}
		
		private var upgradeEnabledBeforeSalvage:Boolean;
		private function onSalvageClick(evt:MouseEvent):void{
			if (this.btnSalvage.enabled){
  				this.upgradeEnabledBeforeSalvage = this.btnUpgrade.enabled;
				disableButtons();													
				this.dwSalvage = DialogWindowFactory.getInstance().getNewDialogWindow(this._uiFramework, this._linkManager, DialogWindowTypes.NORMAL, 200);													
 				setButtonEnabled(this.btnUpgrade, false);
 				setButtonEnabled(this.btnSwapOrbs, false);				
				this.dwSalvage.addEventListener("CLOSE", onSalvageDialogCancel, false, 0, true);				
				this.dwSalvage.addEventListener("OKAY", onSalvageDialogClose, false, 0, true);
				this.dwSalvage.autoSize = true;
				this.dwSalvage.keepOnStage = true;
				this.dwSalvage.setHtmlText(GlobalTexts.salvageWarning);				
				this.dwSalvage.setPosAtMouse();
				GlobalEvent.eventDispatcher.dispatchEvent(new GlobalEvent(GlobalEvent.ALLOW_RING_SELECTABILITY, false));															
			}
		}
		
		private function onSalvageDialogCancel(evt:Event):void {
			// the button had to be enabled before we launched the dialog
			setButtonEnabled(this.btnSalvage, true);
			setButtonEnabled(this.btnSwapOrbs, true);					
			setButtonEnabled(this.btnUpgrade, this.upgradeEnabledBeforeSalvage);
			cleanUpSalvageWindow();			
			GlobalEvent.eventDispatcher.dispatchEvent(new GlobalEvent(GlobalEvent.ALLOW_RING_SELECTABILITY, true));																						
		}	
			
		private function onSalvageDialogClose(evt:Event):void {
			this.dispatchEvent(new UiEvents(UiEvents.RING_SALVAGE,null));
			cleanUpSalvageWindow();
			GlobalEvent.eventDispatcher.dispatchEvent(new GlobalEvent(GlobalEvent.ALLOW_RING_SELECTABILITY, true));																									
		}
		
		private function onMapDone(e:GlobalEvent):void {
			var isNullChamber:Boolean = e.data.isNullChamber;
			if (!isNullChamber) {
				onSalvageDialogCancel(null);
				cleanUpUpgradeWindow();
			}
		}

		private function cleanUpUpgradeWindow():void {
			cleanUpDialogWindow(this.dwUpgrade);
			this.dwUpgrade = null;
		}
		
		private function cleanUpSalvageWindow():void {
			cleanUpDialogWindow(this.dwSalvage);
			this.dwSalvage = null;						
		}		
		
		private function cleanUpDialogWindow(dw:DialogWindow):void {			
			if (dw && dw.isOpen()) {
				dw.close();
				dw.removeEventListener("CLOSE", onSalvageDialogCancel);
				dw.removeEventListener("OKAY", onSalvageDialogClose);
			}
		}			
	}
}
