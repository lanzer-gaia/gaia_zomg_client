package com.gaiaonline.battle.ui.events
{
	import com.gaiaonline.battle.gateway.BattleEvent;
	import com.gaiaonline.battle.gateway.BattleGateway;
	import com.gaiaonline.battle.gateway.BattleMessage;
	import com.gaiaonline.battle.utils.BattleUtils;
	import com.gaiaonline.flexModulesAPIs.globalevent.GlobalEvent;
	import com.gaiaonline.utils.DisplayObjectUtils;
	import com.gaiaonline.utils.FrameTimer;
	
	import flash.display.Stage;
	import flash.events.TimerEvent;
	import flash.system.Capabilities;
	import flash.utils.Timer;
	import flash.utils.getTimer;	
	
	public class StatsCollector
	{
		private static var _instance:StatsCollector = null;

		private var _isStatsCollector:Boolean = false;
		private var _statsCollectionFrequency:Number = NaN; // in milliseconds
		private var _timer:Timer = null;
		
		private var _currentRoom:String = null;
		private var _roomHash:Object = new Object();
		
		private var _lastFrameStartTime:Number = 0;

		private var _gateway:BattleGateway = null;
		private var _stage:Stage = null;
				
		public function StatsCollector(singletonEnforcer:SingletonEnforcer){
			if (singletonEnforcer == null) {
				throw new Error("StatsCollector is a singleton!");
			}
		}
		
		public static function getInstance():StatsCollector {
			if (!_instance) {
				_instance = new StatsCollector(new SingletonEnforcer());
			}
			
			return _instance;
		}
		
		public function set stage(stage:Stage):void {
			this._stage = stage;			
		}
		
		public function set gateway(gateway:BattleGateway):void {
			if (this._gateway) {
				this._gateway.removeEventListener(BattleEvent.START_COLLECTING_STATS, onStatsCollectionStatusUpdate);
			}
			this._gateway = gateway;
			DisplayObjectUtils.addWeakListener(this._gateway, BattleEvent.START_COLLECTING_STATS, onStatsCollectionStatusUpdate);								
			
		}			
		
		private var _enterFrame:FrameTimer = new FrameTimer(onEnterFrame);
		private function onStatsCollectionStatusUpdate(e:BattleEvent):void {		
			var responseObj:Object = e.battleMessage.responseObj;
			if (!responseObj || responseObj.length != 1) {
				return;
			}  		
			var data:Object = responseObj[0];
			if (!data) {
				return;
			}			
			
			if (data.statsCollectionPeriodMsec != null) {
				this._statsCollectionFrequency = data.statsCollectionPeriodMsec;
			}
			
			this._isStatsCollector = !isNaN(this._statsCollectionFrequency) && this._statsCollectionFrequency > 0;				
			
			if (this._isStatsCollector) {
				DisplayObjectUtils.addWeakListener(GlobalEvent.eventDispatcher, GlobalEvent.NEW_ROOM_ENTERED, onNewRoomEntered);
				this._enterFrame.startPerFrame();
				 
				this._timer = new Timer(this._statsCollectionFrequency);
				this._timer.addEventListener(TimerEvent.TIMER, onStatsSendTick);
				this._timer.start();
				
				this.sendOneTimeInfo();
			} else {
				GlobalEvent.eventDispatcher.removeEventListener(GlobalEvent.NEW_ROOM_ENTERED, onNewRoomEntered);
				this._enterFrame.stop();
				 
				this._statsCollectionFrequency = NaN;
				if (this._timer) {
					this._timer.stop();
					this._timer.removeEventListener(TimerEvent.TIMER, onStatsSendTick);
					this._timer = null;
				}
			}
		}

		private function onNewRoomEntered(e:GlobalEvent):void {
			var data:Object = e.data;			
			this._currentRoom = data.newRoomId;
		}								

		private function sendOneTimeInfo():void {
			// this is one time information we send
			var o:Object = {os:Capabilities.os, 
							flashVersion:Capabilities.version, 
							screenResolutionX:Capabilities.screenResolutionX, 
							screenResolutionY:Capabilities.screenResolutionY};
			var msg:BattleMessage = new BattleMessage("clientFlashStats", o);				
			this._gateway.sendMsg(msg);									
		}
				
		private function onStatsSendTick(e:TimerEvent):void {
			if (this._currentRoom == null) {
				return;
			}
			var info:Object = new Object();
			for (var roomId:String in this._roomHash) {
				var bucket:Bucket = this._roomHash[roomId];
				info[roomId] = {ticks:bucket.ticks, 
								frameIntervalSum:bucket.frameIntervalSum,
								frameIntervalSquaredSum:bucket.frameIntervalSquaredSum,
								maxframeInterval:bucket.maxframeInterval};
			}
			var msg:BattleMessage = new BattleMessage("clientPeriodicStats", info);
			this._gateway.sendMsg(msg);
			BattleUtils.cleanObject(this._roomHash);
		}
		
		private function getBucket(roomId:String):Bucket {
			if (!roomId || roomId == "") {
				return null;
			}
			var bucket:Bucket = this._roomHash[roomId];
			if (!bucket) {
				bucket = new Bucket();
				this._roomHash[roomId] = bucket;
			}
			return bucket;
		}
		
		private function onClientTick(currTime:Number):void {
			var roomBucket:Bucket = this.getBucket(this._currentRoom);
			if (roomBucket) {
				roomBucket.addNewframeInterval(currTime);
			}
		}
		
		private function onEnterFrame():void {
			if (this._lastFrameStartTime == 0) {
				this._lastFrameStartTime = getTimer()
			} else {
				var currTime:Number = getTimer();
				onClientTick(currTime - this._lastFrameStartTime);
				this._lastFrameStartTime = currTime; 
			}
		} 
	}
}

class SingletonEnforcer {}

class Bucket {
	private var _ticks:uint = 0;
	private var _frame_interval_sum:Number = 0;
	private var _frame_interval_squared_sum:Number = 0;
	private var _max_frame_interval:Number = 0;
	
	public function Bucket():void {		
	}		
	
	public function addNewframeInterval(newframeInterval:Number):void {
		++this._ticks;
		this._frame_interval_sum += newframeInterval;
		this._frame_interval_squared_sum += Math.pow(newframeInterval, 2);
		this._max_frame_interval = Math.max(this._max_frame_interval, newframeInterval);
	}	
	
	public function get ticks():uint {
		return this._ticks;	
	}
	
	public function get frameIntervalSum():Number {
		return this._frame_interval_sum;	
	}

	public function get frameIntervalSquaredSum():Number {
		return this._frame_interval_squared_sum;	
	}

	public function get maxframeInterval():Number {
		return this._max_frame_interval;	
	}
	
}