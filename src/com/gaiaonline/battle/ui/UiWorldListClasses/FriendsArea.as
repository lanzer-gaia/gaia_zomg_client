package com.gaiaonline.battle.ui.UiWorldListClasses
{
	import com.gaiaonline.battle.ui.components.ScrollBarVer;
	import com.gaiaonline.battle.ui.components.TabButton;
	import com.gaiaonline.battle.ui.components.TabManager;
	
	import flash.display.MovieClip;
	import flash.events.MouseEvent;
	import flash.geom.Rectangle;

	public class FriendsArea extends MovieClip
	{
		public var btnFriendsName:TabButton
		public var mcFriendsList:MovieClip;
		public var scrFriendsList:ScrollBarVer;	
		
		public var btnFriendsServerName:TabButton;
		
		private var friendsTabManager:TabManager;
		private var friendsItems:Array = new Array();
		private var friendsSortOption:Object = null;
		private var friendsSortParam:String = "serverName";	
		
		public var friendsMask:MovieClip;
		
		public function FriendsArea()
		{
			super();
			this.scrFriendsList.init(this.mcFriendsList, friendsMask.getBounds(this));
			this.scrFriendsList.smallStep = 20;			
			this.scrFriendsList.bigStep = 60; 
			
			
			
			//--- Friends List
			this.friendsTabManager = new TabManager(true);
			this.friendsTabManager.addTabs(btnFriendsName, null);
			this.friendsTabManager.addTabs(btnFriendsServerName, null, true);
			this.btnFriendsName.addEventListener(MouseEvent.CLICK, onBtnFriendsNameClick, false, 0, true);		
			this.btnFriendsServerName.addEventListener(MouseEvent.CLICK, onBtnFriendsServerNameClick, false, 0, true);
		}
		
		private function addFriendItem(item:FriendItem, updateSort:Boolean = true):void{
			if (this.friendsItems.indexOf(item) < 0){				
				this.friendsItems.push(item);				
				this.mcFriendsList.addChild(item);				
				if (updateSort){
					this.sortFriendsOn(this.friendsSortParam, this.friendsSortOption);
					this.scrFriendsList.update();
				}				
			}
		}
		public function removerFriendItem(item:FriendItem, updateSort:Boolean = true):void{
			if (this.mcFriendsList.contains(item)){
				this.mcFriendsList.removeChild(item);							
			}
			var i:int = this.friendsItems.indexOf(item);
			if (i >= 0){
				this.friendsItems.splice(i,1);
			}
			if (updateSort){
				this.scrFriendsList.update();
			}
			
		}
		
		private function onBtnFriendsNameClick(evt:MouseEvent):void{
			this.friendsSortParam = "friendName";
			if (this.btnFriendsName.sortAscending){
				this.friendsSortOption = null;
			}else{
				this.friendsSortOption = Array.DESCENDING;
			}		
			this.sortFriendsOn(this.friendsSortParam, this.friendsSortOption);
		}
		private function onBtnFriendsServerNameClick(evt:MouseEvent):void{
			this.friendsSortParam = "serverName";
			if (this.btnFriendsServerName.sortAscending){
				this.friendsSortOption = null;
			}else{
				this.friendsSortOption = Array.DESCENDING;
			}		
			this.sortFriendsOn(this.friendsSortParam, this.friendsSortOption);
		}
		
		private function sortFriendsOn(param:String, options:Object = null):void{
			this.friendsSortOption = options;
			this.friendsSortParam = param;
			this.friendsItems.sortOn(this.friendsSortParam, this.friendsSortOption);
			for (var i:int = 0; i < this.friendsItems.length; i++){				
				this.friendsItems[i].y = i * 20;
			}			
		}
		
		public function refreshFriendsList(friends:Array):void{
			// Update existing and Add New
			for (var i:int = 0; i < friends.length; i++){
				var exists:Boolean = false;
				for (var ii:int = 0; ii < this.friendsItems.length; ii++){
					if (friends[i].userId == this.friendsItems[ii].userId){
						exists = true;
						this.friendsItems[ii].friendName = friends[i].friendName;
						this.friendsItems[ii].serverName = friends[i].serverName;						
						break;											
					}
				}
				if (!exists){					
					var nItem:FriendItem = new FriendItem();
					nItem.userId = friends[i].userId;
					nItem.friendName = friends[i].friendName;
					nItem.serverName = friends[i].serverName;								
					this.addFriendItem(nItem, false);
				}
			}			
			
			//--  find item that need to be remove			
			var itemsToRemove:Array = new Array();
			for (var n:int = 0; n < this.friendsItems.length; n++){
				var ok:Boolean = false;
				for (var nn:int = 0; nn < friends.length; nn++){
					if (this.friendsItems[n].userId == friends[nn].userId){
						ok = true;
						break;
					}
				}
				if (!ok){
					itemsToRemove.push(this.friendsItems[n]);
				}
			}			
			
			// remove serverItems that need to be remove	
			for (var r:int = 0; r < itemsToRemove.length; r++){				
				this.removerFriendItem(itemsToRemove[r], false);
			}		
			
			// resort the list
			this.sortFriendsOn(this.friendsSortParam, this.friendsSortOption);			
			this.scrFriendsList.update();			
		}
		
	}
}