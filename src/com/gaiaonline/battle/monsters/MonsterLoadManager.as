package com.gaiaonline.battle.monsters
{
	import com.gaiaonline.battle.ApplicationInterfaces.IFileVersionManager;
	import com.gaiaonline.battle.ApplicationInterfaces.IUIFramework;
	import com.gaiaonline.battle.gateway.BattleEvent;
	import com.gaiaonline.battle.gateway.BattleGateway;
	import com.gaiaonline.battle.gateway.BattleMessage;
	import com.gaiaonline.battle.map.MapRoom;
	import com.gaiaonline.battle.sounds.ActorSoundManager;
	import com.gaiaonline.flexModulesAPIs.globalevent.GlobalEvent;
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	
	public class MonsterLoadManager extends EventDispatcher
	{
		
		private var _monsters:Object = new Object();	
			
		private var _uiFramework:IUIFramework;
		private var _fileVersionManager:IFileVersionManager;
		private var _baseUrl:String;
		private var _progressEventDispatcher:ProgressEventDispatcher;				
		private var _monsterPreloadList:Array = new Array();
		private var _battleGateway:BattleGateway;
		private var _useRasterize:Boolean = false;
				
		private var _lastNonNullChamberZoneId:String;
			
		public function MonsterLoadManager(uiFramework:IUIFramework, baseUrl:String, fileVersionManager:IFileVersionManager, battleGateway:BattleGateway){
			this._uiFramework = uiFramework;
			this._baseUrl = baseUrl;
			this._fileVersionManager = fileVersionManager;
			this._battleGateway = battleGateway;
			
			GlobalEvent.eventDispatcher.addEventListener(GlobalEvent.MAP_LOAD_ZONE, onMapUnloadZone, false, 0, true);	
			
		}
			
		public function getBaseMonster(url:String):BaseMonsterLoader{
					
			var a:Array = url.replace(/\\/g,"/").split("/")
			var name:String = a[a.length -1];
			if (this._monsters[name] == null){
				this._monsters[name] = new BaseMonsterLoader(this._uiFramework, url, this._useRasterize);
			}			
			return BaseMonsterLoader(this._monsters[name]);
		}
		
		private function onMapUnloadZone(event:GlobalEvent):void{	
			/*
			we do not clear ALL monster anymore .. 
			only does that are not needed (base on the monster Preload list.	
			
			var zoneId:String = event.data.zone;
			if (!MapFilesFactory.getInstance().mapFiles.isNullchamber(zoneId) && zoneId != this._lastNonNullChamberZoneId){
				//clearAll();
				this._lastNonNullChamberZoneId = zoneId;
			}
			*/
			
		}
		
		public function removeMonster(url:String):void{
									
			var a:Array = url.replace(/\\/g,"/").split("/")
			var name:String = a[a.length -1];					
			delete this._monsters[name];
			this._monsters[name] = null;
		}
		
		public function preloadMonsters():EventDispatcher{			
			var msg:BattleMessage = new BattleMessage("preload",null);
			msg.addEventListener(BattleEvent.CALL_BACK, onPreloadCallBack);
			this._battleGateway.sendMsg(msg);
			
			this._progressEventDispatcher = new ProgressEventDispatcher();
			return this._progressEventDispatcher;
							
		}
		private function onPreloadCallBack(evt:BattleEvent):void{
			
			var preloadUrls:Array = evt.battleMessage.responseObj[0].preloadURLs;
			var vUrl:String;
			var mName:String;
						
			///---- get the list of monsters
			var monsterList:Object = new Object();
			for (var ii:int = 0; ii < preloadUrls.length; ii++){
				mName = preloadUrls[ii];	
				vUrl = "v?=" + this._fileVersionManager.getClientVersion("monsters/" + mName + ".swf");
				monsterList[mName+".swf?"+vUrl] = mName;				
			}
			
			
			
			//-- Note we do not unload previous monster if the new list is very small			
			///----- Unload unused Monsters			
			if (preloadUrls.length >= 4){ 
				var sm:ActorSoundManager = ActorSoundManager.getInstance();	
				for (var name:String in this._monsters){
					if (this._unloadExceptions.indexOf(name) < 0){
						var m:MapRoom = this._uiFramework ? this._uiFramework.map.getCurrentMapRoom() : null;
						var roomScale:Number = 1;			
						if (m != null){							
							roomScale = m.scale/100;
						}					
						
						if ((monsterList[name] == null) || roomScale != BaseMonsterLoader(this._monsters[name]).scale){											
							sm.clearAll(BaseMonsterLoader(this._monsters[name]).baseMonster);																				
							BaseMonsterLoader(this._monsters[name]).dispose();						
							this._monsters[name] = null;				
							delete this._monsters[name];	
							
						}
					}
				}
			}			
			
			///----- Get Monsters to Load 						
			var monsterLoader:Object = new Object();			
			for (var i:int = 0; i < preloadUrls.length; i++){				
				mName = preloadUrls[i];			
				vUrl = "v?=" + this._fileVersionManager.getClientVersion("monsters/" + mName + ".swf");
				if (monsterLoader[mName] == null && this._monsters[mName + ".swf?"+vUrl] == null){					
					var url:String = _baseUrl + "monsters/" + mName + ".swf?"+vUrl;				
					var bml:BaseMonsterLoader = getBaseMonster(url);	
					if (!bml.loaded){						
						monsterLoader[mName] = bml;					
						this._monsterPreloadList.push(bml);
					}				
				}
			}					
			monsterLoader = null;									
			
			/////---- Start Loading new Monsters						
			if (this._monsterPreloadList.length > 0){				
				this._progressEventDispatcher.setTotal(_monsterPreloadList.length);
				var bml2:BaseMonsterLoader = _monsterPreloadList.shift();				
				bml2.addEventListener(Event.COMPLETE, onMonsterPreloaded);
				bml2.load();
			}else{
				_progressEventDispatcher.complete();
				_progressEventDispatcher = null;
				GlobalEvent.eventDispatcher.dispatchEvent(new GlobalEvent(GlobalEvent.MONSTER_PRELOAD_DONE,null));
			}		
			
			
		}
		
		private var _unloadExceptions:Array = new Array();
		public function addUnloadException(monsterName:String):void{
			
			var mName:String = monsterName + ".swf?v?=" + this._fileVersionManager.getClientVersion("monsters/" + monsterName + ".swf");
			this._unloadExceptions.push(mName);
			
		}
		
		private function onMonsterPreloaded(evt:Event):void{
			BaseMonsterLoader(evt.target).removeEventListener(Event.COMPLETE, onMonsterPreloaded);
			this._progressEventDispatcher.update(_monsterPreloadList.length);
			
			if (_monsterPreloadList.length > 0){
				var bml2:BaseMonsterLoader = _monsterPreloadList.shift();				
				bml2.addEventListener(Event.COMPLETE, onMonsterPreloaded);
				bml2.load();				
			}else{
				_progressEventDispatcher.complete();
				_progressEventDispatcher = null;
				GlobalEvent.eventDispatcher.dispatchEvent(new GlobalEvent(GlobalEvent.MONSTER_PRELOAD_DONE,null));
			}
			
		}
						
		public function clearAll():void{
			
			if (this._monsters != null){
				var sm:ActorSoundManager = ActorSoundManager.getInstance();			
				for(var name:String in this._monsters){
					if (this._monsters[name] is BaseMonsterLoader){					
						sm.clearAll(BaseMonsterLoader(this._monsters[name]).baseMonster);																				
						BaseMonsterLoader(this._monsters[name]).dispose();						
					}
					this._monsters[name] = null;
				}
			}
			
			this._monsters = new Object();
		}
	
	
		public function get useRasterize():Boolean{
			return this._useRasterize;
		}
		public function set useRasterize(v:Boolean):void{
			this._useRasterize = v;
		}
	
	}
	
}

	
import flash.events.EventDispatcher;
import flash.events.ProgressEvent;
import flash.events.Event;	

internal class ProgressEventDispatcher extends EventDispatcher{	
	private var _total:int = 0;
	public function ProgressEventDispatcher(){
		
	}
	public function setTotal(total:int):void{
		this._total = total;
	}
	public function update(numLeftToLoad:Number):void{
		this.dispatchEvent(new ProgressEvent(ProgressEvent.PROGRESS, false, false, this._total - numLeftToLoad, this._total));
	}
	public function complete():void{
		this.dispatchEvent(new Event(Event.COMPLETE));
	}
	
}