package com.gaiaonline.battle.Loot
{
	import com.gaiaonline.battle.map.TintTypes;
	import com.gaiaonline.flexModulesAPIs.globalevent.GlobalEvent;
	import com.gaiaonline.objectPool.LoaderFactory;
	import com.gaiaonline.platform.actors.ITintable;
	import com.gaiaonline.utils.DisplayObjectStopper;
	import com.gaiaonline.utils.DisplayObjectStopperModes;
	import com.gaiaonline.utils.SpritePositionBubbler;
	import com.gaiaonline.utils.factories.ILoaderContextFactory;
	
	import flash.display.DisplayObject;
	import flash.display.Loader;
	import flash.display.LoaderInfo;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.geom.Point;
	import flash.net.URLRequest;

	public class LootParticle extends SpritePositionBubbler implements ITintable
	{	
		public var value:int = 0;
		private var target:DisplayObject;
		private var phase:int;
		private var mcItem:Sprite;
		private var zSpeed:Number;
		private var angle:Number;
		private var speed:Number;
		private var vx:Number;
		private var vy:Number;
		private var scale:Number;		
		private var assetLoader:Loader; 
		private var _loaderContextFactory:ILoaderContextFactory;
		public var id:String;
		
		private var _garbageStopper:DisplayObjectStopper = new DisplayObjectStopper(DisplayObjectStopperModes.SHOW_NO_ANIM, true);
		
		public function LootParticle(){			
			reset();
			_garbageStopper.addGarbageStopper(this);
		}
		
		public function dropLoot(loaderContextFactory:ILoaderContextFactory, url:String, lootPoint:Point, target:DisplayObject, angle:int = 0, scale:Number = 0.75, value:int = 1, id:String = null):void
		{
			this.value = value;
			this.id = id;
			this._loaderContextFactory = loaderContextFactory;
			this.mcItem = new Sprite();			
			this.addChild(this.mcItem);
			
			this.target = target;
									
			// Scale;
			this.scale = scale;			
			this.scaleX = this.scaleY = (this.scale * 1.3333333);
			//trace(this.scale);
			this.zSpeed = this.zSpeed * this.scale;
			this.speed = this.speed * this.scale;
			
			// adjust angle
			this.angle = (angle+90) * (Math.PI / 180);
				
			// vector x and y;		
			this.vx = this.speed * Math.cos(this.angle);
			this.vy = this.speed * Math.sin(this.angle);		
			
			// start position				
			this.x = lootPoint.x;
			this.y = lootPoint.y;
			
			load(url);
			
			this.addEventListener(Event.ENTER_FRAME, onEnterFrame);
		}
		
		public function setTint(r:int, g:int, b:int):void{
			//nothing for now
		}

		public function getTintType():TintTypes{
			return TintTypes.NONE;
		}
		
		private function onEnterFrame(evt:Event):void{
						
			if (this.phase == 0){				
				// bounce
				this.mcItem.y += this.zSpeed;
				if (this.mcItem.y >= 0){
					if (this.zSpeed > (6*this.scale) ){
						this.zSpeed = -this.zSpeed + (7*this.scale);
					}else{
						this.mcItem.x = 0;
						this.phase = 1;
					}					
				}
				this.zSpeed += (5*this.scale);
				
				// movement
				this.x += this.vx;
				this.y += this.vy;
				
			}else if (this.phase == 1){
				
				// cal dist
				var dx:Number = this.target.x - this.x;
				var dy:Number =  this.target.y - this.y;				
				var dist:Number =  Math.sqrt((dx*dx) + (dy*dy));
				
				if (dist <= this.speed){
					this.x = this.target.x;
					this.y = this.target.y;					
					GlobalEvent.eventDispatcher.dispatchEvent(new GlobalEvent(GlobalEvent.LOOT_PARTICLE_ANIM_DONE, {particle:this}));
				}else{
					var a:Number = Math.atan2(dy, dx);
					this.vx = this.speed * Math.cos(a);
					this.vy = this.speed * Math.sin(a);
					this.x += this.vx;
					this.y += this.vy;
					this.speed = this.speed + (3 * this.scale);
				}
				
			}					
			
		}	
		
				
		private function load(url:String):void{			
			if (url != null){
				assetLoader= LoaderFactory.getInstance().checkOut();
				assetLoader.contentLoaderInfo.addEventListener(Event.COMPLETE, onLoaded);	
				assetLoader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, onIoError);			
				assetLoader.load(new URLRequest(url), this._loaderContextFactory.getLoaderContext());			
			}
		}
		private function onLoaded(evt:Event):void{
			mcItem.addChild(assetLoader.content);
			checkInLoader();
		}		
		private function onIoError(evt:IOErrorEvent):void{
			trace("missing Loot image"+ LoaderInfo(evt.target).loaderURL)
			checkInLoader();
		}
		
		public function destruct():void {
			this.reset();
		}
	
		private function removeEventListenersFromAssetLoader():void
		{
			assetLoader.contentLoaderInfo.removeEventListener(Event.COMPLETE, onLoaded);
			assetLoader.contentLoaderInfo.removeEventListener(IOErrorEvent.IO_ERROR, onIoError);
		}
	
		private function checkInLoader():void
		{
			if(null != assetLoader) {
				removeEventListenersFromAssetLoader();
				LoaderFactory.getInstance().checkIn(assetLoader);
				assetLoader = null;
			}
		}
	
		public function reset():void{			           
			checkInLoader();
			
			if(this.mcItem && this.mcItem.parent == this)
			{
				this.removeChild(this.mcItem);
			}
			this.mcItem = null;
			this._loaderContextFactory = null;			
			this.removeEventListener(Event.ENTER_FRAME, onEnterFrame);
			
			this.target = null;
			this.phase = 0;
			this.zSpeed = -30;
			this.angle = 0;
			this.speed = 4;
			this.vx = 0;
			this.vy = 0;
			this.scale = 100;
			this.value = 0;
		}
	}
}