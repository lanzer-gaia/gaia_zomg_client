package com.gaiaonline.battle.sounds
{
	import com.gaiaonline.objectPool.ObjectPool;
	
	public interface ISoundPoolManager
	{
		function getSoundPool(id:String):ObjectPool;
	}
}