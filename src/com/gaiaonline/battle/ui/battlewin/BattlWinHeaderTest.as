package com.gaiaonline.battle.ui.battlewin
{
	import com.gaiaonline.battle.ApplicationInterfaces.IUIFramework;
	import com.gaiaonline.battle.GlobalColors;
	import com.gaiaonline.battle.newactors.BaseActorEvent;
	import com.gaiaonline.flexModulesAPIs.globalevent.GlobalEvent;
	
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.text.TextField;
	
	
	public class BattlWinHeaderTest extends MovieClip
	{
		private var _uiFramework:IUIFramework;
		
		private var _txtZone:TextField;
		private var _serverName:String;
		private var _zoneName:String;

		
		private var _txtGold:TextField;
		private var _icoGold:Sprite;
		
		private var _txtGCash:TextField;
		private var _icoGCash:Sprite;
		
		private var _txtOrbs:TextField;
		private var _icoOrbs:MovieClip;
		
		private var _txtCL:TextField;
		private var _icoCL:MovieClip;
		
		private var _mcShopButton:MovieClip;	
		
		public function BattlWinHeaderTest()
		{
			super();
			
			var n:Number = GlobalColors.AREA_CHANNEL;		
			var s:Sprite;
			var G:GlobalEvent;
			
			var b:BaseActorEvent
			
		}

	}
}