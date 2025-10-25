package com.gaiaonline.battle.emotes
{
	import com.gaiaonline.battle.ApplicationInterfaces.IUIFramework;
	import com.gaiaonline.objectPool.LoaderFactory;
	
	import flash.display.Loader;
	import flash.display.LoaderInfo;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.net.URLRequest;
	
	public class EmoteOld extends EventDispatcher
	{
		
		public var id:String;
		public var Loaded:Boolean = false;
		private var mcEmote:MovieClip;
		private var _order:int;
		
		private var iconArray:Array = new Array();
		private var animArray:Array = new Array();
		
		private var _uiFramework:IUIFramework = null;

		public function EmoteOld(uiFramework:IUIFramework, id:String, order:int){
			this._uiFramework = uiFramework;
			this.id = id;
			this._order = order;				
		}
		
		public function init(url:String):void{
			
			var loader:Loader = LoaderFactory.getInstance().checkOut();
			loader.contentLoaderInfo.addEventListener(Event.COMPLETE, onLoaded);
			loader.load(new URLRequest(url), this._uiFramework.loaderContextFactory.getLoaderContext());		
			
		}
		
		private function onLoaded(evt:Event):void{
			this.mcEmote = MovieClip(LoaderInfo(evt.target).content);
			
			for (var i:int = 0; i < this.iconArray.length; i++){
				Sprite(this.iconArray[i]).addChild(Sprite(this.mcEmote.getIcon()));
			}
			
			this.Loaded = true;		
			this.dispatchEvent(new Event(Event.COMPLETE));
			
			LoaderInfo(evt.target).loader.contentLoaderInfo.removeEventListener(Event.COMPLETE, onLoaded);
			LoaderFactory.getInstance().checkIn(LoaderInfo(evt.target).loader);
		}	
		
		public function getEmoteAnim():MovieClip{
			if (this.Loaded){
				var e:MovieClip = MovieClip(this.mcEmote.getEmoteAnim());
				return e;
			}
			else{
				return null;
			}
		}
		
		public function getEmoteIcon():Sprite{
			
			var ico:Sprite = new Sprite();
			
			if (this.Loaded){
				var s:Sprite = Sprite(this.mcEmote.getIcon());
				ico.addChild(s);
			}else{
				this.iconArray.push(ico);
			}
			
			return ico;
		}

		public function get order():int { return this._order; }				
	}
}