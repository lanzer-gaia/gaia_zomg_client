package com.gaiaonline.battle.userinput
{
	import com.gaiaonline.battle.ApplicationInterfaces.IUIFramework;
	import com.gaiaonline.battle.map.Map;
	import com.gaiaonline.battle.newactors.BaseActor;
	import com.gaiaonline.battle.newactors.EnvActor;
	import com.gaiaonline.flexModulesAPIs.actorInfo.ActorTypes;
	import com.gaiaonline.flexModulesAPIs.globalevent.GlobalEvent;
	import com.gaiaonline.utils.DisplayObjectUtils;
	import com.gaiaonline.utils.FrameTimer;
	import com.gaiaonline.utils.MouseEventProxy;
	
	import flash.display.DisplayObject;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Point;
		
	public class MouseIcon extends Sprite
	{
		private var mc:MovieClip		
		
		public var actorTarget:int = 0;
		//public var isUI:Boolean = false;
		public var isMapCollision:Boolean = false;
		public var isPortal:Boolean = false;
		public var portalType:String = "na";
		public var isWordBubble:Boolean = false;
		public var isLink:Boolean = false;
		private var _isPointTarget:int = -1;
		private var isMap:Boolean = false;
		public var isEnvObj:Boolean = false;
		public var isTalkIcon:Boolean = false;	
		
		private var _mcVisible:Boolean = false;
		private var _mcCurrFrame:Number = NaN;
		private var _mcPortalVisible:Boolean = false;
		private var _mcPortalLabel:String = null;				
		
		private var _uiFramework:IUIFramework = null;
		
		public function MouseIcon(uiFramework:IUIFramework):void{
			this._uiFramework = uiFramework;
			
			this.addEventListener(Event.ADDED_TO_STAGE, onAddedToStage, false, 0, true);
			this.mouseEnabled = false;
			this.mouseChildren = false;

			DisplayObjectUtils.addWeakListener(GlobalEvent.eventDispatcher, GlobalEvent.MOUSE_OVER_STATE_CHANGED, onMouseOverStateChanged);
		}
			
		public function setMouseMc(mc:MovieClip):void{
			this.mc = mc;
			this.mc.mouseEnabled = false;
			this._mcVisible = this.mc.visible;
			this._mcPortalVisible = this.mc.portal.visible;
						
			this.addChild(this.mc);			
		}

		private var _frameTimer:FrameTimer = new FrameTimer(_onEnterFrame);		
		private function onAddedToStage(evt:Event):void{
			this.mouseEnabled = false;
			
			_uiFramework.stageMouseMoveLimiter.addListener(_onMouseMove);
			this._frameTimer.startPerFrame();
		}

		private function _onMouseMove(mep:MouseEventProxy):void
		{
			const evt:MouseEvent = mep.original;
			if (this.mc != null){				
				this.x = evt.stageX;
				this.y = evt.stageY;
				
				this.isMap = this._uiFramework.map.getMapDisplayObject().contains( DisplayObject(evt.target) );
				if (this.isMap){
					this.setMouseIcon();
				}else{
					if (this._mcCurrFrame != 1) {
						this.mc.gotoAndStop(1);
						this._mcCurrFrame = 1;
					}						
					if (this._mcVisible) {
						this._mcVisible = false;
						this.mc.visible = false;
					}

					if (this.isPortal) {					
						this.mc.portal.gotoAndStop(this.portalType);
						this._mcPortalLabel = this.portalType;
					}
				}
			}
		}

		private static var s_underPointHelper:Point = new Point(NaN, NaN);
		private function _onEnterFrame():void{
			if (this.actorTarget != 0){			
				s_underPointHelper.x = this.stage.mouseX;
				s_underPointHelper.y = this.stage.mouseY;
				var a:Array = this.stage.getObjectsUnderPoint(s_underPointHelper);			
				var dpo:DisplayObject;	
				var len:uint = a.length;			
				 for (var i:int = 0; i < len; i++){			
					dpo = a[i];					
					while( dpo != null && !(dpo is Map) && !(dpo is BaseActor && BaseActor(dpo).actorType != ActorTypes.COMPANION) && !(dpo is EnvActor)){								
						dpo = dpo.parent;													
					}				
					if (dpo is BaseActor || dpo is EnvActor){												
						break;
					}	
				}							
				if (!(dpo is BaseActor) && !(dpo is EnvActor)){										
					this.actorTarget = 0;
				}	
				dpo = null; 
			} 
			
			if (this.mc != null){				
				if (this.isMap){
					this.setMouseIcon();
				}else{
					if (this._mcCurrFrame != 1) {					
						this.mc.gotoAndStop(1);
						this._mcCurrFrame = 1;
					}												
					if (this._mcVisible) {
						this._mcVisible = false;
						this.mc.visible = false;
					}
				}
			}
			
		}
		
		private function setMouseIcon():void{
			if (this.mc == null || this.mc.portal == null){
				return;
			}
			var frame:int = 0;
			if (this._mcPortalVisible != this.isPortal) {
				this._mcPortalVisible = this.isPortal;
				this.mc.portal.visible = this.isPortal;
			}
					
			if (this._isPointTarget >= 0){				
				frame = 7;
				if (!this._mcVisible) {
					this._mcVisible = true;
					this.mc.visible = true;
				}
				if (this._mcPortalVisible) {
					this._mcPortalVisible = false;
					this.mc.portal.visible = false;
				}
			}else if (this.isWordBubble){
				frame = 1;	
				if (this._mcVisible) {
					this._mcVisible = false;
					this.mc.visible = false;
				}
				
			}else if(this.isLink || this.isEnvObj){
				frame = 6;
				if (!this._mcVisible) {
					this._mcVisible = true;
					this.mc.visible = true;
				}
				if (this._mcPortalVisible) {
					this._mcPortalVisible = false;
					this.mc.portal.visible = false;
				}
							
			}else if (this.isPortal){				
				frame = 2;
				if (this._mcPortalLabel != this.portalType){
					this.mc.portal.gotoAndStop(this.portalType);
					this._mcPortalLabel = this.portalType;
				}		
				if (!this._mcVisible) {
					this._mcVisible = true;
					this.mc.visible = true;
				}
					
			}else if (this.actorTarget >	 0){				
				if (this.actorTarget == 1){
					frame = 3;					
				}else if (this.actorTarget == 4){	 
					frame = 6;			
				}else{
					frame = 4;	
				}				
				if (!this._mcVisible) {
					this._mcVisible = true;
					this.mc.visible = true;
				}
				
			}else if (this.isMapCollision){
				frame = 5;	
				if (!this._mcVisible) {
					this._mcVisible = true;
					this.mc.visible = true;
				}
				
			} else {
				frame = 1;	
				if (this._mcVisible) {
					this._mcVisible = false;
					this.mc.visible = false;
				}
			}
						
			if (frame > 0 && this._mcCurrFrame != frame){
				DisplayObjectUtils.stopAllMovieClips(this.mc);
				this.mc.gotoAndStop(frame);
				this._mcCurrFrame = frame;
				
				if(isPortal){
					DisplayObjectUtils.startAllMovieClips(this.mc.portal.getChildAt(0));
				}

			}
			
		}
		
		private function onMouseOverStateChanged(e:GlobalEvent):void {
			var data:Object = e.data;
			
			if (data.hasOwnProperty("actorTarget")) {
				this.actorTarget = data.actorTarget;
			}
			if (data.hasOwnProperty("isEnvObj")) {
				this.isEnvObj = data.isEnvObj;
			}
			if (data.hasOwnProperty("isWordBubble")) {
				this.isWordBubble = data.isWordBubble;
			}
			if (data.hasOwnProperty("isMapCollision")) {
				this.isMapCollision = data.isMapCollision;
			}
			if (data.hasOwnProperty("isPortal")) {
				this.isPortal = data.isPortal;
			}
			if (data.hasOwnProperty("portalType")) {
				this.portalType = data.portalType;
			}
			if (data.hasOwnProperty("isLink")) {
				this.isLink = data.isLink;
			}
			if (data.hasOwnProperty("isPointTarget")) {
				this.isPointTarget = data.isPointTarget;
			}						
			if (data.hasOwnProperty("isTalkIcon")) {
				this.isTalkIcon = data.isTalkIcon;
			}						
		}
		
		public function reset():void{
			this.isMapCollision = false;
			this.isPortal = false;
			this.portalType = "na";
			this.isWordBubble = false;
			this.isLink = false;
			this.isEnvObj = false;
			this.isTalkIcon = false;
			this.actorTarget = 0;		
		}
		
		public function get isPointTarget():int{
			return this._isPointTarget;
		}
		public function set isPointTarget(v:int):void{
			this._isPointTarget = v;
			var isMouseEnabled:Boolean = !(this._isPointTarget >= 0);
			var isMouseChildren:Boolean = !(this._isPointTarget >= 0);
			GlobalEvent.eventDispatcher.dispatchEvent(new GlobalEvent(GlobalEvent.MAP_SET_MOUSE_ENABLED, {enabled:isMouseEnabled}));
			GlobalEvent.eventDispatcher.dispatchEvent(new GlobalEvent(GlobalEvent.MAP_SET_MOUSE_CHILDREN, {enabled:isMouseChildren}));
			if (this._isPointTarget < 0){
				setMouseIcon();		
			}
		}
		
	
	}
	
	
}