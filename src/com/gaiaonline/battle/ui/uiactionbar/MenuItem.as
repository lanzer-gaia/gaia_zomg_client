package com.gaiaonline.battle.ui.uiactionbar
{
	import flash.events.MouseEvent;
	import flash.text.AntiAliasType;
	import flash.text.TextFormat;

	public class MenuItem extends MenuItemFl
	{

		public function MenuItem()
		{
			super();
			
			this.btn.addEventListener(MouseEvent.MOUSE_OVER, onMouseOver, false, 0, true);
			this.btn.addEventListener(MouseEvent.MOUSE_OUT, onMouseOut, false, 0, true);
					
		}
						
		private function onMouseOver(evt:MouseEvent):void{
			this.txt.textColor = 0xFF00ff;
		}
		private function onMouseOut(evt:MouseEvent):void{
			this.txt.textColor = 0xFFFFFF;
		}
	}		
}