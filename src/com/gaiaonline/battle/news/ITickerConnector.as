package com.gaiaonline.battle.news
{
	public interface ITickerConnector
	{
		function registerForTickerEvents(handler:ITwitterEventHandler):void;
		function unregisterForTickerEvents(handler:ITwitterEventHandler):void;

		function getTweets():void;		
	}
}