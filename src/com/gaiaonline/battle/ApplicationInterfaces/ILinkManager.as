package com.gaiaonline.battle.ApplicationInterfaces
{
	public interface ILinkManager {
		function setLink(key:String, value:String):void;
		function getLink(key:String):String;
		
		function set baseURL(url:String):void;
		function get baseURL():String;
		
		function set spaceName(spaceName:String):void;
		function get spaceName():String;
	}
}