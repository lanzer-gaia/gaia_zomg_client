package com.gaiaonline.battle.sounds
{
	
	
	import flash.display.Sprite;
	import flash.media.Sound;
	import flash.utils.getDefinitionByName;
	
	public class SoundFile extends Sprite
	{
		
		public function SoundFiles(){
			
		}
		
		
		public function getSound(soundId:String):Sound{				
			var s:Sound = null;
			try {
				var c:Class = Class(getDefinitionByName(soundId));
				s = new c() as Sound;
			} catch (e:ReferenceError){
				
			}
			
			return s;
		}
	}
}