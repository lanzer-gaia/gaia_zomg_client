package com.gaiaonline.battle.map
{
	public class NullMapEffect extends MapEffectBase implements IMapEffect
	{
		public function NullMapEffect(){}

		public function out(x:Number, y:Number):void{
			runWarpOutComplete()
		}
		
		public function int(x:Number, y:Number):void{
			runWarpInComplete();
		}
		
	}
}