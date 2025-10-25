package com.gaiaonline.battle.newactors
{
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.display.MovieClip;
	
	public class HitNumber extends MovieClip
	{
		private var xSpeed:int = 0;
		private var ySpeed:int = 0;
		
		public function HitNumber(){		
			this.ySpeed = -20;
			var min:Number = -10;
			var max:Number = 10;
			this.xSpeed = Math.floor(Math.random() * (max - min + 1)) + min;
			this.addEventListener(Event.ENTER_FRAME, onEnterFrame);	
			
		}
		
		private function onEnterFrame(evt:Event):void{
			
			
			this.x += this.xSpeed;
			this.y += this.ySpeed;
			this.ySpeed += 2;
			
			if (this.ySpeed > 5){
				this.alpha -= 0.1;
			}
			if (this.alpha <= 0){
				if (this.hasEventListener(Event.ENTER_FRAME)){
					this.removeEventListener(Event.ENTER_FRAME, onEnterFrame);	
				}
				if (this.parent != null && this.parent.contains(this)){
					this.parent.removeChild(this);				
				}
			}
				
		}
	}
}