package com.gaiaonline.battle.map
{
	import com.gaiaonline.battle.ConColors;
	import com.gaiaonline.battle.utils.BattleUtils;
	
	import flash.display.DisplayObjectContainer;
	import flash.events.Event;
	import flash.geom.ColorTransform;
	import flash.geom.Point;
	import flash.geom.Transform;
	import flash.utils.getTimer;
	
	public class AwareMonster extends AwareObject
	{
		
		private var _speed:Number = NaN;
		private var _conLevelDiff:Number = NaN;
		private var _conColor:Number = NaN;
		private var _lastMoveTime:int = 0;
		private var _throttler:int = 0;
		private var _conColors:ConColors = null;
		
		public function AwareMonster() {
		}		

		public function initialize(args:Array):void {
			var mapRoomManager:IMapRoomManager = args[0];
			var dir:String = args[1];
			var room:String = args[2];
			super.init(mapRoomManager, dir, room);		
			this.addEventListener(Event.ENTER_FRAME, onEnterFrame, false, 0, true);			
			this._conColors = ConColors.getInstance();			
		}

		private function onEnterFrame(evt:Event):void {			
			if ((++_throttler % 2) == 0) {
				if (!this._myParent) {
					this._myParent = this.parent;					
				}
				// [bgh] calculate where the monster should be now.
				doMove();
				
				// [bgh] calculate what opacity the bubble should be
				_alpha = calculateAlpha();
				
				// [bgh] calculate what scale the bubble should be
				_scale = calculateScale();
				
				drawAwareness();
			}
		}
		
		public function dispose():void {
			this.removeEventListener(Event.ENTER_FRAME, onEnterFrame);			
		}
		
		override public function reset():void {
			_speed = NaN;
			_conLevelDiff = NaN;
			_conColor = NaN;
			_lastMoveTime = 0;
			_myParent  = null;
			_throttler = 0;
			
			this.setVisible(false);						

			super.reset();
			
			this.dispose();
		}
		
		private function doMove():void {
			// [bgh] calculate where the monster should be now.
			if (!isNaN(_speed) && null!=_targetLoc && null!=_serverLoc && !_targetLoc.equals(_serverLoc)) {

				const time:int = getTimer();
				var elapsedMilliSeconds:int = time - _lastMoveTime;
				_lastMoveTime = time;

				var seconds:Number = elapsedMilliSeconds / 1000;
				var movePixels:Number = seconds * _speed;
				var distance:Number = BattleUtils.distanceBetweenPoints(_targetLoc, _serverLoc);

				var percentMoved:Number = Math.min(1, movePixels / distance);
				var currentLoc:Point = Point.interpolate(_targetLoc, _serverLoc, percentMoved);
				setPosition(currentLoc.x, currentLoc.y);
			}
		}
		
		public function setConLevelDiff(conDiff:Number):void {
			if(isNaN(_conLevelDiff) || conDiff != _conLevelDiff) {
				_conLevelDiff = conDiff;
				_conColor = this._conColors.getConColorForDiff(_conLevelDiff);
			}
		}

		// simply saving the previous frame's draw arguments to see if we can skip drawing for this frame
		private var _lastDrawn:Object =
		{
			scale: NaN,
			alpha: NaN,
			color: 0
		};
 	
		private function drawAwareness():void {
			if(!isNaN(_scale) && !isNaN(_alpha) && !isNaN(_conLevelDiff)) {
				if (this._scale > 0 && this._alpha > 0){

					if (this._scale != _lastDrawn.scale) {					
						this.scaleX = this.scaleY = this._scale/2;
						_lastDrawn.scale = this._scale;
					}

					if (this._conColor != _lastDrawn.color || this._alpha != _lastDrawn.alpha) {

						var thisTransform:Transform = this.transform;   // expensive getter, copy to local ref -kja
						var ct:ColorTransform = thisTransform.colorTransform;
						
						ct.color = this._conColor;
						ct.alphaMultiplier = this._alpha;									
						thisTransform.colorTransform = ct;
						
						_lastDrawn.alpha = this._alpha;
						_lastDrawn.color = this._conColor;
				    }

					this.setVisible(true);
				}else{
					this.setVisible(false);
				}
			}
		}
		
		public function setPosition(xPos:Number, yPos:Number):void {
			
			if (_serverLoc == null) {
				_serverLoc = new Point();  // optimization -kja
			}
			
			if (xPos != _serverLoc.x || yPos != _serverLoc.y) {

				_serverLoc.x = xPos;
				_serverLoc.y = yPos;
	
				if(!_playerRoom) {
					_playerRoom = this._mapRoomManager.getCurrentMapRoom();
				}
				
				if(_playerRoom) {
					var pt:Point = _playerRoom.getRoomOffset();
					this.x = (pt.x) + (_drawX || (_serverLoc.x * _playerRoom.scale / 100)) ;
					this.y = (pt.y) + (_drawY || (_serverLoc.y * _playerRoom.scale / 100));
				}
			}
		}
		
		
		public function setSpeed(spd:Number):void {
			this._speed = spd;
		}
		
		public function setDestination(tx:Number, ty:Number):void {
			if (_targetLoc == null) {
				_targetLoc = new Point();
			}
			_targetLoc.x = tx;
			_targetLoc.y = ty;
			_lastMoveTime = getTimer();
		}
	}
}
