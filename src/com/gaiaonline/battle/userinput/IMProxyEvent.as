package com.gaiaonline.battle.userinput
{
	// We can't include any reference to the IMManager in UIManager.fla because of a bug in CS3.  IMManager references
	// our AIM API component, which in turn uses the open source wimas library (that wraps the AIM web APIs directly);
	// for some reason, reference to the wimas code causes the CS3 compiler to barf when compiling UIManager.fla (it
	// reports a reference error for every symbol with external linkage (not sure whether declaring on the stage is operative
	// there, too).  So rather than refer to IMManager directly, we talk with through this IMProxyEvent, and likewise, it 
	// talks back using this same proxy event class.
	// -- Mark Rubin
	
	import flash.events.Event;
	import flash.events.EventDispatcher;

	public class IMProxyEvent extends Event 
	{
		// Fire this to initialize the IMManager; it will also log you in
		public static const INIT:String = "init";
		// Fire this to log off of IM
		public static const SIGN_OFF:String = "signOff";		
		
		//*** Events the IMManager fires to its clients
		public static const IM_RECEIVED:String = "imReceeived";
		public static const LOGIN_SUCCESS:String = "loginSuccess";
		public static const NOT_LOGGED_IN:String = "notLoggedIn";
		public static const ACTION_REQUESTED_WITH_NO_SESSION:String = "actionRequestedWithNoSession";
		public static const LOGIN_ERROR:String = "loginError";
		public static const MESSAGE_DELIVERY_FAILURE:String = "messageDeliveryFailure";
		public static const MESSAGE_DELIVERY_SUCCESS:String = "messageDeliverySuccess";		
		
		//*** Events the clients fire to the IMManager
		public static const SEND_IM_WITH_GAIA_ID:String = "sendWithGaiaID";
		public static const SEND_IM_WITH_GAIA_NAME:String = "sendWithGaiaName";		
		public static const SEND_IM_TO_GUILD:String = "sendIMToGuild";				

		// used to dispatch events through this proxy class
		public static var proxy:EventDispatcher = new EventDispatcher();		

		// The real events that the IMManager would like to fire to its clients:
		// they get wrapped in this IMProxyEvent, and we stuff the real event as
		// a member here, with accessors below.
		private var _imReceivedEvent:IMReceivedEvent = null;
		private var _battleIMEvent:BattleIMEvent = null;
		
		private var _errorCode:String = null;
		private var _message:String = null;
		private var _gaiaId:String = null;
		private var _gaiaName:String = null;
		private var _guildId:String = null;
		
		public function IMProxyEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false) {
			super(type, bubbles, cancelable);
		}		
		
		public function set imReceivedEvent(e:IMReceivedEvent):void {
			_imReceivedEvent = e;
		}
		
		public function get imReceivedEvent():IMReceivedEvent {
			return _imReceivedEvent;
		}

		public function set battleIMEvent(e:BattleIMEvent):void {
			_battleIMEvent = e;
		}
		
		public function get battleIMEvent():BattleIMEvent {
			return _battleIMEvent;
		}

		public function set gaiaId(gaiaId:String):void {
			_gaiaId = gaiaId;
		}
		
		public function get gaiaId():String {
			return _gaiaId;
		}

		public function set gaiaName(gaiaName:String):void {
			_gaiaName = gaiaName;
		}
				
		public function get gaiaName():String {
			return _gaiaName;
		}

		public function set guildId(guildId:String):void {
			_guildId = guildId;
		}
		
		public function get guildId():String {
			return _guildId;
		}				
		
		public function set message(message:String):void {
			_message = message;
		}
		
		public function get message():String {
			return _message;
		}
		
		public function set errorCode(code:String):void {
			_errorCode = code;
		}
		
		public function get errorCode():String {
			return _errorCode;
		}
	}
}