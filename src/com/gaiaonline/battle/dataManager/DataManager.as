package com.gaiaonline.battle.dataManager
{
	import com.gaiaonline.battle.ApplicationInterfaces.IGatewayFactory;
	import com.gaiaonline.battle.gateway.BattleGateway;
	
	import flash.utils.Dictionary;
	
	public class DataManager
	{
		private var _gatewayFactory:IGatewayFactory = null;
		private var _gateway:BattleGateway = null;
		
		private var _dataObjs:Dictionary = new Dictionary(true);
		
		public function DataManager(gatewayFactory:IGatewayFactory)
		{
			this._gatewayFactory =  gatewayFactory;
			this._gateway = this._gatewayFactory.battleGateway;
		}	
						
		public function getData(cmd:String, refresh:Boolean = false):DataObject{
			
			var dObj:DataObject = null;
			
			if (this._dataObjs[cmd] == null){
				this._dataObjs[cmd] = new DataObject(cmd);
				this._gateway.sendMsg(new msg
				return this._dataObjs[cmd];
			}
					
			
		}

	}
}