package com.gaiaonline.battle.map
{
	import com.gaiaonline.battle.ApplicationInterfaces.IUIFramework;
	import com.gaiaonline.battle.gateway.BattleEvent;
	import com.gaiaonline.battle.gateway.BattleGateway;
	import com.gaiaonline.battle.newactors.*;
	import com.gaiaonline.flexModulesAPIs.globalevent.GlobalEvent;
	import com.gaiaonline.utils.FrameTimer;
	
	import flash.display.*;
	import flash.events.*;
	import flash.geom.*;
	import flash.utils.*;

	public class DebuggingLayer extends Sprite
	{
		private var targets:Dictionary;
		private var id:int;
		private var room:MapRoom;
		
		private var kLifeTimeMsec:int = 2500;
		
		private var _gateway:BattleGateway = null;
		private var _uiFramework:IUIFramework = null;
		private var _frameTimer:FrameTimer = new FrameTimer(runOnce);
		public function DebuggingLayer(gateway:BattleGateway, uiFramework:IUIFramework)
		{
			super();
			
			this._gateway = gateway;
			this._uiFramework = uiFramework;
			
			graphics.clear();
			
			this._gateway.addEventListener(BattleEvent.DEBUG_DRAW_TARGET, onDebugDrawTarget, false, 0, true);
			GlobalEvent.eventDispatcher.addEventListener(GlobalEvent.PLAYER_CREATED, onPlayerInfo, false, 0, true);
			
			targets = new Dictionary();
			id = 0;

			this._frameTimer.start(250, 1);			
		}
		
		private function onDebugDrawTarget(evt:BattleEvent):void
		{
			var obj:Object = evt.battleMessage.responseObj[0];
			addTarget( obj.px, obj.py, obj.roomName, obj.colorRRGGBB );
		}
		
		private function onPlayerInfo(evt:GlobalEvent):void
		{
			ActorManager.getInstance().myActor.addEventListener(ActorMoveEvent.MOVE, onPlayerMove, false, 0, true);
		}
		
		private function onPlayerMove(evt:ActorMoveEvent):void
		{
			var currentRoom:MapRoom = this._uiFramework.map.getCurrentMapRoom();
			if(currentRoom != room)
			{
				room = currentRoom;
				clearTargets();
			}
		}
		
		private function clearTargets():void
		{
			var tid:String
			for( tid in targets )
			{
				var target:Object = targets[tid];
				removeChild( target.sprite );
				delete target.sprite;
			}
			
			targets = new Dictionary();
		}
				
		private function runOnce():void
		{
			processExistingTargets();
		}
		
		public function processExistingTargets():void
		{
			var now:int = new Date().getTime();
			
			var kept:Dictionary = new Dictionary();
			var tid:String
			for( tid in targets )
			{
				var target:Object = targets[tid];
				if( target.dieTime > now )
				{
					var id:int = target.id;
					kept[id] = target;
					
					var tdiff:int = target.dieTime - now;
					var scale:Number = tdiff / kLifeTimeMsec;
					target.sprite.alpha = scale;
				}
				else
				{
					removeChild( target.sprite );
					delete target.sprite;
				}
			}
			
			targets = kept;
		}
		
		public function addTarget( x:int, y:int, roomID:String, color:int ):void
		{
			var room:MapRoom = this._uiFramework.map.getRoomById( roomID );
			if( room != null )
			{
				x *= (room.scale / 100.0);
				y *= (room.scale / 100.0);

				var offset:Point = room.getRoomOffset();
				x += offset.x;
				y += offset.y;
				
				var radius:int = 10;
				
				var target:Object = new Object();
	
				target.sprite = new Sprite();
				
				target.sprite.graphics.clear();
				target.sprite.graphics.lineStyle( 2, color ); 
				target.sprite.graphics.drawCircle( x, y, radius );
	
				target.sprite.graphics.moveTo( x-radius, y-radius );
				target.sprite.graphics.lineTo( x+radius, y+radius );
	
				target.sprite.graphics.moveTo( x-radius, y+radius );
				target.sprite.graphics.lineTo( x+radius, y-radius )
	
				target.id = id;
				target.dieTime = new Date().getTime() + kLifeTimeMsec;
				
				targets[id] = target;
				id++;
				
				this.addChild( target.sprite );
			}
		}
	}
}