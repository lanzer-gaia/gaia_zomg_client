package com.gaiaonline.battle.newrings
{
	import com.gaiaonline.battle.ui.ToolTipOld;
	
	import flash.display.Bitmap;
	import flash.display.MovieClip;
	
	public class ItemIconBase extends MovieClip
	{
		public var position:int = -1;
		public var type:int = -1;
		private var _id:String = "";
		private var _bitmap:Bitmap = null;
				
		public function ItemIconBase(img:Bitmap){
			this._bitmap = img;
			loadBitmap();			
		}
	
		protected function loadBitmap():void {
			if (this.bitmap != null){
				this.graphics.beginBitmapFill(this._bitmap.bitmapData, null, false);
				this.graphics.drawRect(0,0,this._bitmap.width, this._bitmap.height);
				this.graphics.endFill();		
			}						
		}	
		
		protected function get bitmap():Bitmap {
			return this._bitmap;			
		}
		
		public function get id():String {
			return _id;
		}
		
		public function set id(id:String):void {
			_id = id;
		}		
	}
}