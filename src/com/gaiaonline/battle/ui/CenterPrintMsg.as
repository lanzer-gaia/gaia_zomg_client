package com.gaiaonline.battle.ui
{
	import com.gaiaonline.battle.GlobalColors;
	import com.gaiaonline.flexModulesAPIs.globalevent.GlobalEvent;
	
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.TimerEvent;
	import flash.filters.GlowFilter;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;
	import flash.utils.Timer;
	
	public class CenterPrintMsg extends Sprite
	{	
		public static const RING_TYPE:String = "ring";	
		public static const RECIPE_TYPE:String = "recipe";	
		public static const CONSUMABLE_TYPE:String = "consumable";	
		public static const BADGE_TYPE:String = "badge";							
				
		private var txt:TextField;
		private var timer:Timer;		
		private var format:TextFormat = new TextFormat();
		private var _outlineColor:Number = NaN;
		
		private var ringCenterPrintColors:CenterPrintColors = null;
		private var recipeCenterPrintColors:CenterPrintColors = null;
		private var consumableCenterPrintColors:CenterPrintColors = null;
		private var badgeCenterPrintColors:CenterPrintColors = null;
		private var defaultCenterPrintColors:CenterPrintColors = null;

		public function CenterPrintMsg(msg:String, type:String=""){
			
			this.mouseEnabled = false;
			this.mouseChildren = false;
			
			
//		    format.font = "arial";
		    format.font = "myArial";
		    format.size = 16;
		    
		    var CenterPrintColors:CenterPrintColors = getCenterPrintColors(type);		   

		   	format.color = CenterPrintColors.textColor;
			
			this.txt = new TextField();
			this.txt.selectable = false;			
			this.txt.defaultTextFormat = format;
			this.txt.embedFonts = true;			
			this.txt.htmlText = msg;
			this.txt.autoSize = TextFieldAutoSize.CENTER;			
			this.addChild(this.txt);
			
			this.filters = CenterPrintColors.glowFilters;
			
			this.x = 0;
			
			this.timer = new Timer(2000);
			this.timer.addEventListener(TimerEvent.TIMER, onTimer, false, 0, true);
			this.timer.start();

			GlobalEvent.eventDispatcher.dispatchEvent(new GlobalEvent(GlobalEvent.ALERT, {type:AlertTypes.CENTER_PRINT_START}));						
		}
		
		private function getCenterPrintColors(type:String):CenterPrintColors {				
			switch (type) {
				case RING_TYPE:
					if (ringCenterPrintColors == null) {
						ringCenterPrintColors = new CenterPrintColors();
						ringCenterPrintColors.glowFilters = [new GlowFilter(GlobalColors.BEIGE, 1, 4,4,4, 1 ), new GlowFilter(0xFFE34C, 0.7, 8, 8, 1, 3) ]; // gold
						ringCenterPrintColors.textColor = 0xFFF5BF;
						this._outlineColor = GlobalColors.BEIGE;
					}						
					return ringCenterPrintColors; 
					break;
				case RECIPE_TYPE:
					if (recipeCenterPrintColors == null) {
						recipeCenterPrintColors = new CenterPrintColors();
						recipeCenterPrintColors.glowFilters = [new GlowFilter(GlobalColors.VERY_LIGHT_GREEN, 1, 4,4,4,1), new GlowFilter(0x39C942, 0.7, 8, 8, 1, 3)]; // green 
						recipeCenterPrintColors.textColor = 0xBFF2C2;
						this._outlineColor = GlobalColors.VERY_LIGHT_GREEN;						
					}						
					return recipeCenterPrintColors; 
					break;
				case CONSUMABLE_TYPE:
					if (consumableCenterPrintColors == null) {
						consumableCenterPrintColors = new CenterPrintColors();
						consumableCenterPrintColors.glowFilters = [new GlowFilter(GlobalColors.LIGHT_BLUE, 1, 4,4,4,1), new GlowFilter(0x4CFFFF, 0.7, 8, 8, 1, 3)]; // cyan 
						consumableCenterPrintColors.textColor = 0xBFFFFF;
						this._outlineColor = GlobalColors.LIGHT_BLUE;												
					}						
					return consumableCenterPrintColors; 
					break;
				case BADGE_TYPE:
					if (badgeCenterPrintColors == null) {
						badgeCenterPrintColors = new CenterPrintColors();
						badgeCenterPrintColors.glowFilters = [new GlowFilter(GlobalColors.LIGHT_VIOLET, 1, 4,4,4,1), new GlowFilter(0xA54CFF, 0.7, 8, 8, 1, 3)]; // violet 
						badgeCenterPrintColors.textColor = 0xDFBFFF;
						this._outlineColor = GlobalColors.LIGHT_VIOLET;																		
					}						
					return badgeCenterPrintColors; 
					break;					
				default: 
					if (defaultCenterPrintColors == null) {
						defaultCenterPrintColors = new CenterPrintColors();
						defaultCenterPrintColors.glowFilters = [new GlowFilter(GlobalColors.LIGHT_SALMON, 1, 4,4,4,1), new GlowFilter(0xFF4C4C, 0.7, 8, 8, 1, 3)];
						defaultCenterPrintColors.textColor = 0xFFBFBF;
						this._outlineColor = GlobalColors.LIGHT_SALMON;																		
					}						
					return defaultCenterPrintColors; 
			}
		}
		public function get message():String {
			var text:String = null;
			if (this.txt != null) { 
				text = this.txt.text;
			}
			
			return text;
		}
		
		private function onTimer(evt:TimerEvent):void{
			this.timer.stop();
			this.addEventListener(Event.ENTER_FRAME, onEnterFrame, false, 0, true);
		}
		private function onEnterFrame(evt:Event):void{
			this.txt.alpha -= 0.1;
			if (this.txt.alpha <= 0){					
				//this.removeChild(this.txt);				
				this.removeEventListener(Event.ENTER_FRAME, onEnterFrame);	
				this.dispatchEvent(new CenterPrintMsgEvent("DONE", this._outlineColor));
			}
		} 
		
	}
}

class CenterPrintColors {
	public var glowFilters:Array = null;
	public var textColor:Number = NaN;
}