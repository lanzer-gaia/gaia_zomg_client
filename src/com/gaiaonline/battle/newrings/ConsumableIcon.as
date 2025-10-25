package com.gaiaonline.battle.newrings
{
	import flash.display.Bitmap;

	public class ConsumableIcon extends ItemIconBase
	{
		public function ConsumableIcon(img:Bitmap)
		{
			super(img);
		}

		public function get consumableId():String {
			return super.id;
		}
		
		public function set consumableId(id:String):void {
			super.id = id;
		}

	}
}