package com.gaiaonline.battle.ui
{
	import com.gaiaonline.flexModulesAPIs.globalevent.GlobalEvent;
	import com.gaiaonline.utils.DisplayObjectUtils;
	
	public class WorldTimerManager
	{
		private static var instance:WorldTimerManager = null;
		
		private static var timersDataHash:Object = {};
		
		public function WorldTimerManager(singletonEnforcer:SingletonEnforcer) {
			if (singletonEnforcer == null) {
				throw "WorldTimerManager is a singleton.  Use getInstance() to instantiate.";
			}
		}

		public static function getInstance():WorldTimerManager{
			if (!instance) {
				instance = new WorldTimerManager(new SingletonEnforcer());
			}
			DisplayObjectUtils.addWeakListener(GlobalEvent.eventDispatcher, GlobalEvent.WORLD_TIMER, onWorldTimer);

			return instance;			
		}

		private static function onWorldTimer(evt:GlobalEvent):void {			
			var data:Object = evt.data;
			var name:String = data.name;
			if (!name || name.length == 0) {
				// badly formatted timer; blow it off
				return;
			}
			
			// get the current hash for this timer or create a new one if there is no previous one
			var timerData:Object = WorldTimerManager.timersDataHash[name];
			if (!timerData) {
				timerData = data;
				WorldTimerManager.timersDataHash[name] = timerData;
			}

			// check for show/hide (destroy)
			if (data.show == null) { // default to showing, if a show value was not sent
				data.show = true;
			}
			var show:Boolean = data.show;						
			if (!show) { // treat hide as an implicit destroy
				delete WorldTimerManager.timersDataHash[name];
			}			
			timerData.show = show;						
			
			// update the hashed data
			var title:String = data.title;
			if (title && title.length > 0) {
				timerData.title = title;				
			}
						
			if (data.start != null) {
				timerData.start = data.start;
			}
						
			if (data.finish != null) {
				timerData.finish = data.finish;
			}
			
			if (data.countUp != null) {
				timerData.countUp = data.countUp;
			}
			
			timerData.playing = data.playing;
			timerData.stop = data.stop;			
			
			GlobalEvent.eventDispatcher.dispatchEvent(new GlobalEvent(GlobalEvent.WORLD_TIMER_UPDATE, timerData));						
		}
	}
}

internal class SingletonEnforcer {}


