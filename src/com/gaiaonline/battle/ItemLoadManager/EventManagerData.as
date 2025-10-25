package com.gaiaonline.battle.ItemLoadManager
{
	import flash.events.IEventDispatcher;
	
	/**
	 * For use with EventManager
	 * 
	 */
	
	public class EventManagerData
	{
		public var dispatcher:IEventDispatcher = null;
		public var eventType:String = null;
		
		public function EventManagerData(eventDispatcher:IEventDispatcher, eventType:String){
			this.dispatcher = eventDispatcher
			this.eventType = eventType;
		}

	}
}