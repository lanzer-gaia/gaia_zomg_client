package com.gaiaonline.battle.newrings
{
	import com.gaiaonline.battle.ApplicationInterfaces.IFileVersionManager;
	import com.gaiaonline.battle.ItemLoadManager.ItemLoadEvent;
	import com.gaiaonline.battle.gateway.BattleEvent;
	import com.gaiaonline.battle.gateway.BattleGateway;
	import com.gaiaonline.battle.gateway.BattleMessage;
	import com.gaiaonline.objectPool.LoaderFactory;
	import com.gaiaonline.utils.DisplayObjectStopper;
	import com.gaiaonline.utils.DisplayObjectStopperModes;
	import com.gaiaonline.utils.DisplayObjectUtils;
	import com.gaiaonline.utils.FrameTimer;
	import com.gaiaonline.utils.factories.ILoaderContextFactory;
	
	import flash.display.Loader;
	import flash.display.LoaderInfo;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.net.URLRequest;
	
	public class RingLoader
	{
		private var _ring:Ring = null;		
		
		
		private var iconLoader:Loader;
		private var swfLoader:Loader;
		private var _loaderContextFactory:ILoaderContextFactory = null;
		private var _fileVersionManager:IFileVersionManager = null;
		private var _baseUrl:String = null;		

		public function RingLoader(baseUrl:String, fileVersionManager:IFileVersionManager, loaderContextFactory:ILoaderContextFactory) {
			this._baseUrl = baseUrl;
			this._fileVersionManager = fileVersionManager;
			this._loaderContextFactory = loaderContextFactory;
		}
		
		// Loaders 
		
		public function createRing(obj:Object,ringId:String):Ring {			
			
			_ring = new Ring(ringId);
			_ring.isFullRing = true;
			_ring.name = obj.ringName;
			
			_ring.description = obj.ringDescription;
			_ring.type = obj.ringType;
			_ring.exhaustion = obj.ringExhaustion;
			_ring.targetType = obj.ringTargets;
			_ring.itemThumbNail = obj.itemThumbNail;
			_ring.timeUsedAtLoadTime = obj.ringRageRechargedSoFar;			
			
			if (_ring.targetType == -1){
				_ring.isPointTarget = true;
			}		
			
			_ring.rage = new Object();				
			if (obj.ringRageArray != null){					
				for (var i:int = 0; i < obj.ringRageArray.length; i++){
					_ring.rage[obj.ringRageArray[i].ringRageLevel] = new Object();
					_ring.rage[obj.ringRageArray[i].ringRageLevel].range = obj.ringRageArray[i].ringRageRank;
					_ring.rage[obj.ringRageArray[i].ringRageLevel].recharge = obj.ringRageArray[i].ringRageRecharge;
					if (obj.ringRageArray[i].ringRageProjectileSpeed != null){
						_ring.rage[obj.ringRageArray[i].ringRageLevel].ProjectileSpeed = obj.ringRageArray[i].ringRageProjectileSpeed;
					}
					
				}
			}			
					
			if(_ring.rage != null && _ring.rage[0] != null && _ring.rage[0].ProjectileSpeed != null){
				_ring.projectileSpeed = _ring.rage[0].ProjectileSpeed;
				_ring.isProjectile = true;
				
			}			
			
			if (_ring.iconUrl == null || !_ring.isIconLoaded){
				_ring.iconUrl = obj.ringIcon;
				_ring.isIconLoaded = false;
			}
			if (_ring.animUrl == null || !_ring.isAnimLoaded){				
				_ring.animUrl = obj.swf;	
				_ring.isAnimLoaded = false;
			}			
															
			// set all Stats fro that level
			if (!_ring.isIconLoaded){				
				LoadIcon(_ring.iconUrl);
				
			}else if ( !_ring.isAnimLoaded && this._ring.type != 0 ){				
				_ring.animUrl = obj.swf;
				this.LoadAnim(_ring.animUrl);				
			}else{
				this.doneLoading();
			}	

			_ring.stats.length = 0;			
			if (obj.ringStatDescriptionsList != null){
				for (var si:int = 0; si < obj.ringStatDescriptionsList.length; si++){							
					_ring.stats.push(obj.ringStatDescriptionsList[si]);
				}					
			}
			
			return _ring;
		}

		// call server to get swf url .. and load ringAnim
		public function loadSimpleRing(gateway:BattleGateway, ring:Ring):void{
			_ring = ring;
			if (null != ring && !_ring.isLoadingAnim){
				_ring.isLoadingAnim = true;
				log("Call to get ring swf : " + _ring.ringId);

				var msg:BattleMessage = new BattleMessage("ringSwf",{rid:_ring.ringId});			
				msg.addEventListener(BattleEvent.CALL_BACK, onSwfUrlCallBack);			
				gateway.sendMsg(msg);
			}
		}

		
		private function log(...args):void{
			var s:String;			
			for (var p:String in args){				
				if (s == null){
					if (args[p] == null){
						s = "null";
					}else{
						s = args[p];
					}
				}else{
					if (args[p] == null){
						s = s = s + ", null";
					}else{
						s = s + "," +String( args[p]);
					}
				} 
			}				
		}
	
		private function onSwfUrlCallBack(evt:BattleEvent):void{
			
		
			if (evt.battleMessage.responseObj.length > 0){
				if (evt.battleMessage.responseObj[0].spd != null){
					_ring.projectileSpeed = evt.battleMessage.responseObj[0].spd;
					_ring.isProjectile = true;
				}			
				
				this.LoadAnim(evt.battleMessage.responseObj[0].swf);
			}
			
			BattleMessage(evt.target).removeEventListener(BattleEvent.CALL_BACK, onSwfUrlCallBack);
			
		}
		
		// Load Icon image --
		private var _callLater:FrameTimer = new FrameTimer(onIconLoaded);
		private var _pendingLoad:Array = []; 
		private function LoadIcon(url:String):void
		{
			_pendingLoad.push(url);
			_callLater.startPerFrame(0, 1);
		}	
	
		private function onIconLoaded():void
		{
			var url:String;
			while (url = _pendingLoad.shift())
			{
				// Set bmIcon
				_ring.bmIcon = RingIconFactory.getBitmap(url);
				_ring.isIconLoaded = true;
				
				// call Load Swf
				if (!_ring.isAnimLoaded && this._ring.type != 0){
					this.LoadAnim(_ring.animUrl);				
				}else{
					this.doneLoading();
				}
			}
		}		
		
		private static function assertOnNull(condition:Object, msg:String):void { if (!condition) throw "[kja] ERROR: " + msg + "null"; }

		//--- Load Swf Anim
		// load the RingAnim -- dispathc event when loaded
		public function LoadAnim(url:String):void{
			this.swfLoader = LoaderFactory.getInstance().checkOut();
			
			// [kja] FS#33525 - we're getting hard-to-replicate stack traces, this extra reporting will help pin down
			// what's failing
			assertOnNull(this.swfLoader, "swfLoader"); 
			assertOnNull(this.swfLoader.contentLoaderInfo, "swfLoader.contentLoaderInfo"); 
			assertOnNull(this._fileVersionManager, "fileVersionManager");
			assertOnNull(this._loaderContextFactory, "loaderContextFactory");

			this.swfLoader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, onAnimIoError);
			this.swfLoader.contentLoaderInfo.addEventListener(IOErrorEvent.NETWORK_ERROR, onAnimIoError);
			this.swfLoader.contentLoaderInfo.addEventListener(IOErrorEvent.VERIFY_ERROR, onAnimIoError);
			this.swfLoader.contentLoaderInfo.addEventListener(IOErrorEvent.DISK_ERROR, onAnimIoError);
			this.swfLoader.contentLoaderInfo.addEventListener(Event.COMPLETE, onAnimLoaded);			
			
			//**** Load Version Neded ***
			var vUrl:String = "?v=" + this._fileVersionManager.getClientVersion("rings/" + url);			
			this.swfLoader.load(new URLRequest(this._baseUrl+ "rings/" + url + vUrl), this._loaderContextFactory.getLoaderContext());
		}
		
		private var _ringGarbageStopper:DisplayObjectStopper = new DisplayObjectStopper(DisplayObjectStopperModes.SHOW_NO_ANIM, true);
		
		private function onAnimLoaded(evt:Event):void{
			// clear odl anim;
			if (_ring.mcAnimRef != null){
				DisplayObjectUtils.ClearAllChildrens(_ring.mcAnimRef);
			}			
									
			// set mcAnimRef
			_ring.mcAnimRef = Sprite(LoaderInfo(evt.target).content);
			_ring.isAnimLoaded = true;
			_ring.isLoadingAnim = false;
			
			//--- Stop all Anim
			DisplayObjectUtils.stopAllMovieClips(_ring.mcAnimRef);
			
			_ringGarbageStopper.addGarbageStopper(_ring.mcAnimRef);
						
			this.swfLoader.contentLoaderInfo.removeEventListener(IOErrorEvent.IO_ERROR, onAnimIoError);
			this.swfLoader.contentLoaderInfo.removeEventListener(IOErrorEvent.NETWORK_ERROR, onAnimIoError);
			this.swfLoader.contentLoaderInfo.removeEventListener(IOErrorEvent.VERIFY_ERROR, onAnimIoError);
			this.swfLoader.contentLoaderInfo.removeEventListener(IOErrorEvent.DISK_ERROR, onAnimIoError);
			this.swfLoader.contentLoaderInfo.removeEventListener(Event.COMPLETE, onAnimLoaded);	
			
			LoaderFactory.getInstance().checkIn(swfLoader);
			swfLoader = null;

			// Dispatch event Loaded			
			this.doneLoading();
		}
		private function onAnimIoError(evt:Event):void{			
			this.doneLoading();
		}
	
		private function doneLoading():void{
			_ring.dispatchEvent(new Event(Ring.LOADED));
			_ring.dispatchEvent(new ItemLoadEvent(ItemLoadEvent.ITEM_LOADED));
			_ring.maintainLoaderReference(null);			
		}
	}
}
