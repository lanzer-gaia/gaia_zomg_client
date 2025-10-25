package com.gaiaonline.battle.gateway
{
	import flash.events.Event;

	public class GWEvent extends Event
	{
		public static const LOGIN:String = "Login";
		public static const LOGIN_FAIL:String = "Login_fail";
		public static const CONNECTION_LOST:String = "Connection_lost";
		public static const CALL_BACK:String = "Call_Back";
		public static const ACTOR_UPDATE:String = "Actor_Update";
		public static const RELOCATE:String = "Relocate";
		public static const ACTOR_ACTION:String = "Actor_Actrion";
		public static const LOOT:String = "Loot";
		public static const CHAT:String = "Chat";
		public static const ACTOR_LEAVE:String = "Actor_Leave";
		public static const DIALOG:String = "Dialog";
		public static const ALL_OUTGOING:String = "All_Outgoing";
		public static const ALL_INCOMMING:String = "All_Incomming";
		
		public static const TEAM_UPDATE:String = "Team_Update";
		public static const TEAM_INVITE:String = "Team_Invite";
		public static const TEAM_INVITE_REJECTED:String = "Team_Invite_Rejected";
		public static const TEAM_MEMBER_GONE:String = "Team_Member_Gone";
	
		private var myResult:GWMessage;
		
		
		public function GWEvent(type:String, msg:GWMessage = null)
		{
			super(type, false, false);
			this.myResult = msg;
		}
		
		
		//getter setter
		public function get gwMessage():GWMessage
		{
			if (this.myResult == null)
			{
				//trace("[GW] no GWMessage to return, make a null one.");
				return new GWMessage("null", null);
			}
			return this.myResult;
		}
	}
}