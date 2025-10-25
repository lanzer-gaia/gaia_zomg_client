package com.gaiaonline.battle.moduleManagers
{
	import com.gaiaonline.battle.ui.AlertTypes;
	import com.gaiaonline.battle.ui.IAsyncCreationHandler;
	import com.gaiaonline.battle.ui.IFlexUiManager;
	import com.gaiaonline.battle.ui.IModuleManager;
	import com.gaiaonline.battle.ui.PDAController;
	import com.gaiaonline.containers.GameWindowEvent;
	import com.gaiaonline.containers.GameWindowManager;
	import com.gaiaonline.containers.GameWindowSettings;
	import com.gaiaonline.containers.IGameWindowFactory;
	import com.gaiaonline.flexModulesAPIs.gatewayInterfaces.IBattleGateway;
	import com.gaiaonline.flexModulesAPIs.globalevent.GlobalEvent;
	import com.gaiaonline.flexModulesAPIs.pda.IPDA;
	import com.gaiaonline.utils.DisplayObjectUtils;
	
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;

	public class PDAModuleManager implements IModuleManager, IAsyncCreationHandler
	{
		private var _pending:Boolean = false;
		private var _instance:DisplayObject = null;
		private var _controller:PDAController = null;
		
		private var _title:String = null;
		private var _window:DisplayObjectContainer = null;
		private var _windowManager:GameWindowManager = null;
		private var _windowFactory:IGameWindowFactory;
		private var _gateway:IBattleGateway = null;
		
		private var _flexUIManager:IFlexUiManager = null;
		
		private var _path:String = null;
		private var _winUtils:WindowUtils = null;
		
		public function PDAModuleManager()
		{
		}

		public function init(path:String, title:String, gateway:IBattleGateway, flexWinLayer:DisplayObjectContainer, flexUIManager:IFlexUiManager, windowManager:GameWindowManager, windowFactory:IGameWindowFactory, params:XML=null):void
		{
			_winUtils = new WindowUtils(flexWinLayer);
			
			_path = path;					// the module path
			_title = title;
			
			_gateway = gateway;
			
			_flexUIManager = flexUIManager;
			_windowManager = windowManager;
			_windowFactory = windowFactory;
			
			DisplayObjectUtils.addWeakListener(GlobalEvent.eventDispatcher, GlobalEvent.PDA_TOGGLE, onTogglePDA);
			
			this._controller = PDAController.getInstance(_flexUIManager, _gateway);
			getModule();
		}

		private function getModule():void
		{
			if (!_pending) {
				this._flexUIManager.getModule(_path, this);
				_pending= true;
			}
		}
		
		public function onCreation(instance:Object, modulePath:String):void
		{
			this._instance = DisplayObject(instance);
			
			this._window = this._windowFactory.createWindow(_title, true);
			this._window.addEventListener(GameWindowEvent.CLOSE, onClosePDAWidget, false, 0, true);
			this._window.addChild(this._instance);
			this._windowManager.add(this._window, new GameWindowSettings(_title).setPos(10, 50).setSize(200, 250).setMinSize(150, NaN));
			this._controller.addView(IPDA(this._instance));
			this.openPDAWidget();
		}
		
		private function isPDAOpen():Boolean {
			return this._window && _winUtils.isWindowOpen(this._window.parent); 
		}
		
		private function openPDAWidget(activeTabIndex:int = -1):void{
			if (!isPDAOpen()) {	//this._uiState.forcedPDAClose - handle
				/* if (this.actionBar) {
					this.actionBar.setPDAOpen(true);
				}*/				
				
				_controller.setPDAOpen(true);
				_winUtils.openWindow(_window);	
				GlobalEvent.eventDispatcher.dispatchEvent(new GlobalEvent(GlobalEvent.ALERT, {type:AlertTypes.GENERIC_OPEN}));																																													
			}
			/* if (!this._uiState.forcedPDAClose) {
				if (activeTabIndex >= 0) {
					_controller.activeTab = activeTabIndex;
				}										
			} */
		}
		
		private function onTogglePDA(e:GlobalEvent):void
		{
			if (_winUtils.isWindowOpen(_window)) {
				closePDAWidget();
			} else {
				openPDAWidget();
			}
		}
		
		private function onClosePDAWidget(e:GameWindowEvent):void
		{
			closePDAWidget();
		}
		
		private function closePDAWidget():void {
			if (!_window){
				return;
			}
			
			if (isPDAOpen()) {
				/* if (this.actionBar) {
					this.actionBar.setPDAOpen(false);
				} */
				_controller.setPDAOpen(false);				
				_winUtils.closeWindow(_window);
				GlobalEvent.eventDispatcher.dispatchEvent(new GlobalEvent(GlobalEvent.ALERT, {type:AlertTypes.GENERIC_CLOSE}));
			}
		}
		
	}
}