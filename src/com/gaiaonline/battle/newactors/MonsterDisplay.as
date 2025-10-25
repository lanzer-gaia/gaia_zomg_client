package com.gaiaonline.battle.newactors
{
	import com.gaiaonline.battle.ApplicationInterfaces.IAssetFactory;
	import com.gaiaonline.battle.ApplicationInterfaces.IUIFramework;
	import com.gaiaonline.battle.gateway.BattleGateway;
	import com.gaiaonline.battle.monsters.BaseMonsterLoader;
	import com.gaiaonline.battle.monsters.MonsterAnimQueue;
	import com.gaiaonline.battle.monsters.MonsterLoadManager;
	import com.gaiaonline.battle.monsters.MonsterProjectile;
	import com.gaiaonline.battle.newrings.RingAnim;
	import com.gaiaonline.battle.sounds.ActorSound;
	import com.gaiaonline.battle.ui.events.UiEvents;
	
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	public class MonsterDisplay extends ActorDisplay
	{
		private var baseMonster:BaseMonsterLoader;	
		private var _monsters:Array = [];
		private var _sounds:ActorSound;
		private var dead:Boolean = false;
		private var targetActor:Object;
		private var projectileSpeed:Number = -1;
		private var state:int = -1;
		private var previousPose:String = "idle";		
		private var pose:String = "idle";		
		private var portraitArray:Array = new Array();
		private var _monsterLoadManager:MonsterLoadManager;
		
		public function MonsterDisplay(assetFactory:IAssetFactory, baseUrl:String, baseActorId:String = null, monsterLoadManager:MonsterLoadManager= null){
			super(assetFactory, baseUrl, baseActorId);	
			this._monsterLoadManager = monsterLoadManager;
			this._frameQueueList.addFrameQueue(fnSetDir);
			this.clearPortraitArray(this.portraitArray);
		}	
		
		private function get sounds():ActorSound {
			if (!this._sounds) {
				this._sounds = new ActorSound(this._uiFramework.volumes);
			}
			
			return this._sounds;
		}
				
		public override function loadActor(gateway:BattleGateway, uiFramework:IUIFramework, url:String):void{
			super.loadActor(gateway, uiFramework, url);			
			if (this.isDispose){
				return;
			}
			
			this.url = url;
			if (this.url != null){
				this.baseMonster = this._monsterLoadManager.getBaseMonster(this.url);
				if (!this.baseMonster.loaded){
					this.baseMonster.addEventListener(Event.COMPLETE, onActorLoaded, false, 0, true);
					this.baseMonster.load();
				}
				this.initMonster();
				super.onActorLoaded(new Event(Event.COMPLETE));			
			}else{
				trace("=== Missing URL for Monster == ");
			}			
			
		}
		
		protected override function onActorLoaded(evt:Event):void{
			if (this.isDispose){
				return;
			}				
			///---- Clear tmep Monster
			this.removeChild(this.actorBtn);
			this.removeChild(this.mcBound);
			this.clearRingAnimList();
			this.animList.length = 0;

			for (var i:int = 0; i < this._monsters.length; i++){								
				this._monsters[i].removeEventListener(Event.REMOVED_FROM_STAGE, onMonsterRemovedFromStage);					
				this._monsters[i] = null;	
			}
			this._monsters.length = 0;
					
			this.initMonster();						
			
			super.onActorLoaded(new Event(Event.COMPLETE));		
			this.setState(this.state);		
			if (this.dead){
				//trace("[MonsterDisplay onActorLoaded ]  - dispatch MonsterDeath", this.name, this.dead);
				this.dispatchEvent(new Event("MonsterDeath"));
			}
			
		}		
						
		//----------------------------
		private static var s_defaultMonsterAnim:Sprite;
		public function getNewGenericMonsterAnim():Sprite
		{
			if (!s_defaultMonsterAnim)
			{
				s_defaultMonsterAnim = this.assetFactory.getInstance("GenericMonsterAnim") as Sprite;
			}		
			return s_defaultMonsterAnim;
		}

		private function initMonster():void{
			
			this.isGlow = this.baseMonster.isGlow;
			this.flip = this.baseMonster.flip;
			this.actorBtn = this.baseMonster.checkOutActorBtn();
			
//			this.displaySilhouette = this.baseMonster.displaySilhouette;
			
			if (this.actorBtn != null){				
				this.actorBtn.alpha = 0;	
				this.addChild(this.actorBtn);
				if (this.baseMonster.useButtonOnly){
					this.hitArea = this.actorBtn;
					this.mouseChildren = false;
				}else{
					this.mouseChildren = true;
				}									
			}
									
			if (this.parent != null){
				if (this.parent is BaseActor){
					this.sounds.initSound(BaseActor(this.parent), this.baseMonster.baseMonster);
				}else{
					this.sounds.initSound(null, this.baseMonster.baseMonster);
				}
			}else{
				this.addEventListener(Event.ADDED_TO_STAGE, onAddedToStage, false, 0, true);
			}				
								
			this.genericAnim = new RingAnim(this.baseUrl, this._gateway, this._uiFramework, this, "GenericMonster", "caster", getNewGenericMonsterAnim());			
			this.genericAnim.actorRef.addEventListener("MonsterDead", onMonsterDeath, false, 0, true);	
			this.genericAnim.actorRef.addEventListener("startProjectile", onProjectile, false, 0, true);		
			this.genericAnim.actorRef.addEventListener("MonsterActionEnd", MonsterActionEnd, false, 0, true);
			this.animList.push(this.genericAnim);				
						
			//var r:Rectangle = this.genericAnim.actorRef.getBounds(this);			
			var r:Rectangle
			if (this.actorBtn != null){
				r = this.actorBtn.getBounds(this.actorBtn);
			}else{
				r = this.genericAnim.actorRef.getBounds( this.genericAnim.actorRef);
			}
			this.genericHit.x = r.x + r.width/2 - (r.width * 0.1);
			this.genericHit.y = r.y + r.height/2 - (r.height * 0.2);
			
			
			this.mcBound = new Sprite();
			this.mcBound.graphics.beginFill(0x0000FF);
			this.mcBound.graphics.drawRect(r.x, r.y, r.width, r.height);
			this.mcBound.graphics.endFill();
			this.mcBound.visible = false;
			this.addChild(this.mcBound)
			
			this.reticle.width = this.genericAnim.actorRef.getBounds(null).width * 1.2;			
			if (this.reticle.width < 125){
				this.reticle.width = 125;
			}else if (this.reticle.width > 180){
				this.reticle.width = 180;
			}
			this.reticle.height = this.reticle.width * 0.5;			
			
		}	
		private function onAddedToStage(evt:Event):void{
			this.removeEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
			if (this.parent is BaseActor){
				this.sounds.initSound(BaseActor(this.parent), this.baseMonster.baseMonster);
			}else{
				this.sounds.initSound(null, this.baseMonster.baseMonster);
			}
		}
						
		public function get monsters():Array {
			return _monsters;
		}
				
		public override function getNewActor(pooling:Boolean = true):Sprite{
			if (this.isDispose){
				return null;
			}
			
			if(this.baseMonster != null){				
				var m:*;		
				if (pooling){
					m = this.baseMonster.checkOutMonster(this.baseActorId);
				}else{
					m =  this.baseMonster.getNewMonster();
				}

				if (m)
				{
					m.x += 71;
					m.y += 139;
					//trace("[MonsterDisplay getNewActor] ", this.name, this.currentActorAnim)					
					if (MovieClip(m).hasOwnProperty("setPoseState")){
						m.setPoseState(this.pose, this.state);
					}else{
						this.playAnim(this.currentActorAnim, null, true);
					}
					
					this.monsters.push(m);
							
					m.addEventListener(Event.REMOVED_FROM_STAGE, onMonsterRemovedFromStage, false, 0, true);
					m.mouseEnabled = false;	
					return m;		
				}
			}
			trace(" getNewActor() Missing baseMonster");				
			return null;
		}
		
		public override function getTargetInfoPortrait():Sprite {
			return this.getPortrait();
		}
		
		
		public override function getDialogPortrait():Sprite{
			return this.getPortrait();
		}
		
		private function getPortrait():Sprite {
			if (this.isDispose){
				return null;
			}

			var s:Sprite = new Sprite();
			if(this.baseMonster != null && this.baseMonster.loaded){				
				s.addChild( this.baseMonster.getPortrait() );				
				if (!this._isLoaded){
					s.graphics.lineStyle(1,0xFF0000);
					s.graphics.beginFill(0,0);
					s.graphics.drawRect(0,0,42,42);
					s.graphics.endFill()
					this.portraitArray.push(s);					
				}
											
			}else{
				s.graphics.lineStyle(1,0xFF0000);
				s.graphics.beginFill(0,0);
				s.graphics.drawRect(0,0,42,42);
				s.graphics.endFill()		
				this.portraitArray.push(s);
			}
			return s;
			
		}
		
		protected override function refreshPortraits():void{
			if (this.baseMonster != null && this.baseMonster.loaded){
				for (var i:int = 0; i < this.portraitArray.length; i++){
					var s:Sprite = this.portraitArray[i] as Sprite;					
					if (s != null && this.baseMonster != null && this.baseMonster.getPortrait != null){
						//--- clear						
						while(s.numChildren > 0){
							s.removeChildAt(0);
						}
						s.graphics.clear();									
						s.addChild( this.baseMonster.getPortrait() );										
					}
				}				
				this.portraitArray.length = 0;
			}
		}
		
		private function onMonsterRemovedFromStage(evt:Event):void{
			if (this.monsters != null){
				var i:int = this.monsters.indexOf(evt.target);			
				if (i >=0){
					this.monsters[i].removeEventListener(Event.REMOVED_FROM_STAGE, onMonsterRemovedFromStage);
					if (!this.baseMonster.checkInMonster(this.monsters[i])){
						//DisplayObjectUtils.ClearAllChildrens(this.avs[i]);
						this.monsters[i].dispose();
					}										
					this.monsters.splice(i,1);
				}
			}			
		}
				
		public override function setDirection(angle:Number):void{
			if (this.isDispose){
				return;
			}
			super.setDirection(angle);
			this._frameQueueList.addToFrameQueue(fnSetDir, angle, true);							
		}
		private function fnSetDir(data:Object):void{			
			for (var i:int = 0; i < this.monsters.length; i++){
				this.monsters[i].setAngle(this.direction);
			}
		}
		
		public override function setState(state:int=0):void{
			if (this.isDispose){
				return;
			}	
			
			if (this.state != state){					
				this.state = state;	
				if (!this.dead){			
					//MonsterAnimQueue.addToQueue(this, fnState, "state");
					fnState();
				}
			}
			this.mouseChildren = false;
			this.mouseEnabled = true;
		}
		private function fnState():void{
			for (var i:int = 0; i < this.monsters.length; i++){				
				if (this.monsters[i].hasOwnProperty("setState")){
					this.monsters[i].setState(this.state);	
				}		
			}
		}
						
		private function onProjectile(evt:UiEvents):void{
			if (this.baseMonster != null && this.baseMonster.getNewProjectile != null){
				var mc:MovieClip = this.baseMonster.getNewProjectile();
				var ba:BaseActor = BaseActor(this.parent);													
				new MonsterProjectile(this._uiFramework, mc, this.targetActor, new Point(ba.position.x, ba.position.y), this.projectileSpeed, evt.value);				
			}									
		}
		
		
		public override function onQuickMove(type:String, cTime:int=0, totalTime:int = 0):Object{
			if (this.isDispose){
				return null;
			}
			
			var obj:Object = {startFrame:0, frameFromEnd:0};
			if (this.monsters[0] != null){
				for (var i:int = 0; i < this.monsters.length; i++){
					if (this.monsters[i].hasOwnProperty("onQuickMove")){						
						obj = this.monsters[i].onQuickMove(type, cTime, totalTime);	
					}						
				}				
			}
			return obj;
		}
		
		public override function playSound(soundID:String):void{
			if (this.isDispose){
				return;
			}
			
			this.sounds.playFrame(soundID, false, true);
		}
		
		// Actions ----------------------------
		private static const nonRepeatableAnims:Array = ["idle", "hit", "walk", "die", "aggroIn", "aggroOut", "spawn"];		
		public override function playAnim(action:String, param:Object = null, allowRepeatAnim:Boolean = false):void{
			if (this.isDispose){
				trace("[MonsterDisplay playAnim ] already dispose ", this.name)
				return;
			}			
			var prevAnim:String = this.currentActorAnim;
			super.playAnim(action);	
			//trace("[MonsterDisplay playAnim ] ", this.name, this.dead, this.pose, action, this.currentActorAnim)		
			if (!this.dead){
				if (allowRepeatAnim || MonsterDisplay.nonRepeatableAnims.indexOf(this.currentActorAnim) == -1 ||  prevAnim != action) {							
					switch (this.currentActorAnim){			
						case "idle":						
							this.idle();
							break;
										
						case "hit":
							var type:String = "hit";
							if (param != null){
								type = String(param);
							}			
							this.playHit(type);	
							break;
						
						case "walk":
							this.walk();
							break;
						
						case "die":
							this.die();
							break;
						
						case "aggroIn":
							this.aggroIn();					
							break;
						
						case "aggroOut":
							this.aggroOut();					
							break;
						
						case "spawn":
							this.spawn();
							break;
						
						case "sit":
							this.sit();
							break;						
							
						case null:
							break;
									
						default:						
							var target:Object = null;
							var s:Number = -1;
							if (param != null){
								if (param.target != null){
									target = param.target;							
								}
								if (param.speed != null){
									s = param.speed;
								}		
							}									
							this.attack(action, target, s);
							break;	
					}
				}
			}else{
				//trace("[MonsterDisplay playAnim ] CALL DIE",this.name , this.pose, " =========================")	
				this.die();
			}
		}
		
		//** SPAWN ************************
		private function spawn():void{
			if (!this.dead){
				this.pose = "spawn";	
				MonsterAnimQueue.addToQueue(this, fnSpawn, "spawn", null, true);
			}
		}
		private function fnSpawn():void{
			if(this.monsters.length && MovieClip(this.monsters[0]).hasOwnProperty("spawn")){
				for (var i:int = 0; i < this.monsters.length; i++){
					this.monsters[i].aggro = this.aggro;				
					this.monsters[i].spawn();					
				}		
			}
		}
		
		//** SIT (Most monster do nto have sit pot ... this is for avatarMonster.. like the UFO) ************************
		private function sit():void{
			if (!this.dead ){
				this.pose = "sit";
				this.previousPose = "sit";
				MonsterAnimQueue.addToQueue(this, fnSit, "sit");
			}
		}
		private function fnSit():void{			
			for (var i:int = 0; i < this.monsters.length; i++){
				this.monsters[i].aggro = this.aggro;
				this.monsters[i].sit();
			}
			if(this.sounds) {
				if (this.aggro){
					this.sounds.playFrame("aggro_sit");
				}else{
					this.sounds.playFrame("sit");
				}
			}
		}
		
		
		
		//** IDLE ************************
		private function idle():void{
			if (!this.dead){
				this.pose = "idle";
				this.previousPose = "idle";
				MonsterAnimQueue.addToQueue(this, fnIdle, "idle");
			}	
		}
		private function fnIdle():void{
			for (var i:int = 0; i < this.monsters.length; i++){
				this.monsters[i].aggro = this.aggro;				
				this.monsters[i].idle();							
			}
			if(this.sounds) {
				if (this.aggro){						
					this.sounds.playFrame("aggro_idle");
				}else{			
					this.sounds.playFrame("idle");
				}
			}
		}
		
		//** WALK ************************
		private function walk():void{
			if (!this.dead ){
				this.pose = "walk";
				this.previousPose = "walk";
				MonsterAnimQueue.addToQueue(this, fnWalk, "walk");
			}
		}
		private function fnWalk():void{			
			for (var i:int = 0; i < this.monsters.length; i++){
				this.monsters[i].aggro = this.aggro;
				this.monsters[i].walk();
			}
			if(this.sounds) {
				if (this.aggro){
					this.sounds.playFrame("aggro_walk");
				}else{
					this.sounds.playFrame("walk");
				}
			}
		}
		
		private function playHit(param:String):void{
			if (!this.dead){
				this.pose = "hit";
				if(param == "criticalhit"){				
					MonsterAnimQueue.addToQueue(this, fnPlayHitMajor, "hit");	
				}else{				
					MonsterAnimQueue.addToQueue(this, fnPlayHitMinor, "hit");
				}
			}
			
		}
		private function fnPlayHitMinor():void{
			for (var i:int = 0; i < this.monsters.length; i++){
				this.monsters[i].aggro = this.aggro;
				this.monsters[i].hit();
			}
			if(this.sounds) {
				this.sounds.playFrame("minorPain");				
			}
		}
		private function fnPlayHitMajor():void{
			for (var i:int = 0; i < this.monsters.length; i++){
				this.monsters[i].aggro = this.aggro;
				this.monsters[i].hit();
			}
			if(this.sounds) {
				this.sounds.playFrame("minorPain");				
			}
		}
			
		private function attack(atk:String, targetActor:Object = null, speed:Number = -1):void{
			if (!this.dead){		
				this.pose = atk;
				this.targetActor = targetActor;
				this.projectileSpeed = speed;			
				MonsterAnimQueue.addToQueue(this, fnAttack, "atk", atk);
			}
		}
		private function fnAttack(data:Object):void{
			for (var i:int = 0; i < this.monsters.length; i++){	
				this.monsters[i].aggro = this.aggro;			
				this.monsters[i].attack(data);			
			}
			if(this.sounds) {
				this.sounds.playFrame(data.toString());
			}	
		}
		private function die():void{
			this.pose = "death";
			this.dead = true;
			//trace("[MonsterDisplay die] add fnDie to Animation queue")
			MonsterAnimQueue.addToQueue(this, fnDie, "die");		
		}
		private function fnDie():void{
			//trace("[MonsterDisplay fnDie] ", this.monsters.length);
			for (var i:int = 0; i < this.monsters.length; i++){				
				this.monsters[i].aggro = this.aggro;			
				this.monsters[i].die();				
			}
			if(this.sounds) {
				this.sounds.playFrame("die", true);
			}			
		}
		
		private function aggroIn():void{
			if (!this.dead){				
				this.aggro = true;
				if (this.baseMonster.hasAggro){
					this.setState(1);
				}else{
					this.setState(0);
				}					
				this.sounds.playFrame("aggroIn");	
			}	
		}
		
		private function aggroOut():void{
			if (!this.dead){
				this.aggro = false;
				this.setState(0);
				if(this.sounds) {
					this.sounds.playFrame("aggroOut");
				}
			}
		}
						
		// Event Handle on monster
		private function onMonsterDeath(evt:Event):void{
			this.dispatchEvent(new Event("MonsterDeath"));			
		}
		private function MonsterActionEnd(evt:Event):void{
			//trace("[MonsterDisplay Animation End] ", this.currentActorAnim)
			this.currentActorAnim = this.previousPose;			
		}
					
		public override function dispose():void{
			//trace("[MonsterDisplay dispose ] ", this.name, this.dead)
			if (this.genericAnim != null && this.genericAnim.actorRef != null && this.genericAnim.actorRef.hasEventListener("MonsterDead")){
				this.genericAnim.actorRef.removeEventListener("MonsterDead", onMonsterDeath);
			}
			
			if(this.sounds) {
				this._sounds.dispose();
				this._sounds = null;
			}
			
			this.baseMonster.checkInActorBtn(this.actorBtn);
			
			for (var i:int = 0; i < this.monsters.length; i++){											
					
				this.monsters[i].removeEventListener(Event.REMOVED_FROM_STAGE, onMonsterRemovedFromStage);
				this.baseMonster.checkInMonster(this._monsters[i]);		
			
				this.monsters[i] = null;	
			}
			this._monsters.length = 0;
									
			this.baseMonster = null;
									
			super.dispose()
		}		
	}
}
