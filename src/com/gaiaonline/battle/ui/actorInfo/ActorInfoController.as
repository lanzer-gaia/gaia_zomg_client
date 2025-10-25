package com.gaiaonline.battle.ui.actorInfo
{
	import com.gaiaonline.battle.newactors.ActorDisplay;
	import com.gaiaonline.battle.newactors.ActorManager;
	import com.gaiaonline.battle.newactors.BaseActor;
	import com.gaiaonline.battle.newactors.BaseActorEvent;
	import com.gaiaonline.battle.ui.IFlexUiManager;
	import com.gaiaonline.flexModulesAPIs.FlexMenuItem;
	import com.gaiaonline.flexModulesAPIs.IMenuListener;
	import com.gaiaonline.flexModulesAPIs.actorInfo.IActorInfo;
	
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.Sprite;
	import flash.events.Event;
	
	public class ActorInfoController implements IMenuListener
	{
		private var _view:IActorInfo = null;
		
		private var _currTarget:BaseActor = null;
		private var _currName:String = null;
		private var _currId:String = null;
		private var _currRoomId:String = null;		
		private var _actorImage:Sprite = null;	

		private var _visible:Boolean = true;
		private var _isUsingRawData:Boolean = false;
		private var _viewParent:DisplayObjectContainer = null;
				
		private var _menuData:Object = null;
		
		private var _flexUiManangerImpl:IFlexUiManager = null;
		
		public function ActorInfoController(flexUiManagerImpl:IFlexUiManager) {
			this._flexUiManangerImpl = flexUiManagerImpl;
			this._menuData = this._flexUiManangerImpl.getArrayCollection();
		}
		
		public function onMenuItemClick(menuItem:FlexMenuItem):void {
			this._currTarget.handleMenuItemClick(menuItem.label, menuItem.data);			
		}
		 
		public function addView(view:IActorInfo):void {
			//@@@ REALLY ONLY HANDLE ONE VIEW NOW, SO SHOULD COMPLAIN IF ANOTHER IS SET
			this._view = view;
			this._viewParent = DisplayObject(view).parent;
			if (!this._isUsingRawData) {
				this.setActorInfo(this._currTarget, true);
			} else {
				this.setRawData(this._currName, this._currId, this._currRoomId);
			}
		}

		public function hasView(view:IActorInfo):Boolean {
			return view == this._view;
		}

		public function setActorInfo(target:BaseActor, forceUpdate:Boolean = false):void{
			this.setVisible(target != null);

			this._isUsingRawData = false;
			
			if (!target || target.targetType == BaseActor.TARGETTYPE_POWERUSABLE) {
				updateAll();
				return;
			}						
	
			if (!forceUpdate && target == this._currTarget) {
				return;
			}									

			if (this._currTarget) {
				this._currTarget.removeEventListener(BaseActorEvent.NAME_UPDATED, onNameUpdated);		
			}
			
			target.addEventListener(BaseActorEvent.NAME_UPDATED, onNameUpdated, false, 0, true);

			var prevTarget:BaseActor = this._currTarget;
			this._currTarget = target;

			if (target) {
				target.getActorDisplay().removeEventListener(ActorDisplay.LOADED, onActorDisplayLoaded);
				if (this._view || prevTarget != target){	
					loadActorInfo();
					if (!target.getActorDisplay().isLoaded) {
						// then listen for the LOADED event so we can update the UI
						target.getActorDisplay().addEventListener(ActorDisplay.LOADED, onActorDisplayLoaded, false, 0, true);
					}					
				} 
				
				this._currName = target.actorName;
				this._currId = target.actorId;				
				
				this.updateAll(forceUpdate);	
			}				
		}
		
		private function updateActorType():void {
			if (this._view && this._currTarget) {
				this._view.updateActorType(this._currTarget.actorType);
			}
		}		

		private function updateAll(force:Boolean = false):void {
			if (this._view) {
				this.updateActorType();
				this.updateName();
				this.buildMenu();					
			}			
		}
		
		public function setRawData(actorName:String, actorId:String, roomId:String):void {
			this._isUsingRawData = true;
			this._currName = actorName;
			this._currId = actorId;
			this._currRoomId = roomId;

			this.updateAll();
			this.setVisible(true);
		}
						
		private function setVisible(visible:Boolean):void {
			if (this._visible != visible) {
				this._visible = visible;
				this.updateVisibility();
			}				
		}
				
		public function getActor():BaseActor {
			return this._currTarget;
		}
		
		public function getActorId():String {
			return this._currId;
		}
		
		private function onNameUpdated(e:BaseActorEvent):void {
			if (e.actor.actorName != this._currName) {
				this._currName = e.actor.actorName;
				this.updateName();
			}
		}
		
		private function buildMenu():void {
			if (this._currTarget && !this._isUsingRawData) {
				var me:Boolean = (ActorManager.getInstance().myActor.actorId == this._currId);
				var guestUser:Boolean = this._currTarget.isGuestUser();
						
				// Because of 				            
            	// http://bugs.adobe.com/jira/browse/SDK-17302
            	// we can't reuse the same array collection; we have to create a new one each time						
				this._menuData = this._flexUiManangerImpl.getArrayCollection();
				
				this.addMenuItem(FlexMenuItem.VIEW_PROFILE);			
				
				//--- Chat
				if (!me) {
					if (!guestUser) {
						this.addMenuItem(FlexMenuItem.ADD_FRIEND);
					}
					//this.addMenuItem(FlexMenuItem.WHISPER);						
					
					var i:int = ActorManager.getInstance().myActor.ignoreList.indexOf(this._currId);
					if (i < 0){
						this.addMenuItem(FlexMenuItem.ADD_IGNORE);															
					}else{
						this.addMenuItem(FlexMenuItem.REMOVE_IGNORE);																					
					}
					 if (!guestUser) {
						this.addMenuItem(FlexMenuItem.REPORT_ABUSE);
					}								
				}
							
			}			
			if (this._view) {
				this._view.setMenu(this._menuData, this);
			}			
		}

		private function addMenuItem(label:String, alignment:String = "right", skinType:String = "main"):FlexMenuItem {
			var flexMenuItem:FlexMenuItem = new FlexMenuItem(label);
			this._menuData.addItem(flexMenuItem);
			flexMenuItem.alignment = alignment;
			flexMenuItem.skinType = skinType;
			return flexMenuItem;
		}		
		
		private function onActorDisplayLoaded(evt:Event):void {
			if (this._currTarget) {
				this._currTarget.getActorDisplay().removeEventListener(ActorDisplay.LOADED, onActorDisplayLoaded);						
			}
			loadActorInfo();
		}

		private function loadActorInfo():void {
			var target:BaseActor = this._currTarget;
								
			if (target != null) {
				this._currTarget = target;
				this._actorImage = target.getActorDisplay().getTargetInfoPortrait();
				this.updateImage();				
			}	
		}

		private function updateName():void {
			if (this._view) {
				this._view.updateName(this._currName);
			}
		}

		private function updateImage():void {
			if (this._view && this._actorImage) {
				this._view.updateImage(this._actorImage);
			}
		}

		private function updateVisibility():void {
			if (this._view) {
				var displayObject:DisplayObject = DisplayObject(this._view);
				if (displayObject.parent && !this._visible) {
					this._viewParent = displayObject.parent;
					this._viewParent.removeChild(displayObject);
				} else if (!displayObject.parent && this._visible) {						
					this._viewParent.addChild(displayObject);
				}
			}
		}
				
	}
}
