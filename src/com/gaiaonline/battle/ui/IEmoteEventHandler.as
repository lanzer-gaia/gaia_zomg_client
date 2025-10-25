package com.gaiaonline.battle.ui
{
	public interface IEmoteEventHandler
	{
		function onEmoteActivated(emoteID:String):void;
		function onEmotePopupChange(opening:Boolean):void;
	}
}