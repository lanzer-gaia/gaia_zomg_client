package com.gaiaonline.battle.ui
{	
	import com.gaiaonline.battle.gateway.BattleMessage;
	import com.gaiaonline.battle.newactors.ActorManager;
	import com.gaiaonline.battle.newactors.BaseActor;
	import com.gaiaonline.flexModulesAPIs.clcapwidget.IClCapEventHandler;
	import com.gaiaonline.flexModulesAPIs.clcapwidget.IClCapWidget;
	import com.gaiaonline.flexModulesAPIs.gatewayInterfaces.IBattleGateway;
	import com.gaiaonline.flexModulesAPIs.globalevent.GlobalEvent;
	
	import flash.events.TimerEvent;
	import flash.utils.Timer;

	public class ClCapWidgetController implements IClCapEventHandler
	{
		private var _clCapWidget:IClCapWidget;		
		private var _newCl:Number = 1;
		private var _gateway:IBattleGateway;		
		private var _timer:Timer;
		
		public function ClCapWidgetController(gateway:IBattleGateway)
		{
			this._gateway = gateway;
			_timer = new Timer(500);
			_timer.addEventListener(TimerEvent.TIMER, onTimerValidate, false, 0, true);
		}
		
		protected function onTimerValidate(event:TimerEvent):void
		{
			validate();
		}
		
		public function addView(view:IClCapWidget):void{			
			this._clCapWidget = view;
			this._clCapWidget.setEventHandler(this);
			
			var myActor:BaseActor = ActorManager.getInstance().myActor;
			var maxCl:Number = myActor.conLevel;
			if(!this._isNullChamber){
				maxCl = myActor.getSuppressedCL();
			}
			
			this._clCapWidget.minimum = 1;
			this._clCapWidget.maximum = maxCl;
			
			this.init();
			_timer.start();
		}
		
		public function init():void{
			this._clCapWidget.cl = ActorManager.getInstance().myActor.getSuppressedCL();
			this.validate();
			this._clCapWidget.selectAllText();
		}
				
		protected function validate():void{
			if (this._clCapWidget){
				
				var myActor:BaseActor = ActorManager.getInstance().myActor;
				var maxCl:Number = myActor.conLevel;
				if(!this._isNullChamber){
					maxCl = myActor.getSuppressedCL();
				}
				
				var cl:Number = this._clCapWidget.cl;
				
				this._newCl = Math.max(1, Math.min(cl, maxCl));

				this._clCapWidget.plusEnable = this._newCl < maxCl;
				this._clCapWidget.minusEnable = this._newCl > 1;
				
				this.setText();
			}
		}
		
		protected function setText():void{
			var txt:String;
			var down:Boolean = this._clCapWidget.minusEnable;
			var up:Boolean = this._clCapWidget.plusEnable;			
			
			if (down && up){
				//case 3
				txt = "Use the arrows to change your level. Type to enter your desired level manually.";
			}else if(!down && !up){
				//case 5
				txt = "You cannot change your level at this time. Return to the Null Chamber to change your level.";
			}
			else if (!down){
				//case 4
				txt = "Use the right arrow to increase your level. Type to enter your desired level manually.";
			}else if (!isNullChamber){
				//case 2
				txt = "Use the left arrow to lower your level. Return to the Null Chamber to increase your level.";
			}else{
				//case 1
				txt = "Use the left arrow to lower your level. Type to enter your desired level manually.";
			}
			
			this._clCapWidget.setText(txt);
		}
		
		
		private var _isNullChamber:Boolean = false;
		public function get isNullChamber():Boolean
		{
			return _isNullChamber;
		}
		public function set isNullChamber(value:Boolean):void
		{
			_isNullChamber = value;
		}
		
		
		//******* IClCalEventHandler ****
		public function onBtnPlusClick():void{
			this.validate();
			this._clCapWidget.cl = Math.floor(this._newCl + 1);
			this.validate();
		}
		public function onBtnMinusClick():void{
			this.validate();
			this._clCapWidget.cl = Math.floor(this._newCl - 1);
			this.validate();
		}
		
		public function onBtnCancelClick():void{
			GlobalEvent.eventDispatcher.dispatchEvent(new GlobalEvent(GlobalEvent.CL_CAP_CLOSE, null));
			_timer.stop();
		}
		public function onBtnConfirmClick():void{
			this.validate();
			var msg:BattleMessage = new BattleMessage("ringLevelCap",{"ringLevelCap": Math.floor(this._newCl * 10)});
			this._gateway.sendMsg(msg);
			GlobalEvent.eventDispatcher.dispatchEvent(new GlobalEvent(GlobalEvent.CL_CAP_CLOSE, null));
			_timer.stop();
		}
						
	}
}