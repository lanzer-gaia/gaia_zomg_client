package com.gaiaonline.battle.ItemLoadManager
{
	import com.gaiaonline.battle.GlobalTexts;
	import com.gaiaonline.battle.Loot.Orbs;
	import com.gaiaonline.battle.newactors.ActorManager;
	import com.gaiaonline.battle.ui.UiRingInventory;
	import com.gaiaonline.flexModulesAPIs.globalevent.GlobalEvent;

	public class RingItemIconCustomization implements IItemIconCustomization
	{
		private static var _instance:RingItemIconCustomization = null;

		public function RingItemIconCustomization(singletonEnforcer:SingletonEnforcer) {
			if (singletonEnforcer == null) {
				throw new Error("RingItemIconCustomization is a singleton!");
			}
		}

		public static function getInstance():IItemIconCustomization {
			if (!_instance) {
				_instance = new RingItemIconCustomization(new SingletonEnforcer());
			}
			
			return _instance;
		}	
		
		public function getLockedSlotTooltipText():String {
			return GlobalTexts.getLockedRingSlotText();			
		}

		public function getDefaultTooltip(itemIcon:ItemIcon):String {
			var itemLoader:IItemLoader = itemIcon.itemLoader;
			if (itemLoader != null && ActorManager.getInstance().myActor.rings[itemIcon.slot] != null) {
 				return itemIcon.itemLoader.itemName;
			} else {
				return null;
			}
		}
		
		public function getItemUpdateEventType():String {
			return GlobalEvent.RING_UPDATE_DONE;
		}
	}
}

class SingletonEnforcer {
	
}