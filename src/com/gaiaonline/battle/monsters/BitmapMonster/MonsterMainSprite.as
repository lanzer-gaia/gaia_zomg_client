package com.gaiaonline.battle.monsters.BitmapMonster
{		
	import com.gaiaonline.battle.ui.events.UiEvents;
	import com.gaiaonline.utils.Enumeration;
	
	import flash.display.Bitmap;
	import flash.display.MovieClip;
	import flash.display.PixelSnapping;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.media.Sound;
	
	public class MonsterMainSprite extends MovieClip
	{				
		private var _baseActorId:String = "Na";
		private var _state:int = -1;
		private var _pose:MonsterPoseEnum = MonsterPoseEnum.IDLE;
		private var _ang:Number = 0;
		private var _angIndex:int = 0;
		private var _currentLoopPose:MonsterPoseEnum = MonsterPoseEnum.IDLE;
		
		private var _bitmapAnimationData:BitmapAnimationData;
		private var _currentFrame:int = 0;
		private var _bm:Bitmap = new Bitmap();
		private var _bmContainer:Sprite;
		private var _sp:Sprite = new Sprite();
		private var _animType:String = "main";
		private var _isTransition:Boolean = false;
		
		private var _baseMonster:Object = null;
		private var _isAngleRotation:Boolean = false;
		
		private var _quickMoveInFrames:int = 0;
		private var _quickMoveOutFrames:int = 0;		
				
		public function MonsterMainSprite(bitmapAnimationData:BitmapAnimationData, baseMonster:Object)
		{
			this._bitmapAnimationData = bitmapAnimationData;
			this._baseMonster = baseMonster;
			if (this._baseMonster.hasOwnProperty("isAngleRotation")){
				this._isAngleRotation = this._baseMonster.isAngleRotation;
			}
						
			this._bm.pixelSnapping = PixelSnapping.ALWAYS;
			if (this._isAngleRotation){
				this._bmContainer = new Sprite();
				this._bmContainer.addChild(this._bm);
				this.addChild(this._bmContainer);
			}else{
				this.addChild(this._bm);
			}
			
			//--- For Testting : to see the 0,0 ref point
			/*
			this._sp.graphics.beginFill(0x00FF00);
			this._sp.graphics.drawCircle(0,0,5);
			this._sp.graphics.endFill();
			this.addChild(this._sp);
			*/
			
			if (this._baseMonster != null && this._baseMonster.hasOwnProperty("quickMoveInFrames")){
				this._quickMoveInFrames = this._quickMoveOutFrames = this._baseMonster.quickMoveInFrames;
			}
			if (this._baseMonster != null && this._baseMonster.hasOwnProperty("quickMoveOutFrames")){
				this._quickMoveOutFrames = this._baseMonster.quickMoveOutFrames;
			}
						
			this.addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
			this.addEventListener(Event.REMOVED_FROM_STAGE, onRemoveFromStage);
			
		}
		private function onAddedToStage(evt:Event):void{
			this.addEventListener(Event.ENTER_FRAME, onFrame);
		}
		private function onRemoveFromStage(evt:Event):void{
			this.removeEventListener(Event.ENTER_FRAME, onFrame);
		}
		
		public function init():void{
			this._state = -1;
			this._pose = MonsterPoseEnum.IDLE;
			this._currentLoopPose = MonsterPoseEnum.IDLE;
			this.setAngle(45);
		}
		public function reset():void{
			this.init();
		}		
		
		public function spawn():void{
			this.setPose(MonsterPoseEnum.SPAWN)
		}
		public function walk():void{
			this.setPose(MonsterPoseEnum.WALK);
		}		
		public function idle():void{
			this.setPose(MonsterPoseEnum.IDLE);
		}
		public function die():void{			
			this.setPose(MonsterPoseEnum.DEATH);
		}
		public function hit():void{
			this.setPose(MonsterPoseEnum.HIT);
		}
		public function attack(atp:String):void{
			switch(atp.toLowerCase()){
				case "atk0":
					this.setPose(MonsterPoseEnum.ATK0);
					break;
				case "atk1":
					this.setPose(MonsterPoseEnum.ATK1);
					break;
				case "atk2":
					this.setPose(MonsterPoseEnum.ATK2);
					break;
			}
		}		
		
		public function setAngle(angle:Number):int{
			this._ang = angle;
			this._angIndex = this._bitmapAnimationData.getAngleIndex(angle);
			if (this._isAngleRotation){						
				var ang:Number = this._ang - 90;			
				if (ang < 0 ){
					ang = ang + 360;
				}
				if (ang > 180){
					ang = 180 - (ang - 180)
				}
				this._bmContainer.rotation = ang - 180;							
			}
			return this._ang;
		}		
		
		public function setPoseState(pose:String, state:int = 0):void{			
			this.setPose(MonsterPoseEnum(Enumeration.getEnumFromName(MonsterPoseEnum, pose)));
			this.setState(state);			
		}
		
		private function setPose(pose:MonsterPoseEnum):void{			
			if (this._pose != pose && this._bitmapAnimationData.hasPose(pose, this._angIndex)){						
				this._pose = pose;
				this._currentFrame = 0;
				if (!this._pose.isAction() && !this._pose.isQuickMove()){
					this._currentLoopPose = this._pose;
				}
				this._animType = "main";			
			}
		}
		
		public function setState(state:int = 0):void{
			if (this._state != state){				
				this._currentFrame = 0;
				if (this._bitmapAnimationData.hasTransition(this._angIndex, this._pose, this._state, state)){
					this._animType = "ts"+this._state;
					this._isTransition = true;
				}else{
					this._animType = "main";
				}
				this._state = state; 
			}
		}
				
		public function onQuickMove(type:String, cTime:int=0, totalTime:int = 0):Object{
			var qm:MonsterPoseEnum = MonsterPoseEnum.TELEPORT;
			switch(type.toLowerCase()){
				case "teleport":
					qm = MonsterPoseEnum.TELEPORT;
					break;
				
				case "charge":
					qm = MonsterPoseEnum.CHARGE;
					break;					
			}	
			var len:int = (this._bitmapAnimationData.getAnimLength(this._angIndex, qm, "s" + this._state, "qmout")*1000)/16;										
			if (this._pose != qm && cTime < totalTime - len){				
				setPose(qm);			
			}	
			
			if (this._pose.isQuickMove()){	
				if (cTime >= totalTime - len && this._animType != "qmout"){			
					this._animType = "qmout";
					this._currentFrame = 0;
				}else if (cTime < totalTime - len && this._animType != "qmin" && this._animType != "qmloop"){					
					this._currentFrame = 0;
					this._animType = "qmin";
				}
			}
			return {startFrame:this._quickMoveInFrames, frameFromEnd:this._quickMoveOutFrames};
		}
		
		private function onFrame(evt:Event):void{
			if (this._state >= 0){				
				var bmf:BitmapFrame = this._bitmapAnimationData.getFrame(this._angIndex, this._pose, "s" + this._state, this._animType,this._currentFrame);							
				if (bmf != null){
					this._bm.bitmapData = bmf.bitmapData; 
					this._bm.x = bmf.xOffset;
					this._bm.y = bmf.yOffest;			
					this._currentFrame = bmf.nextFrame;					
					this._bm.scaleX = this._bm.scaleY = bmf.scale;
					//trace(this._angIndex, this._pose, this._pose.isAction(), this._currentLoopPose, bmf.label);
					if (!this._pose.isQuickMove() && (this._pose.isAction() || this._isTransition) && bmf.label == "end"){
						if (this._pose == MonsterPoseEnum.DEATH){
							this.dispatchEvent(new Event("MonsterDead"));
						}else{
							this._pose = this._currentLoopPose;
							this._currentFrame = 0;	
							this._animType = "main";
							this._isTransition = false;
							this.dispatchEvent(new Event("MonsterActionEnd"));
						}								
					}else if (!this._pose.isQuickMove() && bmf.label != null){
						this.handleLabels(bmf.label)
					}else if (this._pose.isQuickMove() && bmf.label == "end"){						
						if (this._animType == "qmin"){
							this._animType = "qmloop";
							this._currentFrame = 0;							
						}else if (this._animType == "qmout"){												
							this._pose = this._currentLoopPose;
							this._currentFrame = 0;	
							this._animType = "main";
							this._isTransition = false;
							this.dispatchEvent(new Event("MonsterActionEnd"));	
						}
					}								
				}else{
					trace("[MonsterMainSprite onFrame] Ivalide BitmapFrame : angIndex:" + this._angIndex," pose:" + this._pose, " state:" + this._state, " anim:" + this._animType, " frame:"+this._currentFrame)
				}
			}
		}
			
		private function handleLabels(label:String):void{
			switch (label){
				case "projectile":									
					this.dispatchEvent(new UiEvents("startProjectile", null));
					break;
			}
		}
				
		public function get baseActorId():String{
			return this._baseActorId;
		}
		public function set baseActorId(v:String):void{
			if (this._baseActorId != v){				
				this._baseActorId = v;				
				this.dispatchEvent(new Event("BaseActorIdChanged"));			
			}			
		}
		
		public function dispose():void{
			if (this._isAngleRotation){
				this.removeChild(this._bmContainer);
				this._bmContainer.removeChild(this._bm);
				this._bmContainer = null;
			}else{
				this.removeChild(this._bm);
			}
			this._bm = null;
			this._baseActorId = null;
			this.removeEventListener(Event.ENTER_FRAME, onFrame);
			this._bitmapAnimationData = null;
		}

		//******** baseMonster Implementation	*******
		public function get aggro():Boolean{
			if (this._baseMonster.hasOwnProperty("aggro")){
				return this._baseMonster.aggro;
			}else{
				return false;
			}
		}	
		public function set aggro(v:Boolean):void{
			this._baseMonster.aggro = v;
		}
		
		public function get isGlow():Boolean{
			if (this._baseMonster.hasOwnProperty("isGlow")){
				return this._baseMonster.isGlow;
			}else{
				return false;
			}
		}	
		public function set isGlow(v:Boolean):void{
			this._baseMonster.isGlow = v;
		}
				
		public function getNewMonster():*{
			return new MonsterMainSprite(this._bitmapAnimationData, this._baseMonster);
		}
		
		public function get soundList():Array
		{
			return this._baseMonster.soundList;
		}
		public function get maxRadius():Number
		{
			return _baseMonster.maxRadius;
		}
		public function get minRadius():Number
		{
			return _baseMonster.minRadius;
		}
		
		public function getActorBtn():*
		{
			return _baseMonster.getActorBtn();
		}
		
		public function getPortrait():*
		{
			return _baseMonster.getPortrait();
		}
		
		public function get flip():Boolean
		{
			if(_baseMonster.hasOwnProperty("flip"))
			{
				return _baseMonster.flip;
			}
			return true;
		}
		public function get hasAggro():Boolean
		{
			return _baseMonster.hasAggro;
		}
		
		public function getNewProjectile():MovieClip
		{
			if(_baseMonster.hasOwnProperty("getNewProjectile"))
			{
				return _baseMonster.getNewProjectile();
			}
			return null;	
		}
		
		public function getRing():MovieClip
		{
			var ring:MovieClip = null;
			
			if (this._baseMonster.hasOwnProperty("getRing")){
				ring = this._baseMonster.getRing();
			}
			
			return ring;
		}
		
		public function getSound(soundId:String):Sound{
			return this._baseMonster.getSound(soundId);
		}
		
	}
}