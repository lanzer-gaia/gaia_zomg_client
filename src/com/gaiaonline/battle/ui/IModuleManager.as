package com.gaiaonline.battle.ui
{
	import com.gaiaonline.containers.GameWindowManager;
	import com.gaiaonline.containers.IGameWindowFactory;
	import com.gaiaonline.flexModulesAPIs.gatewayInterfaces.IBattleGateway;
	
	import flash.display.DisplayObjectContainer;
	
	public interface IModuleManager
	{
		function init(path:String, title:String, gateway:IBattleGateway, flexWinLayer:DisplayObjectContainer, flexUIManager:IFlexUiManager, windowManager:GameWindowManager, windowFactory:IGameWindowFactory, params:XML = null):void;
	}
}