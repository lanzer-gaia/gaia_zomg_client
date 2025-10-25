package com.gaiaonline.battle.moduleManagers
{
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	
	public class WindowUtils
	{
		private var _flexWinLayer:DisplayObjectContainer = null;
		
		public function WindowUtils(winLayer:DisplayObjectContainer)
		{
			_flexWinLayer = winLayer;
		}
		
		public function isWindowOpen(w:DisplayObject):Boolean
		{
			return w && this._flexWinLayer.contains(w);
		}
		
		public function openWindow(w:DisplayObject):void
		{
			if (!this._flexWinLayer.contains(w)){
				this._flexWinLayer.addChild(w);
			}
		}
		
		public function closeWindow(w:DisplayObject):void
		{
			if (this._flexWinLayer.contains(w)) {
				this._flexWinLayer.removeChild(w);
			}
		}

	}
}