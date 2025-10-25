package com.gaiaonline.battle.ItemLoadManager
{
	import flash.display.DisplayObject;
	import flash.events.IEventDispatcher;
	
	
	public interface IItemLoader extends IEventDispatcher
	{	
		function get itemName():String;
		function get itemDescription():String;
		function get loaded():Boolean;
		function getNewItemDisplay():DisplayObject;
		// Must dispatch ITEM_LOADED when the item is done loaded all info
	}
}