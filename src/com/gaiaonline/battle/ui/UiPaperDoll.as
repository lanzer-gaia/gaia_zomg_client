package com.gaiaonline.battle.ui
{
	import com.gaiaonline.battle.ApplicationInterfaces.ILinkManager;
	import com.gaiaonline.battle.ApplicationInterfaces.IUIFramework;
	import com.gaiaonline.battle.GlobalColors;
	import com.gaiaonline.battle.newactors.ActorManager;
	import com.gaiaonline.battle.newrings.RingIconFactory;
	import com.gaiaonline.battle.ui.uiactionbar.UiItemBar;
	import com.gaiaonline.flexModulesAPIs.globalevent.GlobalEvent;
	import com.gaiaonline.objectPool.LoaderFactory;
	import com.gaiaonline.utils.DisplayObjectUtils;
	import com.gaiaonline.utils.VisManagerSingleParent;
	
	import flash.display.Bitmap;
	import flash.display.DisplayObject;
	import flash.display.Loader;
	import flash.display.LoaderInfo;
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.MouseEvent;
	import flash.net.URLRequest;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	
	public class UiPaperDoll
	{		
		private var avContainer:MovieClip;
		private var avatarName:TextField;
		private var clanName:TextField;
		private var conLevel:TextField;
		private var totalCharge:TextField;
		private var icoCL:MovieClip;
		private var icoTotalCharge:MovieClip;
		
		private var accuracyPoints:TextField;		
		private var luckPoints:TextField;
		private var dodgePoints:TextField;
		private var willpowerPoints:TextField;		
		private var speedPoints:TextField;
		private var weightPoints:TextField;
		private var healthPoints:TextField;
		private var regenSec:TextField;
		private var exhaustionRegenSec:TextField;		
		private var badgeName:TextField;
		
		private var badgeHeadline:MovieClip;
		private var clanTitle:MovieClip;
		private var ringSlots:MovieClip;
		
		//private var avatarBtn:DefaultButton;
		
		private var actorId:String;
		
		// the actual movie clip/ui element
		private var _mcPaperDoll:MovieClip = null;
		
		private var visManager:VisManagerSingleParent
		
		private var _uiFramework:IUIFramework = null;
		private var _linkManager:ILinkManager = null;

		public function UiPaperDoll(uiFramework:IUIFramework, linkManager:ILinkManager, mcPaperDoll:MovieClip) {
			this._uiFramework = uiFramework;
			this._linkManager = linkManager;
			
			_mcPaperDoll = mcPaperDoll;

			avContainer = mcPaperDoll.avContainer;
			avatarName = mcPaperDoll.avatarName;
			clanName = mcPaperDoll.clanName;
			totalCharge = mcPaperDoll.totalCharge;
			conLevel = mcPaperDoll.conLevel;
			icoCL = mcPaperDoll.icoCL;
			icoTotalCharge = mcPaperDoll.icoTotalCharge;
		
			accuracyPoints = mcPaperDoll.accuracyPoints;
			luckPoints = mcPaperDoll.luck;
			dodgePoints = mcPaperDoll.dodgePoints;
			willpowerPoints = mcPaperDoll.willpowerPoints;
			speedPoints = mcPaperDoll.speedPoints;
			weightPoints = mcPaperDoll.weightPoints;
			healthPoints = mcPaperDoll.healthPoints;
			regenSec = mcPaperDoll.regenSec;
			exhaustionRegenSec = mcPaperDoll.staminaRegen;
			badgeName = mcPaperDoll.badgeName;
		
			badgeHeadline = mcPaperDoll.badgeHeadline;
			clanTitle = mcPaperDoll.clanTitle;
			ringSlots = _mcPaperDoll.ringSlots;
			
			/*
			avatarBtn = _mcPaperDoll.characterLinkBtn as DefaultButton;
			if (avatarBtn != null){
				avatarBtn.init("Customize avatar",true,false);
				avatarBtn.x = 270-avatarBtn.width
				avatarBtn.addEventListener(MouseEvent.CLICK,openUserWebsiteInfo, false, 0, true);
			}
			*/
			
			this.visManager = new VisManagerSingleParent(this._mcPaperDoll);			

			//this.setWidgetVisible(avatarBtn, false);
			
			_mcPaperDoll.tabChildren = false;
			_mcPaperDoll.tabEnabled = false;			
			
			// Hidden for now, since we're not using them.
			this.setWidgetVisible(badgeName, false);
			this.setWidgetVisible(badgeHeadline, false);			
		}
		
		private function setWidgetVisible(widget:DisplayObject, visible:Boolean):void {
			this.visManager.setVisible(widget, visible);
		}

		//**** Main PaperDoll Functionality		
		public function setInfo(initObj:Object):void{
			if (initObj.actorId != null){
				this.actorId = initObj.actorId;
			}
			
			if (initObj.avatarUrl != null){
				this.getAvatarImage(initObj.avatarUrl);
			}				
			
			if (initObj.userName != null){
					avatarName.text = initObj.userName.toUpperCase();
			}

			// assume no cl cap, so calculate normally, and format normally
			var conLevelNum:Number = NaN;
			if (initObj.conLevel != null){
				conLevelNum = initObj.conLevel;
			} else {
				conLevelNum = ActorManager.actorIdToActor(this.actorId).conLevel;
			}
			conLevel.textColor = this.totalCharge.textColor;
			icoCL.gotoAndStop("normal");
			
			// check if the conLevel is modified, and if so, change value and formatting
			if (initObj.suppressedCL != null && initObj.suppressedCL < conLevelNum) {
				icoCL.gotoAndStop("capped");
				conLevel.textColor = GlobalColors.CLCapColor; 
				conLevelNum = initObj.suppressedCL
			}
						
			if (!isNaN(conLevelNum) && this.conLevel != null) {
				conLevel.text = UiManager.formatConLevel(conLevelNum);
			}

			if (initObj.totalCharge != null){
				totalCharge.text = initObj.totalCharge;
			}
			if (initObj.clanName){
				if (initObj.clanName != ""){					
					clanName.text = initObj.clanName;			
				} else {
					clanName.text = "";
					this.setWidgetVisible(clanTitle, false);			
				}
			}
			
			this.setScorePoints(initObj);
			
			if (initObj.rings != null){
				this.updateRings(initObj.rings);
			}
			
			if (initObj.badge != null){
				//this.addBadge();
			}		
			
			/*
			if (avatarBtn != null){				
				if (this.actorId != ActorManager.getInstance().myActor.actorId){									
					avatarBtn.init("View my profile",true,false);
					avatarBtn.x = 270-avatarBtn.width
				}				
			}
			this.setWidgetVisible(avatarBtn, true);
			*/
		}	
		
		//--- Avatar button link
		private function openUserWebsiteInfo(e:MouseEvent):void{
			GlobalEvent.eventDispatcher.dispatchEvent(new GlobalEvent(GlobalEvent.CUSTOMIZE_AVATAR_REQUESTED, { actorId:this.actorId }));						
			}		
		
		//--- Avatar image 
		private function getAvatarImage(url:String):void{
			var l:Loader = LoaderFactory.getInstance().checkOut();
			l.contentLoaderInfo.addEventListener(Event.COMPLETE, onAvatarLoaded);
			l.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, onFileError);
			l.load(new URLRequest(url), this._uiFramework.loaderContextFactory.getLoaderContext());
			//trace("[Ext:Load] "+this.initObject.avatarUrl);
		}		
		private function onFileError(e:IOErrorEvent):void{
			//trace ("[PD, AvatarDummy: 	]",this.initObject.avatarUrl,e);
			LoaderInfo(e.target).loader.contentLoaderInfo.removeEventListener(Event.COMPLETE, onAvatarLoaded);
		}		
		private function onAvatarLoaded(evt:Event):void{
			if (LoaderInfo(evt.target).content != null){
				while(avContainer.numChildren > 0){
					avContainer.removeChildAt(0);
				}
				var avImg:Bitmap = Bitmap(LoaderInfo(evt.target).content);
				avImg.smoothing = true;				
				avContainer.addChild(avImg);
			}
			
			LoaderInfo(evt.target).loader.contentLoaderInfo.removeEventListener(Event.COMPLETE, onAvatarLoaded);
			LoaderInfo(evt.target).loader.contentLoaderInfo.removeEventListener(IOErrorEvent.IO_ERROR, onFileError);


			LoaderFactory.getInstance().checkIn(LoaderInfo(evt.target).loader);
		}
		
		//----
		private function updateRings(rings:Array):void
		{
			for(var i:int = 0; i <= UiItemBar.MAX_BAR_SLOT_INDEX ; ++i)
			{
				var ringSlot:MovieClip = ringSlots["b" + i];
				if (!rings[i] || rings[i].url != ringSlot.lastUrl)
				{
					while( ringSlot.numChildren > 1){
						ringSlot.removeChildAt( ringSlot.numChildren - 1) ;
					}
					if (rings[i])
					{
						ringSlot.lastUrl = rings[i].url;
						ringSlot.addChild(RingIconFactory.getBitmap(rings[i].url));				
						ringSlot.gotoAndStop(2);
						this._uiFramework.tooltipManager.addToolTip(ringSlot, rings[i].name);					
					}else{					
						ringSlot.gotoAndStop(1);
						ringSlot.lastUrl = null;
					}
				}
			}
		}
		
		private function setScorePoints(initObj:Object):void{
			var pointItems:Array = ["accuracy","dodge","willpower","speed","weight","health","luck"];
			for (var i:int=0;i<pointItems.length;i++){
				if (initObj[pointItems[i]]){
					//SCORE BAR				
					var tField:TextField = this[pointItems[i]+"Points"];
					tField.autoSize = TextFieldAutoSize.LEFT;
					var tPoints:Number = initObj[pointItems[i]];
					tField.text = tPoints.toString();
				}
			}
			if (initObj.regen) {
				regenSec.text = initObj.regen+" per second";
			}
			if( initObj.exhaustionRegen ) {
				// we are display "stamina regen", the opposite of exhaustion.
				exhaustionRegenSec.text = - initObj.exhaustionRegen + " per second";
			}
		}
		
		public function dispose():void {
			for(var i:int = 0; i <= UiItemBar.MAX_BAR_SLOT_INDEX ; i++){
				var ringSlot:MovieClip = ringSlots["b"+i];	
				this._uiFramework.tooltipManager.removeToolTip(ringSlot);
			}					
			
			DisplayObjectUtils.ClearAllChildrens(_mcPaperDoll, 5);
			DisplayObjectUtils.ClearAllChildrens(avContainer, 1); // just to make sure the bitmapData is cleaned up
			avContainer = null;
			avatarName = null;
			clanName = null;
			conLevel = null;
			totalCharge = null;			
			accuracyPoints = null;		
			luckPoints = null;
			dodgePoints = null;
			willpowerPoints = null;		
			speedPoints = null;
			weightPoints = null;
			healthPoints = null;
			regenSec = null;
			exhaustionRegenSec = null;		
			badgeName = null;			
			badgeHeadline = null;
			clanTitle = null;
			ringSlots = null;			
			//avatarBtn = null;			
			actorId = null;		
			visManager = null;							
		}
		
	}
}
