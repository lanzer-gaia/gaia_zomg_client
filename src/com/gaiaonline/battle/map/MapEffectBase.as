package com.gaiaonline.battle.map
{
	import com.gaiaonline.utils.RegisterUtils;
	
	public class MapEffectBase
	{
		private var _eventHandlers:Array = [];
		
		public function MapEffectBase()
		{
		}

		public function registerForTransitionEvents(handler:ITransitionEventHandler):void{
			RegisterUtils.register(_eventHandlers, handler);
		}
		
		public function unregisterForTransitionEvents(handler:ITransitionEventHandler):void{
			RegisterUtils.unregister(_eventHandlers, handler);
		}

		protected function runWarpOutComplete():void{
			for each(var warpOutHandler:ITransitionEventHandler in _eventHandlers){
				warpOutHandler.onWarpOutTransitionComplete();
			}
		}
		
		protected function runWarpInComplete():void{
			for each(var warpInHandler:ITransitionEventHandler in _eventHandlers){
				warpInHandler.onWarpInTransitionComplete();
			}
		}

	}
}