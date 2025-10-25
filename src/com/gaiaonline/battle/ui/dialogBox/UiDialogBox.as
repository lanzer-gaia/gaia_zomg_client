package com.gaiaonline.battle.ui.dialogBox
{
	import com.gaiaonline.battle.ui.events.UiEvents;
	import com.gaiaonline.battle.utils.BattleUtils;
	import com.gaiaonline.flexModulesAPIs.globalevent.GlobalEvent;
	import com.gaiaonline.utils.VisManagerSingleParent;
	
	import flash.display.MovieClip;
	import flash.display.SimpleButton;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.MouseEvent;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;	

	public class UiDialogBox extends MovieClip
	{
		private var convs:Object = new Object();
		private var convsList:Array = new Array();
		private var convId:String;
		public var actorId:String;
		private var leftSide:Boolean = false;
		private var wfs:Boolean = false;
		private var visManager:VisManagerSingleParent = null;
		
		public var avLeft:MovieClip;
		public var avRight:MovieClip;
		public var labelLeft:TextField
		public var labelRight:TextField;		
		public var lLeft:MovieClip;
		public var lRight:MovieClip;				
		public var avMask:MovieClip;
		public var cMask:MovieClip;
		public var btnOk:SimpleButton;								
		public var bubble:MovieClip;										
		public var container:MovieClip;												
		public var wait:MovieClip;
		
		public var scr:Object;
		
		public function UiDialogBox(){
			this.visManager = new VisManagerSingleParent(this as MovieClip);			
			this.btnOk.addEventListener(MouseEvent.CLICK, onOkClick, false, 0, true);	
			this.scr.addEventListener("scroll" , onScroll, false, 0, true);			
			this.tabChildren = false;
			this.setWaitVisible(false);
		}
		
		private function onOkClick(evt:MouseEvent):void{
			
			if (this.container && this.container.data) {
				var e:UiEvents = new UiEvents("DIALOG", "");
				e.value = new Object();
				e.value.convId = this.container.convId;
				e.value.dialogId = this.container.data.dialogId;
				e.value.npcId = this.container.data.npcId;
				e.value.actorName = this.container.data.actorName;		
				e.value.numberOfTimesSent = 1;	
							
				var txt:String;
				if (this.container.data.txt != null){
					txt = this.container.data.txt;
					e.value.txt = txt;
				}
				
				var haveNextText:Boolean = this.nextText(e);
	
				e.value.getNext = !haveNextText;
				
				this.dispatchEvent(e);
			} else {
				GlobalEvent.eventDispatcher.dispatchEvent(new GlobalEvent(GlobalEvent.DIALOG_CLOSE, {}));
			}			
		}
				
		
		public function addText(convId:String, dialogId:String, npcId:String, actorId:String, actorName:String, actorMc:Sprite, txt:String = null, options:Array = null):void{
			cancelPendingRequest(convId);			

			if (this.convs[convId] == null){
				this.convs[convId] = new Array();
				this.convsList.push(convId);
			}
			
			
			var obj:Object = new Object();
			obj.dialogId = dialogId;
			obj.npcId = npcId;
			obj.actorId = actorId;			
			obj.actorName = actorName;
			obj.actorMc = actorMc;
			obj.txt = txt;			
			obj.options = options;			
			this.convs[convId].push(obj);		
							
			if (this.convId == null || (this.convId == convId && wfs)){
				this.wfs = false;
				this.convId = convId;
				this.nextText();
			}
			
		}
		
		private var _requestsWaitingForServerResponse:Object = new Object(); // hash of convo IDs to UiEvents and Timers that were dispatched for server responses
		private function nextText(e:UiEvents = null):Boolean{
				
			//----- Create Page		
			if (this.convs[this.convId] != null && this.convs[this.convId][0] != null){				
				var obj:Object = this.convs[this.convId][0];					
				
				this.buildPage(obj);				
				
				// clear from list
				this.convs[this.convId].shift();				
				return true;
			
			}else{
				if (e != null) {
					cancelPendingRequest(e.value.convId);
					var pendingRequest:PendingConversationRequest = new PendingConversationRequest(this, e); 					
					_requestsWaitingForServerResponse[e.value.convId] = pendingRequest;
					pendingRequest.startTimer();
				}
				this.waitForServer();
				return false;
			}			
			
		}
		
		private function setLeftSideVisible(visible:Boolean):void {
			this.visManager.setVisible(this.avLeft, visible);			
			this.visManager.setVisible(this.lLeft, visible);			
			// for some reason, the text gets a bit clipped if I use the visManager, and it's not worth the time for me
			// to figure out why, so I'll just use the native visibility property rather than adding and removing from the stage.
			this.labelLeft.visible = visible;
		}

		private function setRightSideVisible(visible:Boolean):void {
			this.visManager.setVisible(this.avRight, visible);			
			this.visManager.setVisible(this.lRight, visible);			
			// for some reason, the text gets a bit clipped if I use the visManager, and it's not worth the time for me
			// to figure out why, so I'll just use the native visibility property rather than adding and removing from the stage.			
			this.labelRight.visible = visible;	
		}

		private function setContainerTextVisible(visible:Boolean):void {
			this.visManager.setVisible(this.container.txt, visible);
		}
		
		private function setWaitVisible(visible:Boolean):void {
			this.visManager.setVisible(this.wait, visible);
			if (visible) {
				this.wait.gotoAndPlay(2);				
			} else {
				this.wait.gotoAndStop(2);
			}
			
			this.visManager.setVisible(this.container, !visible);
		}			

		private function setOptionsVisible(visible:Boolean):void {
			this.visManager.setVisible(this.container.mcOptions, visible);
		}

		private function setOKButtonVisible(visible:Boolean):void {
			this.visManager.setVisible(this.btnOk, visible);
		}


		private function buildPage(obj:Object):void{
			//--- Clear Anny Options
			while(Sprite(this.container.mcOptions).numChildren > 0){
				Sprite(this.container.mcOptions).removeChildAt(0);
			}
			
			//-- Clear Av
			while(this.avLeft.numChildren >0){
				this.avLeft.removeChildAt(0);
			}
			while(this.avRight.numChildren >0){
				this.avRight.removeChildAt(0);
			}
			
			// set Actor
			var ac:String = obj.actorId;			
			if (ac != this.actorId){
				this.leftSide = !this.leftSide;		
			}	
			this.actorId = ac;	
			if (obj.actorMc != null){
				if (this.leftSide){
					this.avLeft.addChild(obj.actorMc);
					this.labelLeft.text = obj.actorName;		
				}else{
					this.avRight.addChild(obj.actorMc);
					this.labelRight.text = obj.actorName;		
				}		
			}				
			
			// Actor and name visible
			this.setLeftSideVisible(this.leftSide);
			this.setRightSideVisible(!this.leftSide);			
								
			
			// set visible and data
			this.setWaitVisible(false);
			this.container.data = obj;	
			this.container.convId = this.convId;	
					
			
			// Set txt	
			var y:int = 0;			
			if (obj.txt != null){				
				this.container.txt.text = obj.txt;
				TextField(this.container.txt).autoSize = TextFieldAutoSize.LEFT;
				this.setContainerTextVisible(true);				
				y = TextField(this.container.txt).height + 5;
				
			}else{
				this.setContainerTextVisible(false);								
			}
			
			
			//-- Options
			this.container.mcOptions.y = y;
			if (obj.options != null){								
				var oy:int = 0;
				for (var oi:int = 0; oi < obj.options.length; oi++){					
					var o:UiDialogOption = new UiDialogOption();
					o.option.txtOption.text = obj.options[oi].txt;
					o.option.txtOption.autoSize = TextFieldAutoSize.LEFT;					
					o.id = obj.options[oi].id;
					o.y = oy;
					
					SimpleButton(o.btn).height = o.height;
					
					oy = oy + o.height;
					o.addEventListener(MouseEvent.CLICK, onOptionClick);
					Sprite(this.container.mcOptions).addChild(o);					
				}			
				this.setOptionsVisible(true);		
				this.setOKButtonVisible(false);
				
			}else{
				this.setOptionsVisible(false);				
				this.setOKButtonVisible(true);
			}
			
			
			this.setScrollSize();
			
			
						
		}
				
		private function onOptionClick(evt:MouseEvent):void{
			
			
			var e:UiEvents = new UiEvents("DIALOG", "");
			e.value = new Object();
			e.value.convId = this.container.convId;
			e.value.dialogId = this.container.data.dialogId;
			e.value.npcId = this.container.data.npcId;
			e.value.optionId = evt.currentTarget.id;
			e.value.actorName = this.container.data.actorName;
			e.value.numberOfTimesSent = 1;				
			
			/*		
			trace(this.container.convId);						
			trace(this.container.data.txt);
			trace(this.container.data.dialogId);
			trace(this.container.data.npcId);
			trace(this.container.data.actorName);
			trace(evt.currentTarget.id, evt.currentTarget.option.txtOption.text);
			*/
			
			var txt:String;
			if (this.container.data.txt != null){
				txt = this.container.data.txt;
			}
			if (evt.currentTarget.option != null){
				if (txt != null){
					txt = txt + "  " + evt.currentTarget.option.txtOption.text;
				}else{
					txt = evt.currentTarget.option.txtOption.text;
				}
			}
			
			if (txt != null){
				e.value.txt = txt;
			}		
			
			this.dispatchEvent(e);
			
			this.nextText(e);
			
			EventDispatcher(evt.target).removeEventListener(MouseEvent.CLICK, onOptionClick);
			
		}
		
		private function waitForServer():void{
			
			/*
			if (this.convs[convId] != null){
				delete this.convs[convId];
				var i:int = this.convsList.indexOf(convId);
				if (i >=0){
					this.convsList.splice(i,1);
				}		
			} */
			
			//this.convId = null;
			
			this.wfs = true; 
					
			this.setWaitVisible(true);
			this.setOKButtonVisible(false);
		}		
		
		private function cancelPendingRequest(convId:String):void {
			var pendingRequest:PendingConversationRequest = _requestsWaitingForServerResponse[convId];
			if (pendingRequest != null) {
				pendingRequest.endTimer();
			}
			delete _requestsWaitingForServerResponse[convId];			
		}	
		
		public function endConv(convId:String, isNaturalDone:Boolean = true):void{
			var endConvId:String = isNaturalDone ? (convId || this.convId) : null;

			if (convId == null){
				BattleUtils.cleanObject(this.convs);
				this.convsList.length = 0;
				this.convId = null;
				this.leftSide = false;
				GlobalEvent.eventDispatcher.dispatchEvent(new GlobalEvent(GlobalEvent.DIALOG_DONE, {}));				
			}else{
				cancelPendingRequest(convId);
				delete this.convs[convId];
				var i:int = this.convsList.indexOf(convId);	
				if (i >=0){
					this.convsList.splice(i,1);
			
					// get next convId	
					var foundNextConversation:Boolean = false;		
					while (this.convsList.length > 0){										
						this.convId = this.convsList[0]
						if (convs[this.convId]) {
							foundNextConversation = true;
							break;
						} else {
							convsList.shift();
						}
					}
					if (foundNextConversation) {
						this.nextText();					
					}else{			
						this.setWaitVisible(false);
						this.convId = null;
						this.convsList.length = 0;
						BattleUtils.cleanObject(this.convs);
						GlobalEvent.eventDispatcher.dispatchEvent(new GlobalEvent(GlobalEvent.DIALOG_DONE, {}));					
					}
				}
			}
			if (endConvId != null) {
				GlobalEvent.eventDispatcher.dispatchEvent(new GlobalEvent(GlobalEvent.CONVERSATION_END, {convId:endConvId}));
			}																
		}
		
		public function endActorConv(npcId:String):void{
			/*
			trace("END ACTOR  CONV :", actorId)
			trace(this.convsList);
			trace(this.convs);
			for (var i:int = 0; i < this.convsList.length; i++){
				trace(i, this.convsList[i]);
				trace(this.convs[this.convsList[i]]);
				for(var ii:int = 0; ii < this.convs[this.convsList[i]].length; ii++){
					trace(this.convs[this.convsList[i]][ii].npcId);
				}
							
			}
			trace("========");
			
			*/
		}
		
		//--- Scrolll 		
		private function setScrollSize():void{
			
			this.container.y = 17;
			this.scr.scrollPosition = 0;
			this.scr.setScrollProperties(this.cMask.height, 0, this.container.height - this.cMask.height);			
			this.scr.lineScrollSize = this.cMask.height;			
			if( this.container.height - this.cMask.height > 0 ){
				this.scr.visible = true;							
			}else{
				this.scr.visible = false;											
			}			
		}
		
		private function onScroll(evt:Event):void{
			this.container.y = -this.scr.scrollPosition + 17;
		}
		
		
		public function resize(w:Number, h:Number):void{
			
			this.bubble.height = h - 21;			
			this.btnOk.y =  h - 27;
			this.avMask.height = h-15;			
			this.cMask.height = this.bubble.height - 21;		
			this.scr.height = this.cMask.height;
			this.labelLeft.y = this.labelRight.y = h -18;			
			
			this.setScrollSize();		
					
		}	
	
	}
	
}

