package com.gaiaonline.battle.ui.uiactionbar
{
	import com.gaiaonline.battle.ui.events.ActionBarEvent;
	import com.gaiaonline.flexModulesAPIs.globalevent.GlobalEvent;
	import com.gaiaonline.utils.DisplayObjectUtils;
	import com.gaiaonline.utils.MovieClipProxy;
	
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.events.MouseEvent;
	
	public class Menu extends MovieClipProxy
	{
		public var menuLine:MovieClip
		public var mcBack:MovieClip;
		public var mcMask:MovieClip;
		public var btnMenu:MovieClip;
		
		private var items:Array;
		private var itemY:int = 8;//previous value = 6
		private var open:Boolean = false;
		
		private var mcBackIndex:int = -1
		private var mcMaskIndex:int = -1;		
		
		private var _mcMenu:MenuFl;		

		static public const CMD_SHOPS:String = "Shops";
		static public const CMD_OPTIONS:String = "Options";
		static public const CMD_MUSIC_PLAYER:String = "Music player";
		static public const CMD_REPORT_ABUSE:String = "Report Abuse";				
		static public const CMD_HELP:String = "Game Help";				
		static public const CMD_QUIT:String = "Quit";
		static public const CMD_REGISTER:String = "Register";
		static public const CMD_UI_TESTER:String = "UI Tester";		
		static public const CMD_ADMIN_PANEL:String = "Admin Panel";
		static public const CMD_DISCONNECT:String = "Disconnect";
		static public const CMD_CLCAP:String = "Change Level";	
		
		public function Menu(mcMenu:MenuFl)
		{
			super(mcMenu);
			this._mcMenu = mcMenu;
			this.menuLine = this._mcMenu.menuLine;
			this.mcBack = this._mcMenu.mcBack;
			this.mcMask = this._mcMenu.mcMask;
			this.btnMenu = this._mcMenu.btnMenu;
			
			this.items = new Array();
			
			// this order matters, should jive with onGuestRegistered - we could instead implement hide/show semantics for menu items -kja
			this.addMenuItem(CMD_SHOPS);
			this.addMenuItem(CMD_MUSIC_PLAYER);
			this.addMenuItem(CMD_HELP);
			this.addMenuItem(CMD_OPTIONS);
									
			// Removing quit for now, since we can't really reliably close the browser window on quit, and if we just refresh the page, then
			// n00bs are taken past the world server list right back into the game where they hit Quit.
			// -- Mark Rubin
			this.btnMenu.buttonMode = true;
			this.btnMenu.mouseChildren = false;				
			
			this.btnMenu.addEventListener(MouseEvent.MOUSE_OVER, onBtnMenuOver, false, 0, true);
			this.btnMenu.addEventListener(MouseEvent.MOUSE_OUT, onBtnMenuOut, false, 0, true);
			this.btnMenu.addEventListener(MouseEvent.CLICK, onBtnMenuClick, false, 0, true);

			DisplayObjectUtils.addWeakListener(GlobalEvent.eventDispatcher, GlobalEvent.WIDGET_SHOW, onWidgetShow);
			DisplayObjectUtils.addWeakListener(GlobalEvent.eventDispatcher, GlobalEvent.USER_LEVEL_SET, onUserLevelSet);
			DisplayObjectUtils.addWeakListener(GlobalEvent.eventDispatcher, GlobalEvent.SUPPRESSED_CL_CHANGE, onSuppressedCLChange);
			DisplayObjectUtils.addWeakListener(GlobalEvent.eventDispatcher, GlobalEvent.PLAYER_CON_LEVEL_UPDATED, onPlayerCL);
			
			this.mcBackIndex = this.getChildIndex(this.mcBack);				
			this.mcMaskIndex = this.getChildIndex(this.mcMask);
			this.removeChild(this.mcBack);
			this.removeChild(this.mcMask);										
		}

		public function addMenuItem(txt:String, after:String = null):void
		{
			if (this.menuHasItem(txt)) { // prevent duplicates
				return;
			} 

			show(false);  //FS#34151

			var mi:MenuItem = new MenuItem();
			mi.txt.text = txt.toUpperCase();			
			mi.btn.addEventListener(MouseEvent.CLICK, onItemClick);
			mi.x = 0;
			
			var found:Boolean = false; // just in case the item is never found; we'll use this to see if we should just append to the end then
			if (after != null) {			
				for (var i:uint=0;i<this.items.length;++i) {
					var miToFind:MenuItem = this.items[i];
					if (miToFind.txt.text == after.toUpperCase()) {
						found = true;
						var position:uint = i + 1; // our new position
						if (position == this.mcBack.numChildren) { // if the new position is at the end of the list, just place ourselves
							mi.y = this.itemY;							
						} else { // otherwise, put ourselves where the item that currently occupies our slot is
							mi.y = this.items[position].y; 											
						}
						this.items.splice(position, 0, mi);												
						// now walk through and move everything
						for (var j:uint = this.items.length -1; j > position; --j) {
							this.items[j].y+= 18; 					
						}
						// insert us in the display list
						this.mcBack.addChildAt(mi, position);	
						break;					
					}
				}
				this.itemY += 18;								
			}
			
			if (after == null || !found) {						
				this.items.push(mi);			
				this.mcBack.addChild(mi);
				mi.y = this.itemY;			
				this.itemY += 18;//previous value = 20
			} 
		}
		public function removeMenuItem(txt:String):void {
			for (var i:uint=0;i<this.items.length;++i) {
				var mi:MenuItem = this.items[i];
				if (mi.txt.text == txt.toUpperCase()) {
					for (var j:uint = i + 1; j < this.items.length; ++j) {
						this.items[j].y -= 18;						 					
					}
					this.mcBack.removeChild(mi);
					this.items.splice(i,1);
					this.itemY -= 18;									
					//break;
					return;			
				}
			}			
		}
		
		private function menuHasItem(itemName:String):Boolean {
			if (!itemName || itemName.length == 0) {
				return false;				
			}
			
			var hasItem:Boolean = false;
	
			for (var i:uint=0; i<this.items.length; ++i) {
				var miToFind:MenuItem = this.items[i];
				if (miToFind.txt.text == itemName.toUpperCase()) {
					hasItem = true;
					break;	
				}
			}
			
			return hasItem;
		}

		private function onWidgetShow(evt:GlobalEvent):void {
			var widgetName:String = evt.data.widgetName;
			var show:Boolean = evt.data.widgetShow;
			var enable:Boolean = (evt.data.widgetEnable != undefined) ? evt.data.widgetEnable : false;			

			switch (widgetName) {
				default: // do nothing
					break;									
			}
		}

		private var _clearedAsNonGuest:Boolean = false;
		private var _clearedForCLSuppression:Boolean = false;
		private function updateNonGuestEntries():void
		{
			if (_clearedAsNonGuest)
			{
				this.addMenuItem(CMD_REPORT_ABUSE, CMD_MUSIC_PLAYER);
				if (_clearedForCLSuppression)
				{
					// note that this needs to be after the adding of CMD_REPORT_ABUSE!
					this.addMenuItem(CMD_CLCAP, CMD_REPORT_ABUSE); 
				}
			}
		}		
		private function onUserLevelSet(e:GlobalEvent):void
		{
			var isGuest:Boolean = e.data.isGuest;
			var isGuestRegistered:Boolean = e.data.guestRegistered;

			_clearedAsNonGuest = !isGuest || isGuestRegistered;
			updateNonGuestEntries();			
		}
		private function onPlayerCL(e:GlobalEvent):void
		{
			if (int(e.data) >= 1)
			{
				_clearedForCLSuppression = true;
			}
			updateNonGuestEntries();
		}
		
		private function onSuppressedCLChange(e:GlobalEvent):void
		{
			_clearedForCLSuppression = true;
			updateNonGuestEntries();
		}

		private function onItemClick(evt:MouseEvent):void{	
			var e:ActionBarEvent = new ActionBarEvent(ActionBarEvent.MENU_ITEM_CLICK);
			onBtnMenuClick(null); // to toggle it closed			
			e.menuItemName = MenuItem(evt.target.parent).txt.text;
			this.dispatchEvent(e);
		}
				
		
		//**** bntMenu Events
		private static const STATE_CLOSED:int = 1;
		private static const STATE_CLOSED_MOUSEOVER:int = 2;
		private static const STATE_OPEN:int = 3;		
		private static const STATE_OPEN_MOUSEOVER:int = 4;
		public function onBtnMenuClick(evt:MouseEvent):void
		{
			show(!this.open);
		}
		private function show(open:Boolean):void
		{
			this.open = open;	
			if (open)
			{
 				if (!this.contains(this.mcBack)) {
					this.addChildAt(this.mcBack, this.mcBackIndex);
					this.addChildAt(this.mcMask, this.mcMaskIndex);
					this.mcBack.mask = this.mcMask;					
				}				
				this.btnMenu.gotoAndStop(STATE_OPEN);
				this.menuLine.visible = false;
			}
			else
			{
				this.btnMenu.gotoAndStop(STATE_CLOSED);
				this.menuLine.visible = true;
			}

			this.addEventListener(Event.ENTER_FRAME, onEnterFrame, false, 0, true);			
		}
		public function onBtnMenuOver(evt:MouseEvent):void
		{
			this.btnMenu.gotoAndStop(this.open ? STATE_OPEN_MOUSEOVER : STATE_CLOSED_MOUSEOVER);
		}
		public function onBtnMenuOut(evt:MouseEvent):void
		{
			this.btnMenu.gotoAndStop(this.open ? STATE_OPEN : STATE_CLOSED);
		}	
		
		private function onEnterFrame(evt:Event):void{
			var origY:Number = this.mcBack.y;			
			var d:Number = 0;
			if (this.open && this.mcBack.y > -this.itemY){
				d = (Math.abs(this.itemY) - Math.abs(this.mcBack.y))/2;					
				this.mcBack.y -= d 
				if (this.mcBack.y < -this.itemY){
					this.mcBack.y = -this.itemY;
				}
			}else if (!this.open && this.mcBack.y < 0){
				d = (0 - Math.abs(this.mcBack.y))/2;	
				this.mcBack.y -= d;
				if (this.mcBack.y > 0){
					this.mcBack.y = 0;
				}
			}
			
			if (origY == this.mcBack.y) {
				this.removeEventListener(Event.ENTER_FRAME, onEnterFrame);
				if (!this.open && this.contains(this.mcBack)) {
					this.removeChild(this.mcBack);
					this.removeChild(this.mcMask);
				}							
			}
		}
	}
}
