package com.gaiaonline.battle.ui.battlewin
{
	import com.gaiaonline.battle.ApplicationInterfaces.IUIFramework;
	
	public interface IWinHeader
	{
		function init(uiFramework:IUIFramework):void;
		
		function get serverName():String;
		function set serverName(v:String):void;
		
		function get zoneName():String;
		function set zoneName(v:String):void;
		
		function setSize(width:uint, height:uint, right:Number = 0):void;
		
		function startFps():void;
		function stopFps():void;
		
	}
}