package com.gaiaonline.battle.newactors
{
	import com.gaiaonline.battle.ApplicationInterfaces.IFileVersionManager;
	import com.gaiaonline.battle.ApplicationInterfaces.ILinkManager;
	import com.gaiaonline.battle.ApplicationInterfaces.IUIFramework;
	import com.gaiaonline.battle.ItemLoadManager.ConsumableManager;
	import com.gaiaonline.battle.Loot.Orbs;
	import com.gaiaonline.battle.gateway.BattleEvent;
	import com.gaiaonline.battle.gateway.BattleGateway;
	import com.gaiaonline.battle.gateway.BattleMessage;
	import com.gaiaonline.battle.map.CollisionMap;
	import com.gaiaonline.battle.map.TintTypes;
	import com.gaiaonline.battle.monsters.MonsterLoadManager;
	import com.gaiaonline.battle.newcollectibles.CollectiblesUpdater;
	import com.gaiaonline.battle.newghibuffs.GhiBuffsUpdater;
	import com.gaiaonline.battle.newrings.Ring;
	import com.gaiaonline.battle.newrings.RingAnim;
	import com.gaiaonline.battle.ui.events.UiEvents;
	import com.gaiaonline.battle.utils.BattleUtils;
	import com.gaiaonline.battle.utils.DisplayObjectAttacher;
	import com.gaiaonline.flexModulesAPIs.FlexMenuItem;
	import com.gaiaonline.flexModulesAPIs.actorInfo.ActorTypes;
	import com.gaiaonline.flexModulesAPIs.globalevent.GlobalEvent;
	import com.gaiaonline.platform.actors.ICarriable;
	import com.gaiaonline.platform.actors.ICarrier;
	import com.gaiaonline.platform.actors.ISilhouetteable;
	import com.gaiaonline.platform.actors.ISubmersible;
	import com.gaiaonline.platform.actors.ITintable;
	import com.gaiaonline.platform.map.MapFilesFactory;
	import com.gaiaonline.utils.DisplayObjectUtils;
	import com.gaiaonline.utils.FrameTimer;
	import com.gaiaonline.utils.SpritePositionBubbler;
	
	import fl.transitions.Tween;
	import fl.transitions.easing.Bounce;
	
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.IEventDispatcher;
	import flash.events.MouseEvent;
	import flash.external.ExternalInterface;
	import flash.geom.Point;
	import flash.utils.getTimer;
	
	public class BaseActor extends SpritePositionBubbler implements ITintable, ISubmersible, ICarriable, ICarrier, ISilhouetteable
	{
		public static const ACTOR_GONE:String = "ActorGone";
		public static const TEAMMATE_GONE:String = "TeammateGone";		
		public static const REMOVING_ACTOR_FROM_LIST:String = "RemovingActorFromList";		
		public static const PAPER_DOLL_STATS_UPDATED:String = "PaperDollStatsUpdated";
		
		public static const CREW_STATE_NOT_KNOWN:String = "kNotKnown";		
		public static const CREW_STATE_IN:String = "kIn";
		public static const CREW_STATE_LOOKING:String = "kLooking";
		public static const CREW_STATE_NOT_LOOKING:String = "kNotLooking";
		
		public var inCrewState:String = CREW_STATE_LOOKING;
	
		// param
		private var _actorId:String;
		private var me:Boolean = false;
		public var actorName:String;
		public var rage:Number = 0;
		public var url:String;			
		private var _roomId:String;
		private var zoneName:String;
		private var _instanceId:String;
		private var serverSpeed:Number = 100;
		public var hp:Number = 100;
		public var maxHp:Number = 100;		
		public var exhaustion:Number = 0;
		public var maxExhaustion:Number = 100;
		public var ghiEnergy:Number = 0;
		public var ghiProgress:Number = 0;
		public var angle:Number = 0;
		public var weight:Number = 0;
		public var aggro:Boolean = false;
		public var rankCategory:Number = NaN; // used really for monsters/boss levels
		public var radius:Number = 0;
		public var range:Number	 = 150;
		public var isLfg:Boolean = false;
		public var conLevel:Number = NaN;
		public var hitCount:int = -1;
		public var Dialogable:Boolean = false;
		public var suppressedCL:Number = NaN;
		public var userLevel:int = -1;		// indicates unset	
		private var _displaySilhouette:Boolean = false;	
		
		public function get displaySilhouette():Boolean{
			return _displaySilhouette;
		}
		
		public function set displaySilhouette(value:Boolean):void{
			if(value != _displaySilhouette){
				_displaySilhouette = value;
				invalidateDisplayProperties();
			}
		}
		
		public function getCopyOfSpriteToBeSilhouetted():Sprite{
			var sprite:Sprite = getActorDisplay().getNewActor(false);
			sprite.mouseChildren = false;
			sprite.mouseEnabled = false;
			return sprite;
		}
		
		private var _lag:Number = 0;
				
		public var targetCycle:Boolean = true; 
		
		private var subscribedProperties:SubscriptionBasedProperties = null;

		// [kja] clusterfuck:  we have different ring updates coming down through different channels (paper doll vs. ringmanager/actorupdate/moveRing),
		// and their data formats are slightly different (i.e. the actorupdate rings don't include urls, so the character info UI doesn't work).  
		// There needs to be some refactoring alongside the server to have rings be updated a SINGLE way.  This is why we have a rings lookup here
		// and another one in the subscribedProperties for now. 
		private var _rings:Object = {};  
		
		public var gaiaUserLevel:int = 0;
		
		//-- KnockBack
		private var qmType:String;
		private var qmPoints:Array;
		private var qmPointIndex:Number = 0;
		private var qmTime:Number = 500;
		private var qmTotalDist:Number = 0;		
		private var isQm:Boolean = false;
		private var qmStartTime:int = 0;	
		
		//---
		public var actorType:ActorTypes = ActorTypes.PLAYER;
		
		static public const TARGETTYPE_NONE:int = 0;  // [kja] I think these are actually bitflags
		static public const TARGETTYPE_SELF:int = 1;
		static public const TARGETTYPE_FRIEND:int = 2;
		static public const TARGETTYPE_FRIENDSELF:int = 3;
		static public const TARGETTYPE_ENEMY:int = 4;
		static public const TARGETTYPE_POWERUSABLE:int = 8;
		static public const TARGETTYPE_COMPANION:int = 16;
		public var targetType:int = TARGETTYPE_NONE;		
				
		public var isSitting:Boolean = false;
		private var isTarget:Boolean = false;
			
		// display 
		public var displayType:String;
		public var isMonsterAvatar:Boolean = false;
		private var actorDisplay:ActorDisplay		
		private var hpBar:*;
		
		// ----
		private var targetPos:Point = new Point(0,0);
		public var position:Point = new Point(0,0);
		private var lastPos:Point = new Point(0,0);
		private var moveSpeed:Number = 100;
		private var _lastServerPosition:Point = null;		
			
		public var isLeaving:Boolean = false;
		public var isTransition:Boolean = false;			
		
		///--- Pickable
		
		public function getPickedUpBy():ICarrier{
			return pickedUpBy;
		}
		
		public function shouldBeInFront():Boolean{
			if (angle>= 180 && angle < 360){					
				return false;
			}
			return true;	
		}
		
		public var pickedUpActor:BaseActor;
		public var pickedUpBy:BaseActor = null;
		private var _pickedUpById:String = null;
		
		public var isKtfo:Boolean = false;
		
		private var endMoveAngle:int = 0;
		private var setEndAngle:Boolean = false;
		
		public var isLinkDead:Boolean = false;
				
		private var lastFrame:int = -1;	
		// animation states
		private var isWalking:Boolean = false;		
		private var isClientMove:Boolean = false;		
		private var mcWaterAnim:MovieClip;
		private var mcWaterAnimPlaceholder:Sprite = new Sprite();
		private var waterAnimAttached:Boolean = false;		
		
		private var statusEffect:StatusEffect;
						
		//--- Parent actor for latching (boss monster)
		private var parentActorId:String;
		private var parentOffset:Point;
		
		//--- Buffs
		private var _buffs:Object = new Object();
		
		//--- Timer to update Actor when missing info (like URL)
		private var updateTime:int = 2000;
		
		public var ownerId:String;
		
		public var actor_width:Number;
		public var actor_height:Number;
		
		private var paperDollInfoObj:Object = null;
				
		private var _aids:Array = new Array();
		private var displayName:Boolean = true;		
		private var displayStamina:Boolean = true;
		private var displayInCrewState:Boolean = true;		
		private var displayHp:Boolean = true;
		private var displayHpBar:Boolean = true;
		
		private var _redraw:Boolean = true;

		private var _gateway:BattleGateway = null;
		private var _uiFramework:IUIFramework = null;	
		private var _baseUrl:String = null;
		private var _fileVersionManager:IFileVersionManager = null;
							
		private var _isDisposed:Boolean = false; // It looks like an onEnterFrame event is firing elsewhere that causes our dispose() to be called,
												 // and that same event is then causing our enterFrame event handler to get called, but since our
												 // dispose was called first, we're in a bad state.  So we can use this as a guard.
												 
		private var _ignoreList:Array = new Array();
		
		public var allowUserMove:Boolean = true;
		private var _allowUsableUse:Boolean = true; 
		public var wordFilterLevel:Number = NaN;
		
		private var _ringMaxLevel:Number = 2;
		private var _totalOrbs:Orbs = new Orbs(0,0);
		public var clanId:String;
		public var clanName:String;
		private var _linkManager:ILinkManager = null;
		
		private var _ghiBuffsUpdater:GhiBuffsUpdater = null;
		
		public var timeTillOrbSwap:int = 0;
		
		private var _mapActorPositionAdjuster:MapActorPositionAdjuster = null;
		
		private var _monsterLoadManager:MonsterLoadManager = null;

		public function BaseActor(gateway:BattleGateway, uiFramework:IUIFramework, fileVersionManager:IFileVersionManager, linkManager:ILinkManager, mapActorPositionAdjuster:MapActorPositionAdjuster, id:String=null, name:String = null, url:String = null, display:String = "none", actorType:ActorTypes = null, aids:Array = null, ownerId:String = null, monsterLoadManager:MonsterLoadManager = null, scaleXY:Number = 1){
			if (actorType == null) {
				actorType = ActorTypes.PLAYER;
			}
			
			_mapActorPositionAdjuster = mapActorPositionAdjuster;
			
			this._gateway = gateway;
			this._uiFramework = uiFramework;
			this._baseUrl = linkManager.baseURL;
			this._fileVersionManager = fileVersionManager;
			this._linkManager = linkManager;
			this._monsterLoadManager = monsterLoadManager;
			
			if (display == "avatarMonster"){
				this.isMonsterAvatar = true;
				this.displayType = "monster";
			}else{
				this.displayType = display;
			}
			this.actorType = actorType;
							
			this.statusEffect = new StatusEffect(this);
									
			this._actorId = id;

			me = ActorManager.getInstance().isMyActor(actorId);			
			this.url = url;

			if (name == null || name.length <= 0){
				this.actorName = this._actorId;
			}else{	
				this.actorName = name;
			}
			
			this.ownerId = ownerId;
						
			this.updateAids(aids);		
						
			init();	
								
		}
		
		public function set allowUsableUse(value:Boolean):void{
			_allowUsableUse = value;
		}
		
		public function get allowUsableUse():Boolean{
			return (this._allowUsableUse && !isKtfo);
		}

		public function set ignoreList(arr:Array):void{
			if(arr != _ignoreList)
			{
				_ignoreList = arr;
				dispatchEvent(new BaseActorEvent(BaseActorEvent.IGNORE_LIST_CHANGED, this));
			}
		}
		public function get ignoreList():Array{
			return _ignoreList;
		}
		
		public function get actorId():String{
			return _actorId;
		}
		
		private function attachWaterAnim():void
		{
			if(!waterAnimAttached && this.mcWaterAnimPlaceholder && this.mcWaterAnim) {
				var position:int = this.getChildIndex(this.mcWaterAnimPlaceholder);
				this.addChildAt(this.mcWaterAnim, position);
				this.mcWaterAnim.play();
				this.waterAnimAttached = true;
			}
		}
		private function detachWaterAnim():void
		{
			if(waterAnimAttached && this.mcWaterAnim) {
				this.removeChild(this.mcWaterAnim);
				this.mcWaterAnim.stop();
				this.waterAnimAttached = false;
			}
		}
		
		private var hpBarAttacher:DisplayObjectAttacher = null;
		private function setHPBarVisible(visible:Boolean):void {
			if (this.actorType == ActorTypes.NPC){
				if (visible){
					this.hpBar.alpha = 1;
				}else{
					this.hpBar.alpha = 0.4;
				}
				visible = true;				
			}
			if (this.hpBarAttacher == null) {
				this.hpBarAttacher= new DisplayObjectAttacher(this.hpBar, this);
			}
			this.hpBarAttacher.attached = visible;						
		}
		
		private function getNewWaterAnim():MovieClip
		{
			var waterAnim:MovieClip = this._uiFramework.assetFactory.getInstance("WaterAnim") as MovieClip;
			waterAnim.alpha = 0.3;
			waterAnim.stop();
			return waterAnim;
		}
		
		private var _frameTimer:FrameTimer = new FrameTimer(onUpdateTimer);
		private var _actorUpdateTimer:FrameTimer = new FrameTimer(onActorUpdateTimer);
		private var _frameMovement:FrameTimer = new FrameTimer(onMovementEnterFrame);
		private function init():void{
			this._isDisposed = false;
			
			//-- WaterWaveAnim
			this.mcWaterAnim = getNewWaterAnim();
			this.mcWaterAnim.stop();
			this.addChild(this.mcWaterAnimPlaceholder);						
			if (this.url == null || this.url == "undefined"){
				this._frameTimer.start(this.updateTime, 1);
			}
			
			// create actor display ------------------------------------
			switch (this.displayType){
				case "avatar":
					if (this.url != null){
						this.url = this.url.replace(/(_flip|_strip)?.png/, "_strip.png");					
					}
					this.actorDisplay = new AvatarDisplay(this._uiFramework.assetFactory, this._baseUrl, this._actorId);
					if (this.actorDisplay.getActorBtn() != null){
						this.hitArea = this.actorDisplay.getActorBtn();
					}
					break;
				case "monster":
					//**** Load Version Neded ***
					if (this.url != null){				
						var vUrl:String = "v?=" + this._fileVersionManager.getClientVersion("monsters/" + this.url + ".swf");
						this.url = this._baseUrl + "monsters/" + this.url + ".swf?"+vUrl;								
					}					
					this.actorDisplay = new MonsterDisplay(this._uiFramework.assetFactory, this._baseUrl, this._actorId, this._monsterLoadManager);
					break;
					
				/*
				case "env":
					//this.url ="SwitchTest"// this.url;
					this.actorDisplay = new EnvDisplay(this._actorAssets);
					break;
				*/
				
				case "Spawner":
					this.url = "none"
					this.actorDisplay = new SpawnDisplay(this._uiFramework.assetFactory);
					break;
			}
						
			this.actorDisplay.addEventListener(ActorDisplay.LOADED, onActorDisplayLoaded, false, 0, true)
			this.actorDisplay.loadActor(this._gateway, this._uiFramework, this.url);
			this.addChild(this.actorDisplay);
			this.actor_width = this.actorDisplay.width; 
			this.actor_height = this.actorDisplay.height;
			
			// hp bar ------------------------------------------------
			this.hpBar = this._uiFramework.assetFactory.getInstance("HpBar");

			this.hpBar.init(this._actorId);
			this.hpBar.y = 10;
			this.hpBar.setName(this.actorName);
			this.hpBar.setMaxHp(this.maxHp);
			this.hpBar.setMaxExhaustion(this.maxExhaustion);
			this.hpBar.setHp(this.hp);
			
			this.hpBar.setExhaustion(this.exhaustion); 
			
			this.setHPBarVisible(false);			
			this.hpBar.setDisplay(this.displayName, this.displayStamina, this.displayHp, this.displayInCrewState);	
			
			// listeners				
			this._frameMovement.startPerFrame();
			this._actorUpdateTimer.startPerFrame();
			
			this.actorDisplay.addEventListener(MouseEvent.MOUSE_OVER, onMouseOver, false, 0, true);
			this.actorDisplay.addEventListener(MouseEvent.MOUSE_OUT, onMouseOut, false, 0, true);

			this.actorDisplay.addEventListener(ActorDisplay.TRANS_DONE, onTransitionDone, false, 0, true);	
			
			if(me){
				GlobalEvent.eventDispatcher.addEventListener(GlobalEvent.TIME_TILL_ORB_SWAP, onTimeTillOrbSwap, false, 0, true);
			}
							
		}
		
		private function onTimeTillOrbSwap(evt:GlobalEvent):void{
			this.timeTillOrbSwap = evt.data as int;
		}
		
		
		private function onActorDisplayLoaded(evt:Event):void{
			this.statusEffect.refresh();
		}
				
		//------- Movement
		public function move(pos:Point, targetX:Number, targetY:Number, lag:Number =0, isClientMove:Boolean = false):void
		{					
			if (this.isLeaving){
				return;
			}
			this.isClientMove = isClientMove;
			this._lastServerPosition = pos;
								
			if (!this.isSitting || !isClientMove){				
				this.targetPos.x = targetX;
				this.targetPos.y = targetY;
			}
			else
			{
				this.targetPos.x = this.position.x;
				this.targetPos.y = this.position.y;
			}			
		}
		
		public function setPosition(x:Number, y:Number):void{			
			this.position.x = x;
			this.position.y = y;
			this.targetPos.x = x;
			this.targetPos.y = y;
			this.isWalking = false;
			if (!this.isSitting){							
				stand();
			}
			this.updateMcPosition();
		}
		public function stopMove():void{
			var p:Point = this.position;
			this.move(p, this.position.x, this.position.y);
			this.isWalking = false;		
			if (!this.isSitting) {
				stand();
			}
		}
		public function setDirection(targetPos:Point):void{
			var dx:Number = targetPos.x - this.position.x;
			var dy:Number = targetPos.y - this.position.y;
			var dist:Number = Math.sqrt(dx*dx + dy*dy);
			var angle:Number = Math.atan2(dy, dx);		
			
			this.setAngle(angle * 180/Math.PI);
			
			this.updateMcPosition();			
		}

		private var _angleValid:Boolean = true;				
		private function setAngle(angle:Number):void{
			if (angle < 0 ){
				angle = 360 + angle;
			}else if (angle > 360){
				angle = angle - (Math.floor(angle/360)*360);
			}		

			if (this.angle != angle) {			
				this.angle = angle;			
				this._angleValid = false;
				
				//[Fred] Cant dealy the redray cause the setDirection will get dealy 
				//and the ring animatoin  will not be facing in the right direction  up/down
				// so we need to call redrawMcPos and not updateMcPosition
				
				//this.updateMcPosition();
				redrawMcPos();
			}
		}

		public function sit(tellServer:Boolean):void{
			if (!this.isSitting) {
				if (tellServer) {
					var p:Point = this.position;
					this.move(p, this.position.x, this.position.y);
				}
				this.isWalking = false;
				this.actorDisplay.playAnim("sit");

				commitPoseChange(true);
			}
		}
		
		public function stand():void{
			this.actorDisplay.playAnim("idle");
			if (this.isSitting) {
				commitPoseChange(false);
			}									
		}
		private function commitPoseChange(sitting:Boolean):void
		{			
			this.isSitting = sitting;
			if (me) {				
				GlobalEvent.eventDispatcher.dispatchEvent(new GlobalEvent(GlobalEvent.POSE_CHANGE, {sit: isSitting}));
			}
		}
		private function onMovementEnterFrame():void
		{
			if (this._isDisposed) {
				return;
			}			
						
			var updatePos:Boolean = true;
			
			this.lastPos.x = this.position.x;
			this.lastPos.y = this.position.y; 
			
			const now:int = getTimer();
			if (this.lastFrame < 0){
				this.lastFrame = now;
			}
			const dt:int = now - this.lastFrame;
			this.lastFrame = now;	

			var parentLookup:Object =  ActorManager.actorIdToActor(this.parentActorId);
			if (this.parentActorId != null &&  parentLookup != null){
				var pa:BaseActor = BaseActor(parentLookup);
				this.position.x = pa.position.x + this.parentOffset.x;
				this.position.y = pa.position.y + this.parentOffset.y;
				this.setAngle(pa.angle);
				this.updateMcPosition();
				this.checkRedraw();				
				return;
			}
					
			// if Knock Back/Quickmove --- 
			if (this.isQm){				
				if (this.qmStartTime < 0){
					this.qmStartTime = getTimer();
				}
				
				var currentTime:int = getTimer() - this.qmStartTime;
				
				var qmObj2:Object = this.actorDisplay.onQuickMove(this.qmType, currentTime, this.qmTime);		
				var moveSt:Number = qmObj2.startFrame * (1000/16);
				var moveEt:Number = this.qmTime - qmObj2.frameFromEnd * (1000/16);
				var moveTime:Number = moveEt - moveSt;
							
						
				var qmTarget:Point = this.qmPoints[this.qmPointIndex];
				if (currentTime >= moveSt && currentTime <= moveEt){						
					var qmdx:Number = qmTarget.x - this.position.x;
					var qmdy:Number = qmTarget.y - this.position.y;
					var qmDist:Number = Math.sqrt(qmdx*qmdx + qmdy*qmdy);
					var qmAngle:Number = Math.atan2(qmdy, qmdx);
					var moveSpeed:Number = (this.qmTotalDist/ moveTime ) * dt;
					var qmvx:Number = Math.cos(qmAngle) * moveSpeed;
					var qmvy:Number = Math.sin(qmAngle) * moveSpeed;
									
					if (qmDist >= moveSpeed){
						this.position.x += qmvx;
						this.position.y += qmvy;
					}else{
						this.position.x = this.targetPos.x = qmTarget.x;
						this.position.y = this.targetPos.y = qmTarget.y;
					}	
				}else if (currentTime >= this.qmTime){					
					this.isQm = false;
					this.qmStartTime = -1;
					this.position.x = this.qmPoints[this.qmPoints.length-1].x;
					this.position.y = this.qmPoints[this.qmPoints.length-1].y;
					this.actorDisplay.onQuickMove(this.qmType, this.qmTime, this.qmTime);					
				}
				
				if (this.isQm && this.position.x == qmTarget.x && this.position.y == qmTarget.y){					
					if (this.qmPointIndex < this.qmPoints.length-1){
						this.qmPointIndex += 1;
					}			
				}
				
				this.updateMcPosition();
				this.checkRedraw();		
				return;
				
													
			}else {	// Regular Move
				if (!this.isSitting && this._lastServerPosition)
				{																						
					const sdist:Number = BattleUtils.distanceBetweenPoints(this.targetPos, this._lastServerPosition);
					this._lastServerPosition = null;

					// server travel time -  lag						
					const time:Number = Math.max((sdist/this.serverSpeed) - (this._lag/1000), 0.000001);  // prevent div 0
					
					// client distance to travel
					const cdist:Number = BattleUtils.distanceBetweenPoints(this.targetPos, this.position);

					// client true speed
					this.moveSpeed = Math.min(cdist/time, this.serverSpeed * 6);
					}
					
				const speed:Number = this.moveSpeed * (dt/1000);		
				if (!this.isSitting)
				{
					// [kja] check svn for commented-out code that sets the base actor angle when sitting.  It's pretty much identical to the angle code below :/							
					if (this.position.x != this.targetPos.x || this.position.y != this.targetPos.y)
					{						
						if (this.position.x > this.targetPos.x + speed || this.position.x < this.targetPos.x - speed ||
							this.position.y > this.targetPos.y + speed || this.position.y < this.targetPos.y - speed )
						{							
							const dx:Number = this.targetPos.x - this.position.x;
							const dy:Number = this.targetPos.y - this.position.y;
							const dist:Number = Math.sqrt(dx*dx + dy*dy);
							const angle:Number = Math.atan2(dy, dx);				
			
							const vx:Number = Math.cos(angle) * speed;
							const vy:Number = Math.sin(angle) * speed;
							
							this.position.x += vx;
							this.position.y += vy;					

							this.setAngle(angle * 180/Math.PI);			
							
							if (!this.isWalking){						
								this.isWalking = true;
								this.actorDisplay.playAnim("walk");		
							}
						}else{												
							this.position.x = this.targetPos.x;
							this.position.y = this.targetPos.y;
							if (this.isWalking){
								this.isWalking = false;	
								stand();							
							}
							if (this.setEndAngle){
								this.setEndAngle = false;
								this.setAngle(this.endMoveAngle);
							}
						}				
							this.updateMcPosition();	
						}			
					else						
					{ /// you are now at the target
						if (this.isLeaving && !this.isTransition)
						{			
							updatePos = false
							if (this.displayType != "monster" || this.hp > 0){				
								this.dispatchEvent(new Event(ACTOR_GONE));
							}
						}
						if (this.isWalking){			
							this.isWalking = false;
							this.stand();							
						}
					}	
				}
			}

			if (this.pickedUpActor) {
				this.pickedUpActor.position = this.position.clone();				
				this.pickedUpActor.lastPos = this.position.clone();
			}
			checkRedraw();			
		}

		private function checkRedraw():void {
			if (this._redraw){
				this.redrawMcPos();
				this._redraw = false;
			}
		}			

		
		public  function updateMcPosition():void{
			this._redraw = true;			
		}

		//
		// We need this for the object when it first shows up		
		private var _cachedScale:Point = new Point(0, 0);
		public function get scale():Point { return _cachedScale }

		private static const ORIGIN:Point = new Point(0, 0);
		
		private var _scalingDirty:Boolean = false;
		public function get scalingDirty():Boolean{
			return _scalingDirty;
		}
		public function set scalingDirty(v:Boolean):void{
			this._scalingDirty = v;
		}

		public function redrawMcPos():void{
			if (this._isDisposed) {
				return;
			}	
						
			//_scalingDirty = false; //[Fred] this is now done in [MapRoom runObjectSilhouette]
						
			
			if (!this.pickedUpBy){
				
				
				var scale:Number = _mapActorPositionAdjuster.getScale();
				const tx:Number = _mapActorPositionAdjuster.adjustX(this.position.x);
				const ty:Number = _mapActorPositionAdjuster.adjustY(this.position.y);	
			
				if (this._uiFramework && this._uiFramework.map) { 
					if (!this.isClientMove || this._uiFramework.map.getColliionTypeAt(tx, ty) != CollisionMap.TYPE_WALL){	
						if (this.x != tx || this.y != ty){		
							this.x = tx;
							this.y = ty;
						}												
					}else{									
						this.position.x = this.lastPos.x;
						this.position.y = this.lastPos.y;
						this.stopMove();						
					}					
				}

				if (this.pickedUpActor) {
					this.pickedUpActor.x = this.x;					
					this.pickedUpActor.y = this.y - 20;
					if (this.pickedUpActor.actorDisplay) {
						this.pickedUpActor.actorDisplay.scaleX = this._cachedScale.x;
						this.pickedUpActor.actorDisplay.scaleY = this._cachedScale.y;
					}
				}

				if (!this._angleValid) {				
					if (this.actorDisplay != null){
						this.actorDisplay.setDirection(angle);
					}
					
					if (this.pickedUpActor != null){				
						if (pickedUpActor.actorDisplay) {				
							this.pickedUpActor.actorDisplay.setDirection(angle);				
						}				
					}
					this._angleValid = true;
				}

				const oldScaleX:Number = this.actorDisplay ? this.actorDisplay.scaleX : NaN;
				const oldScaleY:Number = this.actorDisplay ? this.actorDisplay.scaleY : NaN;
				if (!isNaN(oldScaleY) && oldScaleY != scale){	
					_scalingDirty = true;
					this._cachedScale.y = scale;												
				}
				if (!isNaN(oldScaleX) && this.actorDisplay && oldScaleX != (scale * this.actorDisplay.hScale)){
					_scalingDirty = true;																		
					this._cachedScale.x = scale * this.actorDisplay.hScale;
				}
			}
			
			if (!isNaN(this._cachedScale.x) && !isNaN(this._cachedScale.y)) {
				if (scalingDirty && this.actorDisplay)
				{
					this.actorDisplay.scaleX = this._cachedScale.x;
					this.actorDisplay.scaleY = this._cachedScale.y;
				}
				dispatchEvent(new ActorMoveEvent(ActorMoveEvent.MOVE, this, scalingDirty, this._cachedScale.x, this._cachedScale.y));
			}
			
			/*
			////---------- Perspective 	--- to scale avatar base on y position and perspective factor .. not fully inmplemented yet
			var perspectiveFactor:Number = 1;	
			if (perspectiveFactor != 0){	
				var yPer:Number = (this.position.y * this.scale.y)/505;						
				this.actorDisplay.scaleX *= (yPer * perspectiveFactor) + (1-perspectiveFactor);
				this.actorDisplay.scaleY *= (yPer * perspectiveFactor) + (1-perspectiveFactor);
			}	
			*/
			/* ---------  for x speed wityh perspective (buggy would need more twiick for mouse and collision data)
			var xp:Number = (this.position.x * Math.abs(this.scale.x)) - (780/2);
			var nx:Number = ((1-yPer) * perspectiveFactor) * xp;
			//trace(Math.round(this.position.x), tx, this.x, Math.round(xp), Math.round(nx), Math.round(tx - nx));
			this.x = Math.round(this.x - nx);
			*/
			//-----------------
			
		}
		
		public function setWaterDepth(depth:Number):void{
			//depth
			this.setZPos(depth * 120 )	
			if (pickedUpActor !=null) {
				this.pickedUpActor.setZPos(depth * 120);
			}
		}
		
		public function get depthEnabled():Boolean{
			return true;
		}
		
		public function get zpos():Number{
			return actorDisplay.zpos;
		}
		
		public function setZPos(z:Number):void{
			if (this.actorDisplay != null){
				this.actorDisplay.zpos = z;
			}
			if (z > 0){
				attachWaterAnim();				
			}else{
				detachWaterAnim();			
			}
			
		}		
		
		public function get instanceId():String {
			return _instanceId;
		}
		private function setInstanceId(id:String):void
		{
			if(_instanceId != id)
			{
				_instanceId = id;
				GlobalEvent.eventDispatcher.dispatchEvent(new GlobalEvent(GlobalEvent.INSTANCE_CHANGED_FOR_ACTOR, {instanceId:this._instanceId, roomId:this._roomId, actor:this}));
			}
		}
		
		//--- Transition ------------
		public function playTransition(frame:String):void{
			
			if (this.actorDisplay != null && !this.isTransition){
				this.actorDisplay.playTransition(frame);
				this.isTransition = true;
			}
			
		}
		
		private var _warpInFrame:String;
		private var _warpTarget:Point = new Point();	
		public function playWarpAnimations(outFrame:String, inFrame:String, x:Number, y:Number):void{
			this._warpInFrame = inFrame;
			this._warpTarget.x = x;
			this._warpTarget.y = y;
			this.stopMove();
			this.playTransition(outFrame);
		}
		
		public function playEffectAnim(effectId:String, type:String = "effect", playEffectStartAnim:Boolean = true):RingAnim{
			if (this.actorDisplay != null){
				return this.actorDisplay.playEffectAnim(effectId, type, playEffectStartAnim);
			}else{
				return null;
			}	
		}
		
		private function onTransitionDone(evt:Event):void{
			this.isTransition = false;
			if (this.isLeaving){	
				this.dispatchEvent(new Event(ACTOR_GONE));
			}else if (this._warpInFrame != null && !isNaN(this._warpTarget.x)){
				this.setPosition(this._warpTarget.x, this._warpTarget.y);
				var tempWarpInFrame:String = this._warpInFrame;
				this._warpTarget.x = NaN;
				this._warpTarget.y = NaN;
				this._warpInFrame = null;
				this.playTransition(tempWarpInFrame);
			}			
		}
		public function setAnimPriority():void{
			this.actorDisplay.setAnimPriority();
		}

// Mouse Event 
		static private const RETICLEWORTHY:int = TARGETTYPE_FRIEND | TARGETTYPE_ENEMY | TARGETTYPE_SELF | TARGETTYPE_POWERUSABLE;
		private function onMouseOver(evt:MouseEvent):void{			
			//--- reticle
			if (this.actorDisplay != null && ((this.targetType | RETICLEWORTHY) != 0) && !this.isLeaving){
				this.actorDisplay.setReticle(this.targetType, this.isTarget);		
			}
			
			//--- hpBar
			if (!this.isLeaving && !this.isTarget){
				this.setHPBarVisible(this.displayHpBar);				
				this.hpBar.alpha = 0.4;
			}
			if (!this.isLeaving){	
				GlobalEvent.eventDispatcher.dispatchEvent(new GlobalEvent(GlobalEvent.MOUSE_OVER_STATE_CHANGED, {actorTarget:this.targetType}));			
			}		
		}
		
		
		private function onMouseOut(evt:MouseEvent):void{
			GlobalEvent.eventDispatcher.dispatchEvent(new GlobalEvent(GlobalEvent.MOUSE_OVER_STATE_CHANGED, {actorTarget:0}));									
			if (!this.isTarget && this.actorDisplay != null){
				this.actorDisplay.clearReticle();
				this.setHPBarVisible(false);				
			}						
		}
				
		// --- hitAnim
		private function playHitNum(hp:Number, type:int):void{
			var per:Number = hp/this.maxHp;			
			this.actorDisplay.playHitNum(hp, type);
		}
		public function playOutOfRange():void{
			this.actorDisplay.playOutOfRange();		
		}
		public function playInvalidTarget():void{
			this.actorDisplay.playInvalidTarget();
		}
		public function playMiss():void{
			this.actorDisplay.playMiss();
		}
		public function playResists():void{
			this.actorDisplay.playResists();
		}		
		public function playReflects():void{
			this.actorDisplay.playReflects();
		} 
		public function playDeflects():void{
			this.actorDisplay.playDeflects();
		} 
		
		public function updateGoldLootDisplay(gold:int = 0):void{
			this.actorDisplay.updateGoldLootDisplay(gold);
		}
		
		// RingAnimation
		public function playRingAnimation(ringId:String, rage:int, type:String, targetActor:Object = null, speed:Number = -1):RingAnim{				
			var ra:RingAnim;			
			if (this.actorDisplay != null){								
				ra = this.actorDisplay.playRingAnim(ringId, rage, type, targetActor, speed);					
			}
			return ra;
		}		
		
		public function playAttack(atk:int, targetActor:Object= null, speed:Number = -1):void{
		
			var param:Object = new Object();
			param.target = targetActor;
			param.speed = speed;							
			this.actorDisplay.playAnim("atk"+String(atk), param);			
		}		
				
		//-- monster spawn anim
		public function playSpawnAnimation():void{
			this.actorDisplay.playAnim("spawn");
		}
		
		// Monster Death Animation
		public function death():void{
			if (this.actorType == ActorTypes.MONSTER && !this.isLeaving && this.actorDisplay != null){
				this.actorDisplay.addEventListener("MonsterDeath", onMonsterDeath, false, 0, true);
				this.isQm = false;
				this.move(position, position.x, position.y, 0);
				this.actorDisplay.playAnim("die");
				this.clearTarget();
				this.isLeaving = true;
				GlobalEvent.eventDispatcher.dispatchEvent(new GlobalEvent(GlobalEvent.MOUSE_OVER_STATE_CHANGED, {actorTarget:0}));													
			}
		}
		public function onMonsterDeath(evt:Event):void{
			displaySilhouette = false;
			this.actorDisplay.removeEventListener("MonsterDeath", onMonsterDeath);
			this.dispatchEvent(new Event(ACTOR_GONE));
		}
		
		private var _visible:Boolean = true;
		override public function set visible(value:Boolean):void {
			if (value != this._visible) {
				this._visible = value;
				this._visibilityValid = !this._visibilityValid;
			}			
		}
		
		private var _targetSetValid:Boolean = true;				
		private var _visibilityValid:Boolean = true;		
		private var _inCrewStateValid:Boolean = true;
		//private var _ringLevelCapValid:Boolean = true;
		private var _suppressedCLValid:Boolean = true;
		private var _conLevelValid:Boolean = true;		
		private var _buffsValid:Boolean = true;
		private var _hpValid:Boolean = true;
		private var _nameValid:Boolean = false;
		private var _hpColorValid:Boolean = true;
		private var _userLevelValid:Boolean = true;
		private var _exhaustionValid:Boolean = true;	
		private var _ghiEnergyValid:Boolean = true;
		private var _rageValid:Boolean = true;	
		private var _pendingSitState:PendingSitState = new PendingSitState;
		private var _moveAngleValid:Boolean = true;
		private var _lookingForGroupValid:Boolean = true;
		private var _ringLockUpdateInfo:Array = null;
		private var _pickedUpByValid:Boolean = true;
		private var _instanceIdValid:Boolean = true;
		private var _roomIdValid:Boolean = true;
		
		private function onActorUpdateTimer():void {
			var globalEventDispatcher:IEventDispatcher = GlobalEvent.eventDispatcher;

			// visiblity is not really (or only) updated by the actor updates here; it could be affected from other places
			if (!this._targetSetValid) {
				this.validateTargetSetState();
				this._targetSetValid = true;						
			}
			
			// visiblity is not really (or only) updated by the actor updates here; it could be affected from other places
			if (!this._visibilityValid) {
				super.visible = this._visible;
				this._visibilityValid = true;
			}
			
			if (!this._inCrewStateValid) {
				globalEventDispatcher.dispatchEvent(new GlobalEvent(GlobalEvent.IN_CREW_STATE_UPDATE, { actor:this, _actorId:this._actorId, inCrewState:this.inCrewState}));
				this._inCrewStateValid = true;
			}

			
			if (!this._suppressedCLValid){
				//if (me){
					globalEventDispatcher.dispatchEvent(new GlobalEvent(GlobalEvent.SUPPRESSED_CL_CHANGE, this.suppressedCL));					
				//}
				this._suppressedCLValid = true;
			}
			

			if (!this._conLevelValid) {			
				this.dispatchEvent(new BaseActorEvent(BaseActorEvent.ACTOR_CON_LEVEL_UPDATED, this));
				//if (me){	
					globalEventDispatcher.dispatchEvent(new GlobalEvent(GlobalEvent.PLAYER_CON_LEVEL_UPDATED, this.conLevel));										
				//}
				this._conLevelValid = true;
			}

			if (!this._buffsValid) {				
				if (this.hasEventListener(BaseActorEvent.BUFFS_UPDATED)) {
					this.dispatchEvent(new BaseActorEvent(BaseActorEvent.BUFFS_UPDATED, this));
				}
				this._buffsValid = true;
			}

			if (!this._hpValid) {
				if (this.hpBar) {
					this.hpBar.setHp(this.hp);			
					this.hpBar.setMaxHp(this.maxHp);
					this.hpBar.setName(this.actorName);			
				}
	
				if (this.hp <= 0) {	
					this.death();
				}			
				
				if (this.hasEventListener(BaseActorEvent.HEALTH_UPDATED)) {
					this.dispatchEvent(new BaseActorEvent(BaseActorEvent.HEALTH_UPDATED, this));
				}
			
				this._hpValid = true;
			}
			
			if (!this._nameValid) {
				this.dispatchEvent(new BaseActorEvent(BaseActorEvent.NAME_UPDATED, this));
				this._nameValid = true;
			}
			
			if (!this._hpColorValid) {
				if (this._uiFramework.userLevelColors[this.gaiaUserLevel] != null){					
					var c:Number = Number("0x" + String(this._uiFramework.userLevelColors[this.gaiaUserLevel]).substr(1,6));
					if (!isNaN(c)){
						if (c <= 0){
							c = 0xFFFFFF;
						}
						this.hpBar.setNameColor(c);
					}					
				}
				this._hpColorValid = true;
			}

			if (!this._userLevelValid) {
				this.setUserLevel(this.gaiaUserLevel);
				this._userLevelValid = true;
			}
			
			if (!this._exhaustionValid) {
				if (this.hpBar) {
					this.hpBar.setExhaustion(this.exhaustion);
					this.hpBar.setMaxExhaustion(this.maxExhaustion);								
				}
				
				if (me){
					ringManager.enableDisableRings();
				}
				
				if (this.hasEventListener(BaseActorEvent.STAMINA_UPDATED)) {
					this.dispatchEvent(new BaseActorEvent(BaseActorEvent.STAMINA_UPDATED, this));
				}
				this._exhaustionValid = true;				
			}
			
			if (!this._ghiEnergyValid) {
				if (me){				
					this.dispatchEvent(new BaseActorEvent(BaseActorEvent.GHI_UPDATED, this));											
				}				
				this._ghiEnergyValid = true;
			}			

			if (!this._rageValid) {
				if (this.hasEventListener(BaseActorEvent.RAGE_UPDATED)) {
					this.dispatchEvent(new BaseActorEvent(BaseActorEvent.RAGE_UPDATED, this));
				}
				this._rageValid = true;
			}
			
			if (this._pendingSitState.dirty)
			{
				if (this._pendingSitState.sitting != this.isSitting)
				{
					if (this._pendingSitState.sitting) {	
						sit(false);					
					}else{			
						stand();
					}
				}
				this._pendingSitState.dirty = false;				
			}
			
			if (!this._lookingForGroupValid) {
				if (me){
					this.dispatchEvent(new BaseActorEvent(BaseActorEvent.LFG_UPDATED, this));																
				}
				
				this._lookingForGroupValid = true;
			}
			
			if (me && this._ringLockUpdateInfo != null) {
				var lockChanged:Boolean = false;	
				var len:uint = this._ringLockUpdateInfo.length;		
				for (var rn:uint = 0; rn < len; ++rn){					
					if (this._ringLockUpdateInfo[rn] == 0){
						if (ringManager.lockSlot(rn)) {
							lockChanged = true
						};
					}else{
						if (ringManager.unlockSlot(rn)) {
							lockChanged = true
						};
					}				
				}
				if (lockChanged){
					GlobalEvent.eventDispatcher.dispatchEvent(new GlobalEvent(GlobalEvent.PLAYER_LOCKED_SLOTS_CHANGED, ringManager.lockSlotCount()));
				}		
				
				this._ringLockUpdateInfo = null;
			}
			
			if (!this._moveAngleValid) {						
				if (this.targetPos.x == this.position.x && this.targetPos.y == this.position.y){					
					this.setAngle(this.endMoveAngle);
					this.setEndAngle = false;
				}else{		
					this.setEndAngle = true;
				}
				
				this._moveAngleValid = true;
			}

			if (!this._pickedUpByValid) {
				if (this._pickedUpById == "" && this.pickedUpBy) {
					this.pickedUpBy.dropActor();
				} else {
					this.tryToBePickedUp(this._pickedUpById);
				}
				
				this._pickedUpByValid = true;
			}
			if (!this._roomIdValid) {
				var currZoneName:String = MapFilesFactory.getInstance().mapFiles.getZoneNameFromRoomId(this._roomId); 
				if (this.zoneName != currZoneName) {
					this.zoneName = currZoneName;
					GlobalEvent.eventDispatcher.dispatchEvent(new GlobalEvent(GlobalEvent.TEAM_UPDATED, {}));
					this.dispatchEvent(new BaseActorEvent(BaseActorEvent.ZONE_CHANGED, this));																											
				}
				
				this._roomIdValid = true;
			}
			
			if (!this._instanceIdValid) {
				setInstanceId(this._instanceId);				
				this._instanceIdValid = true;
			}
		}
		
		private var _scaleXTween:Tween;
		private var _scaleYTween:Tween;
		private var _scaleSet:Boolean = false;
		
		//--- main update	
		private var paperDollProps:Array = ["spd", "conLevel", "mass", "dodge", "will", "healthRegen", "exhaustionRegen", "acc", "luck", "mhp", "ringLevelCap"];
		public function updateActor(obj:Object, lag:int = 0):void{
			this._lag = lag;
			
			if (obj.clanName != null){
				this.clanName = obj.clanName;
			}
			if (obj.clanID != null){
				this.clanId = obj.clanID;
			}
			
			if(obj.scale && obj.scale != this.scaleX)
			{
				if(!_scaleSet)
				{
					this.scaleX = this.scaleY = obj.scale || 1;
				}
				else
				{
					_scaleXTween = new Tween(this, "scaleX", Bounce.easeOut, this.scaleX, obj.scale || 1, 1, true);
					_scaleYTween = new Tween(this, "scaleY", Bounce.easeOut, this.scaleY, obj.scale || 1, 1, true);
				}
			}
			_scaleSet = true;
			
			var updatePaperDoll:Boolean = false;
			for (var prop:String in obj) {
				if (paperDollProps.indexOf(prop) != -1) {
					updatePaperDoll = true;
					break;
				}
			}
			
			var deltas:Object = obj.deltas;
			if (!updatePaperDoll && deltas != null) {
				for (prop in deltas) {
					var propValue:String = deltas[prop].stat;
					if (paperDollProps.indexOf( propValue ) != -1) {
						updatePaperDoll = true;
						break;					
					}
				}
			}
			
			
			var newInCrewState:String = obj.inCrewState;
			if (newInCrewState != null){
				if (this.inCrewState != newInCrewState) {
					this.inCrewState = newInCrewState;	
					this._inCrewStateValid = false;
					}
				}
						
			if (obj.url != null && this.url == null){
				this._frameTimer.stop();

				if (this.displayType == "avatar"){
					this.url = obj.url.replace(/(_flip|_strip)?.png/, "_strip.png");
					this.actorDisplay.loadActor(this._gateway, this._uiFramework, this.url);
				}else if (this.displayType == "monster"){
					var vUrl:String = "v?=" + this._fileVersionManager.getClientVersion("monsters/" + obj.url + ".swf");
					this.url = this._baseUrl + "monsters/" + this.url + ".swf?" + vUrl;
					this.actorDisplay.loadActor(this._gateway, this._uiFramework, this.url);
				}				
			}
									
			if (obj.suppressedCL){
				//trace(" === SuppressedCL update", obj.suppressedCL);				
				var nSCL:Number = Math.round(obj.suppressedCL * 10)/10;
				if (nSCL != this.suppressedCL){
					this.suppressedCL = nSCL;
					this._suppressedCLValid = false;
					//trace("NEW SuppressedCL ", this.suppressedCL, obj.suppressedCL)
				}				
			}

			
			if (obj.conLevel != null){
				//trace(" === ConLevel update", obj,conLevel);
				var newConLevel:Number = Math.round(obj.conLevel * 10)/10;
				if (newConLevel != this.conLevel) {
					this.conLevel = newConLevel;
					this._conLevelValid = false;
					//trace("NEW ConLevel ", this.conLevel, obj.conLevel)
				}
			}
			
			
			var newName:String = obj.nm;
			if (newName != null ){
				if (this.actorName != newName) {
					this.actorName = newName;
					this._hpValid = false;	
					this._nameValid = false;			
				}			
			}			
			
			if (obj.gaiaUserLevel != null) {
				if (obj.gaiaUserLevel != this.gaiaUserLevel){							
					this.gaiaUserLevel = obj.gaiaUserLevel;
					this._hpColorValid = false;	
					this._userLevelValid = false;			
				}				
			}
			
			if (obj.mhp != null){
				var newMaxHp:Number = parseInt(obj.mhp);
				if (newMaxHp != this.maxHp) { 
					this.maxHp = newMaxHp;
					this._hpValid = false;
				}
			}			
			
			if (obj.hp != null){		
				var newHp:Number = parseInt(obj.hp);

				if (this.hp != newHp) { 
					this.hp = Math.max(0, newHp);					
					this._hpValid = false;
				}																
			}

			if (obj.state != null){		
				this.actorDisplay.setState(obj.state);
			}else if(this.isMonsterAvatar){
				this.actorDisplay.setState(0);
			}
						
			if (obj.deltas != null){							
				for(var d:int = 0; d < obj.deltas.length; d++){
					this.updateDeltas(obj.deltas[d]);
				}
			}
			
			var newStatusLabels:Array = obj.statusLabels;
			if (obj.statusLabels != null){						
				this.updateStatus(obj.statusLabels);	
				}
			
			if (obj.statusAnim != null){				
				for (var animationId:String in obj.statusAnim){					
					if (obj.statusAnim[animationId]){									
						this.statusEffect.playStatus(animationId, obj.url == null);
					}else{				
						this.statusEffect.stopStatus(animationId);
					}					
				}
			}
						
			var newRoomName:String = obj.roomName;
			if (newRoomName != null){
				if (this._roomId != newRoomName){					
					this._roomId = newRoomName;
					this._roomIdValid = false;

					if (!this.isTransition){
						var myActor:BaseActor = ActorManager.getInstance().myActor;	
						if (myActor == null || this._roomId == myActor.roomId){
						this.isLeaving = false;
						}
						// set position already defers drawing until the frame boundary
						this.setPosition(obj.px, obj.py);										
					}
					
					var filtersName:Array = MapFilesFactory.getInstance().mapFiles.getActorFilters(this._roomId);
					this.setActorFilters(filtersName);	
				}											
			}
			
			var newInstanceId:String = obj.instanceId;
			if (newInstanceId != null) {
				if (newInstanceId != this._instanceId) {
					this._instanceId = newInstanceId;
					this._instanceIdValid = false;
			}
				}			

			if(obj.spd !=null){				
				this.serverSpeed = parseInt(obj.spd);				
			}
						
			if (obj.radius != null){				
				this.radius = obj.radius;
				//trace(this.actorName, "Radius :", this.radius);
			}
			if (obj.range != null){				
				this.range = obj.range;
				//trace(this.actorName, "Range :", this.range);
			}	
			
			if (obj.exhaustion != null){
				var newExhaustion:Number = obj.exhaustion;
				if (this.exhaustion != newExhaustion) {
					this.exhaustion = obj.exhaustion;
					this._exhaustionValid = false;				
						}
					}					
				
			if (obj.maxexh != null){
				var newMaxStamina:Number = obj.maxexh;
				if (newMaxStamina != this.maxExhaustion) {
					this.maxExhaustion = obj.maxexh;
					this._exhaustionValid = false;
			}
				}

			if (obj.ghiEnergy != null){
				var newGhiEnergy:Number = obj.ghiEnergy;
				if (newGhiEnergy != this.ghiEnergy) {
					this.ghiEnergy = newGhiEnergy;
					this._ghiEnergyValid = false;
				}
			}


			if (obj.ghiProgress != null){
				this.ghiProgress = obj.ghiProgress;								
			}
			
			if (obj.tp != null){
				this.actorType = ActorTypes.intToType(obj.tp);
			}			

			if (obj.rag != null){
				var newRage:Number = obj.rag;
				if (newRage != this.rage) {
					this.rage = obj.rag;
					this._rageValid = false;
				}
			}
			
			if (obj.pse != null){				
				this._pendingSitState.sitting = obj.pse;
				this._pendingSitState.dirty = true;								
			}				
			
			if (obj.aggro != null){
				this.aggro = obj.aggro;
				this.actorDisplay.setAggro(this.aggro);
			}

			if(obj.px != null && obj.py != null && obj.dx != null && obj.dy != null){							
				this.move(new Point(obj.px, obj.py), obj.dx, obj.dy, this._lag, false); 				
			}		
			
			if (obj.rotation != null){				
				var newEndMoveAngle:int = obj.rotation;
				if (newEndMoveAngle != this.endMoveAngle) {
					this.endMoveAngle = newEndMoveAngle;					
					this._moveAngleValid = false;
				}
			}	
					
			if (obj.lookingForGroup != null){
				var newLookingForGroup:Boolean = obj.lookingForGroup;
				if (this.isLfg != newLookingForGroup) {
					this.isLfg = newLookingForGroup;
					this._lookingForGroupValid = !this._lookingForGroupValid;
				}
			}
			
			if (obj.movementParent != null){								
				if (obj.movementParent.actorID == null){
					this.parentActorId = null;
					this.parentOffset = null;
					}else{
					this.parentActorId = obj.movementParent.actorID;
					if (this.parentOffset == null){
						this.parentOffset = new Point(obj.movementParent.offsetX, obj.movementParent.offsetY);
					}else{
					this.parentOffset.x = obj.movementParent.offsetX;
					this.parentOffset.y = obj.movementParent.offsetY;
					}				
				}
				}
						
			//--- Update RingLock
			if (me && obj.ringSlot != null && obj.ringSlot.length > 0){
				this._ringLockUpdateInfo = obj.ringSlot;
				}		
			
			if (obj.aids != null){
				this.updateAids(obj.aids);
			}	
			
			if (obj.hitCount != undefined && this.actorType == ActorTypes.GOOFBALL){
				this.hitCount = obj.hitCount;
				this.actorDisplay.showHitCountNum(this.hitCount);
			}
						
			if (obj.targetCycle != null){
				this.targetCycle = obj.targetCycle;
			}
			
			updateSubscribedProperties(obj);
			
			if (updatePaperDoll) {
				this.dispatchEvent(new Event(PAPER_DOLL_STATS_UPDATED));
			}

			var newAttachToId:String = obj.attachTo;
			if (newAttachToId != null) {
				if (newAttachToId != this._pickedUpById) {
					this._pickedUpById = newAttachToId;
					this._pickedUpByValid = false;					
				}
			}
		}
		
		
		static public var pickUpArtists:Object = new Object();
		public function tryToBePickedUp(pickedUpById:String):void {
			delete BaseActor.pickUpArtists[pickedUpById];
						
			if (this.pickedUpBy && (pickedUpBy.actorId != pickedUpById)) {
				this.pickedUpBy.dropActor();
			}
			if (!this.pickedUpBy) {
				this.pickedUpBy = ActorManager.actorIdToActor(pickedUpById);
				if (this.pickedUpBy) {
					this.pickedUpBy.pickUpActor(this);
				} else {
					BaseActor.pickUpArtists[pickedUpById] = this; 
				}
			}
		}
		
		
		static private const DEFAULT_USER_LEVEL:uint = 8;
		static private const DEV_USER_LEVEL:uint = 150;		
		public function setUserLevel(level:int, force:Boolean = false):void {
			if (this.userLevel != level || force) {
				// special handling for the current player
				if (ActorManager.getInstance().myActor != null && me){
					const bGuestRegistered:Boolean = this.userLevel < DEFAULT_USER_LEVEL && level >= DEFAULT_USER_LEVEL;
		
					this.userLevel = level;
					GlobalEvent.eventDispatcher.dispatchEvent(new GlobalEvent(GlobalEvent.USER_LEVEL_SET, { _actorId:this._actorId, isGuest:this.isGuestUser(), isDev:this.isDev(), guestRegistered: bGuestRegistered }));

					if (flash.external.ExternalInterface.available) {
						try {
			  				ExternalInterface.call("setIsGuest", isGuestUser());
			  			}
			  			catch(error: Error)
			  			{
			  				trace("Err: ", error.message);
			  			}			
					}
				} else {
					this.userLevel = level;
				}
			}
		}			
		
		public function isGuestUser():Boolean {
			return this.userLevel < DEFAULT_USER_LEVEL;
		}
		
		public function isDev():Boolean {
			return this.userLevel >= DEV_USER_LEVEL;
		}
		
		private function get expireSubscribedProperties():Boolean
		{
			return !ActorManager.getInstance().isMyActor(actorId);
		}
		public function setPaperDollSubscription(subscribe:Boolean):void
		{
			if (subscribe)
			{
				if (expireSubscribedProperties || !this.subscribedProperties)
				{
					this.subscribedProperties = new SubscriptionBasedProperties();
				}
			}
			else if (expireSubscribedProperties)
			{				
				this.subscribedProperties = null;
			} 
		}		

		private var _cachedRingArray:Array = [];
		private function updateSubscribedProperties(obj:Object):void {
			if (this.subscribedProperties != null) {
				if (obj.mass != null) {
					this.weight = obj.mass;
				}		
				if (obj.dodge != null) {
					this.subscribedProperties.dodge = obj.dodge;
				}		
				if (obj.will != null) {
					this.subscribedProperties.willPower = obj.will;
				}
				if (obj.healthRegen != null) {
					this.subscribedProperties.healthRegen = obj.healthRegen;
				}
				if (obj.exhaustionRegen != null) {
					this.subscribedProperties.exhaustionRegen = obj.exhaustionRegen;
				}
				if (obj.acc != null) {
					this.subscribedProperties.accuracy = obj.acc;
				}
				if( obj.luck != null ) {
					this.subscribedProperties.luck = obj.luck;
				}
				if (obj.totalCharge != null) {
					this.subscribedProperties.totalCharge  = obj.totalCharge;
				}
				
				if(obj.ringInfoList != null)
				{
					_cachedRingArray.length = 0;
					this.subscribedProperties.rings = _cachedRingArray;

					var ringInfoList:Array = obj.ringInfoList;
					var ringInfoListLength:uint = ringInfoList.length;
					for(var i:uint=0; i<ringInfoListLength; ++i){
						var ringObj:Object = ringInfoList[i];
						var index:int = ringObj.hasOwnProperty("ringSlot") ? ringObj.ringSlot : i;

						this.subscribedProperties.rings[index] =
						{
							ringId:          ringObj.id, 
							url:             ringObj.url, 
							name:            ringObj.name, 
							description:     ringObj.description, 
							chargeLevel:     ringObj.ringLevel
						};
					}
				}
					
				if (obj.radius != null){
					this.radius = obj.radius;
				}
			}		
		}
		
		private function updateSubscribedDeltas(obj:Object):Boolean {
			var found:Boolean = true;
			if (this.subscribedProperties != null) {
				switch (obj.stat) {
					case "dodge":
						this.subscribedProperties.dodge += int(obj.value);
						break;
	
					case "will":
						this.subscribedProperties.willPower += int(obj.value);
						break;
	
					case "healthRegen":
						this.subscribedProperties.healthRegen += int(obj.value);
						break;
	
					case "exhaustionRegen":
						this.subscribedProperties.healthRegen += int(obj.value);
						break;
						
					case "acc":
						this.subscribedProperties.accuracy += int(obj.value);
						break;
						
					case "luck":
						this.subscribedProperties.luck += obj.value;
						break;	
	
					case "totalCharge":
						this.subscribedProperties.totalCharge += int(obj.value);
						break;
					
				  	default: 
				  		found = false;
				  		break;	
				}
			}
			else
			{
				found = false;
			}
			return found;
		}

		public function updateDeltas(obj:Object):Boolean {
			var subscribedDeltaUpdated:Boolean = false;
			
			subscribedDeltaUpdated = updateSubscribedDeltas(obj);
				switch(obj.stat){
					case "hp":
						this.hp += int(obj.value);
						this.hp = Math.max(0, this.hp);
						this._hpValid = false;
														
						if (obj.modifier != "RGN" && obj.modifier != "donotshow" && (obj.cause == ActorManager.getInstance().myActor.actorId || me) ){				
							var type:int = 1; // type 1 = Player Hit, type 2 = Monster Hit, type 3 = Player Criticla Hit, type 4 = Monster Critical Hit, type 5 = Healing,							
							
							if (obj.value > 0){
								type = 5; // Healing  
							}else if (me){
								if (obj.modifier != null && obj.modifier == "criticalhit"){
									type = 3; // Player Critical Hit
								}else{
									type = 1; // Player Hit
								}
							}else{
								if (obj.modifier != null && obj.modifier == "criticalhit"){
									type = 4; // Monster Critical Hit
								}else{
									type = 2; // Monster Hit
								}
							}						

							this.playHitNum(Math.abs(obj.value), type);						
						}
						break;
					
					case "rag":	
								this.rage += int(obj.value);
							this._rageValid = false;
						break;
					
					case "spd":
						this.serverSpeed += int(obj.value);
						break;
	
					case "mass":
						this.weight += int(obj.value);
						break;
	
					case "mhp":
							this.maxHp += int(obj.value);
						this._hpValid = false;						
						break;
							
					case "exhaustion":
							this.exhaustion += int(obj.value);					
						this._exhaustionValid = false;						
						break;	
					
					case "ghiEnergy":
						this.ghiEnergy += int(obj.value);					
						this._ghiEnergyValid = false;			
						break;	
					
					case "ghiProgress":
						this.ghiProgress += int(obj.value);									
						break;	
					
					case "animation":
						this.playEffectAnim(obj.modifier, "caster")
						break;					
					
					default :				
						trace("Other Effect : ", obj.stat, obj.value);
						break;
				}

			return subscribedDeltaUpdated;			
		}
		
		public function getPaperDollObject():Object {
			var obj:Object = new Object();			
			obj.userName = this.actorName;
			obj.clanName = this.clanName; //ActorManager.getInstance().myActor.clanName || "";
			obj.accuracy = this.accuracy;
			obj.luck = Math.floor( this.luck * 100 ); // server sends fractions, we display whole numbers.
			obj.dodge = this.dodge;
			obj.willpower = this.willPower;
			obj.regen = this.healthRegen;
			obj.exhaustionRegen = this.exhaustionRegen;
			obj.totalCharge = this.totalCharge;
			obj.health = this.maxHp;
			obj.speed = this.serverSpeed;
			obj.weight = this.weight;
			obj.conLevel = this.conLevel;								
			obj.rings = this.paperDollRings;
			obj.suppressedCL = this.suppressedCL;
			
			return obj;							
		}
		
		public function updateStatus(newStatusLabels:Object):void{
			var statusLen:uint = newStatusLabels.length;					
			for(var s:uint = 0; s < statusLen; ++s){
				var obj:Object = newStatusLabels[s];
			
			switch(obj.name){
				case "ktfo":
					if (obj.active == 1){
						//this.actorDisplay.playAnim("ko");
						this.statusEffect.playStatus("dazed");
						this.isKtfo = true;
					}else{
						//this.actorDisplay.playAnim("notKo");
						this.statusEffect.stopStatus("dazed");
						this.isKtfo = false;
					}
					this.dispatchEvent(new BaseActorEvent(BaseActorEvent.KTFO_STATUS_CHANGED, this));
						if (ActorManager.getInstance().myActor && (me)){
						GlobalEvent.eventDispatcher.dispatchEvent(new GlobalEvent(GlobalEvent.PLAYER_STATUS_CHANGED, {status:"ktfo", play:this.isKtfo, curableCount:this.curableStatusCount}));											
					}
					break;
				
				case "in_combat":				
					// [kja] was being used to queue combat music				
					break;
				
				case "link_dead":
					//trace("LINK DEAD ", obj.active)
					var ld:Boolean = false;
					if (obj.active != 0){
						ld = true;
					}
					this.isLinkDead = ld;
					if (this.isLinkDead){						
						this.actorDisplay.playAnim("LinkDead");
					}else{
						this.actorDisplay.playAnim("notKo");
					}
					break;
				
				default:
					//trace(obj.name, obj.url);
					if (obj.name != null){
						var eventPayload:Object;
						if (obj.active && (this.buffs[obj.name] == null || this.buffs[obj.name].rageRank != obj.rageRank))
						{							
							this._buffsValid = false;
							this._buffs[obj.name] = 
							{
								name:		obj.name, 
								url:		obj.url, 
								curable:	(obj.curable || false), 
								ghi:		(obj.ghi || false),
								rageRank:   obj.rageRank 
							};
							if (ActorManager.getInstance().isMyActor(this._actorId)){
								eventPayload = { status:this._uiFramework.getBaseItemId(obj.rid), play:true, curableCount:this.curableStatusCount };																			
							}																		
						}
						else if (!obj.active)
						{							
								this._buffsValid = false;
							delete this.buffs[obj.name];
							if (ActorManager.getInstance().isMyActor(this._actorId)){
								eventPayload = { status:this._uiFramework.getBaseItemId(obj.rid), play:false, curableCount:this.curableStatusCount };																			
							}
						}
						if (eventPayload) {
							GlobalEvent.eventDispatcher.dispatchEvent(new GlobalEvent(GlobalEvent.PLAYER_STATUS_CHANGED, eventPayload));
						}
					}												
					break;
			}
		}
			if (this._buffs == null){
				this._buffsValid = false;				
				this._buffs = new Object();
			}
		}
		
		public function updateAids(aids:Array):void
		{
			this._aids = aids;					
			
			if (aids != null && aids.length > 0){
								
				var Combatant:Boolean = false;
				var Usable:Boolean = false;
				
				/* if (aids.indexOf("NPC") >=0){
					this.Dialogable = true;
				} */
				
				if (aids.indexOf("Combatant") >=0){
					Combatant = true;
				}
				if (aids.indexOf("Usable") >=0){
					Usable = true;
				}
				
				if (this.actorType == ActorTypes.GOOFBALL) {
					if (this.ownerId == ActorManager.getInstance().myActor.actorId) {
						this.targetType = TARGETTYPE_POWERUSABLE;
						this.mouseChildren = true;
					} else {
						this.mouseChildren = false;
					}
				}else if (Combatant){ //can be selected and show the reticle					
					if (this.actorType == ActorTypes.PLAYER || this.actorType == ActorTypes.NPC){
						this.targetType = TARGETTYPE_SELF;						
					}else{
						this.targetType = TARGETTYPE_FRIEND;
					}
					this.mouseChildren = true;															
				}else if (Usable){ // can be clicked .. but do not show the reticle
					this.targetType = TARGETTYPE_ENEMY;
					this.mouseChildren = true;								
				}
			}else{
				this.targetType = TARGETTYPE_NONE;
				this.mouseChildren = false;
				this.mouseEnabled = false;
			}	
			
			if (this.actorType != ActorTypes.USABLE) {
				this.displayHpBar = true;
				switch (this.actorType) {
					case ActorTypes.MONSTER:
						this.displayHp = true;
						this.displayStamina = false;
						this.displayInCrewState = false;					
						this.displayName = false;
						break;
					case ActorTypes.NPC:
					case ActorTypes.CRITTER:
					case ActorTypes.GOOFBALL:
						this.displayHp = false;
						this.displayStamina = false;
						this.displayInCrewState = false;										
						this.displayName = true;
						break;
					case ActorTypes.COMPANION:
						this.displayHp = false;
						this.displayStamina = false;
						this.displayInCrewState = false;										
						this.displayName = true;
						this.mouseChildren = true; // [bgh] can hover and see his name
						this.targetType = TARGETTYPE_COMPANION;
						break;
					default:
						this.displayHp = true;
						this.displayStamina = true;
						this.displayInCrewState = !this.isGuestUser();										
						this.displayName = true;
				}
			}
		}
		
		public function resetTargetType():void{
			this.targetType = TARGETTYPE_NONE;
			this.updateAids(this._aids);			
		}
			
		//--- KnockBack
		public function quickMove(type:String, targetPoints:Array, time:int = 1000):void{												
			this.qmType = type;
			this.qmPoints = targetPoints;
			this.qmTime = time;
			if (type == "charge"){
				this.setDirection(this.qmPoints[0]);				
			}
			
			this.qmTotalDist = Point.distance(this.qmPoints[0], this.position);
			for (var i:int = 1; i< this.qmPoints.length; i++){
				this.qmTotalDist += Point.distance(this.qmPoints[i-1], this.qmPoints[i]);
			}
			
			//trace("QUICK MOVE ", this.qmType, this.qmTime, this.qmTotalDist);
			//trace(this.qmPoints);
						
			this.isQm = true;
			this.qmPointIndex = 0;					
			this.targetPos.x = this.qmPoints[0].x;
			this.targetPos.y = this.qmPoints[0].y;			
			this.qmStartTime = -1;
		}
							
		// getters setters		
		private var _currTint:Object = { r: 0, g: 0, b: 0 };	
		public function setTint(r:int, g:int, b:int):void{
			if (this.actorDisplay != null){				
				if (this.actorDisplay.isGlow){
					r = 256; g= 256, b=256;
				}
				if (r != this._currTint.r || g != this._currTint.g || b != this._currTint.b){
					this.actorDisplay.setTint(r, g, b);
				}
				
				this._currTint.r = r;
				this._currTint.g = g;
				this._currTint.b = b;
				
				
				if (pickedUpActor) {
					this.pickedUpActor.setTint(r, g, b);
				}
				
			}
		}
		
		public function getTintType():TintTypes{
			return TintTypes.ALL;
		}
		private var _pendingTargetSetState:Boolean = false;
		public function setTarget():void{
			if (!this._pendingTargetSetState) {
				this._pendingTargetSetState = true;
				this._targetSetValid = false;
			}
		}
			
		public function clearTarget():void{		
			if (this._pendingTargetSetState) {
				this._pendingTargetSetState = false;
				this._targetSetValid = false;
			}				
		}

		private function validateTargetSetState():void {
			if (this._pendingTargetSetState) {
				if (this.targetType == TARGETTYPE_SELF || this.targetType == TARGETTYPE_FRIEND || this.targetType == TARGETTYPE_POWERUSABLE){
					this.isTarget = true;
					if (this.actorDisplay != null){					
						this.actorDisplay.clearReticle();
						this.actorDisplay.setReticle(this.targetType, this.isTarget);
					}				
					
					
					if (this.hpBar != null){					
						this.hpBar.alpha = 1;
						this.setHPBarVisible(this.displayHpBar);
					}
					this.dispatchEvent(new BaseActorEvent(BaseActorEvent.TARGET_SET, this));
				}
			} else {
				this.isTarget = false;			
				if (this.actorDisplay) {		
					this.actorDisplay.setReticle(this.targetType, this.isTarget);
					this.actorDisplay.clearReticle();
					this.setHPBarVisible(false);						
				}						
				this.dispatchEvent(new BaseActorEvent(BaseActorEvent.TARGET_UNSET, this));	
			}
		}
		
		public function getActorBound():Sprite{
			if(null == actorDisplay) {
				return null;
			}
			return this.actorDisplay.mcBound;
		}
		
		public function getActorDisplay():ActorDisplay{
			return this.actorDisplay;
		}
		
		public function getDisplaySprite():Sprite{
			return this.actorDisplay;
		}
		
		private function isInCrew():Boolean {
			return this.inCrewState == CREW_STATE_IN;
		}	

		public function setCrewState(crewState:String):void {
			if (this.inCrewState != crewState) {
				this.inCrewState = crewState
				GlobalEvent.eventDispatcher.dispatchEvent(new GlobalEvent(GlobalEvent.IN_CREW_STATE_UPDATE, { actor:this, _actorId:this._actorId, inCrewState:this.inCrewState}));
			}
		}	
		
		public function isInvitableToCrew():Boolean {
			return !this.isTeammate() && // the other person is not a teammate
					!this.isInCrew() && // the other person is not in a crew (with this added, we probably don't need the isTeammate check)
					ActorManager.getInstance().myActor.isTeamLeader && // I'm a team leader (including a team of just me)
					ActorManager.getInstance().myActor.teamCount() < TeamManager.TEAM_MAX; // I have room left on my team
		}	
		
		public function isTeammate():Boolean {
			return ActorManager.getInstance().myActor.myTeam != null && ActorManager.getInstance().myActor.myTeam[this._actorId] != null;
		} 
		
		public function onMiniMenuItemClick(evt:UiEvents):void{
			this.handleMenuItemClick(evt.value as String);
		}
		
		public function handleMenuItemClick(value:String, data:Object = null):void {
			// guests from external sites aren't allowed to execute mini menu items
			if(ActorManager.getInstance().myActor.isGuestUser())
			{
				GlobalEvent.eventDispatcher.dispatchEvent(new GlobalEvent(GlobalEvent.INVALID_GUEST_OPERATION, {}));
				return;	
			}
			
			var msg:BattleMessage;
			var param:Array;
			
			var myIgnoreList:Array = ActorManager.getInstance().myActor.ignoreList;
					
			switch(value){
				case FlexMenuItem.CHARACTER_INFO:
					GlobalEvent.eventDispatcher.dispatchEvent(new GlobalEvent(GlobalEvent.PLAYER_STATS_REQUESTED, {actor:this}));
					break;				
				
				case FlexMenuItem.INVITE:
					ActorManager.getInstance().myActor.inviteUser(this._actorId, this.actorName);					
					break;
					
				case FlexMenuItem.LEAVE:
					msg = new BattleMessage("157", null);
					this._gateway.sendMsg(msg);			
					break;
				
				case FlexMenuItem.KICK:
					param = new Array();
					param.push(this._actorId);
					msg = new BattleMessage("156", param);
					this._gateway.sendMsg(msg);
					break;
				
				case FlexMenuItem.PROMOTE:
					param = new Array();
					param.push(this._actorId);
					msg = new BattleMessage("155", param);
					this._gateway.sendMsg(msg);
					break;
				
				case FlexMenuItem.ADD_IGNORE:				
					var obj:Object = new Object();
					obj.id = this._actorId;
					obj.boolean = "true";
					msg = new BattleMessage("ignoreChatter", obj);
					this._gateway.sendMsg(msg);
					var i:int = myIgnoreList.indexOf(this._actorId);
					if (i < 0){
						myIgnoreList.push(this._actorId);
					}					
					break;
				
				case FlexMenuItem.REMOVE_IGNORE:
					var obj2:Object = new Object();
					obj2.id = this._actorId;
					obj2.boolean = "false";
					msg = new BattleMessage("ignoreChatter", obj2);
					this._gateway.sendMsg(msg);
					var i2:int = myIgnoreList.indexOf(this._actorId);
					if (i2 >= 0){
						myIgnoreList.splice(i2,1);
					}			
					break;
				case FlexMenuItem.ADD_FRIEND:
					//trace("Fred, hook up the friend stuff.");
					//trace(" -- ", this._actorId)
					msg = new BattleMessage("inviteFriend", {id:this._actorId});
					this._gateway.sendMsg(msg);					
					break;
				case FlexMenuItem.VIEW_PROFILE:
					GlobalEvent.eventDispatcher.dispatchEvent(new GlobalEvent(GlobalEvent.PROFILE_REQUESTED, { _actorId:_actorId }));			
					break;
				
				case FlexMenuItem.WHISPER:
					GlobalEvent.eventDispatcher.dispatchEvent(new GlobalEvent(GlobalEvent.WHISPER_AUTOFILL, {actorName:this.actorName}));				
					break;
				
				case FlexMenuItem.REPORT_ABUSE:
					GlobalEvent.eventDispatcher.dispatchEvent(new GlobalEvent(GlobalEvent.ABUSE_REPORT_START, {actor:this}));				
					break;
					
				case FlexMenuItem.RECREWT:
					GlobalEvent.eventDispatcher.dispatchEvent(new GlobalEvent(GlobalEvent.OPEN_RECREWT, {}));								
					break;
					
				default:
					break;
			}
		}		
		
		
		public function getSuppressedCL():Number{
			
			var cl:Number = this.conLevel;
			if (!isNaN(this.suppressedCL) && this.suppressedCL < this.conLevel){
				cl = this.suppressedCL;
			}
			return cl;
		}
		
		
		//--- PickUp actor ------
		public function pickUpActor(actor:BaseActor):void{
			delete BaseActor.pickUpArtists[this.actorId];
			
			if (actor == this) {
				return;
			}
	
			if (this.pickedUpActor) {
				this.dropActor();
			}		
			
			if (actor != null && !actor.isDisposed) {
				this.pickedUpActor = actor;
				this.pickedUpActor.pickedUpBy = this;
				this.pickedUpActor.actorDisplay.playAnim("idle")		
							
				this.setAngle(this.angle);
				this.pickedUpActor.setAngle(this.angle);
				//this.updateMcPosition();
				this.redrawMcPos();				
			}
		}
		
		private function dropActor():void{
			if (this.pickedUpActor) {
				if (this.pickedUpActor.roomId != this._roomId) {
					ActorManager.getInstance().removeActor(this.pickedUpActor.actorId);
				}
				this.pickedUpActor.pickedUpBy = null;
				this.pickedUpActor = null;
			}
		}
		

		
		public function getActorBtn():Sprite {
			return this.actorDisplay.getActorBtn();
		}
		public function mcHitTestPoint(x:int, y:int):Boolean{
			return this.actorDisplay.mcTestHitPoint(x, y)
		}
		
		//--- update Timer
		private function onUpdateTimer():void{
			this.updateTime *= 2;
			
			var msg:BattleMessage = new BattleMessage("getRoomActorInfo",{actorID:this._actorId});			
			msg.addEventListener(BattleEvent.CALL_BACK, onActorInfo)
			this._gateway.sendMsg(msg);			
		}
		
		private function onActorInfo(evt:BattleEvent):void{
			//trace("ON ACTOR INFO =============", this.actorId);
			var obj:Object = evt.battleMessage.responseObj[0];			
			this.updateActor(obj);			
			//trace(obj.url);			
			if (obj.url == null || obj.url == undefined || obj.url == "undefined" ){
				trace("Still no url for actor: " + this._actorId + "," +  obj.url, 8)
				//trace("START TIMER --", this.updateTime)
				this._frameTimer.start(this.updateTime, 1);
			}
			
			BattleMessage(evt.target).removeEventListener(BattleEvent.CALL_BACK, onActorInfo);
			
		}
		
		//-----------------
		
		public function get distanceFromPlayer():Number{
			var dist:Number = 0;
			if (ActorManager.getInstance().myActor != null){
				dist = this.position.subtract(ActorManager.getInstance().myActor.position).length;	
			}		
			return dist;		
		}
		
		//--
		public function dispose():void
		{
			this.actorDisplay.dispose();
			this._frameMovement.stop();
						
			DisplayObjectUtils.ClearAllChildrens(this.actorDisplay);
			if (this.contains(this.actorDisplay)) {
				this.removeChild(this.actorDisplay);
			}
			this.actorDisplay = null;
			
			this.setHPBarVisible(false);
			DisplayObjectUtils.ClearAllChildrens(this.hpBar);			
			if (this.contains(this.hpBar)) {
				this.removeChild(this.hpBar);
			}
			this.hpBar = null;
			this.detachWaterAnim();
			this.mcWaterAnim = null;
			
			this.hpBarAttacher = null;
			
			this._uiFramework = null;

			this._isDisposed = true;										
		}

		public function get dodge():int {
			return this.subscribedProperties != null ? subscribedProperties.dodge : 0;
		}	
		
		public function get willPower():int {
			return this.subscribedProperties != null ? subscribedProperties.willPower : 0;			
		}	

		public function get healthRegen():int {
			return this.subscribedProperties != null ? subscribedProperties.healthRegen : 0;						
		}	

		public function get exhaustionRegen():int {
			return this.subscribedProperties != null ? subscribedProperties.exhaustionRegen : 0;						
		}	
		
		public function get totalCharge():int {
			return this.subscribedProperties != null ? subscribedProperties.totalCharge : 0;									
		}	
		
		public function get accuracy():int {
			return this.subscribedProperties != null ? subscribedProperties.accuracy : 0;												
		}	
		
		public function get luck():Number {
			var luck : Number = this.subscribedProperties != null ? subscribedProperties.luck : 0;
			return luck;
		}
		
		public function get rings():Object {
			return this._rings;
		}

		private function get paperDollRings():Array {
			return this.subscribedProperties ? subscribedProperties.rings : []; // [kja] be nice to optimize out that array creation, but we need to redesign what happens when getPaperDollInfo gets called
		}
		
		public function get isDisposed():Boolean {
			return this._isDisposed;
		}
		
		public function get ringMaxLevel():Number {
			return this._ringMaxLevel;
		}
		
		public function set ringMaxLevel(num:Number):void{
			_ringMaxLevel = num;
		}
		
		public function set totalCharge(v:int):void
		{
			setPaperDollSubscription(true);

			subscribedProperties.totalCharge = v;
			if (ActorManager.getInstance().isMyActor(_actorId)) {
				this.dispatchEvent(new BaseActorEvent(BaseActorEvent.TOTAL_CHARGE_UPDATED, this));																			
			}			
		}
		
		public function set totalOrbs(v:Orbs):void{
			if (!this._totalOrbs.equals(v)) {
				this.totalOrbs.removeEventListener(Event.CHANGE, onTotalOrbChange);
				this._totalOrbs = v;
				onTotalOrbChange(null);
				this.totalOrbs.addEventListener(Event.CHANGE, onTotalOrbChange, false, 0, true);
			}
		}
		
		protected function onTotalOrbChange(event:Event):void
		{
			if (ActorManager.getInstance().isMyActor(_actorId)) {			
				this.dispatchEvent(new BaseActorEvent(BaseActorEvent.TOTAL_ORBS_UPDATED, this));																							
			}
		}
		public function get totalOrbs():Orbs{
			return this._totalOrbs;
		}
		
		public function moveToTarget(target:BaseActor):void{
			if (allowUserMove){
				this._gateway.sendMsg( new BattleMessage("moveToTarget", {targetID:target.actorId}) );
			}	
		}
		
		public function moveStop():void{
			if (!this.isSitting) {	
				stopMove();								
				var msg:BattleMessage = new BattleMessage("move", {action:"stop", x:Math.round(position.x), y:Math.round(position.y), rmn:roomId});				
				this._gateway.sendMsg(msg);
			}
		}
		
		public function moveTo(serverX:Number, serverY:Number, ignore:Boolean = false):void{
			if (allowUserMove && !isTransition){		
				var p:Point = position;
				if(!ignore){										
					move(p, serverX, serverY, 0, true);			
				}
				
				var msg:BattleMessage = new BattleMessage("move", {action:"moveTo", x:Math.round(serverX), y:Math.round(serverY), roomName:roomId});				
				this._gateway.sendMsg(msg);
			}	
			
		}
		
		public function checkRange(targetActor:Object, range:Number):Boolean{
								
			var dx:Number = position.x - targetActor.position.x;
			var dy:Number = position.y - targetActor.position.y;
			var d1:Number = Math.sqrt(dx*dx + dy*dy);			
			var dist:Number = d1 - radius - targetActor.radius;
			
			return dist <= range;				
		}
	
		public function get ghiBuffsUpdater():GhiBuffsUpdater{
			if(!_ghiBuffsUpdater){
				_ghiBuffsUpdater = new GhiBuffsUpdater(_gateway, _uiFramework, _linkManager);
			}
			return _ghiBuffsUpdater;
		}
		
		private var _ringManager:RingManager = null;
		
		public function get ringManager():RingManager{
			if(!_ringManager){
				_ringManager = new RingManager(_gateway, _uiFramework, _linkManager, this);
				_ringManager.addEventListener(RingManager.RING_LOADED, onRingLoaded, false, 0, true);
			}
			return _ringManager;
		}
		
		private function onRingLoaded(event:Event):void{
			dispatchEvent(new Event(event.type));
		}
		
		public function isSlotLock(slot:int):Boolean{
			return ringManager.isSlotLock(slot);
		}
		
		public function moveRing(fromSlot:int, toSlot:int):void{
			ringManager.moveRing(fromSlot, toSlot);
		}
		public function updateBonusSet():void{
			ringManager.updateBonusSet();
		}
		public function onMoveRing(evt:BattleEvent):void{
			ringManager.onMoveRing(evt);
		}
		public function updateRings():void{
			ringManager.updateRings();
		}
		public function getRingAt(slot:int):Ring{
			return ringManager.getRingAt(slot);
		}
		public function set selectedRingSlot(slot:int):void {
			ringManager.selectedRingSlot = slot;
		}
		public function get selectedRingSlot():int {
			return ringManager.selectedRingSlot;
		}
		public function enableDisableRings():void{
			ringManager.enableDisableRings();
		}
		public function unlockSlot(slot:int):void{
			ringManager.unlockSlot(slot);
		}
		public function lockSlot(slot:int):void{
			ringManager.lockSlot(slot);
		}
		public function get maxRingCL():Number{
			return ringManager.maxRingCL;
		}
		public function updateMaxCL():void{
			ringManager.updateMaxCL();
		}
		
		public function lockSlotCount():int{
			return ringManager.lockSlotCount();
		}
				
		public static function get RING_LOADED():String{
			return RingManager.RING_LOADED;
		}
					
		public var consumableManager:ConsumableManager;
		private var _collectiblesUpdater:CollectiblesUpdater = null;
		private var _teamManager:TeamManager = null;
		
		public function get curableStatusCount():int{
			var count:int = 0;
			for each (var buff:Object in this._buffs){
				if (buff.curable){
					count ++;
				}
			}
			return count;	
		}		
		
		public function get collectiblesUpdater():CollectiblesUpdater{
			if(!_collectiblesUpdater){
				_collectiblesUpdater = new CollectiblesUpdater(_gateway, _uiFramework, _linkManager);
			}
			return _collectiblesUpdater;
		}
		
		public function get buffs():Object {
			return this._buffs;
		}
		public function updateTeam(team:Object = null):void{
			teamManager.updateTeam(team);
		}
		public function isOnATeam():Boolean{
			return teamManager.isOnATeam();
		}
		public function isOnMyTeam(id:String):Boolean{
			return teamManager.isOnMyTeam(id);
		}
		public function teamCount():int{
			return teamManager.teamCount();
		}
		public function inviteUser(actorId:String, userName:String, callback:Function = null):void{
			teamManager.inviteUser(actorId, userName, callback);
		}
		
		public function get isTeamLeader():Boolean{
			return teamManager.isTeamLeader;
		}
		
		private function get teamManager():TeamManager{
			if(!_teamManager){
				_teamManager = new TeamManager(_gateway);
			}
			return _teamManager;
		}
		
		public function get myTeam():Object{
			return teamManager.myTeam;
		}
		
		public function get teamList():Array{
			return teamManager.teamList;
		}
		
		public function get actorFootX():Number{				
			return actorDisplay.actorFootX;
		}
		public function get actorFootY():Number{
			return actorDisplay.actorFootY;
		}
		
		public function get roomId():String{
			return this._roomId;
		}
		public function set roomId(v:String):void{
			this._roomId = v;
			var filtersName:Array = MapFilesFactory.getInstance().mapFiles.getActorFilters(this._roomId);
			this.setActorFilters(filtersName);			
		}
			
		public function setActorFilters(filtersName:Array):void{
			this.actorDisplay.setActorFilters(filtersName);			
		}
		
	}
}
		
import com.gaiaonline.battle.newactors.BaseActor;
import com.gaiaonline.flexModulesAPIs.globalevent.GlobalEvent;	

class PendingSitState
{
	public var dirty:Boolean = false;
	public var sitting:Boolean = false;
};

class SubscriptionBasedProperties {
	public var dodge:Number = 0;
	public var willPower:Number = 0;
	public var healthRegen:Number = 0;	
	public var exhaustionRegen:Number = 0;	
	public var totalCharge:Number = 0;	
	public var accuracy:Number = 0;
	public var luck:Number = 0;
	public var rings:Array = []; 
}
