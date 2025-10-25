package com.gaiaonline.battle.gateway
{
	public class BattleServerRequest
	{
		public var cmd:String;
		public var parameters:Object;
		
		public function BattleServerRequest( cmdd:String, paramz:Object )
		{
			//trace("[BSR] new BattleServerRequest( " + cmdd + ", " + paramz + " )");
			this.cmd = cmdd;
			this.parameters = paramz;
		}
		
		public function getCommand():String
		{
			return cmd;
		}
		
		public function getParameters():Object
		{
			return parameters;
		}
	}
}