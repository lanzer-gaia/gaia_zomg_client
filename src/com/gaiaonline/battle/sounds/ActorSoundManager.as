package com.gaiaonline.battle.sounds
{
	import com.gaiaonline.objectPool.ObjectPool;
	
	import flash.media.Sound;
	import flash.utils.Dictionary;
	
	public class ActorSoundManager
	{
		private static var _instance:ActorSoundManager
		
		private var _soundPoolManagers:Dictionary = new Dictionary(true); 
		
		public function ActorSoundManager(se:SingletonEnforcer)
		{
			if(_instance || !se){
                throw new Error("ActorSoundManager is a singleton.  Use getInstance.");
            }   
		}
		
		
		public function checkout(soundRef:Object, soundId:String):Sound{			
			if (this._soundPoolManagers[soundRef] == null){				
				this._soundPoolManagers[soundRef] = new SoundPoolManager(soundRef, 4);
			}
			var pool:ObjectPool = SoundPoolManager(this._soundPoolManagers[soundRef]).getSoundPool(soundId);
			var s:Sound = pool.checkOut() as Sound;
			return s;
		}
		
		public function checkin(soundRef:Object, soundId:String, sound:Sound):Boolean{			
			if (this._soundPoolManagers[soundRef] != null){
				var pool:ObjectPool = SoundPoolManager(this._soundPoolManagers[soundRef]).getSoundPool(soundId);
				var r:Boolean = pool.checkIn(sound);				
				return r;
			}else{
				return false;
			}
		}
		
		public function clearAll(soundRef:Object):void{
			//trace("Clear all " , soundRef, this._soundPoolManagers[soundRef]);
			if (this._soundPoolManagers[soundRef] != null){
				SoundPoolManager(this._soundPoolManagers[soundRef]).dispose();
				this._soundPoolManagers[soundRef] = null;
				delete this._soundPoolManagers[soundRef];				
			}
		}
		
		public static function getInstance():ActorSoundManager{
            if(!_instance){
                _instance = new ActorSoundManager(new SingletonEnforcer());
            }
            return _instance;
        }
	}    	    
}
internal class SingletonEnforcer{ 

}