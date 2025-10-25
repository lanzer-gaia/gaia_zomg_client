package com.gaiaonline.battle.map
{
	import com.gaiaonline.flexModulesAPIs.globalevent.GlobalEvent;
	
	import flash.geom.Point;
	import flash.utils.getTimer;
	
	public class Environment
	{	
		private var map:Map;	
		public var offset:Point = new Point(0,0);
				
		public function Environment(map:Map){
			this.map = map;	
			GlobalEvent.eventDispatcher.addEventListener(GlobalEvent.GENERIC_WORLD_EVENT, onWorldEvent, false, 0, true);				
		}
		
		static private function fireSoundEvent(evt:String, params:Object):void
		{
			GlobalEvent.eventDispatcher.dispatchEvent(new GlobalEvent(evt, params));
		}	
		private function stopTrainTrack():void{
			
			var obj:Object = new Object();
			obj.trainStop = true;					
			this.map.setBackParam(obj);
			
			fireSoundEvent(GlobalEvent.MAP_SOUND_SETAUTOPLAY, {id:"Horn", autoPlay:false});
			fireSoundEvent(GlobalEvent.MAP_SOUND_STOP, "Horn");		
			
			fireSoundEvent(GlobalEvent.MAP_SOUND_SETAUTOPLAY, {id:"Bump", autoPlay:false});
			fireSoundEvent(GlobalEvent.MAP_SOUND_STOP, "Bump");		
			
			fireSoundEvent(GlobalEvent.MAP_SOUND_SETAUTOPLAY, {id:"TrackMain", autoPlay:false});
			fireSoundEvent(GlobalEvent.MAP_SOUND_STOP, "TrackMain");			
			
			fireSoundEvent(GlobalEvent.MAP_SOUND_SETAUTOPLAY, {id:"Tween2", autoPlay:false});
			fireSoundEvent(GlobalEvent.MAP_SOUND_STOP, "Tween2");			
			
			fireSoundEvent(GlobalEvent.MAP_SOUND_SETAUTOPLAY, {id:"Tween3", autoPlay:false});
			fireSoundEvent(GlobalEvent.MAP_SOUND_STOP, "Tween3");			
			
			fireSoundEvent(GlobalEvent.MAP_SOUND_SETAUTOPLAY, {id:"Tween4", autoPlay:false});
			fireSoundEvent(GlobalEvent.MAP_SOUND_STOP, "Tween4");			
			
			fireSoundEvent(GlobalEvent.MAP_SOUND_SETAUTOPLAY, {id:"Tween4", autoPlay:false});
			fireSoundEvent(GlobalEvent.MAP_SOUND_PLAY, "Screech");	
		}		
		private function onTrainTrak(obj:Object):void{
			
			var dt:int = getTimer() - obj.lastPlay;			
			
			if (!obj.play && dt > obj.speed){
				obj.play = true;
				obj.lastPlay = getTimer();
				obj.frame = 0;			
			}
			
			if (obj.play){				
				
				this.offset.x = 0;
				
				if (obj.frame <= 1){
					this.offset.y = -(obj.frame * 3);
					obj.frame += 1;
				}else{
					this.offset.x = 0;
					this.offset.y = 0;
					obj.frame = 0;
					obj.play = false;
				}	
				this.updateMapPos();		
			}					
		}
		
		private function updateMapPos():void {
			fireSoundEvent(GlobalEvent.ENVIRONMENT_OFFSET_CHANGED, {offset:offset.clone()});
		}
		
		//-- WorldEvent
		private function onWorldEvent(evt:GlobalEvent):void{
			var obj:Object = evt.data;
			switch(obj.bmt){
				case "sound":
					fireSoundEvent(GlobalEvent.MAP_SOUND_PLAY, obj.parameters.soundID);
					break;
				case "stopSound":
					fireSoundEvent(GlobalEvent.MAP_SOUND_STOP, obj.parameters.soundID);
					break;
				case "train":
					if (obj.parameters.action == "stop"){
						this.stopTrainTrack();
					}
					break;
				
				default:
					//trace("unknown worldevent:"+obj.bmt, 4);
					//new WorldEvent( area, postmaster, kTrainEventType, Collections.singletonMap(kWorldEventActionKey, (Object)"stop") );
					this.map.setBackParam(obj);
					break;
										
					wordEvent("MyEvent", {wave:true, speed:3});
			}				
		}
		
	}
}