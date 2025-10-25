package com.gaiaonline.battle.ApplicationInterfaces
{
	import flash.system.ApplicationDomain;
	
	public interface IAssetFactory 
	{
		function addAppDomain(appDomain:ApplicationDomain):void;
		function getClass(className:String, caching:Boolean = true):Class;
		function getInstance(className:String, caching:Boolean = true):Object;
		function checkOut(className:String):Object;
		function checkIn(obj:Object):Boolean;
	}
}