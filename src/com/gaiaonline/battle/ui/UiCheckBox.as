package com.gaiaonline.battle.ui
{
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.events.MouseEvent;

	public class UiCheckBox extends MovieClip
	{
		public function UiCheckBox()
		{
			super();
			this.gotoAndStop("offState");
			this.addEventListener(MouseEvent.CLICK, onMouseClick, false, 0, true);
		}
		
		private function onMouseClick(event:MouseEvent):void
		{
			this.checked = !this.checked;
			this.dispatchEvent(new Event(Event.CHANGE));
		}
		
		public function set checked(check:Boolean):void
		{
			if(check)
			{
				this.gotoAndStop("onState");
			}
			else
			{
				this.gotoAndStop("offState");
			}
		}
		
		public function get checked():Boolean
		{
			return this.currentLabel == "onState"; 
		}
	}
}