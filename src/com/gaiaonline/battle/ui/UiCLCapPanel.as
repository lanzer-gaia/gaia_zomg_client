package com.gaiaonline.battle.ui
{
	import com.gaiaonline.flexModulesAPIs.globalevent.GlobalEvent;
	
	import flash.display.MovieClip;
	import flash.display.SimpleButton;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Rectangle;
	import flash.text.TextField;
				 
	public class UiCLCapPanel extends MovieClip
	{		
		
		public static const APPLY_CLICK:String = "ClPanelApplyclick";
		public static const CANCEL_CLICK:String = "ClPanelCancelclick";
		
		public var txtMax:TextField;
		public var mcSlider:MovieClip;
		public var btnMin:SimpleButton;
		public var btnMax:SimpleButton;
		public var btnCancel:SimpleButton;
		public var btnApply:SimpleButton;	
		
		private var _CLCap:Number = 5;	
		private var _maxCL:Number = 10;	
		
		public function UiCLCapPanel()
		{
			this.txtMax.text = this._maxCL.toPrecision(2);
			this.txtMax.mouseEnabled = false;
			this.mcSlider.mcTray.hitArea = this.mcSlider.mcTray.mcBtn;
			
			this.addEventListener(Event.ADDED_TO_STAGE, onAddedToStage, false, 0, true);
			this.mcSlider.mcTray.addEventListener(MouseEvent.MOUSE_DOWN, onTrayMouseDown, false, 0, true);
			
			this.btnMin.addEventListener(MouseEvent.CLICK, onBtnMinClick, false, 0, true);
			this.btnMax.addEventListener(MouseEvent.CLICK, onBtnMaxClick, false, 0, true);
			
			this.btnApply.addEventListener(MouseEvent.CLICK, onBtnApplyClick, false, 0, true);
			this.btnCancel.addEventListener(MouseEvent.CLICK, onBtnCancelClick, false, 0, true);
			
			GlobalEvent.eventDispatcher.addEventListener(GlobalEvent.CL_CAP_CHANGE, onActorCLCapChange);
			GlobalEvent.eventDispatcher.addEventListener(GlobalEvent.MAX_RING_CL_CHANGE, onMaxRingClChange);
			
			this.setTrayPos();						
		}
		
		private function onAddedToStage(evt:Event):void{
			this.stage.addEventListener(MouseEvent.MOUSE_UP, onStageMouseUp, false, 0, true);
		}
		
		private function onTrayMouseDown(evt:MouseEvent):void{
			this.mcSlider.mcTray.startDrag(false, new Rectangle(0,0,100,0));
			this.mcSlider.mcTray.addEventListener(Event.ENTER_FRAME, onFrame, false, 0, true);
		}
		private function onStageMouseUp(evt:MouseEvent):void{
			this.mcSlider.mcTray.stopDrag();
			this.mcSlider.mcTray.removeEventListener(Event.ENTER_FRAME, onFrame);
		}
		private function onFrame(evt:Event):void{		
			var cl:Number = ( (this.mcSlider.mcTray.x/100) * (this._maxCL-1) ) + 1;
			this._CLCap = Math.floor(cl*10)/10;			
			this.mcSlider.mcTray.txtCL.text = this._CLCap.toString();
		}
		
		private function onActorCLCapChange(evt:GlobalEvent):void{
			this.CLCap = evt.data as Number;
		}	
		private function onMaxRingClChange(evt:GlobalEvent):void{
			this.maxCL = evt.data as Number;
		}
		
		private function onBtnMinClick(evt:MouseEvent):void{
			this.CLCap = 1;
		}
		private function onBtnMaxClick(evt:MouseEvent):void{
			this.CLCap = this._maxCL;
		}
		
		private function onBtnApplyClick(evt:MouseEvent):void{
			this.dispatchEvent(new Event(APPLY_CLICK));			
		}
		private function onBtnCancelClick(evt:MouseEvent):void{
			this.dispatchEvent(new Event(CANCEL_CLICK));			
		}
		
		private function setTrayPos():void{
			if (this._CLCap > 0){
				this.mcSlider.mcTray.x = ( (this._CLCap - 1) / (this._maxCL-1) ) * 100;
				this.mcSlider.mcTray.txtCL.text = this._CLCap.toPrecision(2);
			}else{
				this.mcSlider.mcTray.x = 100;
				this.mcSlider.mcTray.txtCL.text = this._maxCL.toPrecision(2);
			}
			
		}
		
		public function get maxCL():Number{
			return this._maxCL;
		}
		public function set maxCL(v:Number):void{
			this._maxCL = Math.round(v * 10)/10;
			this.txtMax.text = this._maxCL.toString()
			if (this._CLCap >= this._maxCL){
				this._CLCap = 0;
			}
			this.setTrayPos();
		}
		
		public function get CLCap():Number{
			return this._CLCap;
		}
		public function set CLCap(v:Number):void{
			this._CLCap = Math.floor(Math.min(v, this._maxCL) * 10)/10;
			this.setTrayPos();
								
		}

	}
}