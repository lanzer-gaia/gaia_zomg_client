package com.gaiaonline.assets
{
	import flash.display.MovieClip;
	import flash.text.TextField;
	
	public class IconSet extends MovieClip
	{
		public function IconSet(frm_label:String="",w:Number=0,h:Number=0){
			this.gotoAndStop(frm_label);							 
			if (w != 0) this.x = w/2;
			if (h != 0) this.y = h/2;
		}			
	}
}