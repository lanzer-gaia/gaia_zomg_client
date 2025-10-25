package com.gaiaonline.battle.ui
{		
	import com.gaiaonline.battle.news.INewsConnector;
	import com.gaiaonline.battle.news.INewsEventHandler;
	import com.gaiaonline.battle.ui.components.ScrollBarVer;
	import com.gaiaonline.battle.ui.components.TabButton;
	import com.gaiaonline.battle.ui.components.TabEvent;
	import com.gaiaonline.battle.ui.components.TabManager;
	import com.gaiaonline.gsi.GSIEvent;
	import com.gaiaonline.platform.ui.IUIModule;
	
	import flash.display.DisplayObject;
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.geom.Rectangle;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	
	public class UiNews extends MovieClip implements INewsEventHandler
	{
		
		public var btnCurrent:TabButton;
		public var btnArchived:TabButton;
		public var scrNews:ScrollBarVer;
		public var mcNewsContainer:MovieClip;
		public var mcMask:MovieClip;
		
		private var tabManager:TabManager;		
		private var _cssData:String; 
		
		private var _current:Array = new Array();
		private var _archived:Array = new Array();		
				
		private var _baseUrl:String = null;
		private var _partnerId:String = null;
		private var _newsConnector:INewsConnector = null;
				
		private const _welcomeDate:Date = null; // = new Date(Date.parse("04/01/2008"));
		private const _welcomeTitle:String = "Welcome to the zOMG! Open Beta!";
		
		private const NUM_OF_NEWS_ITEMS:uint = 10;
						
		public function UiNews()
		{
			
			this.tabManager = new TabManager(true);
			this.tabManager.addTabs(this.btnCurrent, null, true);
			this.tabManager.addTabs(this.btnArchived, null, false);
			this.tabManager.addEventListener(TabManager.SELECTED_TAB_CHANGE, onTabChange);
												
			this.scrNews.init(this.mcNewsContainer, new Rectangle(1,45,350,314));			
			this.scrNews.smallStep = 20;			
			this.scrNews.bigStep = 280;
			
			this.mcNewsContainer.mask = this.mcMask;
						
		}
		
		public function init(newsConnector:INewsConnector, baseUrl:String, partnerId:String):void{
			_newsConnector = newsConnector;
			_newsConnector.registerForNewsEvents(this);
			
			_baseUrl = baseUrl;
			_partnerId = partnerId;
			
			var l:URLLoader = new URLLoader();
			l.addEventListener(Event.COMPLETE, onCssLoaded, false, 0, true);
			l.load(new URLRequest(_baseUrl + "news/css/news-content.css"));	
		}
		
		private function onCssLoaded(evt:Event):void{
			this._cssData = URLLoader(evt.target).data				
			URLLoader(evt.target).removeEventListener(Event.COMPLETE, onCssLoaded);
		
			var l:URLLoader = new URLLoader();
			l.addEventListener(Event.COMPLETE, onWelcomeLoaded, false, 0, true);
			l.load(new URLRequest(_baseUrl + "news/welcome.html"));	
			
			
		}
		private function onWelcomeLoaded(evt:Event):void{
			var htmText:String = URLLoader(evt.target).data;
			this._current.push({date:this._welcomeDate, title:this._welcomeTitle, post:htmText});
			URLLoader(evt.target).removeEventListener(Event.COMPLETE, onCssLoaded);
		
			this.getNews();		
		}
		
		private function getNews():void{
			_newsConnector.getNews(NUM_OF_NEWS_ITEMS);
		}
		
		
	
		
		
		//*******************************************
		//***** News ********************************
		//*******************************************
		
		public function onNewsSuccess(newsData:Object):void{
			buildNews(newsData);
			_newsConnector.unregisterForNewsEvents(this);
		}
		public function onNewsError():void{
			buildNews(null);
			_newsConnector.unregisterForNewsEvents(this);
		}
		
		private function buildNews(gsiNews:Object = null):void{
			var first:Boolean = true;
			for each(var article:Object in gsiNews){
				if (first){
					this._current.push({date:new Date(Date.parse(article.date)), title:article.title, post:article.post});
					first = false;
				}else{
					this._archived.push({date:new Date(Date.parse(article.date)), title:article.title, post:article.post});
				}
			}
			
			this._current.sortOn("date", Array.DESCENDING | Array.NUMERIC);
			this._archived.sortOn("date", Array.DESCENDING | Array.NUMERIC);			
			this.displayCurrent();			
		}
		
		private function addNewsItem(date:Date, title:String, post:String, minimized:Boolean = false):void{
			if (this.mcNewsContainer) {
				var ni:UiNewsItem = new UiNewsItem(_baseUrl, _partnerId, this._cssData);
				ni.init(date, title, post, minimized);
				ni.addEventListener(UiNewsItem.SIZE_CHANGE, onItemSizeChange, false, 0, true);			
				this.mcNewsContainer.addChild(ni);
			}
		}
		
		private function clearNews():void{
			while(this.mcNewsContainer && this.mcNewsContainer.numChildren > 0){
				var obj:DisplayObject = this.mcNewsContainer.getChildAt(0);
				if (obj.hasEventListener(UiNewsItem.SIZE_CHANGE)){
					obj.removeEventListener(UiNewsItem.SIZE_CHANGE, onItemSizeChange);					
				}				
				this.mcNewsContainer.removeChildAt(0);
			}
		}
				
		
		//*******************************************
		//***** Display******************************
		//*******************************************	
		private function onTabChange(evt:TabEvent):void{
			if (evt.newIndex != evt.lastIndex){
				var txt:String;
				switch(evt.newIndex){
					case 0:
						this.displayCurrent();			
						break;
						
					case 1:
						this.displayArchived();					
						break;
								
				}								
				this.scrNews.update();
			}				

		}
				
		private function displayCurrent():void{
			this.clearNews();
			for (var i:int = 0; i < this._current.length; i++){
				this.addNewsItem(this._current[i].date, this._current[i].title, this._current[i].post);				
			}
			this.addEventListener(Event.ENTER_FRAME, onFrame);
		}
		
		private function displayArchived():void{
			this.clearNews();
			for (var i:int = 0; i < this._archived.length; i++){
				this.addNewsItem(this._archived[i].date, this._archived[i].title, this._archived[i].post, true);				
			}
			this.addEventListener(Event.ENTER_FRAME, onFrame);
		}
		
		private function onItemSizeChange(evt:Event):void{
			if (!this.hasEventListener(Event.ENTER_FRAME)){
				this.addEventListener(Event.ENTER_FRAME, onFrame);
			}
		}	
				
		
		private function onFrame(evt:Event):void{
			this.removeEventListener(Event.ENTER_FRAME, onFrame);
			var recalcY:int = 0;
			if (this.mcNewsContainer) {
				for (var i:int=0; i< this.mcNewsContainer.numChildren; i++){
					var ni:UiNewsItem = this.mcNewsContainer.getChildAt(i) as UiNewsItem;
					if (ni != null){
						ni.y = recalcY;
						recalcY += ni.height + 5;
					}
				}
				this.scrNews.update();
	
				// [kja] See FS#32737.  There's a timing-sensitive bug in the Flash player where it may not repaint itself correctly.
				// The following forces Flash to repaint its contents.
				this.visible = false;
				this.visible = true;
				// [/kja]
			}
		}
	}
}