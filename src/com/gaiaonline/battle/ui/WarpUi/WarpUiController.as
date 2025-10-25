package com.gaiaonline.battle.ui.WarpUi
{
	import com.gaiaonline.flexModulesAPIs.WarpUi.IWarpUiEvent;
	
	public class WarpUiController implements IWarpUiEvent
	{
		public function WarpUiController()
		{
		}
		
		public function onWarpButtonClick(roomName:String):void{
			trace("CALL GattleGateway 198")
		}

	}
}