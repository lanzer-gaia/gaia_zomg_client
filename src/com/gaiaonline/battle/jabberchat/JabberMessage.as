package com.gaiaonline.battle.jabberchat
{
	import flash.events.EventDispatcher;

	public class JabberMessage extends EventDispatcher
	{
		public static const MESSAGE_READY:String = "JabberMessage_MessageReady"; 
			
		public static function getSquashName(userName:String):String{
			var re:RegExp = new RegExp("[^A-Za-z0-9]+");
			var squashName:String = userName;									
			var i:int = squashName.search(re);			
			while (i > -1){
				squashName = squashName.replace(re, "");
				i = squashName.search(re);					
			}
			return squashName.toLowerCase();
		}
		
		
		private var _squashName:String;
		private var _txt:String;
		private var _displayName:String;
		private var _userId:String;
		
		public function JabberMessage(userName:String, txt:String)
		{
			this._txt = txt;
			if (userName != null){
				this._squashName = getSquashName(userName);
			}
		}
		
		
		public function set txt(v:String):void{
			this._txt = v;
		}
		public function get txt():String{
			return this._txt;
		}
		
		public function set displayName(v:String):void{
			this._displayName = v;
		}
		public function get displayName():String{
			return this._displayName;
		}
		
		public function get squashName():String{
			return this._squashName;
		}
		
		private var _isError:Boolean = false;
		public function get isError():Boolean
		{
			return _isError;
		}
		public function set isError(value:Boolean):void
		{
			_isError = value;
		}
		
		public var channel:String = null;
		
				
	}
}