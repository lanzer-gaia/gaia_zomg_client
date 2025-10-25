package classes
{
	import fl.motion.Color;
	
	import flash.display.Sprite;

	public dynamic class RoomInfo extends Sprite
	{
		//[Inspectable(name = "Type", defaultValue = "roominfo")]
		public var type:String = "roominfo";
		
		[Inspectable(name = "Room Id")]
		public var room_name:String;
				
		[Inspectable(name = "Scale", defaultValue = 75)]
		public var room_scale:int = 75;		
		
		[Inspectable(name = "Room Tint Alpha", defaultValue = 0)]
		public var roomTintAlpha:int = 0;
		
		[Inspectable(name = "RoomTint", defaultValue = "FFFFFF", type = "Color")]
		public var roomTint:int = 0;
		
		[Inspectable(name = "TintBackground", defaultValue = true)]
		public var tintBackground:Boolean = true;
				
		[Inspectable(name = "Resolution", defaultValue = 8)]
		public var map_resolution:int = 8;
		
		// exits -----------------------
		[Inspectable(name = "exit north", defaultValue = true)]
		public var north:Boolean = true;		
		
		[Inspectable(name = "exit east", defaultValue = true)]
		public var east:Boolean = true;
		
		[Inspectable(name = "exit south", defaultValue = true)]
		public var south:Boolean = true;
		
		[Inspectable(name = "exit west", defaultValue = true)]
		public var west:Boolean = true;
		
		[Inspectable(name = "Dummy Room", defaultValue = false)]
		public var dummyRoom:Boolean = false;
		
		[Inspectable(name = "Zone", defaultValue = 0)]
		public var zoneId:int = 0;
				
		public var exit_north:String ="";
		public var exit_east:String ="";
		public var exit_south:String ="";
		public var exit_west:String ="";
		
		
		public function RoomInfo(){	
		}
		
		
	}
}