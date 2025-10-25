package com.gaiaonline.battle.map.envobjects
{
	import com.gaiaonline.battle.ui.events.UiEvents;
	
	import flash.display.MovieClip;
	import flash.events.Event;
	
	public class BasicSwitch extends MovieClip
	{
		
		private var state:int = 0;	
		public var isUsable:Boolean = false;
		public var isCustomLight:Boolean = false;
		
		private var _btn:MovieClip;
		private var _mcStates:MovieClip;
		
		public function BasicSwitch(){			
			this._btn = this.getChildByName("btn") as MovieClip;
			this._mcStates = this.getChildByName("mcStates") as MovieClip;
			
			if (this._btn != null){				
				this.hitArea = this._btn;
				this._btn.alpha = 0;							
				this.mouseEnabled = true;
				this.mouseChildren = false;			
			}
			
			if (this._mcStates != null){						
				this._mcStates.gotoAndPlay("s"+String(this.state));			
			}
			this.lightOff();
		}		
				
		public function updateState(obj:Object, transition:Boolean = false):void{	
			//trace("Update switch ", this.name, obj.state)
			if (obj.state != null){	
				if (this._mcStates != null){
					var f:String = "s0";
					if (transition){
						f = "t"+ String(this.state) + "-" + String(obj.state);
					}else{
						f = "s"+String(obj.state);
					}
								
					if (this.containFrameLabel(this._mcStates, f)){										
						this._mcStates.gotoAndPlay(f);						
					}else{						
						this._mcStates.gotoAndPlay("s"+String(obj.state));
					}
				}
				if (this.isCustomLight){
					var e:UiEvents = new UiEvents("LightChange", null);					
					if (obj.state == 0){	
						e.value = false;
					}else{
						e.value = true;
					}		
					this.dispatchEvent(e);
				}				
			}			
			this.state = obj.state || 0;
		}
		
		private function containFrameLabel(mc:MovieClip, frameLabel:String):Boolean{
			var v:Boolean = false;
			for (var i:int = 0; i < mc.currentLabels.length; i++){				
				if (mc.currentLabels[i].name == frameLabel){
					v = true;
					break;
				}
			}
			return v;
		}
		
		public function lightOn():void{
			var e:UiEvents = new UiEvents("LightChange", null);	
			e.value = true;
			this.dispatchEvent(e);	
		}
		
		public function lightOff():void{
			var e:UiEvents = new UiEvents("LightChange", null);	
			e.value = false;
			this.dispatchEvent(e);	
		}
		
		public function btnHitTestPoint(x:int, y:int):Boolean{
			var r:Boolean = false;
			if (this._btn != null){
				r = this._btn.hitTestPoint(x, y, true); 
			}else{
				r = this.hitTestPoint(x, y, true);
			}
			return r;
		}
		
	}
}