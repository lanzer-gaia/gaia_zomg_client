package com.gaiaonline.battle.map
{
	import com.gaiaonline.battle.userServerSettings.IGraphicOptionsSettings;
	import com.gaiaonline.flexModulesAPIs.globalevent.GlobalEvent;
	import com.gaiaonline.platform.actors.ISilhouetteable;
	import com.gaiaonline.utils.FrameTimer;
	import com.gaiaonline.utils.RegisterUtils;
	
	public class SilhouetteManager implements IEnvironmentChanger
	{
		private var _mapRoomManager:IMapRoomManager = null;
		private var _silhouetteTimer:FrameTimer = new FrameTimer(onSilhouetteTimer);
		
		public function SilhouetteManager(mapRoomManager:IMapRoomManager){
			_mapRoomManager = mapRoomManager;
			GlobalEvent.eventDispatcher.addEventListener(GlobalEvent.USER_SETTINGS_LOADED, onGraphicsOptionChanged, false, 0, true);
			GlobalEvent.eventDispatcher.addEventListener(GlobalEvent.GRAPHIC_OPTIONS_CHANGED, onGraphicsOptionChanged, false, 0, true);
//			_silhouetteTimer.startPerFrame(2);
			_silhouetteTimer.start(1000);
		}

		private var _environmentChangeHandlers:Array = [];
		public function registerForEnvironmentChanges(handler:IEnvironmentChangeHandler):void{
			RegisterUtils.register(_environmentChangeHandlers, handler);
		}
		
		public function updateObject(invalidObj:Object):void{
			if(_silhouetteEnabled){
				var silhouettable:ISilhouetteable = invalidObj as ISilhouetteable;
				if(silhouettable){
					var currentRoom:MapRoom = _mapRoomManager.getCurrentMapRoom(); 	
					if(currentRoom){
						currentRoom.runObjectSilhouette(silhouettable);
					}
				}
			}
		}
		
		private var _silhouetteEnabled:Boolean = true;
		
		private function onGraphicsOptionChanged(event:GlobalEvent):void{
			var data:IGraphicOptionsSettings = event.data as IGraphicOptionsSettings;
			if (data){
				_silhouetteEnabled = data.getSilhouettingEnabled();
			}
			
			if(_silhouetteEnabled){
				//if we turn on silhouetting we invalidate everything on the stage to check to see if it's eligible for silhouetting
				for each(var enviroChangeHandler:IEnvironmentChangeHandler in _environmentChangeHandlers){
					enviroChangeHandler.onEnvironmentChange(this);
				}
			}
			else{
				//if we turn off silhouetting we loop through everything and remove the silhouettes.
				_mapRoomManager.getCurrentMapRoom().removeAllObjectSilhouettes();
			}
			
		}
		
		private function onSilhouetteTimer():void{
			var currentRoom:MapRoom = _mapRoomManager.getCurrentMapRoom(); 	
			if(currentRoom){
				currentRoom.checkInvalidSilhouettables();
			}
		}
		
	}
}