import com.gaiaonline.battle.ui.events.UiEvents;
import flash.utils.Timer;
import flash.events.TimerEvent;
import com.gaiaonline.battle.ui.dialogBox.UiDialogBox;
	
class PendingConversationRequest {
	private var _uiEvent:UiEvents = null;
	private var _uiEventClone:UiEvents = null;	
	private var _timer:Timer = null;
	private var _dialogBox:UiDialogBox = null;

	public function PendingConversationRequest(dialogBox:UiDialogBox, e:UiEvents) {
		_uiEvent = e.clone() as UiEvents;
		_dialogBox = dialogBox;
	}
	
	public function startTimer():void {
		_timer = new Timer(2000, 3); // 2 second, three  times
		_timer.addEventListener(TimerEvent.TIMER, onTimer, false, 0, true);
		_timer.addEventListener(TimerEvent.TIMER_COMPLETE, onTimerComplete, false, 0, true);
		_timer.start();
	}
	public function endTimer():void {
		_timer.stop();
	}
	private function onTimer(e:TimerEvent):void {
		++_uiEvent.value.numberOfTimesSent;					
		_dialogBox.dispatchEvent(_uiEvent);
	}
	private function onTimerComplete(e:TimerEvent):void {
		_dialogBox.endConv(_uiEvent.value.convId);
	}
}
	
	
