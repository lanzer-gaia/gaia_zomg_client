package com.gaiaonline.battle.newghibuffs
{
	import com.gaiaonline.utils.factories.ILoaderContextFactory;
	
	// This class really only exists because we need a way to store our loaded ghi buffs (with their icons) independently of the existence
	// of the ghe buffs info tab in the UI.  That UI logic actualy has a GhiManager, and perhaps the logic for these two classes should
	// be combined, but there's something nice about keeping the information about whether we've loaded the info related to a ghi buff (most importantly,
	// its icon's png) separate from the logic of iinserting it into the UI (which the GhiManager currently handles).
	public class GhiBuffsLoadManager
	{
		public static var ghiBuffs:Array = new Array();
		
		public static function contain(id:String):Boolean{
			return getBuff(id) != null;
		}				

		public static function getBuff(id:String):GhiBuff {
			var retBuff:GhiBuff = null;
			for each (var buff:GhiBuff in ghiBuffs) {
				if (buff.id == id) {
					retBuff = buff;
					break;
				}
			}
			
			return retBuff;
		}

		public static function loadBuff(obj:Object):GhiBuff {
			var ghiBuff:GhiBuff = new GhiBuff(obj.rid, obj.ringName, obj.ringType, obj.ringExhaustion, obj.ringIcon, obj.ringDescription, obj.ringTargets, obj.ringStatDescriptionsList);
			ghiBuffs.push(ghiBuff);
			return ghiBuff;
		}
		
		public static function clearCache():void {
			ghiBuffs.length = 0;
		}
	}
}