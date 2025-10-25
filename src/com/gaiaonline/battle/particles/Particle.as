package com.gaiaonline.battle.particles
{
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.filters.BlurFilter;
	import flash.utils.getTimer;

	public class Particle extends Sprite
	{		
		public static const DONE:String = "Done";
		private var _mc:MovieClip;
		private var _emitter:ParticleEmitter;
		private var _ang:Number = 0; 
		private var _time:int = 0;
		private var _fadeTime:int = -1;
		private var _easing:Number = 0;
				
		private var _dist:Number = 0;
		private var _startTime:int = 0;
		private var _startPointX:Number = 0;
		private var _startPointY:Number = 0;
		
		private var _rotationAng:Number = -90;
		private var _xRadius:Number = 0;
		private var _yRadius:Number = 0;
		private var _rotationSpeed:Number = 0;
		public var _xTargetRadius:Number = 0;
		public var _yTargetRadius:Number = 0;
		public var _targetRotationSpeed:Number = 0;
		public var _rotationAceleration:Number = 0;
		public var _xRadiusChange:Number = 0;
		public var _yRadiusChange:Number = 0;
		public var _motionBlur:Number = 1;
						
		public function Particle(emitter:ParticleEmitter, mc:MovieClip, startPointX:Number, startPointY:Number, dist:int, time:int, fadeTime:int = -1, ang:Number = 0, easing:Number = 0)
		{	
			this._mc = mc;			
			this._emitter = emitter;			
			this.addChild(mc);		
			this._time = time;
			this._fadeTime = fadeTime;
			this._ang = ang;
			this._easing = easing;			
			this._dist = dist;
		
			this._startPointX = startPointX;
			this._startPointY = startPointY;	
			this.x = this._startPointX;
			this.y = this._startPointY;
			this.alpha = this._emitter.alpha;
			
			this._startTime = getTimer();
			this.addEventListener(Event.ENTER_FRAME, onFrame);
			super();
		}
		
		private function onFrame(evt:Event):void{
			var lx:Number = this.x;
			var ly:Number = this.y;
			
			var totaltime:int = getTimer() - this._startTime;
			var perTime:Number = totaltime/this._time;			
			var dDist:Number = this._dist * Math.pow(perTime, this._easing);
			var dx:Number = (Math.cos(this._ang * (Math.PI/180)) * dDist) + this._startPointX;
			var dy:Number = (Math.sin(this._ang * (Math.PI/180)) * dDist) + this._startPointY;
									
			this._rotationAng += this._rotationSpeed;
			this.x = dx + (Math.cos(this._rotationAng * (Math.PI/180))* this._xRadius);
			this.y = dy + (Math.sin(this._rotationAng * (Math.PI/180))* this._yRadius);
			
			
			var speedDir:int = 1;
			if (this._targetRotationSpeed < 0){
				speedDir = -1;
			}
			this._targetRotationSpeed += (this._rotationAceleration * speedDir);
			
			if (this._targetRotationSpeed != this._rotationSpeed){
				this._rotationSpeed += (this._targetRotationSpeed - this._rotationSpeed) ;				
			}			
			
			if (this._xTargetRadius > 0){
				this._xTargetRadius += this._xRadiusChange;
			}else{
				this._xTargetRadius = 0;
			}
			if (this._yTargetRadius > 0){
				this._yTargetRadius += this._yRadiusChange;
			}else{
				this._yTargetRadius = 0;
			} 
			
			
			if (Math.abs(this._xRadius) != Math.abs(this._xTargetRadius)){				
				this._xRadius += (this._xTargetRadius - this._xRadius) * 0.3;				
			}
			if (Math.abs(this._yRadius) != Math.abs(this._yTargetRadius)){
				this._yRadius += (this._yTargetRadius - this._yRadius) * 0.3;				
			}
						
			var vx:Number = lx-this.x;
			var vy:Number = ly-this.y;
			this.rotation = Math.atan2(vy, vx) * (180/Math.PI) - 90;
			var d:Number = Math.sqrt(vx*vx + vy*vy);
			this.filters = [new BlurFilter(vx*this._motionBlur,vy*this._motionBlur,1)];
							
			if (this._fadeTime >= 0 && (this._time - this._fadeTime) < totaltime){
				var eAlpha:Number = 1;
				if (this._emitter != null){
						eAlpha = this._emitter.alpha;
				}				
				this.alpha = ( (this._time - totaltime) /this._fadeTime) * eAlpha;					
			}else if (this._emitter != null){							
				this.alpha = this._emitter.alpha;
			}
			if (this.alpha <= 0){
				this.alpha = 0;
				this.dispose();
			}
						
			
		}	
		
		public function dispose():void{
			this.removeEventListener(Event.ENTER_FRAME, onFrame);
			this._emitter = null;
			this._mc = null;
			if (this.parent != null){
				this.parent.removeChild(this);				
			}
			this.dispatchEvent(new Event(DONE));
						
		} 
		
	}
}