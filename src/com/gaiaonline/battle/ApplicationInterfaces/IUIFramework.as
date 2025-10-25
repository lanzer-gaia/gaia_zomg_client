package com.gaiaonline.battle.ApplicationInterfaces
{
	import com.gaiaonline.battle.map.IMap;
	import com.gaiaonline.battle.sounds.AudioSettings;
	import com.gaiaonline.battle.ui.ToolTipOld;
	import com.gaiaonline.utils.MouseMoveLimiter;
	import com.gaiaonline.utils.factories.ILoaderContextFactory;
	
	import flash.display.Stage;
	
	public interface IUIFramework
	{
		function get tooltipManager():ToolTipOld;
		function get map():IMap;
		function get loaderContextFactory():ILoaderContextFactory;
		function get stage():Stage;
		function get userLevelColors():Object;
		function get volumes():AudioSettings;
		function get isLoadedExternally():Boolean;	
		function get assetFactory():IAssetFactory;
		function get stageMouseMoveLimiter():MouseMoveLimiter;
		function set assetFactory(af:IAssetFactory):void;
		function getBaseItemId(itemId:String):String;
		
		// used for debugging purposes		
		function get loadUserItems():Boolean; // rings, power-ups, loot, etc.				
		function get loadUi():Boolean;
		function get showFrameRate():Boolean
		function get ringAnimFpsTest():Boolean; // should be FALSE , only set to true for the automated ring Animnation fps 	
	}
}
