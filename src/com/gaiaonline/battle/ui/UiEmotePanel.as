package com.gaiaonline.battle.ui
{
	import com.gaiaonline.battle.ui.events.UiEvents;
	
	import flash.display.MovieClip;
	import flash.display.SimpleButton;
	import flash.display.Sprite;
	import flash.events.MouseEvent;

	public class UiEmotePanel extends MovieClip
	{
		
		private var yPos:Number = 0;
		private var h:Number = (4 * 23);
		
		public var container:MovieClip;
		public var btnUp:MovieClip;
		public var btnDown:MovieClip;
		
		public function UiEmotePanel(){
			
			this.yPos = this.container.y;
			this.btnUp.addEventListener(MouseEvent.CLICK, onUpClick, false, 0, true);
			this.btnDown.addEventListener(MouseEvent.CLICK, onDownClick, false, 0, true);
			this.tabChildren = false;		
		}
		
		public function addEmote(id:String, EmoteIcon:Sprite):void {
			var ems:UiEmoteSlot = new UiEmoteSlot();
			EmoteIcon.mouseEnabled = false;
			EmoteIcon.mouseChildren = false;
			EmoteIcon.x = 1;
			EmoteIcon.y = 1;
			ems.addChild(EmoteIcon);			
			ems.id = id;
			
			var r:int = Math.abs(Sprite(this.container).numChildren / 6 );
			var c:Number = Sprite(this.container).numChildren - (r*6);
			ems.y = r * 23;
			ems.x = c * 23;
			
			Sprite(ems).addEventListener(MouseEvent.MOUSE_OVER, onSlotMouseOver, false, 0, true);
			Sprite(ems).addEventListener(MouseEvent.MOUSE_OUT, onSlotMouseOut, false, 0, true);
			Sprite(ems).addEventListener(MouseEvent.CLICK, onSlotClick, false, 0, true);
						
			this.container.addChild(ems);
		}
		
		private function onSlotMouseOver(evt:MouseEvent):void{
			MovieClip(evt.target).gotoAndStop(2);
		}
		private function onSlotMouseOut(evt:MouseEvent):void{
			MovieClip(evt.target).gotoAndStop(1);
		}
		private function onSlotClick(evt:MouseEvent):void{
			var id:String = evt.currentTarget.id;
			if (!id) {
				id = evt.target.id;
			}
			var event:UiEvents = new UiEvents("EmoteClick", evt.currentTarget.id);
			this.dispatchEvent(event);
		}
		
		
		private function onUpClick(evt:MouseEvent):void{
			if (this.container.y < this.yPos){
				this.container.y += 23;
			}
		}
		private function onDownClick(evt:MouseEvent):void{
			if (this.container.y > yPos-(this.container.height - h)){
				this.container.y -= 23;
			}
		}
		
	}
}