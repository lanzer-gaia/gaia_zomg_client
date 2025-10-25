package com.gaiaonline.assets
{
	import flash.display.MovieClip;
	import flash.text.TextField;
	
	public class BackgroundBox extends MovieClip
	{
		public function BackgroundBox(w:Number=26,h:Number=26,frame:Number=1){
			this.gotoAndStop(frame);							 
			this.width = w;
			this.height = h;
		}
			
	}
}