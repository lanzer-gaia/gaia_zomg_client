package com.gaiaonline.battle.ui
{
	import com.adobe.serialization.json.JSONEncoder;
	import com.gaiaonline.battle.GST;
	import com.gaiaonline.battle.Globals;
	import com.gaiaonline.battle.gateway.AdminCmdData;
	import com.gaiaonline.battle.gateway.AdminCmdListener;
	import com.gaiaonline.battle.gateway.AdminMsg;
	import com.gaiaonline.battle.gateway.BattleEvent;
	import com.gaiaonline.battle.gateway.BattleMessage;
	import com.gaiaonline.flexModulesAPIs.adminpanel.IAdminPanelEventHandler;
	import com.gaiaonline.flexModulesAPIs.adminpanel.IAdminPanelModule;
	import com.gaiaonline.flexModulesAPIs.gatewayInterfaces.IBattleGateway;
	import com.gaiaonline.flexModulesAPIs.globalevent.GlobalEvent;
	
	import flash.events.Event;

	public class AdminPanelController implements IAdminPanelEventHandler
	{
		private var _battleGateway:IBattleGateway
		private var _view:IAdminPanelModule = null;
		private var _commands:Array = ["nothing"];
		private var _lastCommand:String;
		
		public function AdminPanelController(battleGateway:IBattleGateway)
		{
			_battleGateway = battleGateway;
			_battleGateway.addEventListener(AdminMsg.TYPE, onAdminMsg, false, 0, true);
			_battleGateway.addEventListener(AdminCmdData.TYPE, onAdminCmdData, false, 0, true);
			_battleGateway.addEventListener(AdminCmdListener.TYPE, onAdminListenEvent, false, 0, true);
		}
		
		private function onAdminCmdData(event:AdminCmdData):void
		{
			if(-1 == _commands.indexOf(event.cmd))
			{
				_commands.push(event.cmd);
				if(_view)
				{
					_view.setFilterOptions(_commands);
				}
			}
		}

		private function onAdminMsg(event:AdminMsg):void
		{
			showObjectInConsole(event.data);
		}
		
		private function onAdminListenEvent(event:AdminCmdListener):void
		{
			if(_lastCommand && _lastCommand == event.cmd)
			{
				var response:Object = event.data.responseObj;
				showObjectInConsole(response);
			}
		}
		
		public function addView(view:IAdminPanelModule):void{
			this._view = view;
			this._view.setEventHandler(this);
			this._view.setFilterOptions(_commands);
		}
				
		public function onShowCollisionClick( selected:Boolean ):void
		{
			if( selected )
			{	
				Globals.uiManager.uiFramework.map.drawCollisionMap();
				Globals.uiManager.uiFramework.map.setCollisionShowing( true );
			}
			else
			{
				Globals.uiManager.uiFramework.map.setCollisionShowing( false );
			}
		}
		
		public function onSendCommandClick(cmd:String, paramsString:String):void{
			
			var params:Array = String(paramsString).split(",");
			
			if (!isNaN( parseInt(cmd)) ){
				var msgOld:BattleMessage = new BattleMessage(cmd, params);		
				msgOld.addEventListener(BattleEvent.CALL_BACK, onAdminCommadCallBack);
				this._battleGateway.sendMsg(msgOld);	
			}else{
				var paramObj:Object = new Object();
				for (var i:int = 0; i < params.length; i++){
					var pv:Array = params[i].split(":");
					paramObj[String(pv[0]).replace(" ","")] = pv[1];				
				}				
				var msgNew:BattleMessage = new BattleMessage(cmd, paramObj);
				msgNew.addEventListener(BattleEvent.CALL_BACK, onAdminCommadCallBack);
				this._battleGateway.sendMsg(msgNew);		
			}
			
		}
		
		private function onAdminCommadCallBack(evt:BattleEvent):void{								
			BattleMessage(evt.target).removeEventListener(BattleEvent.CALL_BACK, onAdminCommadCallBack);
			
			var obj:Object = evt.battleMessage.responseObj;
			showObjectInConsole(obj);
		}
		
		private function showObjectInConsole(obj:Object):void
		{
			this._view.setConsoleText(new JSONEncoder(obj).getString());
		}
		
		public function onGstChange( gstDate:Date ): void
		{
			GlobalEvent.eventDispatcher.dispatchEvent(new GlobalEvent(GlobalEvent.GST_SET, gstDate));
		}
		
		public function onLightsClick():void
		{
			var l:Boolean = ! Globals.uiManager.uiFramework.map.isLightsOn();
			GlobalEvent.eventDispatcher.dispatchEvent( new GlobalEvent( GlobalEvent.MAP_SET_LIGHTS, {on:l} ) );
		}
		
		public function onCommandFilter( command:String ):void
		{
			_lastCommand = command;
		}
	}
}