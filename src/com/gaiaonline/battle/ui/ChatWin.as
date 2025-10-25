package com.gaiaonline.battle.ui
{
	import com.gaiaonline.display.windows.Window;
	import flash.display.DisplayObject;
	import flash.events.Event;

	public class ChatWin extends Window
	{
		
		private var mode:int = 0; // 0 close, 1 = open		
		private var winY:Number = 0;
		private var openHeight:int = 200;
		
		public function ChatWin(swfWin:String, container:DisplayObject, isDragable:Boolean=true, isResisable:Boolean=true, showClose:Boolean=true, showMax:Boolean=true, maxWidth:uint=0, maxHeight:uint=0, minWidth:uint=0, minHeight:uint=0)
		{
			super(swfWin, container, isDragable, isResisable, showClose, showMax, maxWidth, maxHeight, minWidth, minHeight);			
			this.tabEnabled = false;
			this.tabChildren = false;
			this.addEventListener(Event.ADDED_TO_STAGE, onChatAddedToStage, false, 0, true);
			this.addEventListener(Event.REMOVED_FROM_STAGE, onChatRemoveFromStage, false, 0, true);
			this.addEventListener(Event.RESIZE, onResize, false, 0, true);
			
		}	
		
		private function onChatAddedToStage(evt:Event):void{
			this.addEventListener(Event.ENTER_FRAME, onEnterFrame);
		}
		private function onChatRemoveFromStage(evt:Event):void{
			this.removeEventListener(Event.ENTER_FRAME, onEnterFrame);
		}
			
		public function setMode(mode:int):void{
					
			if (mode == 0){				
				this.setIsDragable(false);
				this.setMaxHeight(33);
				this.setMinHeight(33);
				this.setSize(this.winWidth, 33);
				this.y = this.winY;				
			} else if (mode==3){
				this.setIsDragable(true);				
				this.setMaxHeight(500);
				this.setMinHeight(50);
				this.setSize(300, 200);				
				this.y = this.winY - this.winHeight + 33;
			} else if (mode==4){
				this.setIsDragable(true);				
				this.setMaxHeight(500);
				this.setMinHeight(100);
				this.setSize(400, 500);				
				this.y = this.winY - this.winHeight + 33;				
			}else{				
				this.setIsDragable(true);				
				this.setMaxHeight(500);
				this.setMinHeight(50);
				this.setSize(this.winWidth, this.openHeight);				
				this.y = this.winY - this.winHeight + 33;				
			}
			this.checkPos();			
			this.mode = mode;
			this.dispatchEvent(new Event(Settings.SETTING_CHANGED_EVENT));
		}	
		
		private function onEnterFrame(evt:Event):void{
			if (this.mode == 0){
				this.winY = this.y;
			}else{
				this.winY = this.y + (this.winHeight - 33);
			}			
		}
		
		public override function getSettings():Object{
			
			var obj:Object = new Object();			
			obj.x = this.x;
			obj.y = this.winY;
			obj.winWidth = this.winWidth;
			//obj.winHeight = this.winHeight;
			//obj.isMax = this.isMax;
			//obj.minWidth = this.minWidth;
			//obj.minHeight = this.minHeight;
			//obj.maxWidth = this.maxWidth;
			//obj.maxHeight = this.maxHeight;
			//obj.isDragable = this.isDragable;
			//obj.isResisable = this.isResisable;
			//obj.showClose = this.showClose;
			//obj.showMax = this.showMax;
			obj.resetWidth = this.resetWidth;
			//obj.resetHeight = this.resetHeight;
			obj.resetX = this.resetX;
			//obj.resetY = this.resetY;			
			
			return obj;
			
		}
		
		public override function setSettings(obj:Object):void{
			this.x = obj.x;			
			this.winWidth = obj.winWidth;			
			this.winY = obj.y;				
			
			if (this.mode == 1){
				this.y = this.winY - this.openHeight + 33;
			}else{
				this.y = this.winY
			}
			
			
			this.isMax = obj.isMax;
			this.minWidth = obj.minWidth;
			//this.minHeight = obj.minHeight;
			this.maxWidth = obj.maxWidth;
			//this.maxHeight = obj.maxHeight;
			//this.isDragable = obj.isDragable;
			//this.isResisable = obj.isResisable;
			//this.showClose = obj.showClose;
			//this.showMax = obj.showMax;			
			this.resetWidth = obj.resetWidth;
			//this.resetHeight = obj.resetHeight;
			this.resetX = obj.resetX;
			//this.resetY = obj.resetY;	
			
			if (this.isLoaded){
				this.setSize(this.winWidth, this.winHeight)
				this.checkPos();	
			}
					
		}		
		
		private function onResize(evt:Event):void{
			if (this.mode == 1){				
				this.openHeight = this.winHeight;
			}
		}
		
		public function setWinY(v:Number):void{
			this.winY = v;
			if (this.mode == 0){
				this.y = this.y;
			}else{
				this.y = this.winY - this.winHeight + 33;
			}		
			
		}			
	}
}