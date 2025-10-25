package com.gaiaonline.battle.preloader
{
	import com.gaiaonline.utils.FrameTimer;
	
	import flash.display.DisplayObject;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.IEventDispatcher;
	import flash.events.ProgressEvent;
	
	import mx.events.FlexEvent;
	import mx.preloaders.IPreloaderDisplay;
	
	public class BattleLoader extends MovieClip implements IPreloaderDisplay
	{
		private var preloaderProgress:PreloaderProgress = null;
		
		public function BattleLoader() {
				this.stop();			
		}

		private function onProgress(e:ProgressEvent):void {
			graphics.clear();			
			var percent:Number = e.bytesLoaded / e.bytesTotal;
			this.preloaderProgress.setPer(percent * 100);			
		}		
				
		public function initialize():void{
			if(this.loaderInfo.parameters["bypassPreloader"] == "true") 
			{
				return;
			}

			this.preloaderProgress = new PreloaderProgress();
			this.preloaderProgress.setText("Loading zOMG!");	

			this.mouseEnabled = false;			
			this.addChild(this.preloaderProgress);
	    }		
		
		private function handleInitComplete(event:FlexEvent):void{
			(event.target as IEventDispatcher).removeEventListener(event.type, arguments.callee);					
			(event.target as IEventDispatcher).removeEventListener(ProgressEvent.PROGRESS, this.onProgress);								
			removeChild(preloaderProgress);
			this.preloaderProgress = null;
			dispatchEvent(new Event(Event.COMPLETE));						
		}
		
		public function set preloader(preloader:Sprite):void {
            preloader.addEventListener(FlexEvent.INIT_COMPLETE, handleInitComplete, false, 0, true);            
			preloader.addEventListener(ProgressEvent.PROGRESS, onProgress);
        }

		public function get backgroundColor():uint {
            return 0x3a3a3a;
        }
        
        public function set backgroundColor(value:uint):void {
        }
        
        public function get backgroundAlpha():Number {
            return 0;
        }
        
        public function set backgroundAlpha(value:Number):void {
        }
        
        public function get backgroundImage():Object {
            return undefined;
        }
        
        public function set backgroundImage(value:Object):void {
        }
        
        public function get backgroundSize():String {
            return "";
        }
        
        public function set backgroundSize(value:String):void {
        }
    
        public function get stageWidth():Number {
            return 1000;
        }
        
        public function set stageWidth(value:Number):void {
        }
        
        public function get stageHeight():Number {
            return 555;
        }
        
        public function set stageHeight(value:Number):void {
        
        }
	}
}
