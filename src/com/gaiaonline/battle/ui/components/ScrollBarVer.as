package com.gaiaonline.battle.ui.components
{
	import com.gaiaonline.battle.ui.events.ScrollBarEvent;
	import com.gaiaonline.utils.DisplayObjectUtils;
	
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.SimpleButton;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Rectangle;

	[Event(name=ScrollBarEvent.SCROLL, type="com.gaiaonline.battle.ui.events.ScrollBarEvent")]
	public class ScrollBarVer extends Sprite
	{
		
		public var slider:Sprite;
		public var bg:Sprite;
		public var btnUp:SimpleButton;
		public var btnDown:SimpleButton;
		
		public var smallStep:Number = 20;
		public var bigStep:Number = 100;
		
		private var _height:Number = 100;
		private var _width:Number = 20;		
		
		private var scrollObj:DisplayObject;
		private var scrollObjHeight:Number = 10;
				
		private var viewArea:Rectangle;
		private var scrollRec:Rectangle;
		private var _isDragging:Boolean = false;
		private var autohide:Boolean = false;
		
		private var btnDownBoundsRelToThis:Rectangle = null;
		private var btnDownBoundsRelToSelf:Rectangle = null;		
		private var btnUpBounds:Rectangle = null;	
				
		public function ScrollBarVer()
		{		
			this.addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
			this._height = super.height;
			this._width = super.width;		
		}
		private function onAddedToStage(evt:Event):void{
			this.slider.addEventListener(MouseEvent.MOUSE_DOWN, onSliderMouseDown, false, 0, true);		
			this.btnUp.addEventListener(MouseEvent.CLICK, onBtnUpClick, false, 0, true);
			this.btnDown.addEventListener(MouseEvent.CLICK, onBtnDownClick, false, 0, true);
			this.bg.addEventListener(MouseEvent.CLICK, onBgMouseClick, false, 0, true);

//			this.stage.addEventListener(MouseEvent.MOUSE_WHEEL, onMouseWheel, false, 0, true);				
		}
		
// Mark Rubin -- Couldn't get this to quite work		
//		private function onMouseWheel(e:MouseEvent):void {
//			var targetContainer:DisplayObjectContainer = e.target as DisplayObjectContainer;
//			var scrollObjContainer:DisplayObjectContainer = this.scrollObj as DisplayObjectContainer;
//			var displayObjTarget:DisplayObject = e.target as DisplayObject;	
//			if (e.target == this || 
//				displayObjTarget && this.contains(displayObjTarget) ||
//				e.target == this.scrollObj || 
//				(scrollObjContainer && displayObjTarget && scrollObjContainer.contains(displayObjTarget))) {
//					var delta:Number = e.delta;
//					if (delta > 0) {
//						this.onBtnUpClick(null);
//					} else {
//						this.onBtnDownClick(null);						
//					}
//			} else {
//				trace("HERE");
//			}
//		}

		private function initButtonsBounds():void {
			if (this.btnDownBoundsRelToThis == null) {
				this.btnDownBoundsRelToThis = this.btnDown.getBounds(this);
			}
			if (this.btnDownBoundsRelToSelf == null) {	
				this.btnDownBoundsRelToSelf = this.btnDown.getBounds(this.btnDown);
			}	
			if (this.btnUpBounds == null) {			
				this.btnUpBounds = this.btnUp.getBounds(this);
			}													
		}		

		public function init(scrollObj:DisplayObject, viewArea:Rectangle, autohide:Boolean = false, scrollTop:Boolean = true):void{
			this.autohide = autohide;
			this.scrollObj = scrollObj;
			this.scrollObjHeight = this.scrollObj.height;
			this.viewArea = viewArea;
			
			this.resize(scrollTop);			
		}
		
		private function resize(scrollTop:Boolean = true):void{
			this.bg.height = this._height;
			this.scaleY = 1;
			
			initButtonsBounds();
						
			//--- set bottom button				
			this.btnDown.y = this._height - this.btnDownBoundsRelToThis.height - this.btnDownBoundsRelToSelf.y;
			
			var rDown:Rectangle  = this.btnDownBoundsRelToThis;
			var rUp:Rectangle = this.btnUpBounds;
			this.scrollRec = new Rectangle(0, this.btnUp.height, this.width, this._height - rUp.height - rDown.height);
						
			this.resizeSlider();			
			if (scrollTop){
				this.slider.y = this.scrollRec.top;
			}else{
				var objH:Number = this.scrollObjHeight-this.viewArea.height;
				var sH:Number = this.maxThumbPos - this.minThumbPos;
				var s:Number = (sH * -(this.scrollObj.y/objH )) + this.minThumbPos;
				if (s > this.maxThumbPos) s = this.maxThumbPos;
				if (s < this.minThumbPos) s = this.minThumbPos;				
				this.slider.y = s;		
			}
		}
		
		
		private function onStageMouseMove(evt:MouseEvent):void{
			if (this._isDragging){
				if (this.slider.y > (this.maxThumbPos)-1){
					this.slider.y = this.maxThumbPos;
				}else if (this.slider.y < (this.minThumbPos +1) ){
					this.slider.y = this.minThumbPos;
				}				
				this.updateObjPos();
			}
		}
		private function onSliderMouseDown(evt:MouseEvent):void{
			if (this.slider.height < this.scrollRec.height){
				this.slider.startDrag(false, new Rectangle(this.slider.x,this.scrollRec.top, 0, this.scrollRec.height - this.slider.height));

				this._isDragging = true;
				DisplayObjectUtils.addWeakListener(this.stage, MouseEvent.MOUSE_UP, onStageMouseUp);
				DisplayObjectUtils.addWeakListener(this.stage, MouseEvent.MOUSE_MOVE, onStageMouseMove);
			}
		}
		private function onStageMouseUp(evt:MouseEvent):void{
			this.slider.stopDrag();
			if (this.stage != null){
				this.stage.removeEventListener(MouseEvent.MOUSE_UP, onStageMouseUp);
				this.stage.removeEventListener(MouseEvent.MOUSE_MOVE, onStageMouseMove);
			}
			this._isDragging = false;
		}
		private function onBtnUpClick(evt:MouseEvent):void{
			this.scroll(-this.smallStep);
		}
		private function onBtnDownClick(evt:MouseEvent):void{
			this.scroll(this.smallStep);
		}
		private function onBgMouseClick(evt:MouseEvent):void{
			if (this.bg.mouseY * this.bg.scaleY < this.slider.y){
				this.scroll(-this.bigStep);
			}else{
				this.scroll(this.bigStep);
			}
		}
		
		public function calculateStep(step:Number):Number {
			return (this.scrollRec.height- this.slider.height) / ((this.scrollObjHeight-this.viewArea.height)/step);
		}

		public function scroll(y:Number):void{
			const s:Number = calculateStep(y);			
			this.slider.y += s;
			if (this.slider.y < this.minThumbPos){
				setSliderToTop();
			}else if (this.slider.y > this.maxThumbPos){
				setSliderToBottom();
			}
			this.updateObjPos();			
		}
		
		private function setSliderToBottom():void {
			this.slider.y = this.maxThumbPos;
		}
		
		private function setSliderToTop():void {
			this.slider.y = this.minThumbPos;			
		}		

		public function scrollToBottom():void {
			setSliderToBottom();
			this.updateObjPos(true);			 
		}
		
		public function scrollToTop():void {
			setSliderToTop();
			this.updateObjPos();				
		}
		
		private function resizeSlider():void{
			
			this.slider.height = (this.viewArea.height/this.scrollObjHeight) * this.scrollRec.height;			
			if(this.slider.height < 10){
				this.slider.height = 10;
				this.visible = true;
			}else if(this.slider.height > this.scrollRec.height){
				this.slider.height = this.scrollRec.height;
				this.slider.y = this.minThumbPos;
				this.visible = !this.autohide;
			}else{
				this.visible = true
			}
			//..... seems like this should sanity check the slider being too big		
		}
		
		private function updateObjPos(forceBottom:Boolean = false):void{
			if (this.slider == null || this.scrollRec == null || this.viewArea == null){
				return;				
			}

			const oldScrollPos:Number = this.scrollObj.y;

			if (this.scrollObjHeight > this.viewArea.height){
				var y:Number = this.slider.y - this.scrollRec.top;
				// using forceBottom to get around any floating point inaccuracies when trying to scroll to bottom
				var p:Number = forceBottom ? 1.0 : y / (this.scrollRec.height - this.slider.height);					
				this.scrollObj.y = this.viewArea.y - (p * (this.scrollObjHeight - this.viewArea.height));
			}else{				
				this.scrollObj.y = this.viewArea.y;
			}
			
			if (oldScrollPos != this.scrollObj.y)
			{
				dispatchEvent(new ScrollBarEvent(ScrollBarEvent.SCROLL));
			}				
		}
		
		public function update():void{
			this.scrollObjHeight = this.scrollObj.height;
			this.resizeSlider();
			this.updateObjPos();			
		}
		
		
		
		public override function set height(v:Number):void{
			this._height = v;
			if (this.scrollObj != null && this.viewArea != null){
				this.resize();
			}
		}
		public override function get height():Number{
			return this._height;
		}
		
		//
		// Note:  unlike most scroll bars, the notion of 'thumbpos' below is in real pixel units of the thumb, not the more typical virtual or scaled units 
		public function get thumbPos():Number
		{
			return this.slider.y;
		}
		public function get maxThumbPos():Number
		{
			return Math.floor(this.scrollRec.bottom - this.slider.height);			
		}
		public function get minThumbPos():Number
		{
			return this.scrollRec.top; 
		}
		public function get isDragging():Boolean
		{
			return this._isDragging;
		}
	}
}