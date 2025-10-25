package com.gaiaonline.battle.newactors
{
	import com.gaiaonline.battle.ApplicationInterfaces.IAssetFactory;
	import com.gaiaonline.battle.ApplicationInterfaces.IUIFramework;
	import com.gaiaonline.battle.gateway.BattleGateway;
	import com.gaiaonline.battle.newrings.RingAnim;
	import com.gaiaonline.battle.utils.LoadPolicyFileManager;
	import com.gaiaonline.utils.DisplayObjectStopper;
	import com.gaiaonline.utils.DisplayObjectStopperModes;
	import com.gaiaonline.utils.DisplayObjectUtils;
	import com.gaiaonline.utils.FrameQueueList;
	import com.gaiaonline.utils.FrameTimer;
	
	import flash.display.LoaderInfo;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.filters.BlurFilter;
	import flash.filters.ColorMatrixFilter;
	import flash.geom.ColorTransform;
	
	public class ActorDisplay extends Sprite
	{		
		public static const LOADED:String = "ActorLoaded";
		public static const TRANS_DONE:String = "Transition_Done"
		
		protected var _isLoaded:Boolean = false;
		
		protected var genericAnim:RingAnim;			
		protected var assetFactory:IAssetFactory;
		protected var baseUrl:String;
		
		public var mcBound:Sprite;
		
		protected var url:String;
		
		public var direction:Number = -45 //135;
		protected var reticle:MovieClip;
		protected var reticlePlaceholder:Sprite = new Sprite();
		
		private var _mask:Sprite;
		public var containers:Sprite;
		public var backContainer:Sprite;
		public var distContainer:Sprite;
		public var blackContainer:Sprite;
		public var frontContainer:Sprite;
		
		protected var genericHit:GenericHitAnim;
		protected var goldLootDisplay:MovieClip;
		protected var actorBtn:MovieClip;
		public var currentActorAnim:String;
		protected var animList:Array = new Array();			
		private var isTransitionAnim:Boolean = false;
		protected var baseActorId:String = null;
		
		private var _garbageStopper:DisplayObjectStopper = new DisplayObjectStopper(DisplayObjectStopperModes.SHOW_NO_ANIM, true);

		protected var _gateway:BattleGateway = null;
		protected var _uiFramework:IUIFramework = null;	
		
		protected var _frameQueueList:FrameQueueList = new FrameQueueList();
		public var hScale:Number = 1;
		public var aggro:Boolean = false;
		
		public var isGlow:Boolean = false;
		public var flip:Boolean = true;
		
		public var isDispose:Boolean = false;
		
		public var displaySilhouette:Boolean = true;
				
		private var _directionInitted:Boolean = false;
		
		public function getActorBtn():MovieClip {
			return actorBtn;
		}
		public function mcTestHitPoint(x:int, y:int):Boolean{
			return this.hitTestPoint(x, y);
		}	
		
		public function ActorDisplay(assetFactory:IAssetFactory, baseUrl:String, baseActorId:String = null){
			this.baseActorId = baseActorId;
			this.assetFactory = assetFactory;	
			this.baseUrl = baseUrl;	
			this.init();							
			
			this._frameQueueList.addFrameQueue(fnPlayHitNumber);
			this._frameQueueList.addFrameQueue(fnHitNumber);	
			this._frameQueueList.addFrameQueue(fnHitCount);					
		}
		
		private function getNewReticle():MovieClip {
			if (this.isDispose){
				return null;
			}
			if(null == this.assetFactory) {
				return null;
			}
			var reticle:MovieClip = this.assetFactory.getInstance("Reticle") as MovieClip;
			DisplayObjectUtils.stopAllMovieClips(reticle);

			return reticle;
		}
				
		private function init():void{
			this._mask = new Sprite();
			
			//-- Mask ----
			_mask.graphics.beginFill(0x0000ff);
			_mask.graphics.drawRect(-300, -350, 600, 355);			
			_mask.graphics.endFill();
									
			this.reticle = getNewReticle();

			this.containers = new Sprite();
												
			this.backContainer = new Sprite();			
			this.distContainer = new Sprite();			
			this.frontContainer = new Sprite();
			
			this.backContainer.mouseChildren = false;
			this.backContainer.mouseEnabled = false;	
			this.distContainer.mouseChildren = false;
			this.distContainer.mouseEnabled = false;	
			this.frontContainer.mouseChildren = false;
			this.frontContainer.mouseEnabled = false;							

			this.genericHit = new GenericHitAnim(this.assetFactory);
			this.goldLootDisplay = this.assetFactory.checkOut("GoldLootDisplay") as MovieClip;
			this.goldLootDisplay.y = -132;		
			DisplayObjectUtils.stopAllMovieClips(this.goldLootDisplay,1);	
			this._garbageStopper.addGarbageStopper(this.goldLootDisplay);
			
			this.genericHit.mouseEnabled = this.genericHit.mouseChildren = false;
			this.goldLootDisplay.mouseEnabled = this.goldLootDisplay.mouseChildren = false;
			this.goldLootDisplay.addEventListener("Done", onGoldLootDisplayDone);
							
			// reticle				
			this.addChild(this.reticlePlaceholder);
			
			// RingAnim container
			this.addChild(this.containers);
			this.containers.addChild(this.backContainer);
			this.backContainer.name = "backContainer";
			this.containers.addChild(this.distContainer);
			this.distContainer.name = "distContainer";
			this.containers.addChild(this.frontContainer);
			this.frontContainer.name = "frontContainer";						
								
			// hit Spark and Numbers
			this.addChild(this.genericHit);	
			
			// add button
			if (this.actorBtn != null){		
				this.actorBtn.visible = false;
				this.actorBtn.x = -71;
				this.actorBtn.y = -139;
				this.addChild(this.actorBtn);		
				this.hitArea = this.actorBtn;				
				this.mouseChildren = false;							
			}
			
			//--- add alpha Layer for water last
			this.containers.mouseEnabled = false;
			this.containers.mouseChildren = false;
			
			this._mask.mouseEnabled = false;
			this._mask.mouseChildren = false;
									
		}
				
		// overide base on the type of Actor (Avatar , Monsters... )
		public function loadActor(gateway:BattleGateway, uiFramework:IUIFramework, url:String):void{
			this._gateway = gateway;
			this._uiFramework = uiFramework;
			LoadPolicyFileManager.LoadPolicyFile(this.url);			
		}
		
		protected function onActorLoaded(evt:Event):void{
			if (this.isDispose){
				return;
			}						
			this._isLoaded = true;
					
			this.dispatchEvent(new Event(LOADED));
			if (this.currentActorAnim == null){
				this.isTransitionAnim = false;
				this.currentActorAnim = "idle";
			}
			
			if (this.isTransitionAnim){
				this.playTransition(this.currentActorAnim);
			}else{								
				this.playAnim(this.currentActorAnim, null, true);
			}
			this.setDirection(this.direction);
			
			this._garbageStopper = null;
			
			this.refreshPortraits();			
		}
				
		public function getNewActor(pooling:Boolean = true):Sprite{
			return null;
		}
		public function getDialogPortrait():Sprite{
			return null;
		}
		public function getTargetInfoPortrait():Sprite{
			return null
		}		
		protected function refreshPortraits():void{
			
		}
		
		private var _directionRepeat:uint = 0;
		public function setDirection(angle:Number):void{
			if (this.isDispose){
				return;
			}
			
			if (angle < 0 ){
				angle = 360 + angle;
			}else if (angle > 360){
				angle = angle - (Math.floor(angle/360)*360);
			}						

			if (!this._directionInitted || this.direction != angle) {
				this.direction = angle;				
								
				if (this.flip && (this.direction > 270 || this.direction <= 90) ){				
					if (this.hScale != -1){											
//						trace("Flip BACK" , this.baseActorId , this.scaleX)						
						this.hScale = -1;
						this.genericHit.scaleX = -1;
						this.goldLootDisplay.scaleX = -1;
					}		
				}else{		
					if (this.hScale != 1){
//						trace("Flip NORMAL", this.baseActorId, this.scaleX)						
						this.hScale = 1;					
						this.genericHit.scaleX = 1;		
						this.goldLootDisplay.scaleX = 1;
					}			
				}				
				this._directionInitted = true;
			}								
		}
		
		public function playAnim(action:String, param:Object= null, allowRepeatAnim:Boolean = false):void{
			if (this.isDispose){
				return;
			}
			
			this.currentActorAnim = action;
		}
				
		public function playHitNum(hp:Number, type:int = 1):void{
			if (this.isDispose){
				return;
			}		
			this._frameQueueList.addToFrameQueue(fnPlayHitNumber, {hp:hp, type:type}, true);
			this._frameQueueList.addToFrameQueue(fnHitNumber, {hp:hp, type:type}, false);	
							
		}
		
		private function fnPlayHitNumber(data:Object = null):void{
			if (data.type < 5){
				if (data.type < 3){
					this.genericHit.spark("NormalHit");
					this.playAnim("hit", "normalhit");
				}else{
					this.genericHit.spark("CriticalHit");
					this.playAnim("hit", "criticalhit");
				}				
			}
		}
		private function fnHitNumber(data:Object = null):void{
			this.genericHit.hitNumber(data.hp, data.type);	
		}
		
		
		public function showHitCountNum(hp:Number):void{	
			if (this.isDispose){
				return;
			}
					
			this._frameQueueList.addToFrameQueue(fnHitCount, hp, true);
		}
		private function fnHitCount(data:Object):void{
			this.genericHit.hitCountNumber(Number(data));
		}
		
		public function setAggro(v:Boolean):void{
			if (this.isDispose){
				return;
			}
			this.aggro = v;
			if (this.aggro){
				this.playAnim("aggroIn")
			}else{
				this.playAnim("aggroOut")
			}			
				
				
		}
		
		public function setState(state:int = 0):void{
			
		}
		
		public function playOutOfRange():void{
			this.genericHit.outOfRange();			
		}
		public function playInvalidTarget():void{
			if (this.isDispose){
				return;
			}
			
			this.genericHit.invalidTarget();
		}
		public function playMiss():void{
			if (this.isDispose){
				return;
			}
			
			this.genericHit.miss();
		}
		public function playResists():void{
			if (this.isDispose){
				return;
			}
			this.genericHit.resists();
		}
		public function playReflects():void{
			if (this.isDispose){
				return;
			}
			this.genericHit.reflects();
		}
		public function playDeflects():void{
			if (this.isDispose){
				return;
			}
			this.genericHit.deflects();
		}
		
		public function updateGoldLootDisplay(gold:int = 0):void{
			if (!this.contains(this.goldLootDisplay)){
				this.addChild(this.goldLootDisplay);				
				DisplayObjectUtils.startAllMovieClips(this.goldLootDisplay);
			}
			this.goldLootDisplay.updateCount(gold);
		}
		private function onGoldLootDisplayDone(evt:Event):void{
			if (this.goldLootDisplay != null) {
				DisplayObjectUtils.stopAllMovieClips(this.goldLootDisplay,1);
				if (this.goldLootDisplay.parent == this) {
					this.removeChild(this.goldLootDisplay);
				}
			}
		}
			
		protected function onErrorLoading(evt:IOErrorEvent):void{
			if (this.isDispose){
				return;
			}
			
			this.dispatchEvent(evt);
			
			try{			
				//LoaderInfo(evt.target).loader.contentLoaderInfo.removeEventListener(Event.COMPLETE, onActorLoaded);
				//LoaderInfo(evt.target).loader.contentLoaderInfo.removeEventListener(IOErrorEvent.IO_ERROR, onErrorLoading);
				LoaderInfo(evt.target).loader.unload();
			}catch(e:Error){
				trace(e.message);
			}
		}
		
		public function onQuickMove(type:String, cTime:int=0, totalTime:int = 0):Object{
			if (this.isDispose){
				return null;
			}
			
			return {startFrame:0, frameFromEnd:0};
		}
		
		// Ring animation 
		public function playRingAnim(ringId:String, rage:int, type:String = "caster", targetActor:Object = null, speed:Number = -1, mcRef:Sprite = null):RingAnim{
			if (this.isDispose){
				return null;
			}			
														
			var ra:RingAnim = new RingAnim(this.baseUrl, this._gateway, this._uiFramework, this, ringId, type, mcRef, targetActor, speed, rage);
					
			ra.addEventListener(RingAnim.ANIM_DONE, onAnimDone);
			ra.addEventListener(RingAnim.PRIORITY_CHANGE, onAnimPriorityChange);				
					
			var dir:String;							
			if (this.direction >=180 && this.direction < 360){
				dir="Up" + String(rage);
			}else{
				dir="Down" + String(rage);
			}
											
			this.animList.push(ra);
			
			ra.playAnim(dir);
			
			return ra;
		}

		private static const s_transitionTable:Object =
		{
			"crystal_in":	"CrystalIn",
			"crystal_out":	"CrystalOut",
			"portal_in":	"PortalIn",
			"portal_out":	"PortalOut",
			"warp_in":		"WarpIn",
			"warp_out":		"WarpOut",
			"buzz_in":		"BuzzIn",
			"buzz_out":		"BuzzOut"
		};
		private function getNewTransitionAnim(tType:String):Sprite
		{
			const assetName:String = s_transitionTable[tType];
			return assetName ? 	(this.assetFactory.getInstance(assetName) as Sprite) : null;
		}
		
		public function playTransition(tType:String):void {
			if (this.isDispose){
				return;
			}
			
			this.currentActorAnim = tType;
			this.isTransitionAnim = true;
			
			var mcAnim:Sprite = getNewTransitionAnim(tType);
				if (mcAnim == null){
					trace("Missing transaction Anim: ", tType)
					return;
				}
								
				var ra:RingAnim = new RingAnim(this.baseUrl, this._gateway, this._uiFramework, this, tType, "caster", mcAnim);								
				if (!ra.loaded){
					this.dispatchEvent(new Event(TRANS_DONE));
					return;
				}
				
				//ra.rage = rage;
				ra.addEventListener(RingAnim.ANIM_DONE, onTransitionDone);
				ra.addEventListener(RingAnim.PRIORITY_CHANGE, onAnimPriorityChange);				
				ra.priority = 999999;
								
				var dir:String;			
				if (this.direction >=180 && this.direction < 360){
					dir="Up0";
				}else{
					dir="Down0";
				}
									
				ra.playAnim(dir);				
				this.animList.push(ra);
				
				this.setAnimPriority();
		}

		private var _ringAnimStore:Object = {};
		private var _stopper:DisplayObjectStopper = new DisplayObjectStopper(DisplayObjectStopperModes.SHOW_NO_ANIM, true);		
		private function getNewRingAnim(tType:String):Sprite
		{
			var retval:Sprite = _ringAnimStore[tType];
			if (!retval)
			{			
				retval = this.assetFactory.getInstance(tType) as Sprite;
				if (retval != null){
					DisplayObjectUtils.stopAllMovieClips(retval);
					_stopper.addGarbageStopper(retval);
					_ringAnimStore[tType] = retval;
				}
			}
			return retval;
		} 

		private static const s_soundMap:Object =
		{
			"SuperCharge": "SuperChargeSound",
			"ExtraOrbs": "DoubleOrbsSound",
			"RingPolish": "RingPolishSound",
			"Cure":"CureSound",
			"Revive":"ReviveSound",
			"ReviveLite":"ReviveLiteSound"
		};
		private function setupEffectAnimSound(mcAnim:MovieClip, effectId:String):void
		{
			// [kja] FS#34007
			if (!mcAnim.soundList)
			{
				var mappedSound:String = s_soundMap[effectId];
				if (mappedSound)
				{
					mcAnim.soundList = [{ frame:"caster0", repeat:1, vol:100, sounds:[ mappedSound ] }];
					mcAnim.minRadius = 80;
					mcAnim.maxRadius = 600;
				}
			}
		}
		public function playEffectAnim(effectId:String, type:String = "effect", playEffectStartAnim:Boolean = true):RingAnim{
			if (this.isDispose){
				return null;
			}
			
			//---- SPecial Case for revive ======
			if (effectId == "Revive" && !ActorManager.getInstance().myActor.isKtfo){
				effectId = "ReviveLite";
			}
			
			this.currentActorAnim = effectId;
			//this.isTransitionAnim = true;
			
			if (this.isLoaded){
				//trace("PLAY EFFECT : ", effectId)
				
				var mcAnim:Sprite = getNewRingAnim(effectId);
				if (mcAnim == null){
					trace("Missing EFFECT Anim: ", effectId)
					return null;
				}								
				
				setupEffectAnimSound(MovieClip(mcAnim), effectId);				
				var ra:RingAnim = new RingAnim(this.baseUrl, this._gateway, this._uiFramework, this, effectId, type, mcAnim);								
				if (ra.loaded){
					//ra.rage = rage;
					ra.addEventListener(RingAnim.ANIM_DONE, onEffectAnimDone);
					ra.addEventListener(RingAnim.PRIORITY_CHANGE, onAnimPriorityChange);				
					ra.priority = 999999;
									
					var dir:String;			
					if (this.direction >=180 && this.direction < 360){
						dir="Up0";
					}else{
						dir="Down0";
					}
										
					ra.playAnim(dir, playEffectStartAnim);				
					this.animList.push(ra);
					
					this.setAnimPriority();
					
					return ra;
				}else{				
					return null;
				}
					
			}else{
				return null;
			}
		}
		
		public function onTransitionDone(evt:Event):void{
			if (this.isDispose){
				return;
			}
			
			var ra:RingAnim = RingAnim(evt.target);			
			ra.removeEventListener(RingAnim.ANIM_DONE, onAnimDone);
			ra.removeEventListener(RingAnim.PRIORITY_CHANGE, onAnimPriorityChange);	
			var i:int = this.animList.indexOf(ra);
			if (i >= 0){
				delete this.animList[i]
				this.animList.splice(i,1);
			}			
			ra.dipose();
			ra = null;
			setAnimPriority();
			this.isTransitionAnim = false;
			this.dispatchEvent(new Event(TRANS_DONE));
		}
			
		private function onEffectAnimDone(evt:Event):void{
						
			var ra:RingAnim = RingAnim(evt.target);			
			ra.removeEventListener(RingAnim.ANIM_DONE, onAnimDone);
			ra.removeEventListener(RingAnim.PRIORITY_CHANGE, onAnimPriorityChange);	
			var i:int = this.animList.indexOf(ra);
			if (i >= 0){
				delete this.animList[i]
				this.animList.splice(i,1);
			}			
			ra.dipose();
			ra = null;
			setAnimPriority();
			this.isTransitionAnim = false;
			//this.dispatchEvent(new Event(TRANS_DONE));
		}
				
		private function onAnimDone(evt:Event):void{
		
			var ra:RingAnim = RingAnim(evt.target);			
			//trace("ON Anim DONE ", ra.ringId, ra.type)
			ra.removeEventListener(RingAnim.ANIM_DONE, onAnimDone);
			ra.removeEventListener(RingAnim.PRIORITY_CHANGE, onAnimPriorityChange);	
			var i:int = this.animList.indexOf(ra);
			if (i >= 0){
				delete this.animList[i]
				this.animList.splice(i,1);
			}			
			ra.dipose();
			ra = null;
			setAnimPriority();
			
		}
		protected function onAnimPriorityChange(evt:Event):void{
			this.setAnimPriority();			
		}	
		public function setAnimPriority():void{
			if (this.isDispose){
				return;
			}
			
			this.animList.sortOn("priority", Array.NUMERIC | Array.DESCENDING);
			
			for (var i:int=0; i < this.animList.length; i++){				
				var ra:RingAnim = this.animList[i];						
				if (i == 0){
					ra.setDistVisible(true);
				}else{
					ra.setDistVisible(false);
				}
				
			}						
		}
				
		
		public function set zpos(z:Number):void{
			if (this.isDispose){
				return;
			}
			
			if (z > 0){
				if (!this.containers.contains(_mask)){					
					this.containers.addChild(_mask);
					this.containers.mask = _mask;
				}
			}else{
				if (this.containers.contains(_mask)){
					this.containers.removeChild(_mask);
					this.containers.mask = null
				}
			}
			
			if (this.distContainer.y != z){
				this.distContainer.y = z;
			}
			if (this.backContainer.y != z){
				this.backContainer.y = z;
			}
			if (this.frontContainer.y != z){
				this.frontContainer.y = z;
			}
		}
		
		public function get zpos():Number {
			return this.distContainer.y;
		}

		private function attachReticle():void
		{
			if (this.isDispose){
				return;
			}
			if(reticle && !this.contains(this.reticle))
			{
				var position:int = this.getChildIndex(this.reticlePlaceholder);
				DisplayObjectUtils.startAllMovieClips(this.reticle);

				this.addChildAt(this.reticle, position);
			}
		}
		
		private function detachReticle():void
		{
			if (this.isDispose){
				return;
			}
			if(reticle && this.contains(this.reticle))
			{
				DisplayObjectUtils.stopAllMovieClips(this.reticle);
				this.removeChild(this.reticle);
			}
		}
		private var reticleStateDirty:Boolean = false;
		private var showReticle:Boolean = true;
		private var reticleColorTransform:ColorTransform = null;
		private static const type1WithTargetColorTransform:ColorTransform = new ColorTransform(0,1,1,1,0,107,0);
		private static const type1WithoutTargetColorTransform:ColorTransform = new ColorTransform(0,1,1,.4,0,107,0);		
		private static const type2WithTargetColorTransform:ColorTransform = new ColorTransform(1,0.3,0.3,1, 255, 0,0);
		private static const type2WithoutTargetColorTransform:ColorTransform = new ColorTransform(1,0.3,0.3,.4, 255, 0,0);
		
		private var _frameTimer:FrameTimer = new FrameTimer(checkReticleState);
		private function invalidateReticle(attach:Boolean, colorTransform:ColorTransform = null):void {
			this.reticleStateDirty = true;
			this.showReticle = attach;
			this.reticleColorTransform = colorTransform;
			
			_frameTimer.startPerFrame(1, 1);
		}
		private function checkReticleState():void
		{
			if (this.isDispose){
				return;
			}
			
			if (this.reticleStateDirty) {
				if (showReticle) {
					this.attachReticle();
					this.reticle.transform.colorTransform = this.reticleColorTransform;
				} else {
					this.detachReticle();
				}				
				this.reticleStateDirty = false;
				this.reticleColorTransform = null;
			}
		}
		
		// --- reticle // targetType 0 = none, 1 = friend, 2= foes
		public function setReticle(targetType:int, target:Boolean):void{
			if (this.isDispose){
				return;
			}
			
			if (targetType == BaseActor.TARGETTYPE_SELF){
				this.invalidateReticle(true, target ? ActorDisplay.type1WithTargetColorTransform : ActorDisplay.type1WithoutTargetColorTransform);
			}else if (targetType == BaseActor.TARGETTYPE_FRIEND || targetType == BaseActor.TARGETTYPE_POWERUSABLE){
				this.invalidateReticle(true, target ? ActorDisplay.type2WithTargetColorTransform : ActorDisplay.type2WithoutTargetColorTransform);				
			}else{
				this.invalidateReticle(false);								
			}			
		}
		
		public function clearReticle():void{
			if (this.isDispose){
				return;
			}
			this.invalidateReticle(false);
		}
												
		// ----
		protected function clearRingAnimList():void{
			// clear Ring anim
			for (var i:int=0; i<this.animList.length; i++){
				RingAnim(this.animList[i]).removeEventListener(RingAnim.ANIM_DONE, onAnimDone);
				RingAnim(this.animList[i]).removeEventListener(RingAnim.PRIORITY_CHANGE, onAnimPriorityChange);
				RingAnim(this.animList[i]).removeEventListener(RingAnim.ANIM_DONE, onTransitionDone);
				RingAnim(this.animList[i]).removeEventListener(RingAnim.PRIORITY_CHANGE, onAnimPriorityChange);
				RingAnim(this.animList[i]).removeEventListener(RingAnim.ANIM_DONE, onEffectAnimDone);											
				RingAnim(this.animList[i]).dipose();
			}
			this.animList.length = 0;
		}
		
		public function dispose():void
		{
			this.isDispose = true;
								
			// clear button								
			if (this.contains(this.actorBtn)){
				this.removeChild(this.actorBtn);	
			}						
			//DisplayObjectUtils.ClearAllChildrens(this.actorBtn);
						
			this.clearRingAnimList();
			
			this._gateway = null;
			this._uiFramework = null;
			
			//this.genericAnim.dipose();
			this.genericAnim = null;
									
			this.assetFactory.checkIn(this.goldLootDisplay);
			
			this.genericHit.dispose();
			DisplayObjectUtils.stopAllMovieClips(this.genericHit);			
			this.genericHit = null;
			
			this.assetFactory = null;
			this.mcBound = null;
			this.detachReticle();			
			this.reticle = null;
			this.reticlePlaceholder = null;
			this._mask = null;
			this.containers = null;
			this.backContainer = null;
			this.distContainer = null;
			this.blackContainer = null;
			this.frontContainer = null;			
			DisplayObjectUtils.stopAllMovieClips(this.goldLootDisplay);			
			this.goldLootDisplay = null;
			this.actorBtn = null;
			this.hitArea = null;		
			this.currentActorAnim = null;
		
			// clear this
			DisplayObjectUtils.ClearAllChildrens(this);
			
			this._frameQueueList.dispose();
			this._frameQueueList = null;
		}

		protected function clearPortraitArray(array:Array):void {
			var len:uint = array.length;
			for (var i:int = 0; i < len; ++i){
				array[i] = null;
			}
			array = null;		
		}

		private static var s_tintColorTransform:ColorTransform = new ColorTransform();				
		public function setTint(r:int, g:int, b:int):void{
			if (this.isDispose){
				return;
			}
			
			s_tintColorTransform.redMultiplier = r/256;
			s_tintColorTransform.greenMultiplier = g/256;
			s_tintColorTransform.blueMultiplier = b/256;								
			s_tintColorTransform.alphaMultiplier = 1;												
			
			this.distContainer.transform.colorTransform = s_tintColorTransform;
		}	
		
		public function playSound(soundID:String):void{
			
		}		
		
		public function get isLoaded():Boolean {
			return this._isLoaded;
		}
		
		public function getInternalRingAnim():void{
			
		}
		
		
		public function get actorFootX():Number{
			return 0;
		}
		public function get actorFootY():Number{
			return 0;
		}
		
		public function setActorFilters(filtersName:Array):void{
			var filters:Array = new Array();
			for(var i:int = 0; i < filtersName.length; i++){
				switch (filtersName[i]){
					case "black_white":
						filters.push(new ColorMatrixFilter([0.3086000084877014,0.6093999743461609,0.0820000022649765,0,0,0.3086000084877014,0.6093999743461609,0.0820000022649765,0,0,0.3086000084877014,0.6093999743461609,0.0820000022649765,0,0,0,0,0,1,0]) );
						break;
						
					case "blur":
						filters.push(new BlurFilter(8,8));
						break;	
					
				}
			}
			this.containers.filters = filters;
			//this.filters = filters;
		}
		
/*
		override public function set scaleX(scaleX:Number):void {
			super.scaleX = scaleX;
			trace("SCALEX");			
		}

		override public function getRect(targetCoordinateSpace:DisplayObject):Rectangle {
			trace("GETRECT");
			return this.getRect(targetCoordinateSpace);
		}
		override public function getBounds(targetCoordinateSpace:DisplayObject):Rectangle {
			trace("GETBOUNDS");
			return super.getBounds(targetCoordinateSpace);
		}
		
		override public function set alpha(alpha:Number):void {
			trace("ALPHA");			
		}

		override public function set cacheAsBitmap(cacheAsBitmap:Boolean):void {
			trace("BITMAP");			
		}		

		override public function set mask(mask:DisplayObject):void {
			trace("MASK");			
		}

		override public function set opaqueBackground(opaqueBackground:Object):void {
			trace("OPAQUE");			
		}

		override public function set scaleX(scaleX:Number):void {
			trace("SCALEX");			
		}

		override public function set scaleY(scaleY:Number):void {
			trace("SCALEY");			
		}

		override public function set x(x:Number):void {
			trace("X");			
		}

		override public function set y(y:Number):void {
			trace("Y");			
		}

	*/			
		
	}
}
