package com.gaiaonline.battle.RingPlayer
{
	import com.gaiaonline.battle.ApplicationImplementations.UIFrameworkImpl;
	import com.gaiaonline.battle.ApplicationInterfaces.ILinkManager;
	import com.gaiaonline.battle.ApplicationInterfaces.IUIFramework;
	import com.gaiaonline.battle.Globals;
	import com.gaiaonline.battle.newactors.ActorDisplay;
	import com.gaiaonline.battle.newactors.AvatarDisplay;
	import com.gaiaonline.battle.newrings.RingAnim;
	import com.gaiaonline.objectPool.LoaderFactory;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Loader;
	import flash.display.LoaderInfo;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.MouseEvent;
	import flash.geom.ColorTransform;
	import flash.net.URLRequest;
	import flash.text.TextField;
	import flash.utils.getTimer; 
	
	//import fl.controls.*;
		
	public class RingPlayer extends MovieClip
	{
		
		private var	Player:AvatarDisplay;
		private var ringMcRef:Sprite;
		private var radioLevel:int = 0;
		private var raEffect:RingAnim;
		private var atkStartTime:int = 0;
		private var baseUrl:String = null;
		private var linkManager:ILinkManager = null;
	
		public function RingPlayer():void{
			
						
			///-- Base Url	
			var rootUrl:String = this.loaderInfo.url;		
			var u:String = rootUrl.substring(0, rootUrl.lastIndexOf("/")+1);			
			if (u == "file://"){				
				u = rootUrl.substring(0, rootUrl.lastIndexOf("\\")+1)
			}		
			this.linkManager.baseURL = u;
			this.baseUrl = u;
			
			
			this.Player = new AvatarDisplay(this);
			
			this.mcHeader.btnLoad.addEventListener(MouseEvent.CLICK, onAvatarLoadClick);
						
			this.mcDirection.btnDL.addEventListener(MouseEvent.CLICK, onBtnDL, false, 0, true);
			this.mcDirection.btnUL.addEventListener(MouseEvent.CLICK, onBtnUL, false, 0, true);
			this.mcDirection.btnUR.addEventListener(MouseEvent.CLICK, onBtnUR, false, 0, true);
			this.mcDirection.btnDR.addEventListener(MouseEvent.CLICK, onBtnDR, false, 0, true);
			
			this.mcRingInfo.btnLoad.addEventListener(MouseEvent.CLICK, onRingLoadClick, false, 0, true);
			this.mcRingInfo.btn0.addEventListener(MouseEvent.CLICK, onBtn0, false, 0, true);
			this.mcRingInfo.btn1.addEventListener(MouseEvent.CLICK, onBtn1, false, 0, true);
			this.mcRingInfo.btn2.addEventListener(MouseEvent.CLICK, onBtn2, false, 0, true);
			this.mcRingInfo.btn3.addEventListener(MouseEvent.CLICK, onBtn3, false, 0, true);
			
			Sprite(this.mcRingInfo.mcRingTxt).transform.colorTransform = new ColorTransform(1,0,0,1,0,0,0,0);
			
			this.mcRingInfo.mcEffect.visible = false;			
//			var rbg:RadioButtonGroup = new RadioButtonGroup("RadioButtonGroup");
//			rbg.addEventListener(Event.CHANGE, onRadioChange);
//			this.mcRingInfo.mcEffect.r0.group = rbg;
//			this.mcRingInfo.mcEffect.r1.group = rbg;
//			this.mcRingInfo.mcEffect.r2.group = rbg;
//			this.mcRingInfo.mcEffect.r3.group = rbg;
//			
			this.mcRingInfo.mcEffect.btnStart.addEventListener(MouseEvent.CLICK, onBtnStart, false, 0, true);
			this.mcRingInfo.mcEffect.btnStop.addEventListener(MouseEvent.CLICK, onBtnStop, false, 0, true);
			
		}
		
	
		// Load Avatar
		private function loadPlayer(url:String):void{
			var uiFramework:IUIFramework = new UIFrameworkImpl(null, null, this.stage);
			uiFramework.loaderContextFactory.baseUrl = this.baseUrl;
			this.Player.loadActor(null, uiFramework, url);
			this.Player.addEventListener(ActorDisplay.LOADED, onPlayerLoaded, false, 0, true);			
			
		}		
		private function onPlayerLoaded(evt:Event):void{
			var s:Sprite = this.Player.getNewActor();
			this.actorContainer.addChild(this.Player);
			this.Player.setDirection(45);
			this.Player.x = this.stage.stageWidth/2;
			this.Player.y = this.stage.stageHeight/2 + 50;			
		}
		
		
		// Load Ring	
		private function loadRing(ringName:String):void{
			
			if (this.raEffect != null){
				this.raEffect.dispell();
				this.raEffect = null;
			}
			
			while(this.Player.backContainer.numChildren >1){
				this.Player.backContainer.removeChildAt(1);
			}
			while(this.Player.distContainer.numChildren >1){
				this.Player.distContainer.removeChildAt(1);
			}
			while(this.Player.frontContainer.numChildren >1){
				this.Player.frontContainer.removeChildAt(1);
			}
				
			var l:Loader = LoaderFactory.getInstance().checkOut()
			l.contentLoaderInfo.addEventListener(Event.COMPLETE, onRingLoaded);
			l.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, onIoError);
			l.load(new URLRequest(this.baseUrl+ "rings/"+ringName+".swf"), Globals.getLoaderContext());
		}
		private function onRingLoaded(evt:Event):void{
			this.ringMcRef = Sprite(LoaderInfo(evt.target).content);
			
			if ( this.ringMcRef.getChildByName("eDist") != null ){
				this.mcRingInfo.mcEffect.visible = true;
			}else{
				this.mcRingInfo.mcEffect.visible = false;
			}
			
			Sprite(this.mcRingInfo.mcRingTxt).transform.colorTransform = new ColorTransform(1,1,1,1,0,0,0,0);
			
			LoaderInfo(evt.target).loader.contentLoaderInfo.removeEventListener(Event.COMPLETE, onRingLoaded);
			LoaderInfo(evt.target).loader.contentLoaderInfo.removeEventListener(IOErrorEvent.IO_ERROR, onIoError);
			LoaderFactory.getInstance().checkIn(LoaderInfo(evt.target).loader);
			
		}		
		private function onIoError(evt:IOErrorEvent):void{
			this.mcRingInfo.txtRingName.text = "invalide ring Name";
			Sprite(this.mcRingInfo.mcRingTxt).transform.colorTransform = new ColorTransform(1,0,0,1,0,0,0,0);
			this.ringMcRef = null;
			LoaderInfo(evt.target).loader.contentLoaderInfo.removeEventListener(Event.COMPLETE, onRingLoaded);
			LoaderInfo(evt.target).loader.contentLoaderInfo.removeEventListener(IOErrorEvent.IO_ERROR, onIoError);
		}
		
		
		// header
		private function onAvatarLoadClick(evt:MouseEvent):void{
			loadPlayer(this.mcHeader.txtUrl.text);
		}
		
		// Ring info 
		private function onRingLoadClick(evt:MouseEvent):void{
			this.loadRing(this.mcRingInfo.txtRingName.text);
		}
		
		private function onBtn0(evt:MouseEvent):void{
							
			if (this.ringMcRef != null){				
				if (this.mcRingInfo.chkCaster.selected){
					this.atkStartTime = getTimer();					
					var ra:RingAnim = this.Player.playRingAnim("RING", 0, "caster", null, -1, this.ringMcRef);
					ra.addEventListener(RingAnim.HIT_TIME, onHitTime);
				}
				if (this.mcRingInfo.chkTarget.selected){					
					this.Player.playRingAnim("RING", 0, "target", null, -1, this.ringMcRef);
				}
			}			
		}
		private function onBtn1(evt:MouseEvent):void{
			if (this.ringMcRef != null){
				if (this.mcRingInfo.chkCaster.selected){					
					this.atkStartTime = getTimer();
					//this.Player.playRingAnim("RING", 1, "caster", null, -1, this.ringMcRef);
					var ra:RingAnim = this.Player.playRingAnim("RING", 1, "caster", null, -1, this.ringMcRef);
					ra.addEventListener(RingAnim.HIT_TIME, onHitTime);
				}
				if (this.mcRingInfo.chkTarget.selected){
					this.Player.playRingAnim("RING", 1, "target", null, -1, this.ringMcRef);
				}
			}			
		}
		private function onBtn2(evt:MouseEvent):void{
			if (this.ringMcRef != null){
				if (this.mcRingInfo.chkCaster.selected){
					this.atkStartTime = getTimer();					
					//this.Player.playRingAnim("RING", 2, "caster", null, -1, this.ringMcRef);
					var ra:RingAnim = this.Player.playRingAnim("RING", 2, "caster", null, -1, this.ringMcRef);
					ra.addEventListener(RingAnim.HIT_TIME, onHitTime);
				}
				if (this.mcRingInfo.chkTarget.selected){
					this.Player.playRingAnim("RING", 2, "target", null, -1, this.ringMcRef);
				}
			}			
		}
		private function onBtn3(evt:MouseEvent):void{
			if (this.ringMcRef != null){
				if (this.mcRingInfo.chkCaster.selected){
					this.atkStartTime = getTimer();
					//this.Player.playRingAnim("RING", 3, "caster", null, -1, this.ringMcRef);
					var ra:RingAnim = this.Player.playRingAnim("RING", 3, "caster", null, -1, this.ringMcRef);
					ra.addEventListener(RingAnim.HIT_TIME, onHitTime);
				}
				if (this.mcRingInfo.chkTarget.selected){
					this.Player.playRingAnim("RING", 3, "target", null, -1, this.ringMcRef);
				}
			}			
		}
		
		private function onHitTime(evt:Event):void{
			var dt:int  = getTimer() - this.atkStartTime;
			this.mcHit.gotoAndPlay(1)
			TextField(this.txtHitTime).htmlText = String(dt);
			//trace("dt:", dt.toString());
			RingAnim(evt.target).removeEventListener(RingAnim.ANIM_DONE, onHitTime);
		}
		
		// effect
		private function onRadioChange(e:Event):void {
//			var rbg:RadioButtonGroup = e.target as RadioButtonGroup;
//            var rb:RadioButton = rbg.selection;           
//            this.radioLevel = int(rb.value);
        }
        
        private function onBtnStart(e:MouseEvent):void{
        	if (this.raEffect == null){
        		this.raEffect = this.Player.playRingAnim("RING", this.radioLevel, "effect", null, -1, this.ringMcRef); 
        	}        	      	        
        }
        private function onBtnStop(e:MouseEvent):void{
        	this.raEffect.dispell();
        	this.raEffect = null;
        }	
		
		// Direction Buttons
		private function onBtnDL(evt:MouseEvent):void{
			this.Player.scaleX = 1;	
			this.Player.setDirection(45);
		}
		private function onBtnUL(evt:MouseEvent):void{
			this.Player.scaleX = 1;		
			this.Player.setDirection(-45);
		}
		private function onBtnUR(evt:MouseEvent):void{
			this.Player.scaleX = -1;		
			this.Player.setDirection(-45);
		}
		private function onBtnDR(evt:MouseEvent):void{
			this.Player.scaleX = -1;					
			this.Player.setDirection(45);
		}
		
		
		
		//---- Actor Asset Implementation
		
		public function getNewReticle():Sprite{
			return new Reticle();
		}
		
		public function getNewGenericHitAnim():Sprite{
			//trace("show hits");
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
		
		public function getNewDefaultAvStrip():Bitmap{
			var bmd:BitmapData = new DefaultAvStrip(1200, 150);
			var b:Bitmap = new Bitmap(bmd);
			return b;
		}
		
	}
}