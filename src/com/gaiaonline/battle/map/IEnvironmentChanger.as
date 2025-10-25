package com.gaiaonline.battle.map
{
	public interface IEnvironmentChanger
	{
		function registerForEnvironmentChanges(handler:IEnvironmentChangeHandler):void
		function updateObject(invalidObj:Object):void;
	}
}