package com.gaiaonline.battle.ui
{
	import com.gaiaonline.battle.ApplicationInterfaces.IUIFramework;
	import com.gaiaonline.utils.DisplayObjectUtils;
	
	import flash.display.MovieClip;
	import flash.display.Sprite;
	
	public class UiCollectiblesHolder
	{
		// The movie clip representing the collectibles holder itself
		private var _mc:MovieClip = null;
		private var _uiFramework:IUIFramework = null;
		
		public function UiCollectiblesHolder(uiFramework:IUIFramework, mc:MovieClip) {
			_uiFramework = uiFramework;
			_mc = mc;			
		}

		public function addItemToSlot(icon:Sprite, index:uint, tooltipText:String = null):void {
			var collectibleSlot:MovieClip = MovieClip(_mc["F" + String(index)]);
			
			if (!collectibleSlot)
			{
				trace("ERROR: invalid itemSlot index received.  Server bug?");
				return;
			}

			var container:MovieClip = MovieClip(collectibleSlot.container);
			if (container != null){			
				if (container.numChildren > 0){
					// This shouldn't happen, since we dedupe, but just in case . . .
					trace("ERROR: Duplicate item readded to collectibles holder");
					var oldR:Sprite = Sprite(container.getChildAt(0));	
					container.removeChild(oldR);	
					// no need to remove tooltip, since it'll get reset below
				}
				icon.x = 0;
				icon.y = 0;
				container.addChild(icon);							 
			}
			if (tooltipText != null) {				
				this._uiFramework.tooltipManager.addToolTip(collectibleSlot, tooltipText);
			}
		}		
		
		public function dispose():void {
			for (var i:int = 0; i < _mc.numChildren; i++){
				var mc:MovieClip = _mc.getChildAt(i) as MovieClip;
				if (mc != null){
					this._uiFramework.tooltipManager.removeToolTip(mc);
				}
			}
			
			DisplayObjectUtils.ClearAllChildrens(_mc, 4);
			_mc = null;
		}

	}
}
