package com.gaiaonline.battle.ui.events
{
	import flash.events.Event;

	public class TrackingEvent extends Event
	{
		public static const TRACKING:String = "tracking";
		public static const GUEST_REGISTRATION:String = "526";
		
		public var fid:String = null;
		public var cls:String = null;
		
		public function TrackingEvent(type:String, evtId:String, evtCls:String)
		{
			this.fid = evtId;
			this.cls = evtCls;
			super(type);
		}
		
	}
}