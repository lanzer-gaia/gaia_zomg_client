package com.gaiaonline.battle.particles
{
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.events.TimerEvent;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.Dictionary;
	import flash.utils.Timer;

	public class ParticleEmitter extends MovieClip
	{
		
		public var particlesPerTick:int = 1;
				
		public var particleMaxLiveTime:int = 2000;
		public var particleMinLiveTime:int = 2500;
		public var particleFadeOutTime:int = -1;		
		public var particleAngleRange:Number = 0;
		public var particleMaxDist:int = 100; 
		public var particleMinDist:int = 150;		
		public var particleMinScale:Number = 1;
		public var particleMaxScale:Number = 1;		
		public var particleEasing:Number = 0.2;
		public var motionBlur:Number = 1;
		public var singlePointSpawn:Boolean = false;
		
		private var _mcRef:MovieClip;
		private var _xRadiusMin:Number = 0;
		private var _yRadiusMin:Number = 0;
		private var _xRadiusMax:Number = 0;
		private var _yRadiusMax:Number = 0;
		private var _rotationSpeedMin:Number = 0;
		private var _rotationSpeedMax:Number = 0;
		private var _rotationAceleration:Number = 0;
		private var _xRadiusChange:Number = 0;
		private var _yRadiusChange:Number = 0;
				
			
		private var partClass:Class;
		private var _particles:Dictionary = new Dictionary(true);
		private var _timer:Timer;
						
		public function ParticleEmitter()
		{
			this.visible = false;
			this.addEventListener(Event.REMOVED_FROM_STAGE, onRemovedFromStage);
			super();
		}
				
		public function setParticle(mc:MovieClip):void{
			this.partClass = mc["constructor"];
		}
		public function startEmitter(rate:int = 100):void{
			this.stopEmitter();
			this._timer = new Timer(rate);
			this._timer.addEventListener(TimerEvent.TIMER, onTimer);
			this._timer.start();
		}
		public function stopEmitter():void{
			if (this._timer != null && this._timer.running){
				this._timer.stop();
			}
		}
		
		private static var s_startPoint:Point = new Point(NaN, NaN);
		public function onTimer(evt:Event):void{
			if (this.parent != null){				
				for (var i:int = 0; i < this.particlesPerTick; i++){
					var dist:Number = this.getRandom(this.particleMinDist, this.particleMaxDist);
					var time:Number = this.getRandom(this.particleMinLiveTime, this.particleMaxLiveTime);
					var minAng:Number = this.rotation -(this.particleAngleRange/2);
					var maxAng:Number = this.rotation + (this.particleAngleRange/2);
					var ang:Number = this.getRandom(minAng, maxAng);
				
					s_startPoint.x = this.x;
					s_startPoint.y = this.y;					
					if (!this.singlePointSpawn){
						var rect:Rectangle = this.getBounds(this.parent);
						var px:Number = this.getRandom(rect.left, rect.right);
						var py:Number = this.getRandom(rect.top, rect.bottom);
						s_startPoint.x = px;
						s_startPoint.y = py;
					}			
										
					var p:Particle = new Particle(this, new partClass(), s_startPoint.x, s_startPoint.y, dist, time, this.particleFadeOutTime, ang-90, this.particleEasing);
					p._xTargetRadius = this.getRandom(this._xRadiusMin, this._xRadiusMax);
					p._yTargetRadius = this.getRandom(this._yRadiusMin, this._yRadiusMax);
					p._targetRotationSpeed = this.getRandom(this._rotationSpeedMin, this._rotationSpeedMax, true);
					p._rotationAceleration = this._rotationAceleration;
					p._xRadiusChange = this._xRadiusChange;
					p._yRadiusChange = this._yRadiusChange;
					p._motionBlur = this.motionBlur;
					p.scaleX = p.scaleY = this.getRandom(this.particleMinScale, this.particleMaxScale);
					p.alpha = this.alpha;																			
					this._particles[p] = p;
					p.addEventListener(Particle.DONE, onParticleDone);
					this.parent.addChild(p);								
				}				
			}	
			//this._timer.stop();
		}
		
		private function onParticleDone(evt:Event):void{
			if (this._particles != null && evt.target is Particle && this._particles[evt.target] != null){				
				delete this._particles[evt.target];
			}
		}
		private function getRandom(min:Number, max:Number, negativeRandom:Boolean = false):Number{
			var r:Number = (Math.random() * (max-min)) + min;
			if (negativeRandom){
				if ( (Math.random()*100) < 50 ){
					r = r * -1;
				}
			}
			return r;
		}
		
		public function startParticlesRotation(xRadiusMin:Number, xRadiusMax:Number, yRadiusMin:Number, yRadiusMax:Number, speedMin:Number, speedMax:Number, aceleration:Number = 0, xRadiusChange:Number = 0, yRadiusChange:Number = 0):void{
			if (this._particles != null){
				this._xRadiusMin = xRadiusMin;
				this._xRadiusMax = xRadiusMax;
				this._yRadiusMin = yRadiusMin; 
				this._yRadiusMax = yRadiusMax;
				this._rotationSpeedMin = speedMin;
				this._rotationSpeedMax = speedMax;
				this._rotationAceleration = aceleration;
				this._xRadiusChange = xRadiusChange;
				this._yRadiusChange = yRadiusChange;
				
				for each (var p:Particle in this._particles){
					p._xTargetRadius = this.getRandom(this._xRadiusMin, this._xRadiusMax);
					p._yTargetRadius = this.getRandom(this._yRadiusMin, this._yRadiusMax);
					p._targetRotationSpeed = this.getRandom(this._rotationSpeedMin, this._rotationSpeedMax, true);
					p._rotationAceleration = this._rotationAceleration;
					p._xRadiusChange = this._xRadiusChange;
					p._yRadiusChange = this._yRadiusChange;
				}
			}
		}
		
		public function stopParticlesRotation():void{
			this._rotationSpeedMin = 0;
			this._rotationSpeedMax = 0;
			this._rotationAceleration = 0;
			this._xRadiusChange = 0;
			this._yRadiusChange = 0;
			
			for each (var p:Particle in this._particles){			
				p._targetRotationSpeed = 0
				p._rotationAceleration = 0;
				p._xRadiusChange = 0;
				p._yRadiusChange = 0;
			}
		}
										
		public function onRemovedFromStage(evt:Event):void{	
			this.stopEmitter();
			if (this._particles != null){
				for (var i:int = 0; i < this._particles.length; i++){
					var p:Particle = Particle(this._particles[i]);				
					p.dispose();
				}
			}
			this._particles = null;
			
			this._mcRef = null;
			this.partClass = null;
			this._timer = null;
			
		}
		
	}
}