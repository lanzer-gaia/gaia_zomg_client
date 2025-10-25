package com.gaiaonline.battle.ui.optionPanel
{
	import com.gaiaonline.flexModulesAPIs.globalevent.GlobalEvent;
	import com.gaiaonline.battle.ui.events.UiEvents;
	
	import flash.display.MovieClip;
	import flash.events.*;
	import flash.text.*;

	public class UiGameOption extends MovieClip
	{

		private var initObject:Object;
		private var optionPanel:UiOptionPanel;
		public var optionName:String;
		
		public var optChoice:MovieClip;
		public var optionTitle:TextField;				
		public var titleBackground:MovieClip;
		
		public function UiGameOption(){	

		}
		
		public function init(objInit:Object):void{
			this.initObject = objInit;
			this.optionName = objInit.optionName;
			if (this.initObject.value == 1) this.optChoice.gotoAndStop("onState");
			else this.optChoice.gotoAndStop("offState");
			this.optChoice.buttonMode = true;
			this.optionTitle.text = this.optionName;
			this.optChoice.addEventListener(MouseEvent.CLICK,onMouseClick, false, 0, true);
		}
		 
		private function onMouseClick(evt:MouseEvent):void{
			var event:UiEvents = new UiEvents(GlobalEvent.GRAPHIC_OPTIONS_CHANGED,this.optionName);

			// acting like a radio button--can only turn on if you click
			setState(true);
			event.value = 1;
			
			this.dispatchEvent(event);
		}
		
		public function setState(on:Boolean):void {
			var label:String = on ? "onState" : "offState";
			this.optChoice.gotoAndStop(label);			
		}
		
		public function isOn():Boolean {
			return this.optChoice.currentLabel == "onState";
		}

	}
}