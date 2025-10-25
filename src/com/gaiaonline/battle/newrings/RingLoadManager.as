package com.gaiaonline.battle.newrings
{
	import com.gaiaonline.battle.ApplicationInterfaces.IFileVersionManager;
	import com.gaiaonline.battle.gateway.BattleGateway;
	import com.gaiaonline.objectPool.ObjectPool;
	import com.gaiaonline.utils.factories.ILoaderContextFactory;
	
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.utils.Dictionary;
	
	public class RingLoadManager
	{		
		
		private static var ringAnimDic:Dictionary = new Dictionary(true);
		
		private static var rings:Object = new Object();
		
		private static var _loaderContextFactory:ILoaderContextFactory = null;

		private static var _fileVersionManager:IFileVersionManager = null;

		public static function set loaderContextFactory(lcf:ILoaderContextFactory):void {
			_loaderContextFactory = lcf;
		}
		public static function set fileVersionManager(fileVersionManager:IFileVersionManager):void {
			_fileVersionManager = fileVersionManager;
		}
		
		public static function contain(ringId:String):Boolean{
			if (rings[ringId] != null){
				return true;
			}else{
				return false;
			}
		}
		public static function containFull(ringId:String):Boolean{
			if (rings[ringId] != null && Ring(rings[ringId]).isFullRing){
				return true;
			}else{
				return false;
			}
		}
		
		public static function getRing(ringId:String):Ring{
			return rings[ringId];
		}

		// create new ring if it does not exists
		// call load anim on ring -- will dispatch event when done loading
		public static function LoadSimpleRing(baseUrl:String, gateway:BattleGateway, ringId:String, speed:Number = 0):Ring{
			if (rings[ringId] == null){
				rings[ringId] = new Ring(ringId);
				if (speed > 0){
					Ring(rings[ringId]).isProjectile = false;
					Ring(rings[ringId]).projectileSpeed = speed;
				}
			}

			var rl:RingLoader = new RingLoader(baseUrl, RingLoadManager._fileVersionManager, _loaderContextFactory );

			Ring(rings[ringId]).maintainLoaderReference(rl);
			rl.loadSimpleRing(gateway, rings[ringId]);
			return rings[ringId];
		}
		
		public static function createFullRing(baseUrl:String, ringId:String, obj:Object):Ring{			
			if (rings[ringId] == null || !Ring(rings[ringId]).isFullRing ){				
				var rl:RingLoader = new RingLoader(baseUrl, RingLoadManager._fileVersionManager, _loaderContextFactory);
				rings[ringId] = rl.createRing(obj,ringId);
				Ring(rings[ringId]).maintainLoaderReference(rl);
			}
						
			return rings[ringId];
		}
		
		public static function createSimpleRing(ringId:String, ringMc:MovieClip, speed:Number = 0):Ring{
			if (rings[ringId] == null){
				rings[ringId] = new Ring(ringId, ringMc);
				if (speed > 0){
					Ring(rings[ringId]).isProjectile = false;
					Ring(rings[ringId]).projectileSpeed = speed;
				}
			}	
			
			return rings[ringId];
		}
		
		
		public static function checkOutRingAnim(ringId:String, type:String, mcRef:Sprite):RingAnimPoolObj{
			var name:String = ringId+"_"+type;
			if (ringAnimDic[name] == null){
				var factory:RingAnimPoolObj = new RingAnimPoolObj(mcRef, type);
				ringAnimDic[name] = new ObjectPool(factory, factory, factory, 5);				
			}
			var obj:RingAnimPoolObj = ObjectPool(ringAnimDic[name]).checkOut() as RingAnimPoolObj;
			//trace("chekout",name, ObjectPool(ringAnimDic[name]).usedCount, ObjectPool(ringAnimDic[name]).unUsedCount);
			return obj;
			
		}
		
		public static function checkInRingAnim(ringId:String, type:String, obj:RingAnimPoolObj):Boolean{
			var name:String = ringId+"_"+type;
			if (ringAnimDic[name] == null){
				return false;
			}else{				
				var r:Boolean = ObjectPool(ringAnimDic[name]).checkIn(obj);
				//trace("chekin",name, ObjectPool(ringAnimDic[name]).usedCount, ObjectPool(ringAnimDic[name]).unUsedCount);
				return r;
			}
		}
		
		
	}
}