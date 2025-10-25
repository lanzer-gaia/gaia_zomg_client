package com.gaiaonline.battle.utils
{
	import com.gaiaonline.flexModulesAPIs.globalevent.GlobalEvent;
	
	import flash.events.TimerEvent;
	import flash.utils.Timer;
	
	public class ResetTimeout
	{
		private static var _instance:ResetTimeout = null;
		
		private var timeOutMsg:String = "Time Out";
		private var toTimer:Timer;		
				
		public function ResetTimeout(se:SingletonEnforcer) {
			if (se == null) {
				throw Error("ResetTimeout is a singleton.  Use getInstance()");
			}
		}
		
		public static function getInstance():ResetTimeout {
			if (!_instance) {
				_instance = new ResetTimeout(new SingletonEnforcer());
			}
			
			return _instance;
		}
		
		///------  TimeOutTimer

		public function setResetTimeOut(ms:int, msg:String):void{
			clearResetTimeOut();			
			timeOutMsg = msg;
			toTimer = new Timer(ms,1);
			toTimer.addEventListener(TimerEvent.TIMER, onTimeOut);	
			toTimer.start();		
		}
		public function clearResetTimeOut():void{
			if (toTimer != null){				
				toTimer.stop();			
				toTimer.removeEventListener(TimerEvent.TIMER_COMPLETE, onTimeOut);
			}
			toTimer = null;
		}
		private function onTimeOut(evt:TimerEvent):void{
			toTimer.stop();
			toTimer.removeEventListener(TimerEvent.TIMER_COMPLETE, onTimeOut);
			toTimer = null;
			GlobalEvent.eventDispatcher.dispatchEvent(new GlobalEvent(GlobalEvent.GENERIC_ERR_MSG, {header:"Error", message:timeOutMsg}));
		}		
	}
}

internal class SingletonEnforcer {
}