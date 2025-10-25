package com.gaiaonline.battle.newactors
{
	import flash.display.MovieClip;
	
	public class GoldLootDisplay extends MovieClip
	{
		private var _count:int = 0;

		public var txtGold:MovieClip;
		
		public function GoldLootDisplay()
		{
			super();
			this.stop();
		}
		
		public function updateCount(v:int = 0):void {	
			if (this.currentFrame == 1){
				this._count = v;		
				this.gotoAndPlay(2);
			}else{
				this._count += v;
				if (this.currentFrame >= 12){
					this.gotoAndPlay("reset");	
				}			
			}
			
			this.txtGold.txt.text = this._count.toString();			
		}
		
	}
}