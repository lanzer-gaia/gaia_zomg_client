package com.gaiaonline.battle.jabberchat
{
	import flash.events.Event;
	
	public class JabberEvent extends Event
	{		
		public function JabberEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
		}
				
		public var fromUserName:String;
		public var fromUserId:String;
		public var timeStamp:Date;
		public var msg:String;
		public var channel:String;
		
		public var errorMsg:String = null;
	}
}