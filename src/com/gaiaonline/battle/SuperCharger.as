package com.gaiaonline.battle
{
	import flash.display.Stage;
	import flash.events.Event;
	import flash.utils.getTimer;
	
	public class SuperCharger
	{
		private var frameTimes:Array = [];
		private var totalFrames:uint = Battle.TARGET_FRAME_RATE;
		private var targetFramerate:Number = 0;
		private var stage:Stage = null;
		private var enabled:Boolean = false;
		
		public function SuperCharger(targetFramerate:Number, stage:Stage)
		{
			this.targetFramerate = targetFramerate;
			this.stage = stage;
			stage.addEventListener(Event.ENTER_FRAME, onEnterFrame);
			this.toggle();
		}
		
		private function onEnterFrame(evt:Event):void
		{
			if(!enabled)
			{
				return;
			}
			
			var now:Number = getTimer();
			
			// [bgh] adjust game framerate
			if(totalFrames == frameTimes.length)
			{
				var oldest:Number = frameTimes[0];
				var milliSeconds:Number = (now - oldest);
				var seconds:Number = milliSeconds / 1000;
				var average:Number = Math.round(frameTimes.length / seconds);
				
				if( average < (targetFramerate - 2) )
				{
//					trace("targetFPS:",targetFramerate,"stage.frameRate",stage.frameRate,"average:",average);
					setFrameRate(100);//stage.frameRate + INCREMENT);
				} else if( average > (targetFramerate + 10) )
				{
//					trace("targetFPS:",targetFramerate,"stage.frameRate",stage.frameRate,"average:",average);
					setFrameRate(targetFramerate);//stage.frameRate - INCREMENT);
				}
			}
			
			// [bgh] maintain frame times
			frameTimes.push(now);
			while(totalFrames < frameTimes.length)
			{
				frameTimes.shift();
			}
		}
		
		private function setFrameRate(rate:int):void
		{
			if(stage.frameRate != rate)
			{
				stage.frameRate = rate;
			}
		}
		
		
		public function toggle():void
		{
			enabled = !enabled;
			frameTimes.length = 0;
			stage.frameRate = targetFramerate;
		}
	}
}