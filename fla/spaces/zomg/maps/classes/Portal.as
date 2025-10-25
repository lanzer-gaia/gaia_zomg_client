package classes
{
	import flash.display.MovieClip;

	public dynamic class Portal extends MovieClip
	{
		
		//[Inspectable(name = "Type", defaultValue = "target")]
		public var type:String = "portal";
		
		[Inspectable(name = "Target Name")]
		public var target:String = "";
		
		[Inspectable(name = "Target Room")]
		public var targetRoom:String = "";
		
		public function Portal(){
			
		}
	}
}