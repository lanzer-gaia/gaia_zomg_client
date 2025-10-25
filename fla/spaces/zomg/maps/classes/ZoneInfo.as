package classes
{
	import flash.display.Sprite;

	public dynamic class ZoneInfo extends Sprite
	{
		
		//[Inspectable(name = "Type", defaultValue = "roominfo")]
		public var type:String = "zoneinfo";
		
		[Inspectable(name = "Zone Id", defaultValue = 0)]
		public var zoneId:Number = 0;
		
		[Inspectable(name = "Musics")]
		public var musics:Array = new Array();
		
		[Inspectable(name = "Combat Musics")]
		public var combatMusic:Array = new Array();
		
		[Inspectable(name = "Music Repeat", defaultValue = 3)]
		public var musicRepeat:Number = 3;
		
		public function ZoneInfo(){	
			
		}		
		
	}
}