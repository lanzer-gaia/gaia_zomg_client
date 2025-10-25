package com.gaiaonline.battle.ui.battlewin
{
	import flash.display.Sprite;
	
	public interface IBattleWinHeader
	{
		function getShopButton():Sprite;		
		function showShopCallout(show:Boolean):void;
	}
}