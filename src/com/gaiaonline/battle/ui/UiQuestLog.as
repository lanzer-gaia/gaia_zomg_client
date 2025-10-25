package com.gaiaonline.battle.ui
{
	import com.gaiaonline.battle.GlobalTexts;
	
	import flash.display.MovieClip;

	public class UiQuestLog extends MovieClip
	{
		
		//public var tabBtns:MovieClip;
		public var tabCompleted:UiQuestItemDisplay;
		public var tabActive:UiQuestItemDisplay;		
						
		//private var tabManager:TabManager;
		private var _width:Number = 0;
		private var _height:Number = 0;
		private var _activeQuest:Object = new Object();
		private var _completedQuest:Object = new Object();
		
		public function UiQuestLog()
		{
			super();
			
			this.tabChildren = false;		
			
			this.tabCompleted.setNoTasksString(GlobalTexts.getNoCompletedQuestItemsText());	
			this.tabActive.setNoTasksString(GlobalTexts.getNoActiveQuestItemsText());

			this.mouseEnabled = false;				
		}
		
		private var _activeList:Array = new Array();
		private var _completedList:Array = new Array();
		public function updateInfo(list:Array = null, active:Boolean = true, completed:Boolean = true):void{
			this._activeList.length = 0;
			this._completedList.length = 0;

			for (var i:int= 0; i < list.length; i++){				
				if (list[i].completed){
					_completedList.push(list[i]);
				}else{
					_activeList.push(list[i]);
				}
			}	
			
			if (active || completed){  //[Fred] always update active list (if a completed quest is added most likely a active one is removed
									   //[Mark] but we could be here because of a deletion, so explicitly check if we're here for active or completed				
				this.tabActive.updateInfo(_activeList);
			}
			if (completed){
				this.tabCompleted.updateInfo(_completedList);
			}
		}
				
		
		public override function set width(v:Number):void{
			this._width = v;			
			this.tabActive.width = this._width;
			this.tabCompleted.width = this._width;			
		}
		public override function set height(v:Number):void{
			this._height = v;
			this.tabActive.height = this._height //- this.tabBtns.height;
			this.tabCompleted.height = this._height //- this.tabBtns.height;		
		}
		
	}
}