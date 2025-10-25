package com.gaiaonline.mmo.battle
{
	public class ChangeLevelValidationResult
	{
		public static const stopOnFail:Number = 0;
		public static const stopOnPass:Number = 1;
		
		public static const failButShow:Number = 0;
		public static const failAndHide:Number = 1;
		
		private var _valid:Boolean;
		private var _message:String;
		private var _stopPolicy:Number;
		private var _showPolicy:Number;

		public function ChangeLevelValidationResult( valid:Boolean, message:String, stopPolicy:Number, showPolicy:Number )
		{
			_valid = valid;
			_message = message;	
			_stopPolicy = stopPolicy;
			_showPolicy = showPolicy;
		}
		
		public function get valid():Boolean
		{
			return _valid;
		}
		
		public function get message():String
		{
			return _message;
		}
		
		public function get stopPolicy():Number
		{
			return _stopPolicy;
		}
		
		public function get showPolicy():Number
		{
			return _showPolicy;
		}

	}
}