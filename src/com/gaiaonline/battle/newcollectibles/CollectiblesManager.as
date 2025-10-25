package com.gaiaonline.battle.newcollectibles
{
	import com.gaiaonline.battle.newrings.ItemIconBase;
	import com.gaiaonline.battle.ui.UiCollectiblesHolder;	
	
	public class CollectiblesManager
	{
		private var _collectiblesHolder:UiCollectiblesHolder = null; // class corresponding to the UI
		private var _itemHash:Object = new Object(); // keeps track of which items we've already added, so we don't duplicate

		public function CollectiblesManager(collectiblesHolder:UiCollectiblesHolder) {
			_collectiblesHolder = collectiblesHolder;			
		}
		
		public function dispose():void {			
			_itemHash = null;
			_collectiblesHolder = null;	
		}
		
		public function refresh(collectibles:Object):void {
			for each (var collectible:Collectible in collectibles) {
				// Since once you encouter a ring, you've collected it, we never wipe out previously collected rings;
				// so a refresh doesn't clear our previous collectibles--it just adds new ones
				if (!alreadyAdded(collectible.id) && collectible.bitmap) {					
					var icon:CollectibleIcon = new CollectibleIcon(collectible.bitmap);
					icon.id = collectible.id;
					icon.position = collectible.position;
					addIcon(icon, collectible.name);
				}				
			}	
		}
						
		private function addIcon(icon:ItemIconBase, tooltipText:String = null):void {
			// no dupes!
			if (alreadyAdded(icon.id)) {
				return;
			}
			
			// add the item
			var index:uint = getSlotNumForIcon(icon);
			addItemToSlot(icon, index, tooltipText);
			
			// remember that we added the item
			var id:String = icon.id;			
			_itemHash[id] = index;									
		}
		
		private function alreadyAdded(id:String):Boolean {
			return (_itemHash[id] != undefined);
		}
		
		private function getSlotNumForIcon(icon:ItemIconBase):uint {
			if (icon.position > -1) {
				return icon.position;	
			} else {
				// This is only here because the server is not currently sending down an index for the collectibles yet.  When it does
				// the first part of the conditional will always fire.
				var maxIndexUsed:uint = 0;
				for each (var index:String in _itemHash) {
					var i:int = parseInt(index);
					if (i > maxIndexUsed) {
						maxIndexUsed = i;
					}
				}
				return maxIndexUsed + 1;
			}
		}
		
		private function addItemToSlot(icon:ItemIconBase, index:uint, tooltipText:String = null):void {
			_collectiblesHolder.addItemToSlot(icon, index, tooltipText);
			icon.position = index;			
		}
	}
}
