package com.gaiaonline.battle.ui.UiWorldListClasses
{
	import com.gaiaonline.battle.news.INewsConnector;
	
	public interface INewsHolder
	{
		function showNews(newsConnector:INewsConnector, baseUrl:String, partnerId:String):void;
	}
}