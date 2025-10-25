package com.gaiaonline.battle.ui.events
{
	import flash.events.Event;

	public class ScrollBarEvent extends Event
	{
		public static const SCROLL:String = "scroll";  // sent when the scroll thumb has been dropped somewhere.  Not currently sent while thumb is being dragged 
		public function ScrollBarEvent(type:String)
		{
			super(type, false, false);			
		}
	}
}