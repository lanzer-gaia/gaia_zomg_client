package com.gaiaonline.battle.newrings
{
	// [kja] I've incurred some debt in checking this in - it needs to be refactored to:
	// 1) have instances - nothing about this requires it to really be a singleton
	// 2) be split into two classes, one that knows how to do the embedded loadbytes trick, the other
	//    manages just the resources (and that other could potentially just be AssetFactory)
	// 3) remove some of the now unnecessary loading classes and asynchronous steps in ring/buff
	//    image loading.  It was all done quickly to have minimal impact, and it didn't complicate the
	//    code any - but it could be greatly refactored down to something smaller and simpler
	import com.gaiaonline.utils.DisplayObjectUtils;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Loader;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	
	public class RingIconFactory
	{
		[Embed("../../../../../bin/rings/icons/iconAssets.swf",mimeType='application/octet-stream')]
		private static var embeddedClass:Class;

		private static var loader:Loader;
		private static var _eventDispatcher:EventDispatcher;
		private static var calledInit:Boolean = false;
		// unfortunately, this doesn't trigger until the class is accessed:
		RingIconFactory.init();
		
		public static function init():void {
			if (calledInit) { return; }
			loader = new Loader();
			loader.contentLoaderInfo.addEventListener(Event.INIT,handleLoaderInit);
			loader.loadBytes(new embeddedClass());
			_eventDispatcher = new EventDispatcher();
			calledInit = true;
		}
		
		private static function handleLoaderInit(p_evt:Event):void {
			loader.contentLoaderInfo.removeEventListener(Event.INIT,handleLoaderInit);
			_eventDispatcher.dispatchEvent(new Event(Event.INIT));
		}
		
		public static function get eventDispatcher():EventDispatcher {
			return _eventDispatcher;
		}
		
		public static function get inited():Boolean {
			return (loader.content != null);
		}

		private static var _bitmapDatas:Object = {};
		public static function getBitmap(name:String):Bitmap
		{
			if (!_bitmapDatas[name])
			{
				var BitmapDataSubClass:Class = getDefinition(name);
				if (!BitmapDataSubClass)
				{
					BitmapDataSubClass = getDefinition("missingicon.png");
					trace("RingIconFactory asset not found:", name);
				}
				_bitmapDatas[name] = new BitmapDataSubClass(0, 0);
			}
			return DisplayObjectUtils.createClearAllChildrensImmuneBitmap(BitmapData(_bitmapDatas[name]));
		}
		
		private static function getDefinition(className:String):Class {
			try
			{
				return (inited) ? loader.contentLoaderInfo.applicationDomain.getDefinition(className) as Class : null;
			} 
			catch(e:Error) {} // [kja] we'll assume the user (server) gave bad input, which is not exceptional.
			return null;
		}
	}
}