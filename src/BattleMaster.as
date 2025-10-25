package
{
	import com.gaiaonline.battle.Globals;
	import com.gaiaonline.battle.bm.BmActorManager;
	import com.gaiaonline.battle.bm.BmAreas;
	import com.gaiaonline.battle.bm.BmMap;
	import com.gaiaonline.battle.bm.Console;
	import com.gaiaonline.battle.gateway.BattleEvent;
	import com.gaiaonline.battle.gateway.BattleGateway;
	import com.gaiaonline.gsi.GSIEvent;
	
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.events.KeyboardEvent;

	[SWF(width="580", height="300", frameRate="8")]
	public class BattleMaster extends Sprite
	{
		public static var gateways:Array = [];
		public static var console:Console = new Console();
		public static var settings:Object = {};
		public static var bmMap:BmMap;
		public static var bmActorManagers:Object = {};
		public static var bmAreas:BmAreas;
		
		private static var properties:Object = null;
		
		public function BattleMaster()
		{
			super();
			init();
			settings.ip = "72.5.72.103";
			settings.subdomain = "ztrunk.open.d";
		}
	
		private function init():void {
 			BattleMaster.bmAreas = new BmAreas();
			this.stage.align = StageAlign.TOP_LEFT;
			this.stage.scaleMode = StageScaleMode.NO_SCALE;	
			this.stage.addEventListener(Event.RESIZE, this.onStageResize, false, 0, true);
			
			bmMap = new BmMap();				
			this.addChild(bmMap);
					
			this.addChild(BattleMaster.console);
			this.stage.addEventListener(KeyboardEvent.KEY_DOWN, consoleKeyEventListener, false, 0, true);
			
			console.toggle();			
		}	
		
		private function consoleKeyEventListener(ke:KeyboardEvent):void {
			if(ke.shiftKey && ke.keyCode == 192) {
				console.toggle();
			}
		}

		// Stage Events
		private function onStageResize(evt:Event):void{
			this.width = stage.width;
			this.height = stage.height;
		}
		
		public static function logout(name:String):void {
			gateways.every(function(item:*, index:int, array:Array):void {
				var gw:BattleGateway = item as BattleGateway;
				if(gw) {
					if(0 <= gw.getUserName().indexOf(name)) {
						array.splice(index, 1);
					}
				}
			});
		}
		
		public static function login(name:String, password:String):void {
			// [Mark Rubin] Not the way we parameterize anymore, since we don't store this info in Globals.  So broken for now.
//			Globals.properties["gsiUrl"] = settings.subdomain;
			
			var gw:BattleGateway = new BattleGateway();
			gw.gsiLogIn("battle", name, password);
			gateways.push(gw);

			gw.addEventListener(BattleEvent.LOGIN, function(be:BattleEvent):void {
				gw.removeEventListener( be.type, arguments.callee);
				console.append(be);
				BattleMaster.addGateway(gw);				
			});
			gw.addEventListener(BattleEvent.CONNECTION_LOST, function(be:BattleEvent):void {
				gw.removeEventListener( be.type, arguments.callee);
				console.append(be);
			});
			gw.addEventListener(GSIEvent.LOADED, function(ge:GSIEvent):void {
				gw.removeEventListener( ge.type, arguments.callee);
				console.append(ge);
			});
			gw.addEventListener( BattleEvent.GSI_LOGIN, function(be:BattleEvent):void {
				console.append("GSI Login Successful");
				gw.removeEventListener( be.type, arguments.callee);
				gw.sfLogIn("NA", settings.ip);
			});
			gw.addEventListener( BattleEvent.LOGIN_FAIL, function(be:BattleEvent):void {
				console.append("SmartFox Login Failed");
				gw.removeEventListener( be.type, arguments.callee);
			});
		}
		
		public static function addGateway(gw:BattleGateway):void {
			var bmActorManager:BmActorManager = new BmActorManager();
			bmActorManagers[gw] = bmActorManager;
			bmActorManager.addGateway(gw);
		}
			
		public static function showArea(areaId:String):void{			
			bmMap.showArea(areaId);
		} 
		
	}

	// Testing changes that do nothing
}
