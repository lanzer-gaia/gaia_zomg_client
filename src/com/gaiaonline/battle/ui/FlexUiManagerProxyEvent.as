package com.gaiaonline.battle.ui
{
	import com.gaiaonline.battle.ApplicationInterfaces.IGatewayFactory;
	import com.gaiaonline.battle.ApplicationInterfaces.ILinkManager;
	
	import flash.display.DisplayObject;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	
	public class FlexUiManagerProxyEvent extends Event
	{
		public static const INIT:String = "init";
		public static const SHOW_WIDGET:String = "showWidget";
		
		// used to dispatch events through this proxy class
		public static var proxy:EventDispatcher = new EventDispatcher();		
		
		public var flexLayer:DisplayObject;
		public var gCash:Number;
		public var linkManager:ILinkManager;
		public var gatewayFactory:IGatewayFactory;
		public var winMap:BattleWin;
		
		public var widgetName:String;
		public var showWidget:Boolean;
					
		public function FlexUiManagerProxyEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false) {
			
			super(type, bubbles, cancelable);
		}
		
	}
}