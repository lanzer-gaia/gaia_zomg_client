package com.gaiaonline.battle.monsters
{	
	import com.gaiaonline.battle.ui.events.UiEvents;
	import com.gaiaonline.utils.DisplayObjectStopper;
	import com.gaiaonline.utils.DisplayObjectStopperModes;
	import com.gaiaonline.utils.DisplayObjectUtils;
	import com.gaiaonline.utils.VisManagerSingleParent;
	
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.events.Event;

	public class MonsterMain extends MovieClip
	{
		
		public var aggro:Boolean = false;
				
		private var state:int = -1;
		private var pose:String = "idle";
		private var previousPose:String = "idle";
		private var currentMcState:MovieClip;
		private var death:Boolean = false;
		private var isAction:Boolean = false;
		private var isQm:Boolean = false;
		private var ang:Number = 0;

		private var _spawn:DisplayObject;
		private var _visMgr:VisManagerSingleParent;
		private var _baseActorId:String = "Na";
				
		private var _stopper:DisplayObjectStopper = new DisplayObjectStopper(DisplayObjectStopperModes.SHOW_NO_ANIM, true);
		
		public function MonsterMain():void{
			//trace("[MonsterMain Constructor]", this.name)
 			_spawn = MovieClip(this.getChildAt(0)).getChildByName("spawn");
 			 			 			
 			_visMgr = new VisManagerSingleParent(this, true);
			_visMgr.forEach(addMonsterAnimationGarbageStopper);
					
			this.setAngle(135);
			this.setPoseState(this.pose, this.state);
			this.addEventListener(Event.ENTER_FRAME, onAllFrame);
		}		
		
		
		public function init():void{			
			//trace("[MonsterMain init]", this.name, this.baseActorId)
			this.state = -1;
			this.pose = "idle";
			this.previousPose = "idle";			
			this.death = false;
			this.isAction = false;
			this.isQm = false;
			this.ang = 0;			
			
			this.setAngle(45);
			this.setPoseState(this.pose, this.state);
			if (!this.hasEventListener(Event.ENTER_FRAME)){
				this.addEventListener(Event.ENTER_FRAME, onAllFrame);
			}
		}
		public function reset():void{
			//trace("[MonsterMain Reset]", this.name)
			this.state = -1;
			this.pose = "idle";
			this.previousPose = "idle";			
			this.death = false;
			this.isAction = false;
			this.isQm = false;
			this.ang = 0;
			this._baseActorId = "Na";
			
			this.setAngle(45);
			this.setPoseState(this.pose, this.state);
			if (this.hasEventListener(Event.ENTER_FRAME)){
				//trace("[MonsterMain Reset] - remove event listenr", this.name)
				this.removeEventListener(Event.ENTER_FRAME, onAllFrame);
				this.removeEventListener(Event.ENTER_FRAME, onEnterFrame);
			}
			
			//--- Stop All Animation
			this._visMgr.forEach(disposeAngle);
		}	
		
		public function spawn():void{
			if (_spawn != null){
				this.isAction = true;	
				//trace("[MonsterMain spawn -- addEventListener]", this.name)		
				this.addEventListener(Event.ENTER_FRAME, onEnterFrame);					
				this.setPoseState("spawn", this.state);	
			}
		}
		public function walk():void{
			//trace("MONSTER WALK")
			this.previousPose = "walk";
			if (!this.isQm && !this.isAction && this.pose != "walk"){
				//trace("WALK ",this.name, this.pose,  this.state)				
				this.setPoseState("walk", this.state);
			}
		}
		
		public function idle():void{
			//trace("MONSTER IDLE")
			this.previousPose = "idle";
			if (!this.isQm && !this.isAction && this.pose != "idle"){
				//trace("IDLE ",this.name, this.pose,  this.state)				
				this.setPoseState("idle", this.state);
			}
		}
		
		public function die():void{
			//trace("[MonsterMain die]", this.name)
			this.isQm = false;
			this.isAction = true;
			this.death = true;
			//trace("[MonsterMain die -- addEventListener]", this.name)
			this.addEventListener(Event.ENTER_FRAME, onEnterFrame);	
			this.setPoseState("death", this.state);	
				
		}
		public function hit():void{
			if (!this.isQm){				
				this.isAction = true;
				//trace("[MonsterMain hit -- addEventListener]", this.name)
				this.addEventListener(Event.ENTER_FRAME, onEnterFrame);	
				this.setPoseState("hit", this.state);
			}
		}
				
		public function attack(atp:String):void{
			
			this.isAction = true;
			//trace("[MonsterMain attack -- addEventListener]", this.name)
			this.addEventListener(Event.ENTER_FRAME, onEnterFrame);	
			this.setPoseState(atp, this.state)			
			
		}		

		private var _label:String;
		public function setPoseState(pose:String, state:int = 0):void{
			//trace("set Pose State ", isQm, this.name, pose, state, this.previousPose)
			this.pose = pose;
			if (this.state != state){
				if (this.state != -1){
					_label = "ts" + String(this.state);
				}else{
					_label = null;
				}								
				this.state = state;					
				this.pose = this.previousPose;
			}
			else {
				_label = null;
			}
			
			if (this._visMgr)
			{
				this._visMgr.forEach(setPoseStateForAngle);
			}
			else
			{
				trace("KAI: setting pose state after dispose()?");
			}
		}
		private function setPoseStateForAngle(angle:DisplayObject, index:int):void
		{	
			var mcAng:MovieClip = MovieClip(angle);			
			if (mcAng.getChildByName(pose) != null){				
				for(var poseI:int = 0; poseI < mcAng.numChildren; poseI++){
					var mcPose:MovieClip = MovieClip(mcAng.getChildAt(poseI));
					if (mcPose.name == pose){
						mcPose.visible = true;
					} else {
						mcPose.visible = false;
					}
					
					//--- Set State
					for(var stateI:int = 0; stateI < mcPose.numChildren; stateI++){
						var mcState:MovieClip = MovieClip(mcPose.getChildAt(stateI));
						
						if (mcState.name == "s"+String(Math.max(0,state)) && mcPose.name == pose){							
							mcState.visible = true;							
							if (mcPose.visible && mcAng.visible){
								if (this.currentMcState != null && this.currentMcState.hasEventListener("startProjectile")){
									this.currentMcState.removeEventListener("startProjectile", onProjectile);
								}
								this.currentMcState = mcState;
								this.currentMcState.addEventListener("startProjectile", onProjectile, false, 0, true);									
							}
														
							if (this.containFrameLabel(mcState, _label)){								
								mcState.gotoAndPlay(_label);								
							}else{								
								mcState.gotoAndPlay(1);
							}	
							for(var childIndex:int = 0; childIndex < mcState.numChildren; childIndex++){
								var child:MovieClip = mcState.getChildAt(childIndex) as MovieClip;
								if (child != null){									
									DisplayObjectUtils.startAllMovieClips(child);
								}
							}
							
						}else{												
							mcState.visible = false;							
							DisplayObjectUtils.stopAllMovieClips(mcState);
						}
						
												
					}
				}			
			}else{
				this.isAction = false;			
				if (this.death){		
					//trace("[MonsterMain setPoseForAngle] dispatchMonsterDeath", this.name);			
					this.dispatchEvent(new Event("MonsterDead"));
				}
				else{					
					this.setPoseState(this.previousPose, this.state);
					this.dispatchEvent(new Event("MonsterActionEnd"));
				}
			}
		}
				
		public function setState(state:int = 0):void{
			//trace("SET STATE ",this.name, this.pose,  this.state , state)
			this.setPoseState(this.pose, state);
		}

		var _angleFound:Boolean;		
		public function setAngle(angle:Number):int{
			this.ang = angle;
			//trace("SET ANGLE ", this.ang, this.pose, this.state)
			this._angleFound = false;  //KAI: sucks, this is done above, too
			this._visMgr.forEach(showAngle);
			
			return ang;
		}
		
		private function showAngle(child:DisplayObject, index:int):void
		{						
			var ang:Number = this.ang - 90;
			//trace(" -- " , ang)		
			if (ang < 0 ){
				ang = ang + 360;
			}
			if (ang > 180){
				ang = 180 - (ang - 180)
			}

			var mc:MovieClip = MovieClip(child);
			const min:Number = mc.angMin;
			const max:Number = mc.angMax;

			//trace(min, max, ang);				
			if (!isNaN(min) && !isNaN(max) ){
				if (ang >= min && ang <= max && !_angleFound){
					this._visMgr.setVisible(child, true);
					_angleFound = true;						
				}else{
					this._visMgr.setVisible(child, false);
				}
			}				
		}
				
		public function setNextAction(action:String):void{
			//trace("MonsterMain setNextAction", action)
		}
						
		public function aggroOut():void{
			
			
		}
		public function aggroIn():void{
			
		}
				
		private function onEnterFrame(evt:Event):void{
			//trace("[MonsterMain onEnterFrame ]", this.name, this.death);
			if (this.currentMcState != null && this.currentMcState.currentLabel == "end"){											
				if (this.hasEventListener(Event.ENTER_FRAME)){					
					this.isAction = false;	
					//trace("[MonsterMain die -- removeEventListener]", this.name)						
					this.removeEventListener(Event.ENTER_FRAME, onEnterFrame);
				}
				
				//this.currentMcState.stop();						
				if (this.death){					
					//trace("[MonsterMain onEnterFrame] dispatch MonsterDeath", this.name);
					this.dispatchEvent(new Event("MonsterDead"));					
				}else{
					this.setPoseState(this.previousPose, this.state);
					this.dispatchEvent(new Event("MonsterActionEnd"));
				}
			}else if (this.currentMcState == null){
				//trace(this.name, "invalide Pose/sate", this.pose, this.state)
				if (this.death){
					trace("[MonsterMain onEnterFrame]  Warning!!! Warning!!! currentMcState is null... death = ", this.death, this.name)
				}
				this.isAction = false;
				//trace("[MonsterMain die -- removeEventListener]", this.name)
				this.removeEventListener(Event.ENTER_FRAME, onEnterFrame);
				this.setPoseState(this.previousPose, this.state);
			}		
							
		}	
		
		private function onAllFrame(evt:Event):void{			
			if (this.hasOwnProperty("onFrame")){
				MovieClip(this).onFrame(this.ang);
			}
		}
		
				
		private function containFrameLabel(mc:MovieClip, frameLabel:String){
			var v:Boolean = false;
			for (var i:int = 0; i < mc.currentLabels.length; i++){				
				if (mc.currentLabels[i].name == frameLabel){
					v = true;
					break;
				}
			}
			return v;
		}
		
		private function onProjectile(evt:UiEvents):void{
			var e:UiEvents = new UiEvents("startProjectile", null);
			e.value = evt.value;	
			this.dispatchEvent(e);
		}
		
		public function onQuickMove(type:String, cTime:int=0, totalTime:int = 0):Object{
			if (cTime >= totalTime){
				this.isAction = false;
				this.isQm = false;
				this.setPoseState(this.previousPose, this.state);				
			}else if (this.pose != type){
				this.isAction = true;
				this.isQm = true;					
				this.setPoseState(type, this.state);		
			}
			//trace(this.name, this.currentMcState, cTime, totalTime, this.currentMcState.currentFrame, this.visible, this.currentMcAngle.visible, this.currentMcState.visible, this.currentMcState.parent.visible, this.currentMcState.parent.parent.visible, this.currentMcState.parent.parent.parent.visible);		
			if (this.currentMcState.hasOwnProperty("onQuickMove")){							
				var obj:Object = this.currentMcState.onQuickMove(cTime, totalTime);
				var startFrame = obj.startFrame;
				var frameFromEnd = obj.frameFromEnd;				
				return {startFrame:startFrame, frameFromEnd:frameFromEnd};
			}else{
				return {startFrame:0, frameFromEnd:0};
			}	
				
		}
											
		public function dispose():void{
			this.removeEventListener(Event.ENTER_FRAME, onEnterFrame);
			this.removeEventListener(Event.ENTER_FRAME, onAllFrame);
			
			this.baseActorId = null;
			this._visMgr.forEach(disposeAngle);
			this._visMgr = null;
		}
		
		private function addMonsterAnimationGarbageStopper(child:DisplayObject, index:int):void {
			var mcAng:DisplayObjectContainer = DisplayObjectContainer(child);
			for(var poseI:int = 0; poseI < mcAng.numChildren; ++poseI)
			{
				var mcPose:DisplayObjectContainer = DisplayObjectContainer(mcAng.getChildAt(poseI));
				for(var stateI:int = 0; stateI < mcPose.numChildren; ++stateI)
				{
					var mcState:MovieClip = MovieClip(mcPose.getChildAt(stateI));					
					_stopper.addGarbageStopper(mcState);
				}
			}	
		}
		
		private function disposeAngle(child:DisplayObject, index:int):void {
			//trace("DIPOSE ANGLE ====")			
			DisplayObjectUtils.stopAllMovieClips(child);			
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

	}
}

