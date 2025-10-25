package com.gaiaonline.battle.monsterplayer
{
	import com.gaiaonline.utils.factories.LoaderContextFactory;
	import com.gaiaonline.battle.ApplicationInterfaces.ILoaderContextFactory;
	import com.gaiaonline.battle.monsters.MonsterLoadManager;
	import com.gaiaonline.battle.newactors.ActorDisplay;
	import com.gaiaonline.battle.newactors.MonsterDisplay;
	
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.MouseEvent;
	
	public class MonsterPlayer extends MovieClip
	{	
		
		private var monster:MonsterDisplay;
		private var url:String;
		
		public function MonsterPlayer():void{
					
			this.mcHeader.btnLoad.addEventListener(MouseEvent.CLICK, onMonsterLoadClick, false, 0, true);			
			this.mcControls.nsAngle.addEventListener(Event.CHANGE, onStAngleChange, false, 0, true);
			this.mcControls.nsState.addEventListener(Event.CHANGE, onStStateChange, false, 0, true);
			this.mcControls.btnSpawn.addEventListener(MouseEvent.CLICK, onSpawnClick, false, 0, true);
			this.mcControls.btnIdle.addEventListener(MouseEvent.CLICK, onIdleClick, false, 0, true);
			this.mcControls.btnWalk.addEventListener(MouseEvent.CLICK, onWalkClick, false, 0, true);
			this.mcControls.btnHit.addEventListener(MouseEvent.CLICK, onHitClick, false, 0, true);
			this.mcControls.btnDeath.addEventListener(MouseEvent.CLICK, onDeathClick, false, 0, true);
			this.mcControls.btnAtk0.addEventListener(MouseEvent.CLICK, onAtk0Click, false, 0, true);
			this.mcControls.btnAtk1.addEventListener(MouseEvent.CLICK, onAtk1Click, false, 0, true);
			this.mcControls.btnAtk2.addEventListener(MouseEvent.CLICK, onAtk2Click, false, 0, true);
			this.mcControls.btnAtk3.addEventListener(MouseEvent.CLICK, onAtk3Click, false, 0, true);
		}
		
		
		private function loadMonster(url:String):void{
			if (this.monster != null){					
				this.monster.dispose();
				this.monster = null;
				
				MonsterLoadManager.removeMonster(this.url);
			}
			this.url = url;
			this.monster = new MonsterDisplay(this);				
			this.monster.addEventListener(ActorDisplay.LOADED, onMonsterLoaded, false, 0, true);
			this.monster.addEventListener(IOErrorEvent.IO_ERROR, onIoError, false, 0, true);

			this.monster.loadActor(null, null, url);
		}
		private function onMonsterLoaded(evt:Event):void{
			this.monster.removeEventListener(ActorDisplay.LOADED, onMonsterLoaded);
			this.monster.removeEventListener(IOErrorEvent.IO_ERROR, onIoError);
			
			this.mcControls.nsState.value = 0;
			this.actorContainer.addChild(this.monster);
			this.monster.x = this.stage.stageWidth/2;
			this.monster.y = this.stage.stageHeight/2 + 50;
			this.setDir(this.mcControls.nsAngle.value);	
			this.monster.setState(this.mcControls.nsState.value);	
		}
		
		private function setDir(angle:Number):void{
			//trace(angle);
			if (this.monster != null){					
				this.monster.setDirection(angle);
				this.monster.scaleX = this.monster.hScale;
			}
		}
		
		private function onIoError(evt:Event):void{
			this.mcHeader.txtUrl.text = this.mcHeader.txtUrl.text + " Url not found";
			this.monster.removeEventListener(ActorDisplay.LOADED, onMonsterLoaded);
			this.monster.removeEventListener(IOErrorEvent.IO_ERROR, onIoError);
		}
				
				
		private function onMonsterLoadClick(evt:MouseEvent):void{
			this.loadMonster(this.mcHeader.txtUrl.text);
		}
				
		private function onStAngleChange(evt:Event):void{
			if (this.mcControls.nsAngle.value >= 360){
				this.mcControls.nsAngle.value = 0;
			}else if (this.mcControls.nsAngle.value < 0){
				this.mcControls.nsAngle.value = 360 + this.mcControls.nsAngle.value;
			}
			
			this.setDir(this.mcControls.nsAngle.value);
		}
		
		private function onStStateChange(evt:Event):void{
			if (this.monster != null){
				this.monster.setState(this.mcControls.nsState.value);
			}
		}
		
		private function onSpawnClick(evt:MouseEvent):void{
			if (this.monster != null){
				this.monster.playAnim("spawn");
			}
		}
		private function onIdleClick(evt:MouseEvent):void{
			if (this.monster != null){
				this.monster.playAnim("idle");
			}
		}
		private function onWalkClick(evt:MouseEvent):void{
			if (this.monster != null){
				this.monster.playAnim("walk");
			}
		}
		private function onHitClick(evt:MouseEvent):void{
			if (this.monster != null){
				this.monster.playAnim("hit");
			}
		}
		private function onDeathClick(evt:MouseEvent):void{
			if (this.monster != null){
				this.monster.addEventListener("MonsterDeath", onMonsterDie, false, 0, true);
				this.monster.playAnim("die");				
			}
		}
		private function onAtk0Click(evt:MouseEvent):void{
			if (this.monster != null){
				this.monster.playAnim("atk0");
			}
		}	
		private function onAtk1Click(evt:MouseEvent):void{
			if (this.monster != null){
				this.monster.playAnim("atk1");
			}
		}	
		private function onAtk2Click(evt:MouseEvent):void{
			if (this.monster != null){
				this.monster.playAnim("atk2");
			}
		}	
		private function onAtk3Click(evt:MouseEvent):void{
			if (this.monster != null){
				this.monster.playAnim("atk3");
			}
		}
		
		private function onMonsterDie(evt:Event):void{
			this.loadMonster(this.url);
			this.monster.removeEventListener("MonsterDeath", onMonsterDie);			
		}
			
		//---- Actor Asset Implementation
		
		public function getNewReticle():Sprite{
			return new Reticle();
		}
		
		public function getNewGenericHitAnim():Sprite{
			return new GenericHitAnim();
		}
		
		public function getNewTransitionAnim(tType:String):Sprite{
			var s:Sprite;
			switch (tType){
				case "portal_in":
					s = new PortalIn();
					break;
				
				case "portal_out":
					s = new PortalOut();
					break;
				
				case "hole_out"	:
					s = new HoleOut();
					break;
				
			}
			return s;
		}
		
		public function getNewAvatarBtn():Sprite{
			return new AvatarBtn();			
		}
		
		public function getNewGenericAvatarAnim():Sprite{
			return new GenericAvatarAnim();
		}
		
		public function getNewGenericMonsterAnim():Sprite{
			return new GenericMonsterAnim();
		}
		
	}
}