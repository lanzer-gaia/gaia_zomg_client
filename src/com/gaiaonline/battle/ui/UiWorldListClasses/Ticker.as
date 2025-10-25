package com.gaiaonline.battle.ui.UiWorldListClasses
{
	import com.gaiaonline.battle.news.ITickerConnector;
	import com.gaiaonline.battle.news.ITwitterEventHandler;
	
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.events.TimerEvent;
	import flash.text.TextField;
	import flash.utils.Timer;

	public class Ticker extends MovieClip implements ITwitterEventHandler
	{
		public var txt:TextField;
		private var _twitterTimer:Timer = null;
		private var _tickerConnector:ITickerConnector = null;
		
		private var _txtWidth:int = 0;		
		
		private var _lastTwitterTime:Number = 0;
		private const _twitterNewsURLBase:String = "http://twitter.com/statuses/user_timeline/zOMGDev.json?count=";
		private const _numMessages:uint = 1;  
		
		public function Ticker(tickerConnector:ITickerConnector)
		{			
			super();
			createTimer();
			this._tickerConnector = tickerConnector;
			this._twitterTimer.addEventListener(TimerEvent.TIMER_COMPLETE, onTwitterTimer);	
			this.getTwitter();	
		}
		public function startTicker():void{
			if (!this.hasEventListener(Event.ENTER_FRAME)){
				this.addEventListener(Event.ENTER_FRAME, onFrame, false, 0, true);
			}
			createTimer();
		}
		
		private function createTimer():void{
			if(!_twitterTimer){
				_twitterTimer = new Timer(60000, 1);
			}
		}
		
		public function stopTicker():void{
			this.removeEventListener(Event.ENTER_FRAME, onFrame);
			stopTwitter();
			_tickerConnector.unregisterForTickerEvents(this);
			_twitterTimer = null;
		}
		
		public function setText(text:String):void
		{
			if (this.txt) {
				text = "        " + text + "        -";		
				this.txt.text = text;
				this._txtWidth = this.txt.textWidth;			
	
				var loopGuard:int = 10;
				while(this.txt.textWidth < (696 + this._txtWidth))
				{
					var oldWidth:Number = this.txt.textWidth;
					this.txt.appendText(text);
					if (this.txt.textWidth == oldWidth)
					{
						if (--loopGuard <= 0)
						{
							trace("BUG IN TICKER FOUND - terminating loop before it's infinite");
							break;
						}
					}
				}
			}
		}
		
		private function onFrame(evt:Event):void{
			if (this.txt) {			
				this.txt.scrollH += 3;
				if (this.txt.scrollH >= (this._txtWidth - 3)){
					this.txt.scrollH = 0;
				}
			}
		}
		
		
		//*******************************************
		//***** Twitter *****************************
		//*******************************************	
		public function stopTwitter():void{
			this._twitterTimer.stop();				
		}
		
		private function onTwitterTimer(evt:TimerEvent):void{
			getTwitter();
		}
		
		private function getTwitter():void{
			this._tickerConnector.registerForTickerEvents(this);
			this._tickerConnector.getTweets();
		}
		
		public function onTweetsSuccessful(tweets:Array):void {
			this._twitterTimer.reset();			
			this._twitterTimer.start();
			
			if (tweets == null || tweets.length == 0) {
				return;
			}
			
			var rawDate:String = tweets[0].date;
			var rawText:String = tweets[0].text;
			
			var dt:Date = new Date(Date.parse(rawDate));
			if (this._lastTwitterTime != dt.time){
				this._lastTwitterTime = dt.time;
				
				var ampm:String = "am";
				var h:Number = dt.hours;
				if (h >= 12){
					ampm = "pm";
					if (h > 12){
						h -= 12;
					}
				}				
				var time:String = h+":"+dt.minutes+":"+dt.seconds + " " + ampm;
				var date:String = String(dt.month+1) + "/" + dt.date + "/" + dt.fullYear;
				
				setText("[ " + date + " " + time + " ] " + rawText.replace("\n"," "));				
				startTicker();
			}			
		}
	}
}