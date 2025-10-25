package com.gaiaonline.battle.gateway
{
	public class TransientActorAction
	{
		public var ringId: String;
		public var targetActorId: String;
		public var actionType: String;
		public var rageLevel: int;
		public var secondaryTargets: Object;
		
		public function TransientActorAction( o:Object )
		{
			//debug("new TransientActorAction( "+o+" )");
			
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
			debug("handleNewStyleResponse()");
			this.ringId = o.rid;
			this.targetActorId = o.tid;
			this.actionType = o.tp;
			this.rageLevel = parseInt( o.rl );
			if ( o.std )
			{
				this.secondaryTargets = o.std;
			}
		}
		
		private function handleOldSchoolData( o:Object ): void
		{
			debug("handleOldSchoolData() ... BROKEN");
		}
		
		private function debug( s:String ):void
		{
			trace("[TA_ACTION] " + s );
		}
	}
}