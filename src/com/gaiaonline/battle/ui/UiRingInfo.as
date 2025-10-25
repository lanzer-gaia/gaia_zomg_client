package com.gaiaonline.battle.ui
{
	import com.gaiaonline.battle.ApplicationInterfaces.IUIFramework;
	import com.gaiaonline.battle.GlobalTexts;
	import com.gaiaonline.flexModulesAPIs.globalevent.GlobalEvent;
	import com.gaiaonline.utils.DisplayObjectUtils;
	import com.gaiaonline.utils.VisManagerSingleParent;
	
	import fl.transitions.*;
	import fl.transitions.easing.*;
	
	import flash.display.Loader;
	import flash.display.MovieClip;
	import flash.filters.BevelFilter;
	import flash.filters.BitmapFilter;
	import flash.filters.BitmapFilterQuality;
	import flash.filters.BitmapFilterType;
	import flash.geom.ColorTransform;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	
		
	public class UiRingInfo extends MovieClip
	{
		public var ringInfoHolder:MovieClip;
		public var noRingsTxt:TextField;
		
		private var ringLoader:Loader;
		private var ringImageContainer:MovieClip;
		private var chargeLevelColors:Array;
		private var pressedButton:String;
		private var scrollDescPusher:Number;
		private var scrollStatsPusher:Number;
		private var ringId:int;
	
		private var itemInfo:UiItemInfo = null;
		
		private var visManager:VisManagerSingleParent = null;
		private var _uiFramework:IUIFramework = null;
					
		public function UiRingInfo() {
		
		}
		
		public function init(uiFramework:IUIFramework):void {
			this.visManager = new VisManagerSingleParent(this);
			this._uiFramework = uiFramework;
			
			this.itemInfo = new UiItemInfo(uiFramework, this);
			noRingsTxt.text = GlobalTexts.getNoRingsText();
			setInfoAreaVisible(false);
			
			this.cappedMessage.text = "";
			
			//DisplayObjectUtils.addWeakListener(GlobalEvent.eventDispatcher, GlobalEvent.CL_CAP_CHANGE, onCLCapChange);
			
		}
		
		/*
		private var _cap:Number = 0;
		private function onCLCapChange(capChange:GlobalEvent):void
		{
			_cap = Number(capChange.data);
			updateCappedMessage();
		}
		*/

		private function setInfoAreaVisible(visible:Boolean):void {
			this.visManager.setVisible(ringInfoHolder, visible);
			this.visManager.setVisible(noRingsTxt, !visible);
		}
		
		// public functions
		public function setRingInfo(ringInfo:Object):void{
			this.itemInfo.setRingInfo(ringInfo);
			if (ringInfo != null){
				this.chargeLevelColors = [
					{r:0,g:0,b:0},
					{r:255,g:168,b:0}, //CHARGE LEVEL 1
					{r:220,g:40,b:20}, //CHARGE LEVEL 2
					{r:70,g:150,b:10}, //CHARGE LEVEL 3
					{r:0,g:255,b:40}, //CHARGE LEVEL 4
					{r:0,g:220,b:255}, //CHARGE LEVEL 5
					{r:30,g:160,b:180}, //CHARGE LEVEL 6
					{r:30,g:100,b:180}, //CHARGE LEVEL 7
					{r:0,g:0,b:210}, //CHARGE LEVEL 8
					{r:190,g:90,b:240}, //CHARGE LEVEL 9
					{r:255,g:0,b:240} //CHARGE LEVEL 10					
					
				];

				if (this.ringId != this.initObject.ringId){
					if (0 <= initObject.chargeLevel) {
						this.chargeLevel.autoSize = TextFieldAutoSize.LEFT;						
						this.chargeLevel.text = Number(ringInfo.chargeLevel).toFixed(1);
						this.setChargeLevelBg();
						this.createChargeSteps();
						
						//updateCappedMessage();						
					}								
				}
			}
			
			setInfoAreaVisible(ringInfo != null);									
		}

		/*
		private function updateCappedMessage():void {

			if (this.initObject) {			
				const preciseCL:Number = this.initObject.chargeLevel;
				if (_cap > 0 && _cap < preciseCL)
				{
					this.cappedMessage.text = "(" + UiManager.formatConLevel(_cap) + " capped)";
				}
				else
				{
					this.cappedMessage.text = "";
				}
			}
		}
		*/
		private function get initObject():Object {
			return itemInfo.initObject;
		}
		
		static private const CHARGE_STEPS_PER_LEVEL:uint = 10;
		static private const s_emptyColorTranform:ColorTransform = new ColorTransform();
		private function createChargeSteps():void{
						
			for (var b:int=0; b < CHARGE_STEPS_PER_LEVEL; ++b){				
				var blipFilters:Array = new Array();
				var blip:MovieClip = this.ringInfoHolder.getChildByName("chargeStepBlip"+(b+1)) as MovieClip;				
				if (b < this.initObject.chargeStep){
					
					var cl:int = 10
					if (this.initObject.chargeLevel < 10){
						cl = this.initObject.chargeLevel;
					}
														
					var blipCT:ColorTransform = blip.blipBackground.transform.colorTransform;
					var cR:Number = this.chargeLevelColors[cl].r;
					var cG:Number = this.chargeLevelColors[cl].g;
					var cB:Number = this.chargeLevelColors[cl].b;					
					blipCT.color = cR<<16 | cG<<8 | cB;
					blip.blipBackground.transform.colorTransform = blipCT;
					var glowFilter:BitmapFilter = this.getGlowFilter(); 
	    	        blipFilters.push(glowFilter);
				}else{
					blip.blipBackground.transform.colorTransform = s_emptyColorTranform;
				}
				var bevelFilter:BitmapFilter = getBevelFilter();
				blipFilters.push(bevelFilter);
        	    blip.filters = blipFilters;
        	    blip.cacheAsBitmap = true;
			}
		}
		
		private var _glowFilter:BitmapFilter = null;
		private function getGlowFilter():BitmapFilter {
			if (this._glowFilter == null) {
				var glowSettings:Object = {clr:0xFFF09F,alpa:0.4,xB:3,yB:3,strnght:2}				
				this._glowFilter = itemInfo.getGlowFilter(glowSettings);
			}
			
			return this._glowFilter;
		}
		
		private function setChargeLevelBg():void {
			var col:Object = {r:255,g:0,b:240};
			var cl:int = 10;
			if (this.initObject.chargeLevel < 10){
				cl = 10;
			}
			if (this.initObject != null && this.initObject.chargeLevel != null && this.chargeLevelColors[cl] != null){				
				col = this.chargeLevelColors[cl];
			}
			if (this.imageBgBox != null && this.imageBgBox.bgGrad != null){
				var colorTransform:ColorTransform = this.imageBgBox.bgGrad.transform.colorTransform;
				colorTransform.redOffset = -255+col.r;
				colorTransform.greenOffset = -255+col.g;
				colorTransform.blueOffset = -255+col.b;
				this.imageBgBox.bgGrad.transform.colorTransform = colorTransform;
				this.imageBgBox.alpha = 0.7;
			}
		}
		
		private var _bevelFilter:BitmapFilter = null;
		private function getBevelFilter():BitmapFilter {
			if (_bevelFilter == null) {
	            var distance:Number       = 5;
	            var angleInDegrees:Number = 45;
	            var highlightColor:Number = 0xFFFFFF;
	            var highlightAlpha:Number = 1;
	            var shadowColor:Number    = 0x000000;
	            var shadowAlpha:Number    = 1;
	            var blurX:Number          = 5;
	            var blurY:Number          = 5;
	            var strength:Number       = 0.3;
	            var quality:Number        = BitmapFilterQuality.HIGH;
	            var type:String           = BitmapFilterType.INNER;
	            var knockout:Boolean      = false;
	
	            this._bevelFilter = new BevelFilter(distance,
	                                   angleInDegrees,
	                                   highlightColor,
	                                   highlightAlpha,
	                                   shadowColor,
	                                   shadowAlpha,
	                                   blurX,
	                                   blurY,
	                                   strength,
	                                   quality,
	                                   type,
	                                   knockout);	  		
	  		}
	  		return this._bevelFilter;
        }
			
		public function getCurrentRingId():int{
			return this.itemInfo.getCurrentRingId();
		}	
			
		public function get imageBgBox():MovieClip {
			return this.ringInfoHolder.imageBxBox;
		}
		public function get ringName():TextField {
			return this.ringInfoHolder.ringName;						
		}
		public function get chargeLevel():TextField{
			return this.ringInfoHolder.chargeLevel;			
		}
		public function get cappedMessage():TextField{
			return this.ringInfoHolder.cappedMessage;
		}
		public function get stats():TextField{
			return this.ringInfoHolder.stats;			
		}
		public function get description():TextField{
			return this.ringInfoHolder.description;			
		}		
		public function get statsScrUp():MovieClip{
			return this.ringInfoHolder.statsScrUp;			
		}
		public function get statsScrDown():MovieClip{
			return this.ringInfoHolder.statsScrDown;			
		}
		public function get descScrUp():MovieClip{
			return this.ringInfoHolder.descScrUp;			
		}
		public function get descScrDown():MovieClip{
			return this.ringInfoHolder.descScrDown;			
		}		
		public function get chargeStepBlip1():MovieClip{
			return this.ringInfoHolder.chargeStepBlip1;			
		}
		public function get chargeStepBlip2():MovieClip{
			return this.ringInfoHolder.chargeStepBlip2;			
		}
		public function get chargeStepBlip3():MovieClip{
			return this.ringInfoHolder.chargeStepBlip3;			
		}
		public function get chargeStepBlip4():MovieClip{
			return this.ringInfoHolder.chargeStepBlip4;			
		}
		public function get chargeStepBlip5():MovieClip{
			return this.ringInfoHolder.chargeStepBlip5;			
		}
		public function get chargeStepBlip6():MovieClip{
			return this.ringInfoHolder.chargeStepBlip6;			
		}
		public function get chargeStepBlip7():MovieClip{
			return this.ringInfoHolder.chargeStepBlip7;			
		}
		public function get chargeStepBlip8():MovieClip{
			return this.ringInfoHolder.chargeStepBlip8;			
		}
		public function get chargeStepBlip9():MovieClip{
			return this.ringInfoHolder.chargeStepBlip9;			
		}
		public function get chargeStepBlip10():MovieClip{
			return this.ringInfoHolder.chargeStepBlip10;			
		}
	}
}