package com.gaiaonline.battle.userinput
{
	import flash.events.Event;

	public class IMReceivedEvent extends Event
	{
		public static const IM_RECEIVED:String = "imReceived";
		
		public var message:String;
		public var senderId:String;
		public var channel:String;
		public var senderName:String;
		
		// only used for guild broadcasts
		public var guildName:String = null;
		public var guildId:String = null;
		
		public function IMReceivedEvent(type:String, message:String, senderId:String, channel:String, senderName:String, bubbles:Boolean=false, cancelable:Boolean=false) {
			super(type, bubbles, cancelable);

			this.message = message;
			this.senderId = senderId;
			this.channel = channel;
			this.senderName = senderName;
		}
	}
}