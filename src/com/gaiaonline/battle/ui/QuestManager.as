package com.gaiaonline.battle.ui
{
	import com.gaiaonline.battle.gateway.BattleEvent;
	import com.gaiaonline.battle.gateway.BattleGateway;
	import com.gaiaonline.battle.gateway.BattleMessage;
	import com.gaiaonline.battle.utils.BattleUtils;
	import com.gaiaonline.flexModulesAPIs.globalevent.GlobalEvent;
	
	import flash.events.EventDispatcher;
	import flash.utils.clearTimeout;
	import flash.utils.setTimeout;
	
	public class QuestManager extends EventDispatcher
	{
		private var quests:Object = new Object();
		private var uiQuestLog:UiQuestLog;
		private var competedCount:int = 0;
		private var _gateway:BattleGateway = null;
		
		public function QuestManager(gateway:BattleGateway, uiQuestLog:UiQuestLog){
			this._gateway = gateway;
			this.uiQuestLog = uiQuestLog;			
			this._gateway.addEventListener(BattleEvent.QUEST_UPDATE, onQuestUpdate, false, 0, true);
		}
		
		public function loadQuest():void{
			var msg:BattleMessage = new BattleMessage("quest", null);
			msg.addEventListener(BattleEvent.CALL_BACK, onQuest);
			this._gateway.sendMsg(msg);
			
			clearTimeout(_loadQuestTimeout);
			_loadQuestTimeout = 0;
		}

		private var _loadQuestTimeout:uint = 0;				
		private var _nextRequest:Number = 2000;
		private function onQuest(evt:BattleEvent):void{
			BattleUtils.cleanObject(this.quests);
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
								this.quests[res[i].questId] = Object(res[i]) as Object;
							}				
						}							
					}				
				}												
			}			
			
			this.updateQuestJournal();
			
			GlobalEvent.eventDispatcher.dispatchEvent(new GlobalEvent(GlobalEvent.QUESTS_LOADED, {}));
			
			BattleMessage(evt.target).removeEventListener(BattleEvent.CALL_BACK, onQuest);					
			
		}
		
		private var _completedNotifyIds:Array = new Array();
		private var _activeNotifyIds:Array = new Array();		
		private function onQuestUpdate(evt:BattleEvent):void{
			
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
							this.quests[res[i].questId] = null;
							delete this.quests[res[i].questId];					
						}else{							
							var currQuestData:Object = this.quests[res[i].questId];						
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
							
							this.quests[res[i].questId] = res[i];
							this.quests[res[i].questId].notify = true;
							if (this.quests[res[i].questId].completed){
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
						GlobalEvent.eventDispatcher.dispatchEvent(new GlobalEvent(GlobalEvent.ALERT, {type:AlertTypes.QUEST_UPDATE, textParam:res[i].centerPrint}));																																													
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
			
			for (var id:String in this.quests){				
				
				if ( (this.quests[id].completed != null && completed) || ( (this.quests[id].completed == null || !this.quests[id].completed) && active)){
				
					var q:Object = new Object();
					q.questId = id;
					q.startNPC = this.quests[id].startNPC;								
					if (this.quests[id].url != undefined){			
						q.npcImage = String(this.quests[id].url).replace(/_flip.png|.png/,"_48x48.gif");
						//trace(q.npcImage);					
					}
					else {
						q.npcImage = "http://avatar2.gaiaonline.com/gaia/members/ava/0e/4e/45848d16ab4e0e_48x48.gif";
					}		
									
					q.location = this.quests[id].location;				
					q.questName = this.quests[id].questName;
					q.questDesc = this.quests[id].questSummary; 
					q.info = this.quests[id].stepDesc;				
					q.completed = this.quests[id].completed;
					q.goalProgress = this.quests[id].goalProgress;
					q.goalTotal = this.quests[id].goalTotal;
					q.questGoal = this.quests[id].questGoal;
					q.goalUrl = this.quests[id].goalUrl;
					q.stepType = this.quests[id].stepType;			
					if (q.completed){
						q.status = "Completed";
						q.completedDate = "Thu Feb 07, 2008 12:16 pm";
						cc += 1;
					}else{
						q.status = "Step " + this.quests[id].questStep;// +"." + " of " + this.quests[id].totalSteps + ".";
					}	
					
					if ( (q.completed && completedNotifyIds.length > 0) || (!q.completed && activeNotifyIds.length > 0) ){					
						if (q.completed){
							q.notify = completedNotifyIds.lastIndexOf(id) >= 0;
						}else{						
							q.notify = activeNotifyIds.lastIndexOf(id) >= 0;
						}					
					}else {
						q.notify =  (this.quests[id].notify != null && this.quests[id].notify);	
					}				
					questsArray.push(q);
				
					
				}							
				
			}
									
			this.uiQuestLog.updateInfo(questsArray, active, completed);
			
			if (update){
				if (this.competedCount < cc){
					GlobalEvent.eventDispatcher.dispatchEvent(new GlobalEvent(GlobalEvent.ALERT, {type:AlertTypes.MISSION_COMPLETED}));																																												
				}else{
					GlobalEvent.eventDispatcher.dispatchEvent(new GlobalEvent(GlobalEvent.ALERT, {type:AlertTypes.UPDATE_PDA_STEP}));																																												
				}			
			}
			this.competedCount = cc;
			
		}		
		
		
		public function clearActiveNotification():void{
			for (var id:String in this.quests){		
				if (this.quests[id].completed == null || !this.quests[id].completed){
					this.quests[id].notify = false;
					delete this.quests[id].notify;
				}
			}
		}
		public function clearCompletedNotification():void{
			for (var id:String in this.quests){		
				if (this.quests[id].completed != null && this.quests[id].completed){
					this.quests[id].notify = false;
					delete this.quests[id].notify;
				}
			}
		}		
	}
}
