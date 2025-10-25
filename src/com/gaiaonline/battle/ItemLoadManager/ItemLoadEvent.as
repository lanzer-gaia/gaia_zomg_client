package com.gaiaonline.battle.ItemLoadManager
{
	import flash.events.Event;
		
	public class ItemLoadEvent extends Event
	{
		
		public static const ITEM_LIST_LOADED:String = "ItemListLoaded"
		public static const ITEM_LOADED:String = "ItemLoaded";
		public static const ITEM_MOVE_ERROR:String = "ItemMoveError"  ;
		
		public var itemIcons:Array = new Array();
		public var params:Object = new Object();
		
		public function ItemLoadEvent(type:String, bubbles:Boolean = false, cancelable:Boolean = false)
		{
			super(type, bubbles, cancelable);
		}
				
	}
}