package com.gaiaonline.battle.ItemLoadManager
{
	import com.gaiaonline.battle.ItemLoadManager.ItemIcon;
	
	public class ConsumableItemIconCustomization implements IItemIconCustomization
	{
		private static var _instance:ConsumableItemIconCustomization = null;
				
		public function ConsumableItemIconCustomization(singletonEnforcer:SingletonEnforcer) {
			if (singletonEnforcer == null) {
				throw new Error("ConsumableItemIconCustomization is a singleton!");
			}			
		}

		public static function getInstance():IItemIconCustomization {
			if (!_instance) {
				_instance = new ConsumableItemIconCustomization(new SingletonEnforcer());
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