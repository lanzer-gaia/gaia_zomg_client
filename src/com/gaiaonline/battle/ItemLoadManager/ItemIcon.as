package com.gaiaonline.battle.ItemLoadManager
{
	import com.gaiaonline.battle.ApplicationInterfaces.IUIFramework;
	import com.gaiaonline.flexModulesAPIs.globalevent.GlobalEvent;
	import com.gaiaonline.objectPool.LoaderFactory;
	import com.gaiaonline.utils.DisplayObjectUtils;
	import com.gaiaonline.utils.VisManagerSingleParent;
	
	import flash.display.DisplayObject;
	import flash.display.Loader;
	import flash.display.LoaderInfo;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.net.URLRequest;
	import flash.text.TextField;

	public class ItemIcon extends MovieClip
	{
		public var mcDisable:Sprite;
		public var mcInSwapUi:Sprite;
		public var timer:ItemTimer;
		public var mcContainer:Sprite;
		public var mcHitArea:Sprite;
		public var txtNum:TextField;
		public var mcSoulBoundIcon:MovieClip;

		public var itemLoader:IItemLoader;
		
		private var _isDrag:Boolean = false;		
		private var _disable:Boolean = false;
		private var _usable:Boolean = true;
		private var _slot:int = -1;
		private var _itemId:String;
		private var _icon:DisplayObject;
		private var _displayNum:Boolean = false;
		private var _soulBound:Boolean = false;
		private var _locked:Boolean = false;
		private var _inSwapUi:Boolean = false;
		
		
		private var _customizer:IItemIconCustomization = null;
				
		public var obj:Object = new Object();

		private var _visMgr:VisManagerSingleParent = null;
		
		private var _uiFramework:IUIFramework = null;
							
		public function ItemIcon(uiFramework:IUIFramework, customizer:IItemIconCustomization, itemId:String, slot:int, itemLoader:IItemLoader, soulbound:Boolean = false)
		{
			super();		
			this._uiFramework = uiFramework;			
			this._customizer = customizer;
			this._itemId = itemId;
			this._slot = slot;
			this.itemLoader = itemLoader;			
			if (this.itemLoader != null){		
				if (this.itemLoader.loaded){
					this.setDefaultInfo();
				}else{				
					this.itemLoader.addEventListener(ItemLoadEvent.ITEM_LOADED, onItemLoaded, false, 0, true);				
				}
			}
			this._soulBound = soulbound;
			this.hitArea = this.mcHitArea;
			this.mouseChildren = false;
			this.mcHitArea.visible = false;  // don't use the VisibilityManager for this one, it needs to be on the stage

			this.txtNum.text = "0";

			this._visMgr = new VisManagerSingleParent(this); 
			this._visMgr.setVisible(this.txtNum, this._displayNum);			
			this._visMgr.setVisible(this.mcSoulBoundIcon, this._soulBound);	
			this._visMgr.setVisible(this.timer, false);
			this._visMgr.setVisible(this.mcInSwapUi, false);
			updateEnabled();
			
			DisplayObjectUtils.addWeakListener(this.timer, Event.COMPLETE, onTimerComplete);
		}
		
		private function updateEnabled():void {
			this._visMgr.setVisible(this.mcDisable, (this._disable || !this._usable));			
		}
		private function onItemLoaded(evt:ItemLoadEvent):void{
			if (this.itemLoader) {
				this.itemLoader.removeEventListener(ItemLoadEvent.ITEM_LOADED, onItemLoaded);
			}
			this.setDefaultInfo();
		}

		private function setDefaultInfo():void {
			this.setItemInfo();				
			this.setDefaultTooltip();
			var itemUpdateEventType:String = this._customizer.getItemUpdateEventType();
			if (itemUpdateEventType != null) {
				DisplayObjectUtils.addWeakListener(GlobalEvent.eventDispatcher, itemUpdateEventType, onItemUpdate);
			}											
		}
		
		private function setItemInfo():void{		
			this.setIcon(this.itemLoader.getNewItemDisplay());
			setDefaultTooltip();
		}
		
		private function onItemUpdate(e:GlobalEvent):void {
			if (e.data.slot == this.slot) {
				if (!this._locked) {
					setDefaultTooltip();
				}
			}
		}
		
		public function setDefaultTooltip():void {
			setTooltip(this._customizer.getDefaultTooltip(this));
		}
		

		private function setTooltip(tooltip:String):void {
			this._uiFramework.tooltipManager.removeToolTip(this);
			this._uiFramework.tooltipManager.addToolTip(this, tooltip);			
		}
		
		public function setLocked(locked:Boolean):void {			
			if (locked == this._locked) {
				return;
			}
			
			if (locked) {
				var lockedTooltip:String = this._customizer.getLockedSlotTooltipText();
				if (lockedTooltip != null) {				
					this.setTooltip(lockedTooltip);
				}
			} else {
				setDefaultTooltip();
			}	
			
			this._locked = locked;		
		}
		
		public function startTimer(lenght:Number, startTime:Number = 0):void{
			this._visMgr.setVisible(this.timer, true);
			this.timer.startTimer(lenght, startTime);
		}
		public function resetTimer():void{
			this.timer.resetTimer();
		}
		private function onTimerComplete(e:Event):void {
			this._visMgr.setVisible(this.timer, false);
		}
		
		public function setIcon(icon:DisplayObject):void{
			while(this.mcContainer.numChildren > 0){				
				this.mcContainer.removeChildAt(0);
			}

			this.mcContainer.addChild(icon);
		} 
		
		public function loadIcon(url:String):void{
			while(this.mcContainer.numChildren > 0){
				this.mcContainer.removeChildAt(0);
			}
			var l:Loader = LoaderFactory.getInstance().checkOut();
			l.contentLoaderInfo.addEventListener(Event.COMPLETE, onLoadListener);
			l.load(new URLRequest(url));
						
		}
		
		private function onLoadListener(event:Event):void{
			var loaderInfo:LoaderInfo = (event.target as LoaderInfo);
			loaderInfo.removeEventListener(event.type, arguments.callee);
			this.mcContainer.addChild(loaderInfo.content);
			
			LoaderFactory.getInstance().checkIn(loaderInfo.loader);
		}
		
		public function dispose():void{
			
			this.timer.stop();
			this.timer = null;
			this.itemLoader = null;
			this.obj = null;
			this._visMgr = null;			
			
			while(this.mcContainer.numChildren > 0){				
				this.mcContainer.removeChildAt(0);
			}
			DisplayObjectUtils.ClearAllChildrens(this.mcContainer, 2);						
		}
		
		//******************************
		//--- Properties
		//******************************
		public function set disable(v:Boolean):void{
			this._disable = v;
			updateEnabled();
		}
		public function get disable():Boolean{
			return this._disable;
		}
		
		public function set inSwapUi(v:Boolean):void{
			this._inSwapUi = v;
			this._visMgr.setVisible(this.mcInSwapUi, this._inSwapUi);
		}
		public function get inSwapUi():Boolean{
			return this._inSwapUi;
		}
		
		public function set usable(v:Boolean):void{
			this._usable = v;
			updateEnabled();
		}
		public function get usable():Boolean{
			return this._usable;
		}
		
		public function set slot(v:int):void{
			this._slot = v;
		}
		public function get slot():int{
			return this._slot;
		}
		
		public function set itemId(v:String):void{
			this._itemId = v;
		}
		public function get itemId():String{
			return this._itemId
		}
		
		public function get isDrag():Boolean{
			return this._isDrag;
		}
		public function set isDrag(v:Boolean):void{
			this._isDrag = v;
		}
		
		public function get displayNum():Boolean{
			return this._displayNum;
		}
		public function set displayNum(v:Boolean):void{
			this._displayNum = v;
			this._visMgr.setVisible(this.txtNum, this._displayNum);
		}
		
		public function get quantity():int{
			return parseInt(this.txtNum.text);
		}
		public function set quantity(v:int):void{
			this.txtNum.text = String(v);
		}
		
		public function get SoulBound():Boolean{
			return this._soulBound;
		}
		public function set SoulBound(v:Boolean):void{
			this._soulBound = v;
			this._visMgr.setVisible(this.mcSoulBoundIcon, this._soulBound);
		}
		
		public function playSoulBound():void{
			this._soulBound = true;
			this._visMgr.setVisible(this.mcSoulBoundIcon, this._soulBound);
			this.mcSoulBoundIcon.gotoAndPlay("Anim")
		}
								
	}
}