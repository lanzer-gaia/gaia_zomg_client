package com.gaiaonline.battle.ItemLoadManager
{
	public class GameItemIconCustomization implements IItemIconCustomization
	{
		private static var _instance:GameItemIconCustomization = null;
				
		public function GameItemIconCustomization(singletonEnforcer:SingletonEnforcer){
			if (singletonEnforcer == null) {
				throw new Error("GameItemIconCustomization is a singleton!");
			}			
		}

		public static function getInstance():IItemIconCustomization {
			if (!_instance) {
				_instance = new GameItemIconCustomization(new SingletonEnforcer());
			}
			
			return _instance;
		}	

		public function getLockedSlotTooltipText():String {
			return null;
		}
		
		public function getDefaultTooltip(itemIcon:ItemIcon):String {
			return itemIcon.itemLoader.itemName;
		}
				
		public function getItemUpdateEventType():String {
			return null;
		}				
	}
}

class SingletonEnforcer {
	
}