package com.gaiaonline.battle.gateway
{
	public class TransientActorStatus
	{
		public var statusName:String;
		public var val:Number;
		

		public function TransientActorStatus( o:Object )
		{
			//debug("new TransientActorStatus( "+o+" )");
			
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
			//debug("handleNewStyleResponse()");
			this.statusName = o.name;
			this.val = o.value;
		}
		
		private function handleOldSchoolData( o:Object ): void
		{
			//debug("handleOldSchoolData()");
			var aFields:Array = new Array();
			aFields = o.split(";");
			this.statusName = aFields[0];
			this.val = aFields[1];
		}
		
		
		
		private function debug( s:String ):void
		{
			trace("[TA_STATUS] " + s );
		}
	}
}