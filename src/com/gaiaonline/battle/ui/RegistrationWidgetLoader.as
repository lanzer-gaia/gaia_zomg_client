package com.gaiaonline.battle.ui
{
	import com.gaiaonline.battle.ConfigManager;
	import com.gaiaonline.battle.StepLoader;
	import com.gaiaonline.utils.DisplayObjectUtils;
	
	import flash.display.Loader;
	import flash.display.LoaderInfo;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.ProgressEvent;
	import flash.net.URLRequest;
	import flash.system.LoaderContext;
	import flash.system.Security;
	import flash.system.SecurityDomain;

	[Event(name=Event.INIT, type="flash.events.Event")]  // dispatched upon load of the widget.  It calls initialize on the widget for you.
	public class RegistrationWidgetLoader extends EventDispatcher
	{
		public static const MODE_PICKER:String = "picker";
		public static const MODE_REGISTER_GUEST:String = "registration";

		private static var s_regPath:String = null;
		private var _mode:String = null;
		private var _gsi:String = null;
		private var _cacheBuster:String = null;
		private var _baseURL: String;
		private var _partnerID: String;
		private var _useCaptcha: Boolean = false;
		private var _configManager:ConfigManager = null;
		
		public function RegistrationWidgetLoader(mode:String, gsiSubdomain:String, baseURL: String, partnerID: String, useCaptcha: Boolean)
		{
			super();
			
			_mode = mode;
			_gsi = gsiSubdomain;
			_baseURL = baseURL;
			_partnerID = partnerID;
			_useCaptcha = useCaptcha;
			
			_configManager = ConfigManager.getInstance();

			var loader:Loader = new Loader();
			
			DisplayObjectUtils.addWeakListener(loader.contentLoaderInfo, Event.INIT, onRegistrationLoaded);
			//DisplayObjectUtils.addWeakListener(loader.contentLoaderInfo, ProgressEvent.PROGRESS, onLoadProgress);

			if (!s_regPath)
			{
				var lastTwoDirectories: RegExp = /(?:.*)(\/.*\/.*\/$)/;
				var matches: Array = _baseURL.match(lastTwoDirectories);
				
				/// rather than use "../../", use G lobals.BaseUrl minus the two leading directories. This allows ZomgLoader to load the guest registration.
				s_regPath = (matches && matches.length > 1) ? _baseURL.replace(matches[1], "") : "../.."; 
			}
			
			var context: LoaderContext = new LoaderContext();
			if(Security.sandboxType == Security.REMOTE)
				context.securityDomain = SecurityDomain.currentDomain;
			
			_cacheBuster = String(Math.random()).substr(2); // should be a util fn -kja 

			StepLoader.add(loader, new URLRequest(s_regPath + "/guest/guestRegistration.swf?gver=" + _cacheBuster), context);
		}

		private var _widget:* = null;
		private function onRegistrationLoaded(e:Event):void
		{
			//
			// Initialize the guest registration
			_widget = LoaderInfo(e.target).content;
						
			var params:Object = 
			{
				mainServer:"www.gaiaonline.com",
				gsiSubdomain: _gsi,			
				avPath:"http://a2.cdn.gaiaonline.com/gaia/members/",
				relPath: s_regPath + "/guest/",
				partnerID: _partnerID,
				parentApp: ConfigManager.getInstance().registrationParent,
				trackingTag: _configManager.spaceName,
				omnitureTag: _configManager.regOmnitureTag,
				ff: "false",	// find friends not supported for mini, in game reg
				loginPrompt: "false",
				type: _mode,
				loginURL: "http://" + _gsi + ".gaiaonline.com/launch/zomg",	//@@ [kejk] needs to be changed with the zomg name change
				regURL: "http://" + _gsi + ".gaiaonline.com/register/flash/?v=c",
				gver: _cacheBuster,
				captcha: _useCaptcha.toString()
			};
					
			_widget.initialize(params);
			dispatchEvent(e);
		}

		private function onLoadProgress(evt:ProgressEvent):void
		{
			dispatchEvent(evt);
		}

		public function get widget():*
		{
			return _widget;
		}
	}
}
