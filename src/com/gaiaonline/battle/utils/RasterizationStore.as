package com.gaiaonline.battle.utils
{
	import com.gaiaonline.battle.map.envobjects.BasicSwitch;  // hack - see below
	
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.utils.Dictionary;

	//
	// [kja] RasterizationStore is simply a hash of type to a rasterization (BitmapData) of that type.
	// It will fail to rasterize anything that doesn't have a unique type (i.e. Sprite), and will fail
	// to rasterize anything with an animation.  Bad hack - it also checks for a Zomg-specific
	// "BasicSwitch" type - it should instead have a .disqualifyType() method
	public class RasterizationStore
	{
		private static const DISQUALIFIED_FROM_RASTERIZATION:Object = {};
		private var _types:Dictionary = new Dictionary(true);
		private var _typeCount:int = 0;

		public function RasterizationStore() 
		{
			_types[MovieClip] = DISQUALIFIED_FROM_RASTERIZATION;
			_types[Sprite] = DISQUALIFIED_FROM_RASTERIZATION;
			_types[Shape] = DISQUALIFIED_FROM_RASTERIZATION;
		}

		public function canRasterize(mc:DisplayObjectContainer):Boolean
		{
			//
			// Check our past rasterizations for this type to see if we've succeeded.
			const type:Class = mc["constructor"];
			if (_types[type]) {
				return _types[type] != DISQUALIFIED_FROM_RASTERIZATION;
			}
			if (detectAnimation(mc) || (mc is BasicSwitch)) {
				tr("DISQUALIFIED_FROM_RASTERIZATION type " + type);
				_types[type] = DISQUALIFIED_FROM_RASTERIZATION;
				return false;
			}
			return true;
		}

		//
		// This assumes that mc has a unique type (i.e. green_flower_105, etc), and that all objects of this type
		// are equal citizens in terms of their object heiarchy.  If mc is of a type that changes after construction
		// such that instances of that type differ, you won't get the results you want.  This approach happens to
		// work well for symbols in our maps with repeated instances (trees, rocks, etc). 
		public function rasterize(mc:DisplayObjectContainer):Rasterization
		{
			const type:Class = mc["constructor"];

			if (canRasterize(mc)) {
				var rast:Rasterization = _types[type];
				if (!rast)
				{
					rast = new Rasterization(mc);
					_types[type] = rast;

					++_typeCount;
					tr("new type " + type + ", typeCount: " + _typeCount);
				}
				return rast;
			}
			return null;
		}

		private static function detectAnimation(obj:DisplayObject):Boolean
		{
			//
			// Recursively search for animation frames
			var mc:MovieClip = obj as MovieClip;
			if (mc && mc.totalFrames > 1)
			{
				return true;
			}
			
			var container:DisplayObjectContainer = obj as DisplayObjectContainer;
			if (container && container.numChildren)
			{
				for (var i:int = 0; i < container.numChildren; ++i)
				{
					if (detectAnimation(container.getChildAt(i)))
					{
						return true;
					}
				}
			}
			return false;
		}
		
		private static function tr(str:String):void
		{
//			trace("Rasterization: " + str);
		}
	}
}