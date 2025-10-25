package classes
{
	import flash.display.MovieClip;
	
	public dynamic class MapSound extends MovieClip	
	{
			
		//[Inspectable(name = "Type", defaultValue = "target")]
		public var type:String = "MapSound";
		
		[Inspectable(name = "1- Sound Ids (id,volume, st, et)")]
		public var soundIds:Array = new Array();
		
		[Inspectable(name = "2- Fall Off", defaultValue = true)]
		public var fallOff:Boolean = true;
						
		[Inspectable(name = "3- Min Radius", defaultValue = 100)]
		public var minRadius:int = 100;
		
		[Inspectable(name = "4- Max Radius", defaultValue = 200)]
		public var maxRadius:int = 200;
		
		[Inspectable(name = "5- 3d Sound On", defaultValue = true)]
		public var is3d:Boolean = true;
		
		[Inspectable(name = "6- Min interval", defaultValue = 0)]
		public var minInterval:int = 0;
		
		[Inspectable(name = "7- Max interval", defaultValue = 0)]
		public var maxInterval:int = 0;
						
		[Inspectable(name = "8- Repeat", defaultValue = 0)]
		public var repeat:int = 0;
		
		[Inspectable(name = "9- Room Only", defaultValue = false)]
		public var roomOnly:Boolean = false;
		
		[Inspectable(name = "10- AutoPlay", defaultValue = true)]
		public var autoPlay:Boolean = true;
		
		public function MapSound(){
			
		}			
	}
}