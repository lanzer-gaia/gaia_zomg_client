package com.gaiaonline.battle.newcollectibles
{
	import com.gaiaonline.battle.ApplicationInterfaces.ILinkManager;
	import com.gaiaonline.battle.ApplicationInterfaces.IUIFramework;
	
	// This class really only exists because we need a way to store our loaded Collectibles (with their icons) independently of the existence
	// of the collectibles info tab in the UI.  That UI logic actualy has a CollectiblesManager, and perhaps the logic for these two classes should
	// be combined, but there's something nice about keeping the information about whether we've loaded the info related to a collectible (most importantly,
	// it's icon's png) separate from the logic of iinserting it into the UI (which the CollectiblesManager currently handles).
	
	public class CollectiblesLoadManager
	{
		public static var collectibles:Object = new Object();
		
		private static var _linkManager:ILinkManager = null;
		
		public function CollectiblesLoadManager() {
		}
		
		public static function contain(id:String):Boolean{
			return (collectibles[id] != null);
		}		

		public static function loadCollectible(uiFramework:IUIFramework, linkManager:ILinkManager, obj:Object):Collectible {
			CollectiblesLoadManager._linkManager = linkManager;
			var id:String = obj.id;
			if (collectibles[id] == null){
				collectibles[id] = new Collectible(obj.id, obj.name, obj.icon, CollectiblesLoadManager._linkManager.getLink("images"));
				if (obj.collectiblePosition != null) {
					Collectible(collectibles[id]).position = obj.collectiblePosition;
				}
			}

			var cl:CollectibleLoader = new CollectibleLoader();
			cl.load(uiFramework.loaderContextFactory, CollectiblesLoadManager._linkManager, collectibles[id]);						
								
			return collectibles[id];
		}
	}
}