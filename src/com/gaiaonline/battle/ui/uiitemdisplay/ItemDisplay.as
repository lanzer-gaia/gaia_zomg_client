package com.gaiaonline.battle.ui.uiitemdisplay
{		
	import com.gaiaonline.battle.ApplicationInterfaces.IAssetFactory;
	import com.gaiaonline.battle.ItemLoadManager.ItemIcon;
	import com.gaiaonline.battle.ui.components.ScrollBarVer;
	import com.gaiaonline.battle.ui.uiactionbar.SlotBorderFl;
	import com.gaiaonline.battle.utils.BattleUtils;
	import com.gaiaonline.utils.DisplayObjectUtils;
	
	import flash.display.DisplayObject;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	public class ItemDisplay extends MovieClip
	{
		
		public var scrollBar:ScrollBarVer;
		public var itemsContainer:MovieClip;
		public var startIndex:int = 0;
		
		private var scrollMask:Sprite;		
		
		private var _render:Boolean = false;
		private var _numCol:int = 8;
		private var _colSpace:int = 1;
		private var _rowSpace:int = 1;
		private var _itemWidth:Number = 28
		private var _itemHeight:Number = 28;
		private var _extraRows:int = -1;
		private var _minimumRows:int = 0;				
		private var _assetFactory:IAssetFactory = null;
		private var _items:Object = new Object();
		private var _lastIndex:int = -1;
		
		public function ItemDisplay()
		{
			this.scrollBar.height = this.height;
			this.scaleX = this.scaleY = 1;
			
			this.scrollMask = new Sprite();
			this.scrollMask.graphics.lineStyle(0);
			this.scrollMask.graphics.beginFill(0x0000FF);
			this.scrollMask.graphics.drawRect(0,0,10,10);
			this.scrollMask.graphics.endFill();
			this.addChild(this.scrollMask); 
			this.itemsContainer.mask = this.scrollMask;	
			
			this.addEventListener(Event.ADDED_TO_STAGE, onAddedToStage, false, 0, true);
			this.addEventListener(Event.REMOVED_FROM_STAGE, onRemoveFromStage, false, 0, true);
		}
		public function init(assetFactory:IAssetFactory):void {
			this._assetFactory = assetFactory;
		}
		private function onAddedToStage(evt:Event):void{
			this.addEventListener(Event.ENTER_FRAME, onFrame);
			this._render = true;	
		}		
		private function onRemoveFromStage(evt:Event):void{
			this.removeEventListener(Event.ENTER_FRAME, onFrame);	
		}
		
		private function onFrame(evt:Event):void{
			if (this._render){										
				this.updateDisplay();
			}
		}
		private function updateDisplay():void{

			if (_selection) {
				this.itemsContainer.removeChild(_selection);
			}

			//-- get current last index;
			var lastIndex:int = -1;
			var ci:int = 0;
			for each(var itemSlot:ItemSlot in this._items){					
				if (itemSlot.getItemIcon() != null){
					lastIndex = ci
				}
				ci++;				
			}						
			if (this._extraRows >= 0){									
				lastIndex += (this._extraRows * this._numCol);								
				lastIndex = (Math.ceil( (lastIndex+1)/this._numCol ) * this._numCol) - 1;
				
				var cRow:int = Math.ceil( (lastIndex+1)/this._numCol );
				if (cRow < this._minimumRows){
					lastIndex = (this._minimumRows * this._numCol) -1
				}
			}
			this._lastIndex = lastIndex;					
			
			//-----
			if (lastIndex < this.itemsContainer.numChildren-1){		
				//--- clean extra slot					
				for (var i:int = this.itemsContainer.numChildren; i > lastIndex+1; i--){					
					this.itemsContainer.removeChildAt(this.itemsContainer.numChildren-1);
					delete this._items[i];
				}				
			}else if (lastIndex > this.itemsContainer.numChildren-1){					
				//-- add Extra slot
				var n:int = this.itemsContainer.numChildren;					
				for (var ii:int = n; ii <= lastIndex; ii++){										
					this.addSlot(ii);
				}
			}			
			
			//**********
			//--- set mask size				
			var w:Number = (this._numCol * (this._itemWidth + this._colSpace));
	 		var h:Number = this.scrollBar.height;		 
			if (this.scrollMask.width != Math.round(w) || this.scrollMask.height != Math.round(h)){		 		
		 		this.scrollMask.height = Math.round(h);
				this.scrollMask.width = Math.round(w);
				this.scrollBar.init(this.itemsContainer, new Rectangle(0,0,w,h), false);
		 	}				
			this.scrollBar.x = (this._numCol * (this._itemWidth + this._colSpace));
			this.scrollBar.update();
							
			if (_selection) {
				this.itemsContainer.addChild(_selection);
			}
			
			this._render = false;
			
		}
		
		private function addSlot(index:int):ItemSlot{
			//--- add emtpy slots
				
			var itemSlot:ItemSlot = new ItemSlot(this._assetFactory);
			var row:int = Math.floor(index/this._numCol);				
			var col:int = Math.floor(index - (row*this._numCol));
						
			itemSlot.x = col * (this._colSpace+this._itemWidth);
			itemSlot.y = row * (this._rowSpace+this._itemHeight);
					
			this.itemsContainer.addChild(itemSlot);
			this._items[index] = itemSlot;				
						
			return this._items[index];		
		}
		
		public function addItemIcon(itemIcon:ItemIcon, slot:int):ItemIcon{
			//---add empty slot in front
			slot -= this.startIndex;						
			if (slot > this._lastIndex){
				for (var i:int = this._lastIndex+1; i < slot; i++){						
					this.addSlot(i);
				}
				this._lastIndex = slot;
			}			
			var itemSlot:ItemSlot = this._items[slot] as ItemSlot;			
			if (itemSlot == null){				
				itemSlot = this.addSlot(slot);							
			}			
			this._render = true;	
			return itemSlot.addItemIcon(itemIcon);
		}
		public function removeItemIcon(slot:int, delSlot:Boolean = false):ItemIcon{
			removeSelectionRing();
			slot -= this.startIndex;
			var ic:ItemIcon;			
			var itemSlot:ItemSlot = this._items[slot] as ItemSlot;			
			if (itemSlot != null){				
				ic = itemSlot.removeItemIcon();
				if (delSlot) {
					delete this._items[slot];
				}
				// don't delete the slot or else you won't be able to move future icons here;
				this._render = true;							
			}			
			return ic;
		}
		
		
		private var _globalToLocalHelper:Point = new Point(NaN, NaN);
		public function getSlotAt(x:int, y:int):int{
			var nSlot:int = -1;
			var r:Rectangle = this.scrollMask.getBounds(this);
			
			this._globalToLocalHelper.x = x;
			this._globalToLocalHelper.y = y;
			var p:Point = this.globalToLocal(this._globalToLocalHelper);			
			if (p.x >= r.left && p.x <= r.right && p.y >= r.top && p.y <= r.bottom){				
				var i:int = 0;
				for each(var itemSlot:ItemSlot in this._items){					
					if (itemSlot.hitTestPoint(x, y, true)){
						nSlot = i;
						break;
					}
					i ++;
				}
								
			}
			if (nSlot >= 0){
				nSlot += this.startIndex;
			}		
			return nSlot;
		}
		
		
		public function refresh():void{
			this._render = true;
		}
		
		public function clearAll():void{
			for each(var itemSlot:ItemSlot in this._items){	
				var ic:ItemIcon = itemSlot.removeItemIcon();
				if (ic != null){
					ic.dispose();
				}
				ic = null;
			}
			
			removeSelectionRing();

			while (this.itemsContainer.numChildren > 0){
				this.itemsContainer.removeChildAt(0);
			}
			DisplayObjectUtils.ClearAllChildrens(this.itemsContainer,2);
			this._lastIndex = -1;
			BattleUtils.cleanObject(this._items);
			this._render = true;
		}
		
		private function itemSlotFromSlot(slot:int):ItemSlot {
			return ItemSlot(this._items[slot - this.startIndex]);
		}
		
		private var _selectedSlot:int = -1;
		private var _selection:DisplayObject = null;					
		private function removeSelectionRing():void {
			if (_selection) {
				this.itemsContainer.removeChild(_selection);
				_selection = null;
			}
		}

		public function selectSlot(slot:int):void{

			//-- select slot
			if (this._items[slot - this.startIndex] != null){

				if (!_selection) {
					_selection = new SlotBorderFl();
				}

				var slotObj:DisplayObject = DisplayObject(this._items[slot - this.startIndex]);
				_selection.x = slotObj.x;
				_selection.y = slotObj.y;
				
				this.itemsContainer.addChild(_selection);
			}
			else {
				removeSelectionRing();
			}
		}
		
		public function playUpgrade(slot:int):void{
			var itemSlot:ItemSlot = this._items[slot - this.startIndex] as ItemSlot;
			if (itemSlot != null){			
				itemSlot.playUpgrade();				
			}
		}
		
		public function playSoulBound(slot:int):void{
			var itemSlot:ItemSlot = this._items[slot - this.startIndex] as ItemSlot;
			if (itemSlot != null){			
				itemSlot.playSoulBound();				
			}
		}		
		
		//************************
		// -- Properties
		//************************
		//--
		public function set numColumn(v:int):void{
			this._numCol = v;
			this._render = true;	
		}
		
		public function get numColumn():int{
			return this._numCol;
		}
		
		//---
		public function set columnSpacing(v:int):void{
			this._colSpace = v;
			this._render = true;	
		}
		public function get columnSpacing():int{
			return this._colSpace;
		}
		
		//---
		public function set rowSpacing(v:int):void{
			this._rowSpace = v;			
			this._render = true;
		}
		public function get rowSpacing():int{
			return this._rowSpace;
		}
		
		//--
		public function set extraRows(v:int):void{
			this._extraRows = v;
			this._render = true;
		}
		public function get extraRows():int{
			return this._extraRows;
		}
		
		
		//--
		public function set minimumRows(v:int):void{
			this._minimumRows = v;
			if (this._minimumRows > 0 && this._extraRows < 0){
				this._extraRows = 0;
			}
			this._render = true;
		}
		public function get minimumRows():int{
			return this._minimumRows
		}
						
	}
}