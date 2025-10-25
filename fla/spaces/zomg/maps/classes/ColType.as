package classes
{
	import flash.display.Sprite;
	
	public dynamic class ColType extends Sprite
	{
		[Inspectable(name = "Elevation")]
		public var elevation:Number = 0;
		
		[Inspectable(name = "Terrain", default="Imapasible")]
		public var terrain:String = "Impasible";
		
		public function ColType()
		{
			
		}

	}
}