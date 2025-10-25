package com.gaiaonline.battle.preloader
{
	import flash.text.TextField;
	import flash.events.Event;
	import flash.display.MovieClip;

	public class Preloader extends MovieClip
	{
		[Embed(source="preloader.swf", symbol="PreloaderAssets")]
		private var PreloaderCLS:Class;
		private var preloaderAssets:* = null;	
		
		public function Preloader(){
			this.preloaderAssets = new this.PreloaderCLS();
			preloaderAssets.addEventListener(Event.ADDED_TO_STAGE, onAddedToStage, false, 0, true);
			preloaderAssets.addEventListener(Event.REMOVED_FROM_STAGE, onRemoveFromStage, false, 0, true);
			this.addChild(preloaderAssets);
			
			setPer(0);		
			
			this.addEventListener(Event.ADDED_TO_STAGE, onAddedToStage, false, 0, true);
			this.addEventListener(Event.REMOVED_FROM_STAGE, onRemoveFromStage, false, 0, true);					
		}
		
		private function onAddedToStage(evt:Event):void
		{	
			this.resize();
			this.stage.addEventListener(Event.RESIZE, onStageResize, false, 0, true);
		}
		private function onRemoveFromStage(evt:Event):void
		{
			this.stage.removeEventListener(Event.RESIZE, onStageResize);
		}		
		private function onStageResize(evt:Event):void
		{
			this.resize();
		}
		
		private function resize():void
		{
			this.x = (this.stage.stageWidth/2) - (this.preloaderAssets.width/2);
			this.y = (this.stage.stageHeight/2) - (this.preloaderAssets.height/2);			
		}
		
		public function setPer(per:int):void
		{
			this.preloaderAssets.bar.scaleX = per/100;
		}
		public function setText(txt:String):void
		{
			this.preloaderAssets.info.text = txt;
		}
	}
}