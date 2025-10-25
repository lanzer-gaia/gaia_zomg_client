package com.gaiaonline.battle.ui.UiWorldListClasses
{
	public interface IOptionsHolder
	{
		function showOptions(checked:Boolean):void;
		function registerForOptionsEvents(fxn:Function):void;
		function unregisterForOptionsEvents(fxn:Function):void;
	}
}