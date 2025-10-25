package com.gaiaonline.battle.ui
{
	import com.gaiaonline.battle.ConfigManager;
	import com.gaiaonline.flexModulesAPIs.globalevent.GlobalEvent;
	import com.gaiaonline.objectPool.LoaderFactory;
	
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.Loader;
	import flash.display.LoaderInfo;
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.events.IEventDispatcher;
	import flash.events.NetStatusEvent;
	import flash.events.TimerEvent;
	import flash.geom.Rectangle;
	import flash.media.Video;
	import flash.net.NetConnection;
	import flash.net.NetStream;
	import flash.net.URLRequest;
	import flash.utils.Timer;

	// handle video or other content for load screen
	// loadscreen.swf should fire completion event for loading login UI
	// loadscreen.flv fires off an END_INTRO event for the same
	
	// optionally provide the ability to load an image post flv (_loadBackground)
	public final class UiLoadScreen extends MovieClip
	{
		private var _ns:NetStream = null;
		private var _nc:NetConnection = null
		private var _video:Video = null;
		private var _ratio:Number = 1;
		private var _introDone:Boolean = false;
		
		private var _loader:Loader = null;
		private var _loaderFactory:LoaderFactory = null;
		private var _loadBackground:String = null;
		private var _timer:Timer = null;
		
		private var _configManager:ConfigManager = null;
		
		public function UiLoadScreen(path:String, loadedExternally:Boolean)
		{
			super();
			_configManager = ConfigManager.getInstance();
			
			var loadScreenUrl:String = path;
			if (loadedExternally) {
				loadScreenUrl += "thirdpartyloadscreen.jpg";
			} else {
				loadScreenUrl += _configManager.loadScreen;
			}
			
			// this is optionally loaded after the video finishes - it doesn't fire any events
			if (ConfigManager.getInstance().loadBackground) {
				_loadBackground = path + _configManager.loadBackground;
			}
			
			var timerFunction:Function = null;
			if (loadScreenUrl.indexOf(".flv") != -1) {
				timerFunction = onVideoTimer;
				loadVideo(loadScreenUrl);
			} else {
				timerFunction = onSwfTimer;
				loadContent(loadScreenUrl);
			}
			
			if (!isNaN(_configManager.loadScreenTimer)) {
				_timer = new Timer(_configManager.loadScreenTimer, 1);
				_timer.addEventListener(TimerEvent.TIMER, timerFunction, false, 0, true);
				_timer.start();
			}
					
		}
		
		private function loadVideo(url:String):void
		{
			_nc = new NetConnection();
			_nc.connect(null);
			
			var customClient:Object = new Object();
			customClient.onMetaData = onMetaData;
					
			_ns = new NetStream(_nc);
			_ns.addEventListener(NetStatusEvent.NET_STATUS, onNetStatus, false, 0, true);
			_ns.client = customClient;	// swallow meta and cue events
					
			_video = new Video();
			_video.addEventListener(Event.ADDED_TO_STAGE, onVideoAddedToStage, false, 0, true);
			_video.attachNetStream(_ns);
			this.addChild(_video);
			
			_ns.play(url);
		}
		
		private function onMetaData(item:Object):void
		{
			_ratio = item.width/item.height;
			centerContent();
		}
		
		private function onVideoAddedToStage(event:Event):void
		{
			(event.target as IEventDispatcher).removeEventListener(event.type, arguments.callee);
			stage.addEventListener(Event.RESIZE, onResizeVideo, false, 0, true);
		}
		
		private function onResizeVideo(evt:Event):void{	
			centerContent();
		}
		
		private function resize():void {
			var w:Number = Math.min(Math.ceil(this.width), 2880);	
			var h:Number = Math.min(Math.ceil(this.height), 2880);
			
			var bitmapData:BitmapData = new BitmapData(w, h, true, 0x00000000);
			bitmapData.draw(this);
			var rect:Rectangle = bitmapData.getColorBoundsRect(0xFF000000, 0x00000000, false);
			bitmapData.dispose();
			bitmapData = null;

			var scale:Number = this.stage.stageWidth/(rect.width-1);	
			
			this.scaleX = this.scaleY = scale;
			this.x = 0;
			this.y = this.stage.stageHeight/2 - ((rect.height*scale)/2);
		}
		
		private function centerContent():void
		{
			var stageRatio:Number = this.stage.stageWidth/this.stage.stageHeight;
			
			if (stageRatio > _ratio) {
				_video.height = this.stage.stageHeight;
				_video.width = _video.height*_ratio;
			} else {
				_video.width = this.stage.stageWidth;
				_video.height = _video.width/_ratio;
			}
			
			_video.smoothing = true;
			_video.x = (this.stage.width - _video.width)*.5;
			_video.y = (this.stage.height - _video.height)*.5;
		}
		
		private function onNetStatus(status:NetStatusEvent):void
		{
		 	if (status.info.code == "NetStream.Play.Stop") {
		 		stopVideo();
		 	}
		}
		
		private function onVideoTimer(e:TimerEvent):void
		{
			stopVideo();
		}
				
		private function stopVideo():void {
			stage.removeEventListener(Event.RESIZE, onResizeVideo);
			GlobalEvent.eventDispatcher.dispatchEvent(new GlobalEvent(GlobalEvent.END_INTRO, {}));
			
			if (_timer) {
				_timer.stop();
				_timer = null;	// removes listener
			}
			
			
			// bring up the optional background image after the flv plays
			if (_loadBackground)
			{
				loadContent(_loadBackground);
			}	 		
				
			if (_nc != null && _nc.connected){
				_nc.close();				
			}
			if (_ns != null){
				_ns.close();
			}			
			if (_video != null){
				_video.clear();				
			}
			
			_nc = null;
			_ns = null;
			
			this.removeChild(_video);
			_video = null;
		}
		
		private function loadContent(url:String):void {
			_loaderFactory = LoaderFactory.getInstance();
			
			_loader = _loaderFactory.checkOut();
			_loader.contentLoaderInfo.addEventListener(Event.COMPLETE, onIntroAnimLoaded, false, 0, true);
			_loader.addEventListener(Event.ADDED_TO_STAGE, onIntroAddedToStage, false, 0, true);
			_loader.load(new URLRequest(url));
		}
		
		private function onSwfTimer(e:TimerEvent):void
		{
			onIntroDone();
		}
		
		private function onIntroAnimLoaded(event:Event):void
		{				
			_loader.content.addEventListener("INTRO_DONE", onIntroDone);
			(event.target as IEventDispatcher).removeEventListener(event.type, arguments.callee);
			
			if(String(event.target.contentType).indexOf("image") != -1)
			{
				//if it's a static image we can call the FinishedPlaying function.
				onIntroAnimFinishedPlaying();
			}
			else{
				LoaderInfo(event.target).sharedEvents.addEventListener(Event.COMPLETE, onIntroAnimFinishedPlaying, false, 0, false);
			}
			addChild(_loader)
		}
		
		private function onIntroAddedToStage(event: Event): void
		{
			(event.target as IEventDispatcher).removeEventListener(event.type, arguments.callee);
			resize();
		}
		
		private function onIntroAnimFinishedPlaying(event:Event=null):void{
			if(_loader){
				if(_loader.content is MovieClip){
					(_loader.content as MovieClip).stop();
				}
				else
				{
					var content: DisplayObject = _loader.content;
					content.width = this.stage.stageWidth;
					content.height = this.stage.stageHeight;
				}
			}
		}
		
		
		private function onIntroDone(evt:Event=null):void{
			if (_loader.content) {	// prevent timer from finishing before loaded, if so default to normal behavior 
				_loader.content.removeEventListener("INTRO_DONE", onIntroDone);
				if(!_introDone) {
					GlobalEvent.eventDispatcher.dispatchEvent(new GlobalEvent(GlobalEvent.END_INTRO, {}));
					_introDone = true;
				}
			}
			if (_timer) {
				_timer.stop();
				_timer = null;
			}
		}
		
		public function destroy():void {
			if (_loaderFactory) {
				_loaderFactory.checkIn(_loader);
				_loader = null;
			}
		}
		
		public function get content():DisplayObject
		{
			if (_loader) {
				return _loader.content;
			}
			return null;
		}
			
		
	}
}