package com.gaiaonline.battle
{
	import com.gaiaonline.flexModulesAPIs.globalevent.GlobalEvent;
	import com.gaiaonline.platform.gateway.IGSTConnector;
	import com.gaiaonline.platform.gateway.IResponseHandler;
	import com.gaiaonline.utils.FrameTimer;
	
	import flash.events.EventDispatcher;
	import flash.utils.getTimer;
	
	public class GST extends EventDispatcher implements IResponseHandler
	{
		
		private const gstSpeed:Number = 10.28;		
		private const lightOnTime:Number = 1235; // 20:35
		private const lightOffTime:Number = 205; // 3:25

		
		private var t:int = 0;
		private var startTime:Date = new Date();
		private var tints:Array;		


		private var tintName:String = "na";	
		public var lightsOn:Boolean = false;
		
		private var _gateway:IGSTConnector = null;
			
		public function GST(gateway:IGSTConnector)
		{
			this._gateway = gateway;
			
			// build tint array;
			
			// Midnight 23:10(1390) -> 0:50(50) --> 9.8 min

              // Mid1 23:10(1390) -> 24:00(1440) -->   4.9 min
              // Mid2 00:00(0) -> 0:50(50)	-->	4.9 min
              var Mid1:Object = {name:"Midnight", st:1390, et:1440, r:60, g:65, b:107};
              var Mid2:Object = {name:"Midnight", st:0, et:50, r:60, g:65, b:107};             

              //Pre-dawn 0:50(50) -> 3:25(205) -->  15 min
              var Pre_dawn:Object = {name:"Pre-dawn", st:50, et:205, r:122, g:102, b:112};                

              //Dawn 3:25(205) -> 5:05(305) -->	9.7 min
              var Dawn:Object = {name:"Dawn", st:205, et:305, r:204, g:181, b:187};                

              //Morning = 5:05(305) -> 12:00(720) --> 40.3 min
              var Morning:Object = {name:"Morning", st:305, et:720, r:226, g:216, b:218};                

              //Afternoon = 12:00(720) -> 17:10(1030) --> 30.1 Min 
              var Afternoon:Object = {name:"Afternoon", st:720, et:1030, r:255, g:255, b:255};  

              //Mid Afternoon = 17:10(1030) -> 19:25(1166)  --> 13.2 Min
              var MidAfternoon:Object = {name:"MidAfternoon", st:1030, et:1166, r:237, g:222, b:206};                

              //Dusk = 19:25(1166) -> 20:45(1245)  --> 7.8 Min
              var Dusk:Object = {name:"Dusk", st:1166, et:1245, r:183, g:145, b:123};                

              //Evening = 20:45(1245) -> 23:10(1390)  --> 14.1
              var Evening:Object = {name:"Evening", st:1245, et:1390, r:111, g:106, b:121};

			this.tints = [Mid1, Mid2, Pre_dawn, Dawn, Morning, Afternoon, MidAfternoon, Dusk, Evening];
			
			GlobalEvent.eventDispatcher.addEventListener(GlobalEvent.GST_SET, onGstChange);
		}
		
		public function get time():Date{
			var dt:int = getTimer() - t;
			var nd:Date =  new Date(this.startTime.time + (dt * this.gstSpeed));			
			return nd;
		}
		
		private function onGstChange(evt:GlobalEvent):void
		{
			time = evt.data as Date;
		}

		private var _frameTimer:FrameTimer = new FrameTimer(onTimer);		
		public function set time(value:Date):void{
			if(null==value) { return; }
			
			this.startTime = value;
			this.t = getTimer();

			this._frameTimer.start(5000);
			
			this.updateTint(true);						
		}
		
		private function onTimer():void{
			this.updateTint();		
		}
		
		private var nd:Date = new Date(); // moved this here to prevent our constant creation of Date objects
		private function updateTint(update:Boolean = true):void{
			var dt:int = getTimer() - t;
			nd.setTime(this.startTime.time + (dt * this.gstSpeed));
			var tt:int = ( (nd.hours*60) + nd.minutes);
			
			var tint:Object = this.getTintAt(tt);
			if (tint != null && this.tintName != tint.name){
				this.tintName = tint.name;
				GlobalEvent.eventDispatcher.dispatchEvent(new GlobalEvent(GlobalEvent.MAP_GST_TINT_UPDATE, {r:tint.r, g:tint.g, b:tint.b, update:update}));
			}
			
			
			//-- Light
			var l:Boolean = false;
			if (tt >= this.lightOnTime || tt <= this.lightOffTime){
				l = true;
			}else{
				l = false;
			}	
			
			if (l != this.lightsOn ){
				this.lightsOn = l;			
				GlobalEvent.eventDispatcher.dispatchEvent(new GlobalEvent(GlobalEvent.MAP_SET_LIGHTS, {on:this.lightsOn}));
			}
			
			GlobalEvent.eventDispatcher.dispatchEvent(new GlobalEvent(GlobalEvent.GST_UPDATE, {gst:nd}));
			//trace("GST UPDATE TINT ", nd.toLocaleString(), tt, this.tintName, this.lightsOn)
			
		}
		
		public function getTintAt(t:int):Object{
			var obj:Object;
			for (var i:int = 0; i<this.tints.length; i++){
				if (t >= this.tints[i].st && t < this.tints[i].et){
					obj = this.tints[i];
					break;
				}
			}
			
			return obj;
		}
		
		public function getCurrentTint():Object{
			
			var obj:Object;
			for (var i:int = 0; i<this.tints.length; i++){
				if (this.tints[i].name == this.tintName){
					obj = this.tints[i];
					break;
				}
			}
			
			return obj;
		}
		
		public function loadGst():void{
			_gateway.getGSTTime(this);
		}
		
		public function onResponse(data:Object):void{
			
			var gstData:Object = data[0];
			
			var d:Date = new Date();
			var h:int = gstData.hour;
			var m:int = gstData.min;
			var nd:Date = new Date(d.fullYear, d.month, d.date, h, m);
			this.time = nd;	

			GlobalEvent.eventDispatcher.dispatchEvent(new GlobalEvent(GlobalEvent.GST_LOADED, {}));
			
		}
		
	}
}