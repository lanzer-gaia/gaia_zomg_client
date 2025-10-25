package com.gaiaonline.battle.userServerSettings
{
	import com.gaiaonline.battle.gateway.BattleEvent;
	import com.gaiaonline.battle.gateway.BattleGateway;
	import com.gaiaonline.battle.gateway.BattleMessage;
	import com.gaiaonline.flexModulesAPIs.globalevent.GlobalEvent;
	
	import flash.events.EventDispatcher;
	
	public class UserServerSettings extends EventDispatcher implements IGraphicOptionsSettings, IGameSettings
	{
		private var _gateway:BattleGateway;
		private var _stageQuality:String = "high";
		private var _silhouettingEnabled:Boolean = true;
		private var _ringAnimationDisplay:String = "all";
		
		private var _ringAutoSelect:Boolean = true;
		private var _autoMoveInRange:Boolean = true;
		
		public function UserServerSettings(gateway:BattleGateway)
		{
			this._gateway = gateway;
			GlobalEvent.eventDispatcher.addEventListener(GlobalEvent.GRAPHIC_OPTIONS_CHANGED, onGraphicOptionsChanged, false, 0, true);		
			//GlobalEvent.eventDispatcher.addEventListener(GlobalEvent.USER_SETTINGS_LOADED, onGraphicOptionsChanged, false, 0, true);
		}
				
		public function loadGraphicOptions():void{
			var msg:BattleMessage = new BattleMessage("getNkvp", {keys:["stageQuality","silhouettingEnabled","ringAnimationDisplay","ringAutoSelect","autoMoveInRange"]});
			msg.addEventListener(BattleEvent.CALL_BACK, onStageQualityLoaded);
			this._gateway.sendMsg(msg);
		}
		private function onStageQualityLoaded(evt:BattleEvent):void{
			var responseObj:Object = evt.battleMessage.responseObj[0].values;
			if (responseObj) {
				var quality:String = responseObj["stageQuality"] as String;						
				if (quality && quality.toLowerCase() != this._stageQuality) {
					this._stageQuality = quality.toLowerCase();									
				}
				
				if (responseObj["silhouettingEnabled"] != null){
					var silhouettingEnabled:Boolean = responseObj["silhouettingEnabled"] as Boolean;						
					this._silhouettingEnabled = silhouettingEnabled;
				}								
				
				var ringAnimationDisplay:String = responseObj["ringAnimationDisplay"] as String;						
				if (ringAnimationDisplay && ringAnimationDisplay.toLowerCase() != this._ringAnimationDisplay) {
					this._ringAnimationDisplay = ringAnimationDisplay.toLowerCase();									
				}
				
				if (responseObj["ringAutoSelect"] != null){
					var ringAutoSelect:Boolean = responseObj["ringAutoSelect"] as Boolean;
					this._ringAutoSelect = ringAutoSelect;
				}
				if (responseObj["autoMoveInRange"] != null){
					var autoMoveInRange:Boolean = responseObj["autoMoveInRange"] as Boolean;
					this._autoMoveInRange = autoMoveInRange;
				}
			}
			
			GlobalEvent.eventDispatcher.dispatchEvent(new GlobalEvent(GlobalEvent.USER_SETTINGS_LOADED, this));	
			
		}
		
		private function onGraphicOptionsChanged(evt:GlobalEvent):void{
			var data:IGraphicOptionsSettings = evt.data as IGraphicOptionsSettings;
			if (data != null){
				this._stageQuality = data.getStageQuality();
				this._silhouettingEnabled = data.getSilhouettingEnabled();
				this._ringAnimationDisplay = data.getRingAnimationDisplay();				
			}
			
			var data2:IGameSettings = evt.data as IGameSettings;
			if (data2 != null){
				this._ringAutoSelect = IGameSettings(data2).getRingAutoSelect();
				this._autoMoveInRange = IGameSettings(data2).getAutoMoveInRange();
			}
				
			var graphicOptionsMap:Object = {"stageQuality":this._stageQuality, "silhouettingEnabled":this._silhouettingEnabled , "ringAnimationDisplay":this._ringAnimationDisplay, "ringAutoSelect":this._ringAutoSelect, "autoMoveInRange":this._autoMoveInRange};
			var msg:BattleMessage = new BattleMessage("putNkvp", graphicOptionsMap);
			this._gateway.sendMsg(msg);	
		}
		
		///---- Implementations
		
		public function getStageQuality():String{
			return this._stageQuality.toLowerCase();
		}
		public function getSilhouettingEnabled():Boolean{
			return this._silhouettingEnabled;
		}
		public function getRingAnimationDisplay():String{
			return this._ringAnimationDisplay;
		}
	
		public function getRingAutoSelect():Boolean{
			return this._ringAutoSelect;
		}
		public function getAutoMoveInRange():Boolean{
			return this._autoMoveInRange;
		}
	
	}
}