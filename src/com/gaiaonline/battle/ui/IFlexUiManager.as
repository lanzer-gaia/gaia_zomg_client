package com.gaiaonline.battle.ui
{
	import com.gaiaonline.battle.ApplicationInterfaces.ILinkManager;
	
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	
	import com.gaiaonline.flexModulesAPIs.shopWidget.IShopInfoConnector;
	import com.gaiaonline.flexModulesAPIs.shopWidget.IShopItemPurchaseConnector;
	import com.gaiaonline.flexModulesAPIs.shopWidget.IShopRefresher;

	public interface IFlexUiManager {
		// module getters
		function getModule(modulePath:String,  // constants found in ModulePaths
						   handler:IAsyncCreationHandler):void;
		
		// general utilities
		function clearContentCache(cacheName:String):void;
		function getArrayCollection():Object;
		function initializeContainer(container:Object):void;		
	}
}