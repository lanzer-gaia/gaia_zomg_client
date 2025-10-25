package com.gaiaonline.battle.ui
{
	import com.gaiaonline.battle.ApplicationInterfaces.IUIFramework;
	import com.gaiaonline.battle.gateway.BattleEvent;
	import com.gaiaonline.battle.gateway.BattleGateway;
	import com.gaiaonline.battle.gateway.BattleMessage;
	import com.gaiaonline.battle.map.IMap;
	import com.gaiaonline.battle.utils.NumericRasterTextField;
	import com.gaiaonline.flexModulesAPIs.gatewayInterfaces.IBattleMessage;
	import com.gaiaonline.flexModulesAPIs.globalevent.GlobalEvent;
	import com.gaiaonline.utils.DisplayObjectUtils;
	import com.gaiaonline.utils.FrameTimer;
	
	import flash.display.SimpleButton;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.system.System;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;
	import flash.utils.getTimer;
	
	import it.gotoandplay.smartfoxserver.SocketStats;
	
	public class FrameRate extends Sprite
	{
		private var txtFPS:NumericRasterTextField;
		private var txtTotalMemory:NumericRasterTextField;
		private var txtTotalMemoryDelta:NumericRasterTextField;

		private var txtWrites:NumericRasterTextField;
		private var txtBytesWritten:NumericRasterTextField;
		private var txtReads:NumericRasterTextField;
		private var txtBytesRead:NumericRasterTextField;

		private var txtMx:NumericRasterTextField;
		private var txtMy:NumericRasterTextField;
		private var txtRoom:TextField;
		private var txtServerVer:TextField;
		private var txtClientVer:TextField;		
		
		private var _frameCount:int = 0;
		private var _fpsStartTime:int = 0;
		private var _fpsAutoUpdate:Boolean = true;
			
		private var btn:SimpleButton;
		
		public var mx:Number = 0;
		public var my:Number = 0;		
		
		private static const FIELD_LEFT:Number = 10;
		private static const FIELD_HEIGHT:Number = 15;

		private var _map:IMap;
		private var _socketStats:SocketStats;
        private var _bg:BattleGateway;		
		
		private var _frameTimer:FrameTimer = new FrameTimer(enterFrameListener);

		//
		// Pass in null for SocketStats to turn off its display
		public function FrameRate(uiFramework:IUIFramework, gateway:BattleGateway, showNetworkStats:Boolean)
		{
			_map = uiFramework.map;
            _bg = gateway;			

			if (showNetworkStats)
			{
				_socketStats = gateway.socketStats;
			}

			this.tabEnabled = false;
			this.tabChildren = false;
			
			var format:TextFormat = new TextFormat();
		    format.font = "myArial";
		    format.size = 12;
		    format.color = 0xFFFFFF;
	
			var currentY:Number = 5;
			this.txtFPS = new NumericRasterTextField();		
			this.txtFPS.x = FIELD_LEFT;
			this.txtFPS.y = currentY;
			this.txtFPS.suffix = " fps";
			this.addChild(this.txtFPS);			
			
			currentY += FIELD_HEIGHT;

			this.txtTotalMemory = new NumericRasterTextField();		
			this.txtTotalMemory.x = FIELD_LEFT;
			this.txtTotalMemory.y = currentY;
			this.txtTotalMemory.suffix = " KB";	
			this.txtTotalMemory.showThousandsSeparator = true;
			this.addChild(this.txtTotalMemory);	
						
			currentY += FIELD_HEIGHT;

			this.txtTotalMemoryDelta = new NumericRasterTextField();		
			this.txtTotalMemoryDelta.x = 15;
			this.txtTotalMemoryDelta.y = currentY;
			this.txtTotalMemoryDelta.suffix = " KB";
			this.txtTotalMemoryDelta.showSign = true;	
			this.txtTotalMemoryDelta.showThousandsSeparator = true;
			this.addChild(this.txtTotalMemoryDelta);	

			currentY += FIELD_HEIGHT;

			if (_socketStats)
			{
				this.txtReads = new NumericRasterTextField();
				this.txtReads.x = FIELD_LEFT;
				this.txtReads.y = currentY;
				this.txtReads.suffix = "dn";
				this.addChild(this.txtReads);
	
				this.txtBytesRead = new NumericRasterTextField();
				this.txtBytesRead.x = FIELD_LEFT + 40;
				this.txtBytesRead.y = currentY;
				this.txtBytesRead.suffix = "b";
				this.txtBytesRead.showThousandsSeparator = true;
				this.addChild(this.txtBytesRead);
				
				currentY += FIELD_HEIGHT;
	
				this.txtWrites = new NumericRasterTextField();
				this.txtWrites.x = FIELD_LEFT;
				this.txtWrites.y = currentY;
				this.txtWrites.suffix = "up";
				this.addChild(this.txtWrites);
	
				this.txtBytesWritten = new NumericRasterTextField();
				this.txtBytesWritten.x = FIELD_LEFT + 40;
				this.txtBytesWritten.y = currentY;
				this.txtBytesWritten.suffix = "b";
				this.txtBytesWritten.showThousandsSeparator = true;
				this.addChild(this.txtBytesWritten);
				
				currentY += FIELD_HEIGHT;
			}

			this.txtMx = new NumericRasterTextField();		
			this.txtMx.x = FIELD_LEFT;
			this.txtMx.y = currentY;
			this.txtMx.suffix = "x";	
			this.addChild(this.txtMx);	
			
			this.txtMy = new NumericRasterTextField();		
			this.txtMy.x = 55;
			this.txtMy.y = currentY;
			this.txtMy.suffix = "y";
			this.addChild(this.txtMy);	
			
			currentY += FIELD_HEIGHT;

			this.txtRoom = new TextField();
			this.txtRoom.embedFonts = true;
			this.txtRoom.autoSize = TextFieldAutoSize.LEFT;
			this.txtRoom.defaultTextFormat = format;			
			this.txtRoom.x = FIELD_LEFT;
			this.txtRoom.y = currentY;	
			this.addChild(this.txtRoom);			
			
			currentY += FIELD_HEIGHT;
			
			this.txtServerVer = new TextField();
			this.txtServerVer.embedFonts = true;
			this.txtServerVer.autoSize = TextFieldAutoSize.LEFT;
			this.txtServerVer.defaultTextFormat = format;
			this.txtServerVer.x = FIELD_LEFT;
			this.txtServerVer.y = currentY;			
			this.addChild(this.txtServerVer);

			currentY += FIELD_HEIGHT;

			this.txtClientVer = new TextField();
			this.txtClientVer.embedFonts = true;
			this.txtClientVer.autoSize = TextFieldAutoSize.LEFT;
			this.txtClientVer.defaultTextFormat = format;
			this.txtClientVer.x = FIELD_LEFT;
			this.txtClientVer.y = currentY;			
			this.addChild(this.txtClientVer);
			
			
			var box:Sprite = new Sprite();
			box.graphics.beginFill(0x00FFFF);
			box.graphics.drawRect(0,0,30,18);
			box.graphics.endFill();
			
			var box2:Sprite = new Sprite();
			box2.graphics.beginFill(0xFF0000);
			box2.graphics.drawRect(0,0,30,18);
			box2.graphics.endFill();
			
			this.btn = new SimpleButton(box,box,box2,box2);
			this.addChild(this.btn);
			this.btn.addEventListener(MouseEvent.CLICK, onBtnClick);	
			this.btn.y = 20;
			this.btn.x = 100;
//			uiFramework.tooltipManager.addToolTip(this.btn, "default: gc\nSHIFT: toggle per frame updates\nCTRL: stopAllMovieClips(stage)\nALT: traceDisplayList(stage)");
			uiFramework.tooltipManager.addToolTip(this.btn, "default: gc\nSHIFT: toggle per frame updates\nCTRL: Stop all object on the stage\nALT: traceDisplayList(stage)");
						
			this._frameTimer.startPerFrame();
			this.starFpsCount();
			
			GlobalEvent.eventDispatcher.addEventListener(GlobalEvent.FPS_MONITORING_STATE_CHANGED, onFPSMonitoringStateChange);
		}	

		private var tests:Array =
		[
			function():void
			{
				var msg:BattleMessage = new BattleMessage(BattleEvent.SHOP_INFO, {});
				_bg.sendMsg(msg);
			},
			function():void
			{
				var msg:BattleMessage = new BattleMessage(BattleEvent.GET_NONCE, { });
				_bg.sendMsg(msg);
			},
			function():void
			{
				var msg:BattleMessage = new BattleMessage("buyStoreItem", { nonce: _nonce, itemId: 18032 });
				_bg.sendMsg(msg);
			},
		];

		private function onStoreTestResult(be:BattleEvent):void
		{
			const bmsg:IBattleMessage = be.getBattleMessage();
			switch(be.type) {
			case BattleEvent.SHOP_INFO:
				var storeInfo:Array = bmsg.responseObj[0].storeInfo;
				for (var si:String in storeInfo)
				{
					trace("Store Item:");
					for (var key:String in storeInfo[si])
					{
						trace(" |- " + key + ": " + storeInfo[si][key]);
					} 
				}
				break;
			case BattleEvent.GET_NONCE:
				_nonce = bmsg.responseObj[0].nonce;
				trace("Nonce: " + _nonce);
				break;
			case BattleEvent.BUY_STORE_ITEM:
				trace("buy response " + bmsg.responseObj[0].buyResponse);
				break;
			}
		}

		private var _iTest:uint = 0;
		private var _nonce:String;
		private function nextStoreTest():void
		{
			tests[_iTest++ % tests.length]();
			
			_bg.addEventListener(BattleEvent.SHOP_INFO, onStoreTestResult, false, 0, true);
			_bg.addEventListener(BattleEvent.GET_NONCE, onStoreTestResult, false, 0, true);
			_bg.addEventListener(BattleEvent.BUY_STORE_ITEM, onStoreTestResult, false, 0, true);
		}

		private function onBtnClick(evt:MouseEvent):void{

			if (evt.shiftKey) {
				// toggle the enterframe
				if (this._frameTimer.running)
				{
					this._frameTimer.stop();
				}
				else
				{
					this._frameTimer.startPerFrame();
				}
			}
			else if (evt.ctrlKey && evt.altKey) {
				nextStoreTest();
			}
			else if (evt.ctrlKey) {
				DisplayObjectUtils.stopAllMovieClips(stage);
			}
			else if (evt.altKey) {
				DisplayObjectUtils.traceDisplayList(stage);
			}
			else {
				enterFrameListener();

				var fn:Function = System["gc"] as Function;
				if (fn != null) {
					fn();
				}
			}
		}
		
		private var _lastRender:int = 0;
		private var _lastTotalMemoryKB:int = 0;
		private var _lastRoom:String;
		private function enterFrameListener():void
		{
			++this._frameCount;

			const totalMemoryKB:int = System.totalMemory/1024;
			this.txtTotalMemory.integer = totalMemoryKB; 
			this.txtMx.integer = this.mx;			
			this.txtMy.integer = this.my;
			
			if (_map && _map.isMapLoaded()){
				if (_map.getCurrentMapRoom() != null){
					if (_lastRoom != _map.getCurrentMapRoom().serverRoomId) {
						_lastRoom = _map.getCurrentMapRoom().serverRoomId;
						this.txtRoom.text = _lastRoom;
					}
				}
			}

			const time:int = getTimer();
			const periodRender:Boolean = (time - _lastRender) > 2000;
			if (periodRender) {			
				_lastRender = time;
				this.txtTotalMemoryDelta.integer = totalMemoryKB - _lastTotalMemoryKB;
				_lastTotalMemoryKB = totalMemoryKB;

				if (_socketStats)
				{
					this.txtReads.integer = _socketStats.reads;
					this.txtWrites.integer = _socketStats.writes;
					this.txtBytesRead.integer = _socketStats.bytesRead;
					this.txtBytesWritten.integer = _socketStats.bytesWritten;
					
					_socketStats.clear();
				}
			}
		}	
		
		public function setServerVer(v:String):void{
			this.txtServerVer.text = "server: " + v;
		}
		
		public function setClientVer(v:String):void{
			this.txtClientVer.text = "client: " + v;
		}

		private function onFPSMonitoringStateChange(e:GlobalEvent):void {
			var data:Object = e.data;
			
			if (data.on) {
				this.starFpsCount(data.autoUpdate);
			} else {
				this.stopFpsCount();
			}
		}
		private var _fpsTimer:FrameTimer = new FrameTimer(onFpsTimer);

		public function starFpsCount(autoUpdate:Boolean = true, time:int = 500):void{
			this._fpsAutoUpdate = autoUpdate;
			this._fpsStartTime = getTimer();
			this._frameCount = 0;
			if (this._fpsAutoUpdate){
				this._fpsTimer.start(time);
			}
		}
		public function stopFpsCount():int{
			const now:int = getTimer();

			const dt:Number = (now - this._fpsStartTime)/1000;
			const fps:Number = this._frameCount/dt;
			this.txtFPS.integer = fps;	
			
			this._fpsStartTime = now;
			this._frameCount = 0;
			return fps;
		}
		private function onFpsTimer():void{
			this.stopFpsCount();			
			
			if (!this._fpsAutoUpdate){
				this._fpsTimer.stop();
			}
		}
	}
}
