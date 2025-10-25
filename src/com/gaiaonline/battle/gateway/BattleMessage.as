package com.gaiaonline.battle.gateway
{
	import com.gaiaonline.battle.bm.*;
	import com.gaiaonline.battle.utils.BattleUtils;
	import com.gaiaonline.flexModulesAPIs.gatewayInterfaces.IBattleMessage;
	import com.gaiaonline.utils.*;
	
	import flash.events.EventDispatcher;
	import flash.utils.getTimer;
	
	public class BattleMessage extends EventDispatcher implements IBattleMessage
	{		
		private var _cmd:String = "";				
		private var parameters:Object;
		private var myResult:Object;
		private var myErrorId:int = 0;
		private var myErrorMsg:String = "";	
		private var _sentTime:int = 0;
		private var _lag:int = 0;
		
		private var _tag:Object;
		
		private static const s_EmptyArray:Array = [];
		public function BattleMessage( command:String, requestObj:* )
		{			
			if (requestObj == null){
				requestObj =  s_EmptyArray;
			}
			
			this._cmd = command;			
			this.parameters = requestObj;			
		}
		
		public function debugTrace() : void
		{
			if( this._cmd != null )
			{
				var paramsStr:String;
				var name:String;
				for( name in parameters )
				{
					paramsStr += ( name + "=" + parameters[name] )
					paramsStr += " "
				}
				trace( "cmd=" + _cmd + " params:" + paramsStr )
			}
		}
			
		public function setResult( resultObj:Object ): void
		{
			this._lag = getTimer() - this._sentTime;
			
			this.myResult = resultObj;
			var evt:BattleEvent = new BattleEvent( BattleEvent.CALL_BACK, this );				
			this.dispatchEvent( evt );			
		}
		
		// getter setter;
		public function get sentTime():int{
			return this._sentTime;
		}
		public function set sentTime(v:int):void{
			this._sentTime = v;
		}
		
		public function get lag():int{
			return this._lag;
		}
		public function set lag(v:int):void{
			this._lag = v;
		}
		
		public function get tag():Object{
			return this._tag;
		}
		public function set tag(v:Object):void{
			this._tag = v;
		}
		
		public function get cmd():String{
			return this._cmd;
		}
		public function set cmd(v:String):void{
			this._cmd = v;
		}
		
		public function get responseObj(): Object
		{			
			return this.myResult;
		}
		
		public function get requestObjUnsafeForModifying(): Object
		{
			return this.parameters;			
		}

		public function get requestObjSafeForModifying(): Object
		{
			return BattleUtils.copy(this.parameters);			
		}
		
		public function get commandName(): String
		{
			return this._cmd;
		}
		
		public function get error(): Object
		{
			var er: Object = { id:this.myErrorId, msg:this.myErrorMsg };
			return er;
		}
		
		public function setError( id:int, msg:String ): void
		{
			this.myErrorId = id;
			this.myErrorMsg = msg;
		}
	}
}