package com.gaiaonline.battle.ui.uiactionbar
{
	import com.gaiaonline.battle.ApplicationInterfaces.IAssetFactory;
	import com.gaiaonline.battle.ItemLoadManager.ConsumableLoader;
	import com.gaiaonline.battle.ItemLoadManager.ItemIcon;
	import com.gaiaonline.battle.utils.BattleUtils;
	import com.gaiaonline.flexModulesAPIs.globalevent.GlobalEvent;
	import com.gaiaonline.utils.DisplayObjectUtils;
	import com.gaiaonline.utils.MovieClipProxy;
	import com.gaiaonline.utils.VisManager;
	
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.SimpleButton;
	import flash.events.Event;

	public class UiItemBar extends MovieClipProxy
	{
		public var f0:MovieClip;
		public var f1:MovieClip;
		public var f2:MovieClip;
		public var f3:MovieClip;
		public var f4:MovieClip;
		public var f5:MovieClip;
		public var f6:MovieClip;
		public var f7:MovieClip;
		
		public var polish:MovieClip;
						
		public var btnPopup:SimpleButton;
		
		public var set1:MovieClip;
		public var set2:MovieClip;	
		
		
		private var _usable:Boolean = true;
		private var _cureUsable:Boolean = true;
		private var _shouldPolish:Boolean = false;

		private var _assetFactory:IAssetFactory = null;
		private var _visMgr:VisManager = null;
		
		private var _itemBar:UiItemBarFl;
				
		public static const MAX_BAR_SLOT_INDEX:int = 7;
		
		public function UiItemBar(itemBar:UiItemBarFl)
		{	
			super(itemBar);		
			
			this._itemBar = itemBar;
			
			this.f1 = this._itemBar.f1;
			this.f2 = this._itemBar.f2;
			this.f3 = this._itemBar.f3;
			this.f4 = this._itemBar.f4;
			this.f5 = this._itemBar.f5;
			this.f6 = this._itemBar.f6;
			this.f7 = this._itemBar.f7;
			
			this.polish = this._itemBar.polish;
							
			this.btnPopup = this._itemBar.btnPopup;
			
			this.set1 = this._itemBar.set1;
			this.set2 = this._itemBar.set2;	
			
			
			this._visMgr = new VisManager();
			this._visMgr.registerChildren(this._itemBar);

			setLeftSet(false);
			setRightSet(false);
			
			for (var i:int = 0; i <= UiItemBar.MAX_BAR_SLOT_INDEX ; i++){
				this._visMgr.registerChildren(getSlot(i));
				this.unLockSlot(i);				
			}
			this.usable = this._usable;
			
			if (this.polish != null){				
				this.polish.mouseChildren = false;
				this.polish.mouseEnabled = false;
				this.polish.gotoAndStop(1);
			}

			DisplayObjectUtils.addWeakListener(GlobalEvent.eventDispatcher, GlobalEvent.WIDGET_SHOW, onWidgetShow);			
			DisplayObjectUtils.addWeakListener(this._itemBar, Event.ADDED_TO_STAGE, onItemBarAddedToStage);						
			DisplayObjectUtils.addWeakListener(this._itemBar, Event.REMOVED_FROM_STAGE, onItemBarRemovedFromStage);									
		}
		
		public function init(assetFactory:IAssetFactory):void {
			this._assetFactory = assetFactory;
		}
		
		public function setLeftSet(v:Boolean):void{
			this._visMgr.setVisible(this._itemBar, this._itemBar.set1, v);
			if (v){
				this.set1.play();
			}else{
				this.set1.stop();
			}
		}
		
		// [bgh] FS#21505
		public function hasRingSet():Boolean
		{
			return this._visMgr.isVisible(this.set1) || this._visMgr.isVisible(this.set2);
		}
		
		public function setRightSet(v:Boolean):void{
			this._visMgr.setVisible(this._itemBar, this._itemBar.set2, v);
			if (v){
				this.set2.play();
			}else{
				this.set2.stop();
			}
		}		

		private function getSlot(slot:int):MovieClip
		{
			return this._itemBar["f"+String(slot)];
		}		
		public function lockSlot(slot:int):void{
			if (slot <= UiItemBar.MAX_BAR_SLOT_INDEX ){
				this._visMgr.setVisible(getSlot(slot), getSlot(slot).mcLock, true); 
			}
		}
		public function unLockSlot(slot:int):void{
			if (slot <= UiItemBar.MAX_BAR_SLOT_INDEX ){
				MovieClip(getSlot(slot).mcLock).mouseEnabled = false;
				this._visMgr.setVisible(getSlot(slot), getSlot(slot).mcLock, false); 
			}
		}
		public function isSlotLock(slot:int):Boolean{

			if (slot <= UiItemBar.MAX_BAR_SLOT_INDEX  && slot >= 0){
				return this._visMgr.isVisible(getSlot(slot).mcLock);
			}
			return false;
		}		
		
		public function addItemIcon(itemIcon:ItemIcon, slot:int):ItemIcon{
			var ic:ItemIcon;
			if (slot <= UiItemBar.MAX_BAR_SLOT_INDEX  && itemIcon != null){ 
				//-- get curent ItemIcon				
				var mcContainer:MovieClip = getSlot(slot).mcContainer;
				if (mcContainer.numChildren > 0){
					ic = mcContainer.getChildAt(0) as ItemIcon;
					while (mcContainer.numChildren > 0){
						mcContainer.removeChildAt(0);
					}
				}
				
				//-- add new item Icon
				itemIcon.x = itemIcon.y = 0;
				mcContainer.addChild(itemIcon);
				
				BattleUtils.disableMouseOnChildren(itemIcon);
			}			
			return ic;
		}
		
		public function removeItemIcon(slot:int):ItemIcon{
			var ic:ItemIcon;
			if (slot <= UiItemBar.MAX_BAR_SLOT_INDEX ){
				removeSelectionRing();
				var mcContainer:MovieClip = getSlot(slot).mcContainer;
				if (mcContainer.numChildren > 0){
					ic = mcContainer.getChildAt(0) as ItemIcon;
					while (mcContainer.numChildren > 0){
						mcContainer.removeChildAt(0);
					}
				}
				
			}
			
			return ic;
		}
			
		public function getSlotAt(x:int, y:int):int{
			var nSlot:int = -1;
			for (var i:int = 0; i <= UiItemBar.MAX_BAR_SLOT_INDEX ; i++){
				var mcSlot:MovieClip = getSlot(i) as MovieClip;
				if (mcSlot.hitTestPoint(x, y, true)){
					nSlot = i;
					break;
				}
			}
			return nSlot;
		}
		
		public function clearAll():void{
			for (var slot:int = 0; slot <= UiItemBar.MAX_BAR_SLOT_INDEX ; slot++){
				this.removeItemIcon(slot);
			}
		}
		
		private var _lastSelected:int = -1;
		private var _selection:DisplayObject = null; 
		public function selectSlot(slot:int):void{

			if (UiItemBar.isBarSlot(slot))
			{
				if (!_selection)
				{
					_selection = new SlotBorderFl();
				}
				_selection.x = DisplayObject(getSlot(slot)).x;
				_selection.y = DisplayObject(getSlot(slot)).y;
				this.addChild(_selection);
				
				_lastSelected = slot;
			}
			else
			{
				removeSelectionRing();
			}
		}
	
		public function removeSelectionRing():void {
			if (_selection && _selection.parent)
			{
				_selection.parent.removeChild(_selection);
				_lastSelected = -1;
			}
		}
		
		public function playUpgrade(slot:int):void{
			if (slot <= UiItemBar.MAX_BAR_SLOT_INDEX ){
				// this was always ignoring the 'slot' parameter - probably can be removed -kja
				if (_selection && _selection.parent)
				{
					var slotObj:DisplayObjectContainer = getSlot(_lastSelected) as DisplayObjectContainer;
					var SlotUpgradeAnimation:Class = this._assetFactory.getClass("com.gaiaonline.battle.ui.uiactionbar.SlotUpgradeAnimation");
					if (SlotUpgradeAnimation != null){
						var animation:DisplayObject = new SlotUpgradeAnimation() as DisplayObject; 					
	
						animation.addEventListener(Event.ENTER_FRAME, onAnimationFrame, false, 0, true);
						animation.x = slotObj.x;
						animation.y = slotObj.y;
						this.addChild(animation);
					}
				}
			}
		}
		
		private function onAnimationFrame(e:Event):void {
			
			var mc:MovieClip = MovieClip(e.target);
			if (mc.currentLabel == "done") {
				mc.removeEventListener(Event.ENTER_FRAME, onAnimationFrame);
				mc.parent.removeChild(mc);
			}		
		}

		private function onItemBarAddedToStage(e:Event):void {
			if (this._shouldPolish) {
				this.playPolish();
				this._shouldPolish = true;
			}
		}
		private function onItemBarRemovedFromStage(e:Event):void {
			if (this._shouldPolish) {
				this.stopPolish();
				this._shouldPolish = true;
			}			
		}		
		public function playPolish():void{
			this._shouldPolish = true;
			if (this.polish != null){		
				this.polish.gotoAndPlay(1);
			}
		}
		
		public function stopPolish():void{
			this._shouldPolish = false;			
			if (this.polish != null){
				this.polish.gotoAndStop(1);
			}			
		}
		
		public function playSoulBound(slot:int):void{
			if (slot <= UiItemBar.MAX_BAR_SLOT_INDEX ){
				var mcSlot:MovieClip = getSlot(slot) as MovieClip;
				if (mcSlot != null){
					//var SoulBoundAnimation:Class = this._assetFactory.getClass("com.gaiaonline.battle.ui.uiactionbar.SoulBoundAnimation");
					var animation:DisplayObject = new com.gaiaonline.battle.ui.uiactionbar.SlotUpgradeAnimation();//new SoulBoundAnimation() as DisplayObject; 					
					animation.x = mcSlot.x + 1;
					animation.y = mcSlot.y + 13;
					animation.addEventListener(Event.ENTER_FRAME, onAnimationFrame);
					this.addChild(animation);
				}
			}
		}
		
						
		public function get usable():Boolean{
			return this._usable;
		}
		public function set usable(v:Boolean):void{
			this._usable = v;
			this.updateUsable();
		}
		
		public function get cureUsable():Boolean{
			return this._cureUsable;
		}
		public function set cureUsable(v:Boolean):void{
			this._cureUsable = v;
		}
		
		private function updateUsable():void{
			for (var i:int = 0; i <= UiItemBar.MAX_BAR_SLOT_INDEX ; i++){
				var slot:MovieClip = getSlot(i);				
				this._visMgr.setVisible(slot, slot.mcUnUsable, !(this._usable || (isCure(i) && cureUsable))); 
				slot.mcUnUsable.mouseEnabled = false;
			}
		}
	
		public static function isBarSlot(slot:int):Boolean {
			return slot >= 0 && slot <= MAX_BAR_SLOT_INDEX;
		}
		
		public function isCure(s:int):Boolean {
			var slot:MovieClip = getSlot(s);
			if (slot != null && slot.mcContainer != null && MovieClip(slot.mcContainer).numChildren >= 1){
				var ic:ItemIcon = slot.mcContainer.getChildAt(0) as ItemIcon;
				if (ic != null && ic.itemLoader is ConsumableLoader){
					return ConsumableLoader(ic.itemLoader).itemCanCure;
				}
			}
			return false;
		}
		
		private function onWidgetShow(evt:GlobalEvent):void {
			var widgetName:String = evt.data.widgetName;
			var show:Boolean = evt.data.widgetShow;
			var enable:Boolean = (evt.data.widgetEnable != undefined) ? evt.data.widgetEnable : false;
			switch (widgetName) {
				case "InventoryPanel":
					this._visMgr.setVisible(this._itemBar, this.btnPopup, enable || show);
					break;
				default: // do nothing
					break;
			}
		}
		
		public function get mc():MovieClip {
			return this._itemBar;
		}
	}
}