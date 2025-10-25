package com.gaiaonline.battle.ui.UiWorldListClasses
{
	import flash.display.MovieClip;
	import flash.text.TextField;
	
	public class FriendItem extends MovieClip
	{
		
		public var txtFriend:TextField;
		public var txtServerName:TextField;
		public var userId:String;
		
		private var _enable:Boolean = false;
		
		public function FriendItem()
		{
			
		}
		
		public function setEnable(enable:Boolean):void{
			this._enable = enable;
			if (!this._enable){
				this.txtFriend.textColor = 0x999999;
				this.txtServerName.textColor = 0x999999;
			}else{
				this.txtFriend.textColor = 0xFFFFFF;
				this.txtServerName.textColor = 0xFFFFFF;
			}
		}
	
		
		public function set friendName(v:String):void{
			if (this.txtFriend) {
				if (v!= null){
					this.txtFriend.text = v;
				}else{
					this.txtFriend.text = "";
				}
			}
		}
		public function get friendName():String{
			var ret:String = null;
			if (this.txtFriend) {
				ret = this.txtFriend.text;
			}
			return ret;
		}
		
		public function set serverName(v:String):void{
			if (this.txtServerName) {
				if (v!= null){
					this.txtServerName.text = v;
				}else{
					this.txtServerName.text = null;
				}
			}
		}
		public function get serverName():String{
			var ret:String = null;
			if (this.txtServerName) {
				ret = this.txtServerName.text;
			}
			return ret;
		}

	}
}