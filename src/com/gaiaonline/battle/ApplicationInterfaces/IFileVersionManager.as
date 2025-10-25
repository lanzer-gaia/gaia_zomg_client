package com.gaiaonline.battle.ApplicationInterfaces
{
	public interface IFileVersionManager {
		function getClientVersion(fileName:String):String;
		function getServerVersion():String;				

		function setServerVersion(version:String):void;	
		function setClientVersion(version:String):void;			
	}
}