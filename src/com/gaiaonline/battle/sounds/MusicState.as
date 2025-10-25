package com.gaiaonline.battle.sounds
{
	import com.gaiaonline.utils.Enumeration;

	public class MusicState extends Enumeration
	{
		private static var s_lookup:Object = {};

		public static const PLAYING:MusicState = new MusicState("playing");
		public static const PAUSED:MusicState = new MusicState("paused");
		public static const STOPPED:MusicState = new MusicState("stopped");

		public function MusicState(name:String)
		{
			super(name);
			
			s_lookup[name] = this;
		}
		
		public static function valueOf(enumName:String):MusicState
		{
			return MusicState(s_lookup[enumName]);
		}
	}
}