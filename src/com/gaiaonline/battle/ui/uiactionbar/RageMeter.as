package com.gaiaonline.battle.ui.uiactionbar
{
	import com.gaiaonline.battle.ui.ToolTipOld;
	import com.gaiaonline.flexModulesAPIs.globalevent.GlobalEvent;
	import com.gaiaonline.utils.MovieClipProxy;
	
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.utils.getTimer;

	public class RageMeter extends MovieClipProxy
	{	
		
		public var G3:MovieClip;
		public var G2:MovieClip;
		public var G1:MovieClip;
		public var mcCharge:MovieClip;
		public var mcRage:MovieClip;
		public var meterIcon:MovieClip;		
			
		private var ragePer:int = 100;
		private var charge:int = 0;
		private var charging:Boolean = false;
		private var chargeRate:Number = 1.5;
		private var chargingUp:Boolean = true;
		
		private var _tooltipManager:ToolTipOld = null;
		private var _currState:String = null;
		private var _states:Array = null;
		private static const RAGE:String = "rageState";
		private static const POWER:String = "powerState";
		
		private var time:int = 0;
		
		private var _mcRageMeter:RageMeterFl = null;
		
		public function RageMeter(tooltipManager:ToolTipOld, mcRageMeter:RageMeterFl){
			super(mcRageMeter);

			this._mcRageMeter = mcRageMeter;
			this._tooltipManager = tooltipManager;

			this.G3 = this._mcRageMeter.G3;
			this.G2 = this._mcRageMeter.G2;
			this.G1 = this._mcRageMeter.G1;
			this.mcCharge = this._mcRageMeter.mcCharge;
			this.mcRage = this._mcRageMeter.mcRage;
			this.meterIcon = this._mcRageMeter.meterIcon;
			
			_states	= new Array(2);
			_states[RAGE] = {tip: "Rage Meter", alpha: 100};
			_states[POWER] = {tip: "Power Meter", alpha: 70};	
			
			setRage(0);
			this.G1.visible = false;
			this.G2.visible = false;
			this.G3.visible = false;
		}
		
		public function get usePowerMeter():Boolean {
			return (_currState == POWER);
		}
		
		public function setRage(per:int,powerMeter:Boolean=false):void{
			if (per < 0 ){
				per = 0;
			}else if (per > 100){
				per = 100;
			}
				
			if (per != this.ragePer){				
				this.ragePer = per;					
				this.mcRage.x = -100 + this.ragePer;				
			}
			var state:String = (powerMeter) ? POWER : RAGE;
			if (_currState != state) {
				GlobalEvent.eventDispatcher.dispatchEvent(new GlobalEvent(GlobalEvent.ALLOW_AREA_RINGS_ONLY, powerMeter));	//@@ move me?
				_currState = state;
				_tooltipManager.removeToolTip(_mcRageMeter);
				_tooltipManager.addToolTip(_mcRageMeter, _states[state].tip);
				this.mcRage.alpha = _states[state].alpha;
				this.meterIcon.gotoAndStop(state);
				this.mcRage.gotoAndStop(state);
				this.mcCharge.gotoAndStop(state);
			}
		}
		
		public function startCharging():void{
			if (!this.charging){
				this.charging = true;
				this.time = getTimer();
				this.addEventListener(Event.ENTER_FRAME, onEnterFrame);
			}			
		}
		
		private function onEnterFrame(evt:Event):void{
			if (this.charge < this.ragePer){				
				var t:int = getTimer();
				var dt:int = t - this.time;
				this.time = t;
				

				/*if using powermeter than powermeter range is sliding from 0-100 and than back to 0*/
				if(usePowerMeter){
					if((this.mcCharge.x <= 0)&&(chargingUp == true)){
						this.charge += (dt * 100)/(this.chargeRate*1000);
						if(this.mcCharge.x >= -5){
							this.mcCharge.x = 0;
							chargingUp = false
							this.charge = 99;
						}
					}else{
						this.charge -= (dt * 100)/(this.chargeRate*1000);
						if(this.mcCharge.x <= -100){
							this.mcCharge.x = -100;
							chargingUp = true
						}
					}
				}else{
					/*if not using powermeter than calculating is standard*/
					this.charge += (dt * 100)/(this.chargeRate*1000);
				}
				
				
				if (this.charge >= this.ragePer){
						this.charge = this.ragePer;
						this.mcCharge.x = -100 + this.charge;				
					}else{
						this.mcCharge.x = -100 + this.charge;
					}
					
				//trace("t: "+t+"	dt: "+dt+"	this.time: "+this.time+"	this.charge:"+this.charge+"	mcCharge.x:"+this.mcCharge.x+"this.ragePer:"+this.ragePer+"	chargingUP: "+chargingUp);
				
				if (this.charge <= 33){
					this.G1.visible = false;
					this.G2.visible = false;
					this.G3.visible = false;
					
				}else if (this.charge <= 66){
					this.G1.visible = true;
					this.G2.visible = false;
					this.G3.visible = false;
					
				}else if (this.charge < 100){
					this.G1.visible = true;
					this.G2.visible = true;
					this.G3.visible = false;
				}else{
					this.G1.visible = true;
					this.G2.visible = true;
					this.G3.visible = true;
				}	
						
			}
					
		}
	
		public function stopCharging():int{
			var c:int = this.charge;
			//trace("STOP CHARGING ********************");
			this.removeEventListener(Event.ENTER_FRAME, onEnterFrame);	
			
			this.charge = 0;
			this.mcCharge.x = -100;
			this.charging = false;
			this.G1.visible = false;
			this.G2.visible = false;
			this.G3.visible = false;	
			
			if (usePowerMeter) return c;
			
			if (c<= 33){
				return 0;
				
			}else if (c <= 66){
				return 1;
				
			}else if (c < 100){
				return 2
			}else{
				return 3;
			}		
			
		}
	}
}