package com.gaiaonline.battle.ui.UiWorldListClasses
{
	public interface ITrailerButton{
		function showTrailerButton():void;
		function registerForTrailerEvents(fxn:Function):void;
		function unregisterForTrailerEvents(fxn:Function):void;
	}
}