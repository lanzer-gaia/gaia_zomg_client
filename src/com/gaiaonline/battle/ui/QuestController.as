package com.gaiaonline.battle.ui
{	
	import com.gaiaonline.battle.ui.events.PDAEvent;
	import com.gaiaonline.flexModulesAPIs.gatewayInterfaces.IBattleEvent;
	import com.gaiaonline.flexModulesAPIs.gatewayInterfaces.IBattleGateway;
	import com.gaiaonline.flexModulesAPIs.gatewayInterfaces.IBattleMessage;
	import com.gaiaonline.flexModulesAPIs.globalevent.GlobalEvent;
	
	import flash.events.EventDispatcher;
	import flash.utils.clearTimeout;
	import flash.utils.setTimeout;
	
	public class QuestController extends EventDispatcher
	{
		private var _gateway:IBattleGateway = null;
		private var _quests:Object = new Object();
		private var competedCount:int = 0;
		
		private static var _instance:QuestController = null;
		
		public static function getInstance(gateway:IBattleGateway):QuestController{
			if (_instance == null){
				_instance = new QuestController(new SingletonEnforcer(), gateway);
			}
			return _instance;
		}
		
		public function QuestController(S:SingletonEnforcer, gateway:IBattleGateway){
			this._gateway = gateway;
			this._gateway.addEventListener("updateQuest", onQuestUpdate, false, 0, true);
		}

		private var _msg:IBattleMessage = null;
		public function loadQuest():void{
			_msg = this._gateway.createBattleMessage("quest", null);
			_msg.addEventListener("Call_Back", onQuest);
			this._gateway.sendMsg(_msg);
			
			clearTimeout(_loadQuestTimeout);
			_loadQuestTimeout = 0;
		}

		private var _loadQuestTimeout:uint = 0;				
		private var _nextRequest:Number = 2000;
		private function onQuest(evt:IBattleEvent):void{
			cleanObject(this._quests);
			var res:Object = evt.battleMessage.responseObj;			
			
			if (res != null){
				if(res[0] && res[0].error) {
					
					clearTimeout(_loadQuestTimeout);
					_loadQuestTimeout = setTimeout(loadQuest, _nextRequest);
					_nextRequest *= 2;
				} else {
					for (var i:int = 0; i < res.length; i++){					
						if (res[i].bmt != null && res[i].bmt == "questUpdate"){
							//trace("[QJ]",res[i].questId);
							for (var x:String in res[i]){
								//trace(res[i][x]);
							}
							//trace("---------");
							if (res[i].remove == null || res[i].remove == false){
								this._quests[res[i].questId] = Object(res[i]) as Object;
							}				
						}							
					}				
				}												
			}			
			
			this.updateQuestJournal();
			
			GlobalEvent.eventDispatcher.dispatchEvent(new GlobalEvent(GlobalEvent.QUESTS_LOADED, {}));
			
			_msg.removeEventListener("Call_Back", onQuest);					
			
		}
		
		private var _completedNotifyIds:Array = new Array();
		private var _activeNotifyIds:Array = new Array();		
		private function onQuestUpdate(evt:IBattleEvent):void{
			
			var res:Object = evt.battleMessage.responseObj;	
			var update:Boolean = false;
			var showAlert:Boolean = false;
			
			var activeQuest:Boolean = false;
			var completedQuest:Boolean = false;		
			

			this._completedNotifyIds.length = 0;
			this._activeNotifyIds.length = 0;			
			if (res != null){										
				for (var i:int = 0; i < res.length; i++){						
					if (res[i].bmt != null && res[i].bmt == "questUpdate"){						
						
						////---- check if we need to remove the quest
						if (res[i].remove){
							this._quests[res[i].questId] = null;
							delete this._quests[res[i].questId];					
						}else{							
							var currQuestData:Object = this._quests[res[i].questId];						
							if (currQuestData == null || currQuestData.questStep != res[i].questStep) {					
								// track quest progress
								var step: String;
								if(res[i].questStep) {
									step = res[i].questStep + "_" + res[i].totalSteps;										
								}
								else {
									step = "complete";									
								}
								GlobalEvent.eventDispatcher.dispatchEvent(new GlobalEvent(GlobalEvent.TRACKING_EVENT, "quest_update_" + res[i].questName + "_" + step));					
							}
							
							this._quests[res[i].questId] = res[i];
							this._quests[res[i].questId].notify = true;
							if (this._quests[res[i].questId].completed){
								_completedNotifyIds.push(String(res[i].questId));
							}else{
								_activeNotifyIds.push(String(res[i].questId));
							}
							
							
							showAlert = true;
							if (res[i].completed){
								completedQuest = true;	
							}else{
								activeQuest = true;	
							}				
						
						}						
														
						update = true;
										
					} else if (res[i].bmt != null && res[i].bmt == "centerPrint"){
						GlobalEvent.eventDispatcher.dispatchEvent(new GlobalEvent(GlobalEvent.ALERT, {type:"QUEST_UPDATED", textParam:res[i].centerPrint}));																																													
					}		
				}				
			}
					
			if (update){							
				this.updateQuestJournal(true, activeQuest, completedQuest, _completedNotifyIds, _activeNotifyIds);
			}
						
			if (showAlert) {
				GlobalEvent.eventDispatcher.dispatchEvent(new GlobalEvent(GlobalEvent.QUEST_ALERT, {activeQuest:activeQuest, completedQuest:completedQuest}));
				}				
		}
				
		private function updateQuestJournal(update:Boolean = false, active:Boolean = true, completed:Boolean = true, completedNotifyIds:Array = null, activeNotifyIds:Array = null):void{
			
			if (completedNotifyIds == null){
				completedNotifyIds = new Array();
			}
			if (activeNotifyIds == null){
				activeNotifyIds = new Array();
			}
				
			var questsArray:Array = new Array();
			var cc:int = 0;
			
			for (var id:String in this._quests){				
				
				if ( (this._quests[id].completed != null && completed) || ( (this._quests[id].completed == null || !this._quests[id].completed) && active)){
				
					var q:Object = new Object();
					q.questId = id;
					q.startNPC = this._quests[id].startNPC;								
					if (this._quests[id].url != undefined){			
						q.npcImage = String(this._quests[id].url).replace(/_flip.png|.png/,"_48x48.gif");
						//trace(q.npcImage);					
					}
					else {
						q.npcImage = "http://avatar2.gaiaonline.com/gaia/members/ava/0e/4e/45848d16ab4e0e_48x48.gif";
					}		
									
					q.location = this._quests[id].location;				
					q.questName = this._quests[id].questName;
					q.questDesc = this._quests[id].questSummary; 
					q.info = this._quests[id].stepDesc;				
					q.completed = this._quests[id].completed;
					q.goalProgress = this._quests[id].goalProgress;
					q.goalTotal = this._quests[id].goalTotal;
					q.questGoal = this._quests[id].questGoal;
					q.goalUrl = this._quests[id].goalUrl;
					q.stepType = this._quests[id].stepType;			
					if (q.completed){
						q.status = "Completed";
						q.completedDate = "Thu Feb 07, 2008 12:16 pm";
						cc += 1;
					}else{
						q.status = "Step " + this._quests[id].questStep;// +"." + " of " + this._quests[id].totalSteps + ".";
					}	
					
					if ( (q.completed && completedNotifyIds.length > 0) || (!q.completed && activeNotifyIds.length > 0) ){					
						if (q.completed){
							q.notify = completedNotifyIds.lastIndexOf(id) >= 0;
						}else{						
							q.notify = activeNotifyIds.lastIndexOf(id) >= 0;
						}					
					}else {
						q.notify =  (this._quests[id].notify != null && this._quests[id].notify);	
					}				
					questsArray.push(q);
				
					
				}							
				
			}
			
			var event:PDAEvent = new PDAEvent(PDAEvent.QUEST_DATA);
			event.questData = questsArray;
			this.dispatchEvent(event);
									
			//@@this.uiQuestLog.updateInfo(questsArray, active, completed);
			
			if (update){
				if (this.competedCount < cc){
					GlobalEvent.eventDispatcher.dispatchEvent(new GlobalEvent("alertEvent", {type:"MISSION_COMPLETED"}));																																												
				}else{
					GlobalEvent.eventDispatcher.dispatchEvent(new GlobalEvent("alertEvent", {type:"UPDATE_PDA_STEP"}));																																												
				}			
			}
			this.competedCount = cc;
			
		}		
		
		
		public function clearActiveNotification():void{
			for (var id:String in this._quests){		
				if (this._quests[id].completed == null || !this._quests[id].completed){
					this._quests[id].notify = false;
					delete this._quests[id].notify;
				}
			}
		}
		public function clearCompletedNotification():void{
			for (var id:String in this._quests){		
				if (this._quests[id].completed != null && this._quests[id].completed){
					this._quests[id].notify = false;
					delete this._quests[id].notify;
				}
			}
		}
		
		public static function cleanObject(o:Object):void {
			if (o == null) {
				o = new Object();
				return;
			}
			var foundProps:uint = 0;
			do {
				foundProps = 0;
				for (var key:Object in o) {
					++foundProps;
					delete o[key];
				}
			} while (foundProps > 0);
		}
		
	}
	
}

class SingletonEnforcer { }
