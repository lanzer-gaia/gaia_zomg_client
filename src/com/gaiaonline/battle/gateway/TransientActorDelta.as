package com.gaiaonline.battle.gateway
{
	public class TransientActorDelta
	{
		public var statName:String;
		public var statChange:Number;
		public var modifier:String;
		
		public function TransientActorDelta( o:Object )
		{
			//debug("new TransientActorDelta( "+o+" )");
			
			if ( TransientActor.oldSchool )
			{
				handleOldSchoolData( o );
			}
			else
			{
				handleNewStyleResponse( o );
			}
		}

		private function handleNewStyleResponse( o:Object ): void
		{
			//debug("handleNewStyleResponse()  ... "+ o.stat + ": " + o.value );
			this.statName = o.stat;
			this.statChange = o.value;
			this.modifier = o.modifier;
		}
		
		private function handleOldSchoolData( o:Object ): void
		{
			//debug("handleOldSchoolData()");
			var aFields:Array = new Array();
			aFields = o.split(";");
			this.statName = aFields[0];
			this.statChange = parseInt( aFields[1] );
			try
			{
				this.modifier =  aFields[2];
			}
			catch (e:Error)
			{
				// no label
			}
		}
		
		
		
		private function debug( s:String ):void
		{
			trace("[TA_DELTA] " + s );
		}
	}
}