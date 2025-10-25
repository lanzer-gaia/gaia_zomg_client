package com.gaiaonline.battle.ui.UiWorldListClasses
{
	public interface IWorldListFooter
	{
		function showWorldListFooter():void;
		function registerForWorldListFooterEvents(fxn:Function):void;
		function unregisterForWorldListFooterEvents(fxn:Function):void;
	}
}