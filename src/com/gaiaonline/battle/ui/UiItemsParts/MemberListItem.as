package com.gaiaonline.battle.ui.UiItemsParts
{
	import flash.display.MovieClip;
	import flash.text.TextField;
	
	
	public class MemberListItem extends MovieClip
	{
		private var id:int;
		
		public var userName:TextField;
		public var totalCharge:TextField;
		public var userSelector:MovieClip;
		public var friend_icon:MovieClip;
		
		public function get userId():int{
			return id;
		}
		
		public function set userId(_id:int):void{
			id=_id;
		}
	}
}