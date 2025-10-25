package com.gaiaonline.battle.ui
{	
	import com.gaiaonline.battle.utils.ThirdPartyUtils;
	
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.text.StyleSheet;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	
	public class UiNewsItem extends MovieClip
	{
		public static const SIZE_CHANGE:String = "NewsItemSizeChange";		
		
		public var mcHeader:MovieClip;
		public var txtNews:TextField;		
		
		private var _cssData:String;
		private var _links:Array = new Array();
		private var _loadCount:int = 0;
		private var _minimized:Boolean = false;
		
		private var _baseUrl:String = null;
		private var _partnerId:String = null;
		
		public function UiNewsItem(baseUrl:String, partnerId:String, cssData = null)
		{		
			_baseUrl = baseUrl;
			_partnerId = partnerId;
			this._cssData = cssData;				
			
			this.txtNews.selectable = true;
			this.txtNews.autoSize = TextFieldAutoSize.LEFT;	
			this.txtNews.addEventListener(Event.CHANGE, onTxtChange, false, 0, true);
			this.mcHeader.btnMinMax.addEventListener(MouseEvent.CLICK, onBtnClick, false, 0, true);	
			this.mcHeader.btnMinMax.gotoAndStop(1);
			
			if (this._cssData != null){			
				var css:StyleSheet = new StyleSheet();
				css.parseCSS(this._cssData);			
				this.txtNews.styleSheet = css;
			}							
		}
		
		public function init(date:Date, Title:String, post:String, minimized:Boolean = false):void{			
			if (date != null){
				this.mcHeader.txtDate.text = (date.month+1).toString() + "/" + date.date.toString() + "/" + date.fullYear.toString();
			}else{
				this.mcHeader.txtDate.text = "";
			}
			this.mcHeader.txtTitle.text = Title;
						
			var htmText:String = post.replace(/\n/gi,"").replace(/\l/gi,"").replace(/\r/gi,"");
			if(_partnerId != null){
				htmText = ThirdPartyUtils.prependBaseURLToImageSources(_baseUrl, htmText);
			}
			this.txtNews.htmlText = htmText;
			
			if (minimized){
				this.minimize();
			}else{
				this.maximize();
			}						
				
		}
		
						
		private function onTxtChange(evt:Event):void{
			this.dispatchEvent(new Event(SIZE_CHANGE));			
		}
		
		private function onBtnClick(evt:MouseEvent):void{
			if (this._minimized){
				this.maximize();
			}else{
				this.minimize();
			}
		}
		
		public function minimize():void{
			this._minimized = true;
			this.mcHeader.btnMinMax.gotoAndStop(2);
			if (this.contains(this.txtNews)){
				this.removeChild(this.txtNews);
				this.dispatchEvent(new Event(SIZE_CHANGE));
			}
		}
		public function maximize():void{
			this._minimized = false;
			this.mcHeader.btnMinMax.gotoAndStop(1);
			if (!this.contains(this.txtNews)){
				this.addChild(this.txtNews);
				this.dispatchEvent(new Event(SIZE_CHANGE));
			}
		}
		
	}
}