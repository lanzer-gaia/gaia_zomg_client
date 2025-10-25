package com.gaiaonline.battle.ui.actionbarmodule
{
	import com.gaiaonline.battle.gateway.BattleMessage;
	import com.gaiaonline.battle.newactors.ActorManager;
	import com.gaiaonline.flexModulesAPIs.actionbar.IActionBarEventHandler;
	import com.gaiaonline.flexModulesAPIs.actionbar.IActionBarModule;
	import com.gaiaonline.flexModulesAPIs.gatewayInterfaces.IBattleGateway;
	import com.gaiaonline.flexModulesAPIs.globalevent.GlobalEvent;
	
	import flash.events.TimerEvent;
	import flash.utils.Timer;
	
	public class ActionBarModuleController implements IActionBarEventHandler
	{
		private var _actionBarModule:IActionBarModule = null;
		private var _actorManager:ActorManager;
		private var _gateway:IBattleGateway;
		
		public function ActionBarModuleController(gateway:IBattleGateway)
		{	
			this._gateway = gateway;		
			GlobalEvent.eventDispatcher.addEventListener(GlobalEvent.POSE_CHANGE, onPoseChange, false, 0, true);
			GlobalEvent.eventDispatcher.addEventListener(GlobalEvent.ALLOW_SIT_STAND, onAllowSitStand, false, 0, true);		
		}
		
		public function addView(view:IActionBarModule):void{
			this._actionBarModule = view;
			this._actionBarModule.setPoseEventHandler(this);
		}
		
		
		//**********************
		// -- sit/stand
		//***********************
		private const SIT_STAND_DELAY_TIME:Number = 3 * 1000; // in milliseconds
		private  var _sitStandTimer:Timer = new Timer(SIT_STAND_DELAY_TIME,1);
		private var _allowSitStand:Boolean = true;
		
		public function onBtnPoseClick():void{
			this.sitStand();	
		}		
		
		private function onPoseChange(evt:GlobalEvent):void{
			this._actionBarModule.setPose(evt.data.sit);
		}
	
		private function sitStand():void{
			if (!this._actorManager){
				this._actorManager = ActorManager.getInstance();
			}
			
			if (!this._allowSitStand || this._actorManager.myActor == null) {
				return;
			}
					
			var isSitting:Boolean = _actorManager.myActor.isSitting;	
			
			var sit:Boolean = !isSitting;
			if (isSitting) { // if we go from sitting to standing, we make them wait 3 seconds before sitting again, to prevent cybering				
				startSitStandTimer();
			}
			
			this._actionBarModule.setPose(sit);
			
			if (sit){				
				if (_actorManager.myActor != null){					
					
					//trace("SEND 106  = 1")
					var param:Array = new Array();
					param[0] = 1;				
					var msg2:BattleMessage = new BattleMessage("106", param);
					this._gateway.sendMsg(msg2);															
					_actorManager.myActor.sit(true);						
				}	
			}else{				
				if (_actorManager.myActor != null){
					//trace("SEND 106  = 0")
					var param3:Array = new Array();
					param3[0] = 0;				
					var msg3:BattleMessage = new BattleMessage("106", param3);
					this._gateway.sendMsg(msg3);					
					_actorManager.myActor.stand();
				}
			}
		}	
		
		private function startSitStandTimer():void {
			if (!_sitStandTimer.running) {
				_sitStandTimer.addEventListener(TimerEvent.TIMER, onSitStandTimerDone);
				GlobalEvent.eventDispatcher.dispatchEvent(new GlobalEvent(GlobalEvent.ALLOW_SIT_STAND, {allow:false}));
				_sitStandTimer.start();
			}
		}
		private function onSitStandTimerDone(e:TimerEvent):void {
			GlobalEvent.eventDispatcher.dispatchEvent(new GlobalEvent(GlobalEvent.ALLOW_SIT_STAND, {allow:true}));
		}
		
		private function onAllowSitStand(e:GlobalEvent):void {
			this._allowSitStand = e.data.allow;
			this._actionBarModule.poseEnabled = this._allowSitStand;
			if (this._allowSitStand) {
				this._sitStandTimer.stop();			
			}
		}		
		
		
		

	}
}