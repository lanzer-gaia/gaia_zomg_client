package com.gaiaonline.battle.news
{
	public interface INewsConnector
	{
		function registerForNewsEvents(handler:INewsEventHandler):void;
		function unregisterForNewsEvents(handler:INewsEventHandler):void;
		function getNews(numOfNewsItems:uint=10):void;
	}
}