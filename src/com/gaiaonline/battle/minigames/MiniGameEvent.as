package com.gaiaonline.battle.minigames
{
	import flash.events.Event;

	public class MiniGameEvent extends Event
	{
		public static const WIN: String			= "win";
		public static const LOSE: String		= "lose";
		public static const START: String		= "start";
		public static const GOOD_MOVE: String	= "goodmove";
		public static const BAD_MOVE: String	= "badmove";
		
		private var _score: String;
		private var _message: String; 
		//-----------------------------------------------
		public function MiniGameEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
		}
		
		//-----------------------------------------------
		public function set score(s: String): void
		{
			_score = s;
		}
		
		//-----------------------------------------------
		public function get score(): String
		{
			return _score;
		}
		
	 	//-----------------------------------------------
		public function set message(s: String): void
		{
			_message = s;
		}
		
		//-----------------------------------------------
		public function get message(): String
		{
			return _message;
		} 
	}
}