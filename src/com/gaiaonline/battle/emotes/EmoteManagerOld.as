package com.gaiaonline.battle.emotes
{
	import com.gaiaonline.battle.ApplicationInterfaces.IUIFramework;
	import com.gaiaonline.flexModulesAPIs.globalevent.GlobalEvent;
	
	import flash.display.Sprite;
	import flash.events.Event;
		
	public class EmoteManagerOld
	{
		
		private var displayLayer:Sprite;
		private var _emotes:Object = {};
		
		private var _uiFramework:IUIFramework = null;
		private var _baseUrl:String = null;
		
		public function EmoteManagerOld(uiFramework:IUIFramework, baseUrl:String):void {
			this.init(uiFramework, baseUrl);
		}
		
		public function init(uiFramework:IUIFramework, baseUrl:String):void {
			this._uiFramework = uiFramework;
			this._baseUrl = baseUrl;			
		}

		public function playEmoteAnim(id:String, layer:Sprite, actor:Sprite, sizeRef:Sprite):void {
			var emoteAnim:EmoteAnim = new EmoteAnim(id, layer, actor, sizeRef);
			
			var e:EmoteOld = this.getEmote(id);
			if (this.containsEmote(id)){
				emoteAnim.play(e.getEmoteAnim());
			}else{
				e.addEventListener(Event.COMPLETE, function(evt:Event):void { 
															 onEmoteLoaded(evt, emoteAnim);
															}  );
			}							
		}
		
		private function getEmote(id:String):EmoteOld{
			var e:EmoteOld;			
			if (this._emotes[id] != null){
				e = this._emotes[id];								
			}			
			return e;	
		}		
		
		private function containsEmote(id:String):Boolean{
			if (this._emotes[id] != null && EmoteOld(this._emotes[id]).Loaded){
				return true;
			}else{
				return false;
			}
		}
		
		public function setEmotes(emotes:Array):void {			
			for each (var emoteInfo:Object in emotes) {
				var order:int = emoteInfo.order ? int(emoteInfo.order) : 0;
				var e:EmoteOld = this.loadEmote(emoteInfo.emoticonID, this._baseUrl + "emotes/"+emoteInfo.url, order);
			}			
			GlobalEvent.eventDispatcher.dispatchEvent(new GlobalEvent(GlobalEvent.EMOTES_LOADED, {}));				
		}
		
		private function loadEmote(id:String, url:String, order:int):EmoteOld{	
			
			//**** check for swf at the end of the url
			if(url.substr(url.length -3, 3) != "swf"){
				url += ".swf";
			}			
			this._emotes[id] = new EmoteOld(this._uiFramework, id, order);
			EmoteOld(this._emotes[id]).init(url);
			return this._emotes[id];
		}		
		
		private function onEmoteLoaded(evt:Event, emoteAnim:EmoteAnim):void{
			var e:EmoteOld = EmoteOld(evt.target); 

			emoteAnim.play(e.getEmoteAnim());
			e.removeEventListener(Event.COMPLETE, onEmoteLoaded);
		}
		
		public function get emotes():Object {
			if (this._emotes == null) {
				this._emotes = new Object();				
			}
			
			return this._emotes;
		}
		
	}
}