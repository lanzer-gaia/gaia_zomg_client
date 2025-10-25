package com.gaiaonline.battle.ui
{
	import com.gaiaonline.battle.ApplicationInterfaces.ILinkManager;
	import com.gaiaonline.battle.ApplicationInterfaces.IUIFramework;
	import com.gaiaonline.battle.Globals;
	import com.gaiaonline.battle.utils.BattleUtils;
	import com.gaiaonline.battle.utils.ThirdPartyUtils;
	import com.gaiaonline.display.windows.Window;
	import com.gaiaonline.flexModulesAPIs.globalevent.GlobalEvent;
	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.TextEvent;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.text.StyleSheet;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	
	public class DialogWindow extends EventDispatcher
	{				
		private var container:DisplayObjectContainer
		private var win:Window;
		private var mc:Sprite;
		private var txt:TextField;
		private var back:Sprite;
		
		private var css:StyleSheet
		private var cssUrl:String;
		
		private var _footer:MovieClip;
		
		private var width:Number = 100;
		private var height:Number = 50;
		private var _autoSize:Boolean = true;
		private var _autoCenter:Boolean = false;
		private var _autoCenterTop:Boolean = false;	
		private var _keepOnStage:Boolean = false;			
		private var _customWidth:Boolean = false;
		private var cssLoaded:Boolean = false;
		private var htmlText:String;
		private var _linkManager:ILinkManager = null;
		private var _uiFramework:IUIFramework = null;		
		
		public var params:Object = new Object();
						
		public function DialogWindow(uiFramework:IUIFramework, linkManager:ILinkManager, mcContainer:DisplayObjectContainer, winWidth:Number = 100, winHeight:Number =50, cssUrl:String = "help-files/css/script-dialog.css")
		{
			this._linkManager = linkManager;
			this._uiFramework = uiFramework;
			this.container = mcContainer;	
			this.width = winWidth;
			this.height = winHeight;
			
			this.initMc();
			
			this.win = new Window(this._linkManager.baseURL + "windows/genericwin.swf", this.mc, true, false, true, false, this.width, this.height, 50, 50, false, false, uiFramework.loaderContextFactory);
			//this.win.useMask(false);
			//-- Load StyleSheet
			this.cssUrl = this._linkManager.baseURL + cssUrl;		
			var l:URLLoader = new URLLoader();
			l.addEventListener(Event.COMPLETE, onCssLoaded);
			l.load(new URLRequest(this._linkManager.baseURL + cssUrl));			
						
			/// Event listener
			this.win.addEventListener("CLOSE", onClose);//, false, 0, true); weak reference here breaks prevents onClose from being called
			GlobalEvent.eventDispatcher.addEventListener(GlobalEvent.NEW_ROOM_ENTERED, onClose, false, 0, true);	
						
			this.container.addChild(this.win);
		}
		
		// NOTE: This will only add a footer if autosize is set to true
		public function set footer(ftr:MovieClip):void {
			this._footer = ftr;
		}
		
		public function get footer():MovieClip {
			return this._footer;
		}
		
		private function initMc():void{
			this.mc = new Sprite();
			this.mc.x = 3;
			this.mc.y = 3;		

			//-- init Back
			this.back = new Sprite();
			//this.back.y = 20;			
			this.back.graphics.lineStyle(0,0x000000, 0);
			this.back.graphics.beginFill(0x000000, 1);
			this.back.graphics.drawRect(0,0,this.width-6,this.height-25);
			this.back.graphics.endFill();
									
			this.mc.addChild(this.back);		
						
			//-- init Txt			
			this.txt = new TextField();			
			this.txt.embedFonts = false;
			this.txt.multiline = true;
			this.txt.wordWrap = true;		
			this.txt.selectable = true;
			this.txt.autoSize = TextFieldAutoSize.LEFT;				
			this.txt.textColor = 0xFFFFFF;			
			this.txt.width = this.width - 10;			
			this.txt.x = 3;
			//this.txt.y = 23;
			
			this.txt.addEventListener(TextEvent.LINK, linkHandler, false, 0, true);
			this.mc.addChild(this.txt);		
		}
		
		public function set supportHyperlinks(support:Boolean):void {
			this.txt.selectable = support;
		}
		
		private function onCssLoaded(evt:Event):void{
			URLLoader(evt.target).removeEventListener(	Event.COMPLETE, onCssLoaded );	
			this.css = new StyleSheet();
			this.css.parseCSS(URLLoader(evt.target).data);			
			this.txt.styleSheet = css;
			if(this.htmlText != null){
				this.setTxt()			
			}			
		}
		
		private function setTxt():void{
			this.txt.addEventListener(Event.CHANGE, onChange, false, 0, true);	
			this.txt.htmlText = this.htmlText;
			if (this._autoSize){
				this.setSize();
			}
			if (this._autoCenter){
				this.center();
			} else if (this._autoCenterTop) {
				this.center(true);
			} else if (this._keepOnStage) {
				this.doKeepOnStage();
			}
		}
		
		private function doKeepOnStage():void {
			BattleUtils.keepItemOnStage(this.win.stage, this.win);
		}
		
		private function setSize():void{
			this.back.width = 10;
			this.back.height = 10;

			if (this._customWidth) {
				this.txt.width = this.width - 10;												
			} else {
				if (this.txt.textWidth < this.width - 20){
					this.txt.width = this.txt.textWidth + 10;
				}
			} 
			
			var backHeight:Number = this.mc.height;
			
			var heightAdjust:Number = 0;			
			if (_footer != null) {
				this.mc.addChild(_footer);
				heightAdjust = _footer.height;
				_footer.y = this.mc.y + backHeight// + _footer.height;
				_footer.x = this.mc.width - _footer.width - 10;
			} 
			
			this.back.width = this.mc.width;
			this.back.height = backHeight + heightAdjust + 3;		
			
			this.win.setMaxWidth(this.mc.width + 6);
			this.win.setMaxHeight(this.mc.height + 6);
			this.win.setSize(this.mc.width + 6, this.mc.height + 6);
		}

		private function center(top:Boolean = false):void{
			var x:Number = NaN;
			var y:Number = NaN;

			if (top) {
				// center horizontally relative to the game window (winMap)
				x = Globals.uiManager.winMap.x + (Globals.uiManager.winMap.getSize().width/2) - (this.win.getSize().width/2);
				// place just below the header bar for the game window (winMap)
				y = this.container.stage.y + Globals.uiManager.winMap.y + Globals.uiManager.winMap.getHeaderHeight() ;											
			} else {				
				// center relative to the entire stage
				x = this.container.stage.stageWidth/2 - this.win.getSize().width/2;
				y = this.container.stage.stageHeight/2 - this.win.getSize().height/2;  				
			}

			this.win.x = x;
			this.win.y = y;
		}
		
		private function linkHandler(evt:TextEvent):void{
			var text:String = evt.text;			
			var parameters:Array = text.split(":");
			var cmd:String = parameters[0];
			parameters.splice(0,1);
			var paramsRest:String = parameters.join(":");
									
			switch(cmd.toLowerCase()){
				case "ui":
					GlobalEvent.eventDispatcher.dispatchEvent(new GlobalEvent(GlobalEvent.TEXT_BASED_UI_COMMAND, {paramString:paramsRest}));
					break;
					
				case "url":					
					//navigateToURL(new URLRequest(param), "_blank");
					break;
					
				case "okay":
					// note; for many of our dialog boxes, clicking on a link that reads "OK" will
					// actually issue a close event; but so will clicking on the cancel x button in the top
					// right of the title bar of the dialog.  So I've added the ability to have an explicit
					// okay, as well as a close.
					this.okay();
					break;
					
				case "close":
					this.close();
					break;
					
				case "cancel":
					this.cancel();
					break;					
			}			

			// forward these on to other listeners
			dispatchEvent(evt);			
		}
		
		private function onChange(evt:Event):void{
			if (this._autoSize){				
				this.container.addEventListener(Event.ENTER_FRAME, onFrame);				
			}	
		}
		private function onFrame(evt:Event):void{
			this.container.removeEventListener(Event.ENTER_FRAME, onFrame);
			this.setSize();
		}		
		private function onClose(evt:Event):void{
			this.win.removeEventListener("CLOSE", onClose);
			this.close();
		}
		
		/*		
		public function setHeader(txt:String):void{
			this.txtHeader.htmlText = "<b>" + txt + "</b>";
		}
		*/
		
		public function setHtmlText(txt:String):void{
			this.htmlText = txt.replace(/\n/gi,"").replace(/\l/gi,"").replace(/\r/gi,"");
			var xmlized:XML = null;
			try {
				xmlized = new XML(this.htmlText);
			} catch (e:Error){
				trace(e);
			}
			
			this._customWidth = false; 
													
			if (xmlized != null) {
				if (xmlized.name() == "zOMG") {
					var dialogWidthList:XMLList = xmlized[0].@dialogWidth;
					if (dialogWidthList.length() > 0) {					
						var width:Number = Number(dialogWidthList[0]);
						this._customWidth = true;							
						this.width = width;							
						this.win.setMinWidth(this.width);
						this.win.setMaxWidth(this.width);
						this.htmlText = XML(xmlized[0]).text();
						this.autoSize = true;
					}
				}
			}
			
			if(this._uiFramework.isLoadedExternally)
			{
				htmlText = ThirdPartyUtils.prependBaseURLToImageSources(this._linkManager.baseURL, htmlText);
			}
			
			if (this.cssLoaded){		
				this.setTxt();
			}	
		}
			
		public function setPos(x:Number, y:Number):void{
			if(this.win != null){
				this.win.x = x;
				this.win.y = y;
			}
		}

		public function setPosAtMouse():void {
			if(this.win != null){
				this.win.x = this.container.mouseX;
				this.win.y = this.container.mouseY;
			}
		}
		
		public function set autoSize(v:Boolean):void{
			this._autoSize = v;
			if (this.htmlText != null && this.cssLoaded){
				this.setSize();
			}
		}
		public function get autoSize():Boolean{
			return this._autoSize;
		}
		
		public function set autoCenter(v:Boolean):void{
			this._autoCenter = v;
			if (this.htmlText != null && this.cssLoaded){
				this.center();
			}
		}
		public function get autoCenter():Boolean{
			return this._autoCenter;
		}
		public function set autoCenterTop(v:Boolean):void{
			this._autoCenterTop = v;
			if (this.htmlText != null && this.cssLoaded){
				this.center(true);
			}
		}
		public function get autoCenterTop():Boolean {
			return this._autoCenterTop;
		}
		public function set keepOnStage(v:Boolean):void{
			this._keepOnStage = v;
			if (this.htmlText != null && this.cssLoaded){
				this.doKeepOnStage();
			}
		}
		public function get keepOnStage():Boolean{
			return this._keepOnStage;
		}
		
		private function okay():void {
			this.dispose();
			this.dispatchEvent(new Event("OKAY"));						
		}
		
		private function cancel():void {
			this.dispose();
			this.dispatchEvent(new Event("CANCEL"));			
		}
		
		public function close():void{
			this.dispose();
			this.dispatchEvent(new Event("CLOSE"));
		}
		
		private function dispose():void{
			this.win.removeEventListener("CLOSE", onClose);						
			if (isOpen()){
				this.container.removeChild(this.win);
			}
			
			
			//------------
			if (this.txt.hasEventListener(Event.CHANGE)){
				this.txt.removeEventListener(Event.CHANGE, onChange);
			}			
			
		}
		
		public function isOpen():Boolean {
			return this.container.contains(this.win);
		}

	}
}
