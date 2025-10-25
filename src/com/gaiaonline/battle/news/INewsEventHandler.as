package com.gaiaonline.battle.news
{
	public interface INewsEventHandler{
		function onNewsSuccess(newsData:Object):void;
		function onNewsError():void;
	}
}