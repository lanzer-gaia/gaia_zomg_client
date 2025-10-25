package com.gaiaonline.battle.ui
{
	import com.gaiaonline.battle.ui.events.UiEvents;
	import com.gaiaonline.flexModulesAPIs.globalevent.GlobalEvent;
	
	import flash.display.InteractiveObject;
	import flash.display.MovieClip;
	import flash.display.SimpleButton;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.text.TextField;	

	public class UiAdminPanel extends MovieClip
	{
		public var btnLights:SimpleButton;							
		public var btnSend:SimpleButton;								
		public var btnSetGST:SimpleButton;								
		public var btnShowCollision:SimpleButton;
		public var btnSaveMe:SimpleButton;
		public var chkSpawn:MovieClip;
		public var slider:MovieClip;
		public var txtCallBack:TextField;												
		public var txtCmd:TextField;												
		public var txtGst:TextField;												
		public var txtParam:TextField;																		

		public function UiAdminPanel()
		{
			this.tabEnabled = true;
			
			InteractiveObject(this.txtCmd).tabIndex = 0;
			InteractiveObject(this.txtParam).tabIndex = 1;
			InteractiveObject(this.btnSend).tabIndex = 2;
			InteractiveObject(this.chkSpawn).tabIndex = 3;
			InteractiveObject(this.btnSaveMe).tabIndex = 4;				
			InteractiveObject(this.btnShowCollision).tabIndex = 5;									
			InteractiveObject(this.txtGst).tabIndex = 6;
			InteractiveObject(this.btnSetGST).tabIndex = 7;
			InteractiveObject(this.btnLights).tabIndex = 8;

			this.btnSend.addEventListener(MouseEvent.CLICK, onSendClick, false, 0, true);			
			this.btnShowCollision.addEventListener(MouseEvent.CLICK, onShowCollisionClick, false, 0, true);
			this.btnSetGST.addEventListener(MouseEvent.CLICK, onSetGstClick, false, 0, true);
			this.btnLights.addEventListener(MouseEvent.CLICK, onLightsClick, false, 0, true);
			
			this.slider.gotoAndStop(1);
			this.slider.sliderPanel.btnSlider.gotoAndStop(1);	
			this.slider.sliderPanel.btnSlider.addEventListener(MouseEvent.CLICK, onSliderClick, false, 0, true);			
						
			this.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown, false, 0, true);
			this.addEventListener(KeyboardEvent.KEY_UP, onKeyUp, false, 0, true);
			this.addEventListener(Event.ADDED_TO_STAGE, onAddedToStage, false, 0, true);
			
			this.btnSaveMe.addEventListener(MouseEvent.CLICK, onSaveMe, false, 0, true);

			this.chkSpawn.addEventListener(MouseEvent.CLICK, onChkSpawnClick, false, 0, true);		

			_history.push({cmd: "599", param: "me.setBaseMaxHP(1234567)"});
			_history.push({cmd: "196", param: "1"});
			_history.push({cmd: "599", param: "for (i = 0; i < 40; ++i) {me.getBattleRoom().spawnMonster(\"fluff\",200,200)}"}); 
			_history.push({cmd: "599", param: "me.getBattleRoom().actorList.each{ if(it != me) it.smite() }"});
			_history.push({cmd: "198", param: "TestIsland1_102"});
			setCommandFromHistory(_history.length - 1);
		}
		
		private function onAddedToStage(evt:Event):void {
			this.stage.focus = this.txtCmd;			
		}
		
		private function onSendClick(evt:MouseEvent):void {
			send();
		}
		
		public function getCall():Object
		{
			return {
				cmd: this.txtCmd.text,
				param: this.txtParam.text
			};
		}
		
		public function setCallbackObject(obj:Object):void
		{
			var str:String = "";
			for (var key:String in obj)
			{
				if (str.length)
				{
					str += "; ";
				}
				str += key + ": " + obj[key];
			}
			this.txtCallBack.text = str;
		}

		private function send(bRecordHistory:Boolean = true):void
		{
			if (bRecordHistory)
			{
				const args:Object = getCall();
				const lastItem:Object = _history.length ? _history[_history.length-1] : null;
				if (!lastItem || lastItem.cmd != args.cmd || lastItem.param != args.param)
				{
					_history.push(args);
					_currentHistoryIndex = _history.length-1;
				}
			}

			this.dispatchEvent(new Event("Send"));
		}
		
		private function clearFocus():void {
			this.stage.focus = null;
		}

		private static const KEY_BACKHISTORY:uint = 38;  // up
		private static const KEY_FWDHISTORY:uint = 40;   // dn
		private static const KEY_F12:uint = 123;
		private static const KEY_ESC:uint = 27;
		private var _history:Array = [];
		private var _currentHistoryIndex:int = -1;
		public function onKeyDown(evt:KeyboardEvent):void
		{
			switch(evt.keyCode) {
				case 13:
					send();
					break;
				case KEY_BACKHISTORY:
					setCommandFromHistory(_currentHistoryIndex - 1);
					break;
				case KEY_FWDHISTORY:
					setCommandFromHistory(_currentHistoryIndex + 1);
					break;
				default:
					break;
			}
			evt.stopImmediatePropagation();								
		}
		private function onKeyUp(evt:KeyboardEvent):void
		{
			switch(evt.keyCode) {
			case KEY_ESC:
			case KEY_F12:
				// very dirty, but this is an internal tool
				if (this.parent && this.parent.parent)
				{
					this.parent.parent.removeChild(this.parent);
				}
				break;
			case 13:			
				this.stage.focus = null;
				break;
			}
			evt.stopImmediatePropagation();
		}
		private function setCommandFromHistory(index:int):void
		{
			var old:int = _currentHistoryIndex;
			_currentHistoryIndex = Math.max(0, Math.min(index, _history.length - 1));

			if (old != _currentHistoryIndex)
			{
				this.txtCmd.text = _history[_currentHistoryIndex].cmd;
				this.txtParam.text = _history[_currentHistoryIndex].param;
			}
		}
		
		public function onMapAllAreaClick(evt:MouseEvent):void{
			this.dispatchEvent(new Event("MapAllArea"));
		}
		
		public function onMapAllClick(evt:MouseEvent):void{
			this.dispatchEvent(new Event("MapAll"));
		}
				
		public function onMapRoomClick(evt:Event):void{
			this.dispatchEvent(new Event("MapRoom"));
		}
		
		private function onShowCollisionClick(evt:MouseEvent):void{
			this.dispatchEvent(new Event("ShowCollision"));
		}
		
		private function onChkSpawnClick(evt:MouseEvent):void{
			var check:Boolean = false;			
			if (this.chkSpawn.currentFrame == 2){
				check = true
			}
			
			if (check){
				this.chkSpawn.gotoAndStop(1);				
			}else{
				this.chkSpawn.gotoAndStop(2);
			}			
			
			GlobalEvent.eventDispatcher.dispatchEvent(new GlobalEvent(GlobalEvent.SHOW_SPAWN_STATE_CHANGED, {show:!check}));
		}
		private function onSaveMe(e:Event):void
		{
			// lame.
			var call:Object = getCall();
			this.txtCmd.text = "197";
			send(false);
			
			this.txtCmd.text = "196";
			this.txtParam.text = "20";
			send(false); 
			
			this.txtCmd.text = call.cmd;
			this.txtParam.text = call.param;
		}
				
		private function onSetGstClick(evt:MouseEvent):void{
			
			var a:Array = this.txtGst.text.split(":");			
			if (a.length == 2 && parseInt(a[0]) <= 23 && parseInt(a[1]) <= 59 ){
				var v:Object = {h:parseInt(a[0]), m:parseInt(a[1])}
				var e:UiEvents = new UiEvents("SetGst", null);	
				e.value = v;
				this.dispatchEvent(e);
			}			
					
		}
		
		private function onLightsClick(evt:MouseEvent):void{
			this.dispatchEvent(new Event("Lights"));
		}
	
		private var sliderOpen:Boolean = false;
		//---- Slider
		private function onSliderClick(evt:MouseEvent):void{
			//trace("SLIDE CLICK ", this.sliderOpen)
			if (this.sliderOpen){
				this.slider.gotoAndPlay("close");
				this.slider.sliderPanel.btnSlider.gotoAndStop(1);
				this.sliderOpen = false;
			}else{
				this.slider.gotoAndPlay("open");
				this.slider.sliderPanel.btnSlider.gotoAndStop(2);
				this.sliderOpen = true;
			}
		}
	}
}