package com.gaiaonline.battle.gateway
{
	import flash.events.EventDispatcher;
	
	public class GWMessage extends EventDispatcher
	{
		private var myCmd:String = "";
		private var myCid:String = "";
		private var requestObject:Object;
		private var myResult:Object;
		//private var myMsgString:String = "";
		private var responseString:String = "";	
		
		private var myErrorId:int = 0;
		private var myErrorMsg:String = "";	
		
		public function GWMessage(cmd:String, requestOb:Object)
		{
			this.myCmd = cmd;
			this.requestObject = requestOb;
			//this.myMsg = requestOb;
		}
		
		/**
		internal function getAMF():ByteArray{
			var obj:Object = new Object;
			obj.cmd = this.cmd;
			obj.cid = this.cid;
			obj.msg = this.msg;
			
			var b:ByteArray = new ByteArray();
			b.writeObject(obj);	
			
			return b;	
		}
		 * */
			
		internal function setResult(msg:Object, resString:String = ""):void
		{
			this.myResult = msg;
			this.responseString = resString;
			this.dispatchEvent( new GWEvent(GWEvent.CALL_BACK, this) );
		}
		
		internal function setCid(cid:String):void
		{
			this.myCid = cid;
		}
		
		// getter setter;
		public function get responseObj():Object
		{
			return this.myResult;
		}
		
		public function get requestObj():Object
		{
			return this.requestObject;			
		}
		
		public function set requestObj(v:Object):void
		{
			this.requestObject = v;
		}	
		
		public function get commandName():String
		{
			return this.myCmd;
		}
		public function get callId():String
		{
			return this.myCid;
		}
		
		public function get error():Object
		{
			var er:Object = {id:this.myErrorId, msg:this.myErrorMsg};
			return er;
		}
		public function setError(id:int, msg:String):void
		{
			this.myErrorId = id;
			this.myErrorMsg = msg;
		}
		
		public function get msgString():String
		{
			return this.responseString;
		}
		
		public function getResponseString():String
		{
			return this.responseString;
		}
		
}}