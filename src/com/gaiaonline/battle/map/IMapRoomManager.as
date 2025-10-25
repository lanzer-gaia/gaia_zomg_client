package com.gaiaonline.battle.map
{
	public interface IMapRoomManager
	{
		function getCurrentRoomId():String;
		function getRoomById(id:String):MapRoom;
		function getCurrentMapRoom():MapRoom;
	}
}