package com.gaiaonline.battle
{
	import com.gaiaonline.battle.gateway.BattleEvent;
	import com.gaiaonline.battle.gateway.BattleGateway;
	import com.gaiaonline.battle.gateway.BattleMessage;
	
	import flash.events.TimerEvent;
	import flash.utils.Timer;
	
	public class PingTimer
	{
		private var pingTimer:Timer;
		private var waitTimer:Timer;
		
		private var pingCount:int = 10;
		private var pingDelay:int = 500;
		private var pingWait:int = 5000;
		
		private var pArray:Array = [];
		
		public var lagTime:int = 0;
		
		private var _gateway:BattleGateway = null;
		
		public function PingTimer(gateway:BattleGateway){
			this._gateway = gateway;
			
			this.pingTimer = new Timer(this.pingDelay, this.pingCount);
			this.waitTimer = new Timer(this.pingWait, 1);
			
			this.pingTimer.addEventListener(TimerEvent.TIMER, onPingTimer, false, 0, true);			
			this.waitTimer.addEventListener(TimerEvent.TIMER_COMPLETE, onWaitTimerComplete, false, 0, true);
				
		}
		
		public function start():void{
			this.stop();
			this.pingTimer.start();
		}
		
		
		public function stop():void{
			this.pingTimer.reset();
			this.waitTimer.reset();
			this.pArray.length = 0;
		}
		
		
		private function onPingTimer(evt:TimerEvent):void{
			if (this._gateway.connectedToGameServer){
				var msg:BattleMessage = new BattleMessage("601", null);				
				msg.addEventListener(BattleEvent.CALL_BACK, onCallBack);
				this._gateway.sendMsg(msg);
			}
		}
		private function onCallBack(evt:BattleEvent):void{
			//trace(evt.battleMessage.lag);
			this.pArray.push(evt.battleMessage.lag/2);
			
			if (this.pArray.length >= this.pingCount){
				// Calculate average Lag
				var l:int = 0;
				for(var i:int = 0; i < this.pArray.length; i++){
					l += this.pArray[i];
				}
				
				this.lagTime = l/this.pArray.length;
				//trace("AVG LAG TIME ", this.lagTime)	
				
				this.pArray.length = 0;
				this.pingTimer.reset();
				this.waitTimer.start();	
			}
			
			BattleMessage(evt.target).removeEventListener(BattleEvent.CALL_BACK, onCallBack);
			//trace(this.lagTime);
		}
				
		
		private function onWaitTimerComplete(evt:TimerEvent):void{
			//trace("===============")
			this.pingTimer.reset();
			this.pingTimer.start();
		}
	}
}