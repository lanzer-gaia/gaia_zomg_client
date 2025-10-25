package com.gaiaonline.battle.utils
{
	import flash.display.Bitmap;	
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.geom.Matrix;
	import flash.geom.Rectangle;

	// [kja]
	//
	// Rasterization is really just a convertor from a DisplayObject to a BitmapData.  It's meant to be constructed
	// and then called with .createBitmap to get individual Bitmap instances back.  It knows nothing about RasterizationStore,
	// and doesn't require one, although the store is built to construct, hold, and lookup Rasterization instances.  
	public class Rasterization
	{
		private var _bmd:BitmapData = null;
		private var _left:Number = 0;
		private var _top:Number = 0;
		
		private static const S_SCALE:Number = .50;
		
		private static var _useScaling:Boolean = false;
		
		private var _stats:Object = 
		{
			name: "",
			count: 0
		}
		public function Rasterization(obj:DisplayObject)
		{
			var bound:Rectangle = obj.getBounds(obj);
			_left = bound.left;
			_top = bound.top;
			var scaler:Number = _useScaling ? S_SCALE : 1;
			_bmd = new BitmapData(Math.max(obj.width*scaler,1), Math.max(obj.height*scaler,1), true, 0x00000000);

			var mat:Matrix = new Matrix(1,0,0,1,-_left,-_top);
			if (_useScaling) {
				mat.scale(S_SCALE, S_SCALE);
			}			
			_bmd.draw(obj, mat);

			_stats.name = String(obj);
		}
		public function createBitmap():Bitmap
		{
			var bmp:Bitmap = new Bitmap(_bmd);

			if (_useScaling) { 			
	 			var mat:Matrix = new Matrix(1,0,0,1);
				mat.scale(1/S_SCALE, 1/S_SCALE);
	 			bmp.transform.matrix = mat;
	 			bmp.smoothing = true;
			}
			bmp.x = _left;
			bmp.y = _top;
			
			addRef();
			return bmp;
		}
		private function addRef():void
		{
			// this is just for stats purposes right now;  in the future we could use this
			// as a refcount for limiting the number of Rasterizations via pooling, etc... 
			++_stats.count;
			
			tr("new instance of " + _stats.name + ", instances: " + _stats.count);  
		}
		public function get bitmapData():BitmapData
		{
			return _bmd;
		}
		public function get left():int
		{
			return _left;
		}
		public function get top():int
		{
			return _top;
		}
		
		private static function tr(str:String):void
		{
//			trace("Rasterization: " + str);
		}
	}
}