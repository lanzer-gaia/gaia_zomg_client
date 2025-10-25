package com.gaiaonline.battle.minigames
{
	import com.gaiaonline.containers.GameWindow;
	import com.gaiaonline.containers.GameWindowEvent;
	import com.gaiaonline.flexModulesAPIs.MiniGameWidget.IMiniGame;
	import com.gaiaonline.utils.DisplayObjectUtils;
	
	import flash.display.Loader;
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.net.URLRequest;
	
	public class MiniGameController
	{
		private var _miniGameWidget:IMiniGame;
		private var _loader:Loader;
		private var _mcGame:MovieClip;
		private var _gameWin:GameWindow;
		private var _gameDone:Boolean = false;
				
		public function MiniGameController(miniGameWidget:IMiniGame, gameWindow:GameWindow)
		{
			this._miniGameWidget = miniGameWidget;
			this._gameWin = gameWindow;
			this._gameWin.addEventListener(GameWindowEvent.CLOSE, onGameWinClose);		
		}
		
		public function load(url:String):void{
			this._loader = new Loader();
			this._loader.contentLoaderInfo.addEventListener(Event.COMPLETE, onGameLoaded);
			this._loader.load(new URLRequest(url));				
		}	
		
		private function onGameLoaded(evt:Event):void{			
			this._loader.contentLoaderInfo.removeEventListener(Event.COMPLETE, onGameLoaded);
			
			this._mcGame = this._loader.content as MovieClip;
			this._mcGame.addEventListener(MiniGameEvent.WIN, onGameDone, false, 0, true);
			this._mcGame.addEventListener(MiniGameEvent.LOSE, onGameDone, false, 0, true);
			
			this._miniGameWidget.addGame(this._mcGame);
			this._mcGame.game.init();
		}
		
		private function onGameDone(evt:MiniGameEvent):void{
			this._gameDone = true;
		}
		
		private function onGameWinClose(evt:GameWindowEvent):void{
			dispose();
		}		
		
		public function dispose():void{
			if (this._mcGame != null){				
				if (!this._gameDone){
					this._mcGame.game.win();
				}
				DisplayObjectUtils.stopAllMovieClips(this._mcGame);
				this._mcGame.removeEventListener(MiniGameEvent.WIN, onGameDone);
				this._mcGame.removeEventListener(MiniGameEvent.LOSE, onGameDone);
				this._miniGameWidget.clearGame();
				this._mcGame = null;
			}
			if (this._loader != null){
				this._loader.unload();
				this._loader = null;
			}
		}
				
	}
}