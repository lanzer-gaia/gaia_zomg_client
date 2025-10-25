package com.gaiaonline.battle.ui
{
	import com.gaiaonline.battle.ui.components.ScrollBarVer;
	import com.gaiaonline.utils.VisManagerSingleParent;
	
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;

	public class UiQuestItemDisplay extends MovieClip
	{
		
		public var mcContainer:MovieClip;
		public var mcMask:MovieClip;
		public var scl:ScrollBarVer;
		public var noItemsText:TextField;		
		
		private var _items:Array = new Array();		
		private var _width:Number = 197;
		private var _height:Number = 200;
		
		private var visManager:VisManagerSingleParent;
		private var _scrollToItem:UiQuestItem = null;	
		
		public function UiQuestItemDisplay()
		{
			super();
			this.scl.init(mcContainer, this.mcMask.getRect(this));	
			this.addEventListener(Event.ENTER_FRAME, onEnterFrame, false, 0, true);
			
			this.visManager = new VisManagerSingleParent(this);
			
			this.noItemsText.text = "";
			this.setNoItemsTextVisible(true);									
		}

		public function setNoTasksString(str:String):void {
			this.noItemsText.text = str;
		}
		
		private function setNoItemsTextVisible(visible:Boolean):void {
			this.visManager.setVisible(this.noItemsText, visible);
		}
				
		private function onEnterFrame(evt:Event):void{
			this.resize();
			this.removeEventListener(Event.ENTER_FRAME, onEnterFrame);
			
			if (_scrollToItem) {
				this.scl.scrollToTop();
				_scrollToItem = null;
			}

		}
		
		
		public function clearNotification():void{
			for each(var item:UiQuestItem in this._items){
				item.Highlight = false;
			}
		}
		
		public function resize():void{
			this.mcMask.height = this._height;
			this.mcMask.width = this._width - 13;
			this.scl.x = this.mcMask.width + 0.5;		
			
			var y:Number = 0;
			for each(var item:UiQuestItem in this._items){					
				item.width = this.mcMask.width;				
				item.y = y;
				y += item.mcBack.height + 8;
			}
			
			var pos:Number = this.scl.thumbPos
			this.scl.height = this.mcMask.height;
			this.scl.init(mcContainer, this.mcMask.getRect(this), false, false);
			
			this.noItemsText.width = this.mcMask.width - 20*2;
			this.noItemsText.x = (this.mcMask.width - this.noItemsText.width)/2;			
			this.noItemsText.y = (this.mcMask.height - this.noItemsText.height)/2;			
			this.noItemsText.autoSize = TextFieldAutoSize.CENTER;
			//this.scl.update();
		}
				
		public function updateInfo(list:Array):void{
			this.clearAll();
			for (var i:int = 0; i < list.length; i++){
				var item:UiQuestItem = new UiQuestItem();
				item.mcBack;
				item.updateInfo(list[i]);
				item.Highlight = list[i].notify;				
				addOrderedItems(item);
				item.addEventListener(UiQuestItem.EXTEND_CHANGED, onItemExtendChanged, false, 0, true);							
			}
			if (list.length > 0) {
				this.setNoItemsTextVisible(false);				
			}
			this.addEventListener(Event.ENTER_FRAME, onEnterFrame, false, 0, true);		
		}
		
		private function onItemExtendChanged(evt:Event):void{
			
			for (var i:int = 0; i < this._items.length; i++){
				if (this._items[i] != evt.target){
					UiQuestItem(this._items[i]).extended = false;
				}
			}
			
			this.addEventListener(Event.ENTER_FRAME, onEnterFrame, false, 0, true);		
		}
		
		public function addItem(item:UiQuestItem):void{
			if (this._items.indexOf(item) < 0){
				addOrderedItems(item);
				this.addEventListener(Event.ENTER_FRAME, onEnterFrame, false, 0, true);		
			}
		}
		
		// push the item notifications to the top
		private function addOrderedItems(item:UiQuestItem):void
		{
			if (item.Highlight) {
				_scrollToItem = item;
				this._items.unshift(item);
				mcContainer.addChildAt(item, 0);
			} else {
				this._items.push(item);
				this.mcContainer.addChild(item);
			}
		}
		
		public function clearAll():void{
			for each(var item:UiQuestItem in this._items){
				if (this.mcContainer.contains(item)){
					this.mcContainer.removeChild(item);
				}
			}
			this.setNoItemsTextVisible(true);
			this._items.length = 0;
			this.addEventListener(Event.ENTER_FRAME, onEnterFrame, false, 0, true);				
		}
				
		public override function set width(v:Number):void{
			this._width = v;
			this.addEventListener(Event.ENTER_FRAME, onEnterFrame, false, 0, true);				
		}
		public override function set height(v:Number):void{
			this._height = v;
			this.addEventListener(Event.ENTER_FRAME, onEnterFrame, false, 0, true);	
		}	
		
	}
}