package com.gaiaonline.battle.map
{
		
	import flash.display.DisplayObject;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.TimerEvent;
	import flash.filters.DisplacementMapFilter;
	import flash.geom.ColorTransform;
	import flash.utils.Timer;
	import fl.motion.Color;
	
	public class TintUpdate extends EventDispatcher
	{	
		public var name:String = "";	
		private var mc:DisplayObject;
		private var rate:int;
		private var interval:int;
				
		private var targetColor:ColorTransform;		
		private var originalColor:ColorTransform;				
		
		private var perRate:Number = 0;
		private var per:Number = 0;
		private var timer:Timer;
				
		public function TintUpdate(mc:DisplayObject, rate:int, interval:int){
						
			this.mc = mc;			
			this.rate = rate;
			this.interval = interval;
			this.timer = new Timer(this.interval);
			this.timer.addEventListener(TimerEvent.TIMER, onTimer, false, 0, true);
			
		}
		
		public function updateTint(r:int, g:int, b:int, per:int = 100):void{
					
			var a:int = (per/100) * 255;
			if (this.targetColor != null && this.targetColor.redOffset == r && this.targetColor.greenOffset == g && this.targetColor.blueOffset == b && this.targetColor.alphaOffset == a){
				return;
			}
			
				
			this.targetColor = new ColorTransform(0,0,0,0,r,g,b,a);
			this.originalColor = this.mc.transform.colorTransform;		
						
				
			if (this.targetColor.color != this.originalColor.color || this.targetColor.alphaOffset != this.originalColor.alphaOffset){				
					
				// get the new target color
				var c:ColorTransform = Color.interpolateTransform(this.originalColor, this.targetColor,per/100);
																
				var na:int = (per/100) * 255;
				var nr:int = c.redOffset;
				var ng:int = c.greenOffset;
				var nb:int = c.blueOffset;
							
								
				// get the current color
				var ca:int = this.originalColor.alphaOffset;
				var cr:int = this.originalColor.redOffset;
				var cg:int = this.originalColor.greenOffset;
				var cb:int = this.originalColor.blueOffset;
								
				var dif:int = Math.max(Math.abs(ca-na), Math.abs(cr-nr),Math.abs(cg-ng),Math.abs(cb-nb));
				
									
				if (dif > 0 ){
					var t:Number = (dif*this.rate)/255
					this.perRate = 100/(t/this.interval);
					this.per = 0;
					this.timer.stop();									
					this.timer.start();
					this.update();
				}else{
					this.mc.transform.colorTransform = this.targetColor;
					this.dispatchEvent(new Event("TINT_UPDATE"));		
				}	
				
											
			}
					
		}	
	
		public function setTint(r:int, g:int, b:int, per:Number):void{
			var a:int = (per/100) * 255;
			this.targetColor = new ColorTransform(0,0,0,0,r,g,b,a);	
			this.per = 100;
			this.mc.transform.colorTransform = this.targetColor;
			this.dispatchEvent(new Event("TINT_UPDATE"));		
		}
				
		private function onTimer(evt:TimerEvent):void{
			this.update();
		}
		
		private function update():void{
			this.per += this.perRate;			
			if (this.per >= 100){				
				this.mc.transform.colorTransform = this.targetColor;
				this.timer.stop();
			}else{
				this.mc.transform.colorTransform = Color.interpolateTransform(this.originalColor, this.targetColor, this.per/100);				
			}	
			this.dispatchEvent(new Event("TINT_UPDATE"));
		}
				
				
	}
}