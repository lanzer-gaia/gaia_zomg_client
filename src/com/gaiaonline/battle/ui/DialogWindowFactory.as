package com.gaiaonline.battle.ui
{
	import com.gaiaonline.battle.ApplicationInterfaces.ILinkManager;
	import com.gaiaonline.battle.ApplicationInterfaces.IUIFramework;
	
	import flash.display.MovieClip;
	
	public class DialogWindowFactory
	{
		private static var instance:DialogWindowFactory = null;
		
		private static var s_layerMappings:Object = null;
		
		public function DialogWindowFactory(se:SingletonEnforcer) {
			if (se == null) {
				throw new Error("DialogWindowFactory is a singleton; use getInstance");
			}
		}
		
		static public function setTypeMappings(mappings:Object):void {
			DialogWindowFactory.s_layerMappings = mappings;
		}
		
		private static function typeToLayer(type:DialogWindowTypes):MovieClip {
			return DialogWindowFactory.s_layerMappings[type];
		}
		
		static public function getInstance():DialogWindowFactory {
			if (!instance) {
				instance = new DialogWindowFactory(new SingletonEnforcer());
			}	
			
			return instance;
		}
		
		public function getNewDialogWindow(uiFramework:IUIFramework, linkManager:ILinkManager, layerType:DialogWindowTypes, winWidth:Number = 100, winHeight:Number =50, cssUrl:String = "help-files/css/script-dialog.css"):DialogWindow {
			return new DialogWindow(uiFramework, linkManager, DialogWindowFactory.s_layerMappings[layerType] ,winWidth, winHeight, cssUrl);
		}
	}
}

internal class SingletonEnforcer {}