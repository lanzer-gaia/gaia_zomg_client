package com.gaiaonline.battle.ItemLoadManager
{
	import com.gaiaonline.gsi.GSIEvent;
	import com.gaiaonline.gsi.GSIGateway;
	
	import flash.events.EventDispatcher;
	
	public class GSIEventManager extends EventDispatcher
	{
		private var _gsiNumbers:Array = null;
		private var _gsiGateway:GSIGateway = null;
		
		public function GSIEventManager(gsiGateway:GSIGateway, gsiNumbers:Array){
			_gsiNumbers = gsiNumbers;
			_gsiGateway = gsiGateway;
			
			_gsiGateway.addEventListener(GSIEvent.LOADED, onLoaded, false, 0, true);
		}
		
		private function onLoaded(event:GSIEvent):void{
//			if( (var index:int = _gsiNumbers.indexOf(event.gsiMethod) ) >= 0){
//				_gsiNumbers.splice(index, 1)
//				
//				if(_gsiNumbers.length <= 0){
//					event.target.removeEventListener(event.type, onLoaded);
//					dispatchEvent( new Event(Event.COMPLETE) );
//				}
//			}
		}
		
	}
}