package com.gaiaonline.battle.ui.uiitemdisplay
{
	import com.gaiaonline.battle.ApplicationInterfaces.IAssetFactory;
	import com.gaiaonline.battle.ItemLoadManager.ItemIcon;
	import com.gaiaonline.battle.ui.uiactionbar.SoulBoundAnimation;
	import com.gaiaonline.battle.ui.uiactionbar.SlotUpgradeAnimation;
	
	import flash.display.DisplayObject;
	import flash.display.MovieClip;
	import flash.events.Event;

	public class ItemSlot extends MovieClip
	{
		public var itemContainer:MovieClip;
		private static var assetFactory:IAssetFactory = null;
		
		public function ItemSlot(assetFactory:IAssetFactory)
		{
			super();
			ItemSlot.assetFactory = assetFactory;
			this.stop();
		}
		
		public function addItemIcon(itemIcon:ItemIcon = null):ItemIcon{
			var cItem:ItemIcon;
			if (this.itemContainer.numChildren > 0){
				 cItem = this.itemContainer.getChildAt(0) as ItemIcon;
				 while(this.itemContainer.numChildren > 0){
				 	this.itemContainer.removeChildAt(0);
				 }
			}
			if (itemIcon != null){				
				itemIcon.x = itemIcon.y = 0;
				this.itemContainer.addChild(itemIcon);
			}			
			
			return cItem;
		}
		
		public function getItemIcon():ItemIcon{
			var cItem:ItemIcon;
			if (this.itemContainer.numChildren > 0){				
				cItem = this.itemContainer.getChildAt(0) as ItemIcon;
			}
			return cItem;
		}
		public function removeItemIcon():ItemIcon{
			var cItem:ItemIcon;
			if (this.itemContainer.numChildren > 0){
				cItem = this.itemContainer.getChildAt(0) as ItemIcon;
				while(this.itemContainer.numChildren > 0){
				 	this.itemContainer.removeChildAt(0);
				 }
			}
			return cItem;
		}

		public function playUpgrade():void{
			var animation:DisplayObject = new SlotUpgradeAnimation();
			if (animation != null){
			animation.addEventListener(Event.ENTER_FRAME, onAnimationFrame);
			animation.x = this.x;
			animation.y = this.y;
			this.parent.addChild(animation);
		}
		}
		public function playSoulBound():void{
			var animation:DisplayObject = new SoulBoundAnimation();
			if (animation != null){
			animation.x = this.x + 1;
			animation.y = this.y + 13; 					
			animation.addEventListener(Event.ENTER_FRAME, onAnimationFrame);
			this.parent.addChild(animation);
		}
		}
		private function onAnimationFrame(e:Event):void {
			var mc:MovieClip = MovieClip(e.target);
			if (mc.currentLabel == "done") {
				mc.removeEventListener(Event.ENTER_FRAME, onAnimationFrame);
				mc.parent.removeChild(mc);
			}		
		}
	}
}