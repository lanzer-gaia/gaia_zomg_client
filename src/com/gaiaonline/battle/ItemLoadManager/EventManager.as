package com.gaiaonline.battle.ItemLoadManager
{
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	import flash.events.ProgressEvent;

	/**
	 * Handy class to make it easier to handle event dependencies.  For example if you need several
	 * events to fire before showing a login screen, this class makes it easier to parallelize 
	 * the events and listen for a single Event.COMPLETE event on EventManager
	 */
	
	[Event(name="complete", type="Event")] 
	public class EventManager extends EventDispatcher
	{
		
		private var _totalListeners:uint = 0;
		private var _totalFired:uint = 0;
		private var _debugName:String;
		public function EventManager(eventManagerDataObjects:Array, debugName:String = null){
			super();
			
			_debugName = debugName;
			try{
				for each(var data:EventManagerData in eventManagerDataObjects){
					registerListener(data.dispatcher, data.eventType);
				}
			}
			catch(error:Error){
				trace("Event Manager received an object that was not EventManagerData: " + error.message);
			}
		}
		
		private function registerListener(target:IEventDispatcher, eventType:String):void{			
			if(target && eventType && eventType.length > 0){
				target.addEventListener(eventType, onComplete, false, 0, false);
				_totalListeners++;
			}
		}
		
		private function onComplete(event:Event):void{
			event.target.removeEventListener(event.type, onComplete);
			_totalFired++;
			
			//not 100% convinced I should use ProgressEvent, especially since ProgressEvent insists upon BytesLoaded
			//and BytesTotal.  However, it gets the job done without extra classes.  If we decide showing byte information
			//this will have to be refactored somewhat.
			dispatchEvent(new ProgressEvent(ProgressEvent.PROGRESS, false, false, _totalFired, _totalListeners));

			if (_debugName)
			{			
				trace("EventManager.onComplete firing for", event.type, _totalFired + "/" + _totalListeners);
			} 			

			if(_totalFired >= _totalListeners){
				dispatchEvent( new Event(Event.COMPLETE) );
			}
		}
	}
}