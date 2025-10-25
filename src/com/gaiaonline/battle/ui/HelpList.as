package com.gaiaonline.battle.ui
{
	import com.gaiaonline.battle.ApplicationInterfaces.IFileVersionManager;
	import com.gaiaonline.battle.Globals;
	
	import flash.events.Event;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	
	public class HelpList
	{
		
		private var xml:XML;
		
		private var _baseUrl:String = null;
		private var _fileVersionManager:IFileVersionManager = null;
		
		public function HelpList(fileVersionManager:IFileVersionManager, baseUrl:String) {
			this._fileVersionManager = fileVersionManager;			
			this._baseUrl = baseUrl;			
		}
		
		public function load():void{
			var l:URLLoader = new URLLoader();
			l.addEventListener(Event.COMPLETE, onLoaded);
			var vUrl:String = "?v=" + this._fileVersionManager.getClientVersion("help-files/helpList.xml");			
			l.load(new URLRequest(this._baseUrl + "help-files/helpList.xml"+ vUrl));	
		}
		
		private function onLoaded(evt:Event):void{			
			this.xml = new XML(URLLoader(evt.target).data)
			this.getTopics();
			URLLoader(evt.target).removeEventListener(Event.COMPLETE, onLoaded);	
		}
		
		public function getTopics():Array{
			
			var topics:Array = new Array();
			for each(var topic:XML in this.xml..topic){
				var t:Object = {title:topic.@title, contentLink:topic.@link, relatedNames:new Array()};
				for each(var name:XML in topic..relateName){					
					t.relatedNames.push(name);
				}
				
				topics.push(t);		
			}
			
			return topics;			
			
			
			
			/* [
				{ title:"Topic Name",relatedNames:["Another topic name","Map system","City buildings"],contentLink:"topic-help.html"},
				{ title:"Fight and battles",relatedNames:["Monster destroy","Using rings"],contentLink:"topic-help.html"},
				{ title:"Monsters",relatedNames:["Creatures","Devils"],contentLink:"topic-help.html"},
				{ title:"NPC",relatedNames:["Non playing characters","Ingame characters"],contentLink:"topic-help.html"},
				{ title:"Cities",relatedNames:["Towns","Villages"],contentLink:"topic-help.html"},
				{ title:"Armor",relatedNames:["Defense","Shield","Helmet","Gloves"],contentLink:"topic-help.html"},
				{ title:"Weapons",relatedNames:["Combat items","Using weapons"],contentLink:"topic-help.html"},
				{ title:"Battle Rings",relatedNames:["Ring spells","Ring power","Updating rings","Destroying rings","Orbs"],contentLink:"topic-help.html"}
			]; */
		}

	}
}