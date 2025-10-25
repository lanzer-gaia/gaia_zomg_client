package com.gaiaonline.battle.ui
{
	import com.gaiaonline.battle.ApplicationInterfaces.ILinkManager;
	import com.gaiaonline.battle.newactors.ActorManager;
	import com.gaiaonline.flexModulesAPIs.globalevent.GlobalEvent;
	
	import flash.display.MovieClip;
	import flash.events.MouseEvent;
	import flash.external.ExternalInterface;
	import flash.net.URLRequest;
	import flash.net.navigateToURL;
	import flash.text.TextField;
	
	public class UiLinksPanel extends MovieClip
	{	
		public var linkItem:MovieClip;
		private var mcLinks:MovieClip;
		
		private var _linkManager:ILinkManager = null;
		
		public function UiLinksPanel(linkManager:ILinkManager)
		{
			this._linkManager = linkManager;
			
			this.removeChild(this.linkItem);		
			
			this.mcLinks = new MovieClip();
			this.mcLinks.x = 8;
			this.mcLinks.y = 22;
			this.addChild(mcLinks);
			this.tabChildren = false;
		}
		
		
		public function setLinks(list:Array):void{
			while(this.mcLinks.numChildren > 0){
				MovieClip(this.mcLinks.getChildAt(0)).removeEventListener(MouseEvent.MOUSE_OVER, onItemMouseOver);
				MovieClip(this.mcLinks.getChildAt(0)).removeEventListener(MouseEvent.MOUSE_OUT, onItemMouseOut);
				MovieClip(this.mcLinks.getChildAt(0)).removeEventListener(MouseEvent.CLICK, onItemClick);
				this.mcLinks.removeChildAt(0);
			}
			
			for (var i:int = 0; i < list.length; i++){
				
				var c:Class = this.linkItem["constructor"] as Class;
				
				var li:MovieClip = new c();
				
				li.addEventListener(MouseEvent.MOUSE_OVER, onItemMouseOver, false, 0, true);
				li.addEventListener(MouseEvent.MOUSE_OUT, onItemMouseOut, false, 0, true);
				li.addEventListener(MouseEvent.CLICK, onItemClick, false, 0, true);
					
				li.txt.text = list[i].display;					
				li.txt.width = li.txt.textWidth + 10;
				
				var url:String = this._linkManager.getLink(list[i].linkId);	
				if (list[i].param != null){
					url = url + list[i].param;
				}			
				li.urlLink = url;
				
				li.y = i * 14;
				
				this.mcLinks.addChild(li);							
			}
			
		}
		
		
		private function onItemMouseOver(evt:MouseEvent):void{
			TextField(evt.currentTarget.txt).textColor = 0xFAE88C;
		}
		
		private function onItemMouseOut(evt:MouseEvent):void{
			TextField(evt.currentTarget.txt).textColor = 0xFFFFFF;
		}
		
		private function onItemClick(evt:MouseEvent):void{
			//trace(" -- ",evt.currentTarget, evt.currentTarget.urlLink);
			
			if(evt.target.text){
				GlobalEvent.eventDispatcher.dispatchEvent(new GlobalEvent(GlobalEvent.TRACKING_EVENT, "zomg_click_link_" + evt.target.text));
			}	
				
			if (evt.currentTarget.urlLink == null){
				return;
			}
			var a:Array = evt.currentTarget.urlLink.split(":");
			
			if(ActorManager.getInstance().myActor.isGuestUser()) {
				GlobalEvent.eventDispatcher.dispatchEvent(new GlobalEvent(GlobalEvent.INVALID_GUEST_OPERATION, {}));
			}
			else if (a[0] == "javascript"){
				var param:Array = ["","","",""];
				if (a.length > 2){		
					param = a[2].split(",");
					for (var i:int = 0; i< 4; i++){
						if (param[i] == null){param[i] = ""};
					}			
				}
				try{
					var rr:* = ExternalInterface.call(a[1], param[0], param[1], param[2], param[3]);							
					
				}catch(e:Error){
					trace("Err: ", e.message)
				}				
			} 
			else {
				var r:URLRequest = new URLRequest(evt.currentTarget.urlLink);			
				navigateToURL(r, "GaiaWindow");
			}
		}
	}
}