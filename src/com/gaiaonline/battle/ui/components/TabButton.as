package com.gaiaonline.battle.ui.components
{
	import com.gaiaonline.battle.ui.events.UiEvents;
	import com.gaiaonline.utils.DisplayObjectUtils;
	
	import flash.display.MovieClip;
	import flash.events.MouseEvent;
	import flash.text.TextField;
	
	public class TabButton extends MovieClip
	{
		
		public var back:MovieClip;
		public var txtLabel:TextField;
		public var mcSort:MovieClip;
			
		private var _isActive:Boolean = false;
		private var _mouseOver:Boolean = false;
		private var _sortAscending:Boolean = true;
		private var _enabled:Boolean = true;
				
		public function TabButton(){
			this.buttonMode = true;
			this.mouseChildren = false;
			//this.txtLabel.mouseEnabled = false;
			
			DisplayObjectUtils.addWeakListener(this, MouseEvent.MOUSE_OVER, onMouseOver);
			DisplayObjectUtils.addWeakListener(this, MouseEvent.MOUSE_OUT, onMouseOut);
			DisplayObjectUtils.addWeakListener(this, MouseEvent.CLICK, onMouseClick);				
		}
		
		private function onMouseOver(evt:MouseEvent):void{
			this._mouseOver = true;	
			this.setState();		
		}
		private function onMouseOut(evt:MouseEvent):void{
			this._mouseOver = false;
			this.setState();	
		}
		private function onMouseClick(evt:MouseEvent):void{	
			if (!this._enabled) {
				evt.preventDefault();
				evt.stopPropagation();
				return;
			}
			if (this._isActive){				
				this.setSort(!this._sortAscending);		
			}else{
				this.isActive = true;
				this.dispatchEvent(new UiEvents(UiEvents.TAB_IS_ACTIVE,""));
			}		
			this.dispatchEvent(new UiEvents(UiEvents.TAB_CLICK,""));
		}
		
		private function setSort(ascending:Boolean):void{
			this._sortAscending = ascending;
			if(this.mcSort != null){
				if (ascending){					
					this.mcSort.gotoAndStop("Ascending");
				}else{					
					this.mcSort.gotoAndStop("Descending");
				}
			}
		}
		
		private function setState():void{
			var s:String = "unselected_"
			if (this.isActive){
				s = "selected_";
				if (this.totalFrames == 2){
					this.gotoAndStop(2);
				}			
			}else{
				if (this.totalFrames == 2){
					this.gotoAndStop(1);
				}
			}
			
			var m:String = "MouseOff";
			if (this._mouseOver){
				m = "MouseOn";
			}			
			this.back.gotoAndStop(s+m);
		}

		public function get isEnabled():Boolean {
			return this._enabled;
		}
		
		public function set isEnabled(enabled:Boolean):void {
			this._enabled = enabled;
		}		
		
		public function get isActive():Boolean{
			return this._isActive;
		}
		
		public function set isActive(v:Boolean):void{
			this._isActive = v;
			this.setState();		
		}
		
		public function get sortAscending():Boolean{
			return this._sortAscending;
		}
		
		public function set sortAscending(v:Boolean):void{
			this.setSort(v);
		}
		
		public function set isDisabled(v:Boolean):void{
			if (v){
				this.buttonMode = false;
				this._isActive = true;
				this.txtLabel.alpha = 0.5;
			} else {
				this.buttonMode = true;
				this.txtLabel.alpha = 1;			
			}
			this.setState();
		}
	}
}