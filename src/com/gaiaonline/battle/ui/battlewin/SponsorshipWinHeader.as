package com.gaiaonline.battle.ui.battlewin
{
	import com.gaiaonline.battle.ApplicationInterfaces.IUIFramework;
	
	import flash.display.MovieClip;
	import flash.text.TextField;
	
	public class SponsorshipWinHeader extends MovieClip implements IWinHeader
	{
		private var _uiFramework:IUIFramework;
		
		private var _txtZone:TextField;
		private var _serverName:String;
		private var _zoneName:String;
		
		public function SponsorshipWinHeader() 
		{
			
		}
		
		//******************************
		private function refeshZoneName():void{
			if (this._txtZone != null){
				this._txtZone.text = this._zoneName + " / " + this._serverName;
			}
		}
		
		//********** FPS **************
		public function startFps():void{
			
		}
		public function stopFps():void{
			
		}
		
		//*****************************************
		//***** IWinHeaqer Implemantation *********
		//*****************************************
		public function init(uiFramework:IUIFramework):void{
			this._uiFramework = uiFramework;
			
			this._txtZone = TextField(this.getChildByName("txtZone"));
			this._txtZone.selectable = false;
			this._txtZone.mouseEnabled = false;
		}
		
		public function get serverName():String{
			return this._serverName;
		}
		public function set serverName(v:String):void{
			this._serverName = v;
			this.refeshZoneName();
		}
		
		public function get zoneName():String{
			return this._zoneName;
		}
		public function set zoneName(v:String):void{
			this._zoneName = v;
			this.refeshZoneName();
		}
		
		public function setSize(width:uint, height:uint, right:Number = 0):void{
			
		}

	}
}