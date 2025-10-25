package com.gaiaonline.battle.ui
{
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.events.TextEvent;
	import flash.net.URLRequest;
	import flash.net.navigateToURL;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;
	
	public class UiPartnerLoginPanel extends UiLoginPanel
	{
		public function UiPartnerLoginPanel()
		{
			super();
			
			this.mcLogin.lnkLogIn.addEventListener(MouseEvent.CLICK, onLogin, false, 0, true);
		}
		
		override protected function _onKeyDown(evt:KeyboardEvent):void{
			if (evt.keyCode == 13){
				return;			
			} else {
				super._onKeyDown(evt);
			}
		}
		
		private function onLogin(e:MouseEvent):void
		{
			navigateToURL(new URLRequest("http://"+this.gsiSubdomain+".gaiaonline.com/launch/zomg?"), "_top");
		}
	}
}
