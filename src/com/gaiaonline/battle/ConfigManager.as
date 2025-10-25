package com.gaiaonline.battle
{
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	
	public class ConfigManager extends EventDispatcher
	{
		private static var _instance: ConfigManager;
		
		private var _loaded:Boolean = false;
		private var _xml:XML;
		
		
		public function ConfigManager(s: SingletonEnforcer)
		{					
		}
		
		public static function getInstance(): ConfigManager
		{
			if(ConfigManager._instance == null)
			{
				ConfigManager._instance = new ConfigManager(new SingletonEnforcer());
			}
				
			return ConfigManager._instance;
		}
		
		public function loadConfigFile(url:String):void{
			this._loaded = false;
			
			var l:URLLoader = new URLLoader();
			l.dataFormat = URLLoaderDataFormat.TEXT;
			l.addEventListener(Event.COMPLETE, onXmlLoaded);		
			l.load(new URLRequest(url));
		}
		private function onXmlLoaded(evt:Event):void{
			this._xml = new XML( evt.target.data );
			this._loginPath = this._xml.Login.@path;
			
			// registration widget
			this._registrationParent = this._xml.Registration.@type;
			this._regOmnitureTag = this._xml.Registration.omnitureTag;
			
			// load screen
			this._loadScreen = this._xml.LoadScreen.@file;
			this._loadBackground = this._xml.LoadScreen.background;
			this._loadScreenTimer = parseInt(this._xml.LoadScreen.timer);
			
			// UI Modules
			_moduleXMLList = this._xml.Modules.Module;

			// Main Window file
			this._mainWindowUrl = this._xml.MainWindow.@file;			
			this._mainWindowMaximize = this._xml.MainWindow.@maximize == "true";			
			
			
			// Generic window swf to use for old style (non mxml) window
			this._genericWindowUrl = this._xml.GenericWindow.@file;
			
			
			this._loaded = true;
			this.dispatchEvent(new Event(Event.COMPLETE));
		}
		
		private var _spaceName:String = null;
		public function set spaceName(sn:String):void{
			_spaceName = sn;
		}
		public function get spaceName():String{
			return _spaceName;
		}
		
		private var _loginPath:String;
		public function get loginPath():String{
			return this._loginPath;
		}
		
		private var _registrationParent:String;
		public function get registrationParent():String{
			return this._registrationParent;
		}
		
		private var _regOmnitureTag:String;
		public function get regOmnitureTag():String{
			return this._regOmnitureTag;
		}
		
		public function get loaded():Boolean{
			return this._loaded;
		}
		
		private var _loadScreen:String;
		public function get loadScreen():String{
			return this._loadScreen;
		}
		
		private var _loadBackground:String = null;
		public function get loadBackground():String{
			return this._loadBackground;
		}
		
		private var _loadScreenTimer:Number = NaN;
		public function get loadScreenTimer():Number{
			return this._loadScreenTimer;
		}
		
		private var _moduleXMLList:XMLList = null;
		public function get moduleXMLList():XMLList
		{
			return this._moduleXMLList;
		}

		private var _mainWindowUrl:String;
		public function get mainWindowUrl():String{
			return this._mainWindowUrl;
		}
		
		private var _mainWindowMaximize:Boolean = false;
		public function get mainWindowMaximize():Boolean{
			return this._mainWindowMaximize;
		}
		
		private var _genericWindowUrl:String;
		public function get genericWindowUrl():String{
			return this._genericWindowUrl;
		}
	}
}

class SingletonEnforcer { }