package com.gaiaonline.battle.map
{
	public interface IMapEffect
	{
		function registerForTransitionEvents(handler:ITransitionEventHandler):void;
		function unregisterForTransitionEvents(handler:ITransitionEventHandler):void;
		function out(x:Number, y:Number):void;
		function int(x:Number, y:Number):void;
	}
}