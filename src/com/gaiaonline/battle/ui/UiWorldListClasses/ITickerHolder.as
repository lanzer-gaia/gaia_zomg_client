package com.gaiaonline.battle.ui.UiWorldListClasses
{
	import com.gaiaonline.battle.news.ITickerConnector;

	public interface ITickerHolder
	{
		function showTicker(tickerConnector:ITickerConnector):void;
	}
}