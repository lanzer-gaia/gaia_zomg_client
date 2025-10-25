package com.gaiaonline.battle.ui
{
	import com.gaiaonline.flexModulesAPIs.globalevent.GlobalEvent;
	import com.gaiaonline.utils.DisplayObjectUtils;
	
	public class WorldCounterManager
	{
		private static var instance:WorldCounterManager = null;
		
		private static var countersDataHash:Object = {};
		
		public function WorldCounterManager(singletonEnforcer:SingletonEnforcer) {
			if (singletonEnforcer == null) {
				throw "WorldCounterManager is a singleton.  Use getInstance() to instantiate.";
			}
		}

		public static function getInstance():WorldCounterManager{
			if (!instance) {
				instance = new WorldCounterManager(new SingletonEnforcer());
			}
			DisplayObjectUtils.addWeakListener(GlobalEvent.eventDispatcher, GlobalEvent.WORLD_COUNTER, onWorldCounter);

			return instance;			
		}

		private static function onWorldCounter(evt:GlobalEvent):void {			
			var data:Object = evt.data;
			var name:String = data.name;
			if (!name || name.length == 0) {
				// badly formatted counter; blow it off
				return;
			}
			
			// get the current hash for this counter or create a new one if there is no previous one
			var counterData:Object = WorldCounterManager.countersDataHash[name];
			if (counterData == null) {
				counterData = data;
				WorldCounterManager.countersDataHash[name] = counterData;
			}

			// check for show/hide (destroy)
			if (data.show == null) { // default to showing, if a show value was not sent
				data.show = true;
			}
			var show:Boolean = data.show;						
			if (!show) { // treat hide as an implicit destroy
				delete WorldCounterManager.countersDataHash[name];
			}			
			counterData.show = show;
			
			// update the hashed data
			var title:String = data.title;
			if (title && title.length > 0) {
				counterData.title = title;				
			}
						
			if (data.value != null) {
				counterData.value = data.value;
			}
			counterData.goal = data.goal;

			GlobalEvent.eventDispatcher.dispatchEvent(new GlobalEvent(GlobalEvent.WORLD_COUNTER_UPDATE, counterData));						
		}
	}
}

internal class SingletonEnforcer {}


