package com.gaiaonline.battle.map.envobjects
{
	import flash.display.MovieClip;
	import flash.display.SimpleButton;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import com.gaiaonline.battle.ui.events.UiEvents;
	import flash.geom.ColorTransform;
	
	public class BasicLight extends MovieClip
	{
		
		private var state:int = 0;	
		public var isUsable = false;
		public var isCustomLight:Boolean = true;
			
		public function BasicLight(){						
		}
		
		public function updateState(obj:Object, transition:Boolean = false):void{
			if (obj.state != null){
				this.state = obj.state;
				
				var e:UiEvents = new UiEvents("LightChange", null);	
				if (this.state == 0){	
					e.value = false;
				}else{
					e.value = true;
				}		
				this.dispatchEvent(e);		
			}	
						
		}				
		
	}
}