package com.gaiaonline.battle
{
	import com.gaiaonline.objectPool.LoaderFactory;
	
	import flash.display.Loader;
	import flash.display.LoaderInfo;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import flash.events.TimerEvent;
	import flash.net.URLRequest;
	import flash.system.LoaderContext;
	import flash.utils.Timer;	
	
	//
	// This class was created as a way of dealing with the mysterious, intermittent "[Unload SWF]" bugs, where swfs
	// would sometimes unload with no warning before they had finished downloading.  We now think this has to do
	// with the internals of Loader, and garbage collection of the contentLoaderInfo property.  See:
	//
	// http://bugs.adobe.com/jira/browse/FB-13014
	//
	// StepLoader previously (svn#21222) addressed the issue by putting successive load requests into a queue and
	// serializing them, but it appears this technique was no longer sufficient to postpone the gc'ing of the loader.
	// We now instead store references to the contentLoaderInfo, which seems to do the trick (this has been
	// compellingly verified in a simple test app that reliably replicates the unload bug).
	//   -kja 
	public class StepLoader
	{		
		private static var list:Array = new Array();
		private static var timeOut:int = 0;		
		
		public function StepLoader()
		{
		}

		private static var s_pendingLoaderInfos:Object = {};
		public static function add(loader:Loader, request:URLRequest, context:LoaderContext=null, holdReferenceForever:Boolean = false):void{
			
			s_pendingLoaderInfos[request.url] = new LoaderEntry(loader.contentLoaderInfo, holdReferenceForever); 

			loader.contentLoaderInfo.addEventListener(Event.COMPLETE, onComplete);						
								
			loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, onLoadError);
			loader.contentLoaderInfo.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onLoadError);			
			
			loader.load(request, context);						
		}

		private static var _pendingRemovees:Array = [];
		private static var _nextFrameTimer:Timer = null;		
		private static function remove(loaderInfo:LoaderInfo):void
		{
			loaderInfo.removeEventListener(Event.COMPLETE, onComplete);
											
			loaderInfo.removeEventListener(IOErrorEvent.IO_ERROR, onLoadError);
			loaderInfo.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, onLoadError);			
			loaderInfo.removeEventListener(IOErrorEvent.NETWORK_ERROR, onLoadError);
			loaderInfo.removeEventListener(IOErrorEvent.VERIFY_ERROR, onLoadError);
			loaderInfo.removeEventListener(IOErrorEvent.DISK_ERROR, onLoadError);

			// Nuke the contentLoaderInfo on the very next frame (any sooner seems to allow the unload bug to occur)
			_pendingRemovees.push(loaderInfo);
			if (!_nextFrameTimer) {
				_nextFrameTimer = new Timer(1);
				_nextFrameTimer.addEventListener(TimerEvent.TIMER, removeTimeout);
			}
			_nextFrameTimer.start();
		}

		private static function removeTimeout(unused:TimerEvent):void
		{
			_nextFrameTimer.stop();
			while(_pendingRemovees.length) {
				removeLoaderInfoReference(LoaderInfo(_pendingRemovees.pop()));
			}
		}

		private static function removeLoaderInfoReference(loaderInfo:LoaderInfo):void
		{
			for (var swf:String in s_pendingLoaderInfos)
			{
				if (LoaderEntry(s_pendingLoaderInfos[swf]).contentLoaderInfo == loaderInfo)
				{
					if (!LoaderEntry(s_pendingLoaderInfos[swf]).holdForever)
					{
						s_pendingLoaderInfos[swf] = null;
						delete s_pendingLoaderInfos[swf];
					}
					break;
				}
			}
			//trace("WARNING: s_pendingLoaderInfos missing an entry");  we really shouldn't get here, but we seem to - needs debugging.
		}


		private static function onComplete(evt:Event):void{
			var loaderInfo:LoaderInfo = LoaderInfo(evt.target)
			remove(loaderInfo);
			try{
				LoaderFactory.getInstance().checkIn(loaderInfo.loader);
			}
			catch(error:Error){}
		}
		private static function onLoadError(evt:Event):void{			
			var loaderInfo:LoaderInfo = LoaderInfo(evt.target)
			remove(loaderInfo);
			try{
				LoaderFactory.getInstance().checkIn(loaderInfo.loader);
			}
			catch(error:Error){}
		}
	}
}
	import flash.display.LoaderInfo;
	

internal class LoaderEntry
{
	public var contentLoaderInfo:LoaderInfo;
	public var holdForever:Boolean;
	public function LoaderEntry(_contentLoaderInfo:LoaderInfo, _holdForever:Boolean)
	{
		contentLoaderInfo = _contentLoaderInfo;
		holdForever = _holdForever;
	}
}