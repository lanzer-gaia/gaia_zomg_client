package com.gaiaonline.battle.map
{
	import com.gaiaonline.flexModulesAPIs.globalevent.GlobalEvent;
	import com.gaiaonline.utils.DisplayObjectUtils;
	import com.gaiaonline.utils.FrameTimer;
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.geom.Point;
	import flash.utils.getTimer;
	
	public class MapMover extends EventDispatcher
	{
		public static const MAP_SLIDE_DONE:String = "mapMover_map_slide_done";
		
		private var _mapSliding:Boolean = false;
		private var mapTx:Number = 0;
		private var mapTy:Number = 0;
		private var _slideDist:Number = 500;
		private var _slideSpeed:Number = 250; // speed of slide in millisec
		
		private var _frameTimer:FrameTimer = null;
		
		private var mapX:Number = 0;
		private var mapY:Number = 0;
		
		private var _map:Map = null;
		private var _time:int = 0;
		
		//this might not stay here, but MapMover is the only thing that uses it.
		private var environment:Environment = null;;
		
		public function MapMover(map:Map){
			
			_map = map;
			_frameTimer = new FrameTimer(onEnterFrame);
			_frameTimer.startPerFrame();

			environment = new Environment(map);
			DisplayObjectUtils.addWeakListener(GlobalEvent.eventDispatcher, GlobalEvent.ENVIRONMENT_OFFSET_CHANGED, onEnvironmentOffsetChanged);
		}

		public function get mapSliding():Boolean{
			return _mapSliding;
		}

		public function slideToRoom(room:MapRoom):void{
			this._mapSliding = true;
			this.mapTx = -(room.layoutPos.x * 780);
			this.mapTy = -(room.layoutPos.y * 505);
			var dx:Number = this.mapTx - this.mapX;
			var dy:Number = this.mapTy - this.mapY;
			this._slideDist	= Math.sqrt(dx*dx + dy*dy);
			
			this.updatePos();
		}

		public function moveToRoom(room:MapRoom):void{
			var p:Point = new Point( room.layoutPos.x * 780, room.layoutPos.y * 505 );			
			this.mapX = -p.x;
			this.mapY = -p.y;			
			this.mapTx = -p.x;
			this.mapTy = -p.y;
			updatePos();
		}

		private function onEnterFrame():void{
			
			const currTimer:int = getTimer(); 	
			const dt:int = currTimer - this._time;
			this._time = currTimer;
			
			
			const dx:Number = this.mapTx - this.mapX;
			const dy:Number = this.mapTy - this.mapY;
			const dist:Number = Math.sqrt(dx*dx + dy*dy);
			const speed:Number = this._slideDist * (dt/this._slideSpeed);
			
			if (dist >= speed){					
				var angle:Number = Math.atan2(dy, dx);
				var vx:Number = speed * Math.cos(angle);
				var vy:Number = speed * Math.sin(angle);
				this.mapX += vx;
				this.mapY += vy;
				this.updatePos();
			}
			else if(this._mapSliding){
															
				this.mapX = this.mapTx;
				this.mapY = this.mapTy;					
				this.updatePos();						
				
				this._mapSliding = false;
				dispatchEvent(new Event(MAP_SLIDE_DONE));
			}
		}
		
		
		private function updatePos():void{						
			var nx:Number = Math.round(this.mapX * _map.scaleX);
			var ny:Number = Math.round(this.mapY * _map.scaleY);

			_map.x = nx + environment.offset.x;
			_map.y = ny + environment.offset.y;
		}

		private function onEnvironmentOffsetChanged(e:GlobalEvent):void {
			updatePos();									
		}

	}
}