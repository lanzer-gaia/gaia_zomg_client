package com.gaiaonline.battle.ui
{
	import flash.display.MovieClip;
	import flash.text.TextField;

	public class UiTrackListItem extends MovieClip
	{
		private var _id:int;
		private var _frm:int;		
						
		public var trackNum:TextField;
		public var trackName:TextField;
				
		public function UiTrackListItem() {
			super();
		}
		
		public function set id(newId:int):void {
			this._id = newId;
		}
		
		public function get id():int {
			return this._id;
		}
		
		public function set frm(newFrm:int):void {
			this._frm = newFrm;
		}
		
		public function get frm():int {
			return this._frm;
		}		
	}
}