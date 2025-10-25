package com.gaiaonline.battle.ui.UiWorldListClasses
{
	
	public interface IFriendsListPanel
	{
		function showFriends():void;
		function removerFriendItem(item:FriendItem, updateSort:Boolean = true):void;
		function refreshFriendsList(friends:Array):void;
	}
}