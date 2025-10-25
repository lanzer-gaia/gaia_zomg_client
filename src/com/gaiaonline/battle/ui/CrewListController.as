package com.gaiaonline.battle.ui
{
	import com.gaiaonline.battle.newactors.ActorManager;
	import com.gaiaonline.battle.newactors.BaseActor;
	import com.gaiaonline.battle.newactors.TeamManager;
	import com.gaiaonline.battle.ui.actorInfo.TargetInfoController;
	import com.gaiaonline.flexModulesAPIs.actorInfo.ITargetInfo;
	import com.gaiaonline.flexModulesAPIs.crewListWidget.ICrewList;
	import com.gaiaonline.flexModulesAPIs.globalevent.GlobalEvent;
	import com.gaiaonline.utils.DisplayObjectUtils;
	
	import flash.display.DisplayObject;
	import flash.events.MouseEvent;
	
	public class CrewListController implements IAsyncCreationHandler
	{
		private var _flexUiManager:IFlexUiManager = null;
		private var _view:ICrewList = null;
		
		private var _targetInfoControllersNeedingViews:Array = [];
		private var _targetInfoControllers:Array = [];
		
		public function CrewListController(flexUiManager:IFlexUiManager) { 
			this._flexUiManager= flexUiManager;
			this.initInternalState();
		}
		
		public function addView(view:ICrewList):void {
			//@@@ REALLY ONLY HANDLE ONE VIEW NOW, SO SHOULD COMPLAIN IF ANOTHER IS SET
			this._view = view;
			var len:uint = this._targetInfoControllersNeedingViews.length;
			for (var i:uint = 0; i < len; ++i) {
				this.getNewTargetView();
			}
		}
		
		private function initInternalState():void {			
			DisplayObjectUtils.addWeakListener(GlobalEvent.eventDispatcher, GlobalEvent.LEFT_TEAM, onLeftTeam);						
			DisplayObjectUtils.addWeakListener(GlobalEvent.eventDispatcher, GlobalEvent.INVITE_TO_TEAM, onInviteToTeam);
		}

		public function onCreation(object:Object, modulePath:String):void
		{
			switch(modulePath) {
				case ModulePaths.TARGETINFO:
					onTargetInfoViewLoaded(object);
					break;
				default: // do nothing
					break;
			}
		}

		private function getNewTargetView():void {
			this._flexUiManager.getModule(ModulePaths.TARGETINFO, this);
		}				

		private function onTargetInfoViewLoaded(instance:Object):void {
			var targetInfoInstance:DisplayObject = DisplayObject(instance);
			var targetInfoController:TargetInfoController = this._targetInfoControllersNeedingViews.shift();
			this._view.addPlayerInfo(targetInfoInstance);
			this._flexUiManager.initializeContainer(targetInfoInstance);
			targetInfoController.addView(targetInfoInstance as ITargetInfo);
			targetInfoInstance.addEventListener(MouseEvent.CLICK, onViewSelected, false, 0, true);
		}
		
		private function onViewSelected(e:MouseEvent):void {
			var targetInfoInstance:ITargetInfo = ITargetInfo(e.currentTarget);
			for each (var controller:TargetInfoController in this._targetInfoControllers) {
				if (controller.hasView(targetInfoInstance)) {
					ActorManager.getInstance().selectActor(controller.getActorId());
				}
			}
		}
		
		private function onLeftTeam(e:GlobalEvent):void {
			var actorId:String = e.data.actorId;
			if (actorId != ActorManager.getInstance().myActor.actorId) {
				this.removeUser(actorId);
			}			
		}
		
		private function onInviteToTeam(e:GlobalEvent):void {
			var actorId:String = e.data.actorId;
			var actorName:String = e.data.actorName;
			var roomId:String = e.data.roomName;
			if (this.actorIdToControllerIndex(actorId) == -1 &&
				!ActorManager.getInstance().myActor.isOnMyTeam(actorId) && 
				ActorManager.getInstance().myActor.teamCount() < TeamManager.TEAM_MAX) {
				
				var targetInfoController:TargetInfoController = this.getNewtargetInfoController();
				targetInfoController.setRawData(actorName, actorId, roomId);
			}
		}
		
		private function removeUser(actorId:String):void {
			var controllerIndex:int = this.actorIdToControllerIndex(actorId);
			if (controllerIndex >= 0) {
				var targetInfoController:TargetInfoController = this._targetInfoControllers[controllerIndex];
				this._targetInfoControllers.splice(controllerIndex, 1);
				targetInfoController.setActorInfo(null);
			}
		}
		
		public function clearAll():void{
			var me:BaseActor = ActorManager.getInstance().myActor;
			var myController:TargetInfoController = null;
			var targetInfoController:TargetInfoController = null; 
			while (this._targetInfoControllers.length > 0) {
				targetInfoController = this._targetInfoControllers[0];
				if (targetInfoController.getActorId() != me.actorId) {
					this.removeUser(targetInfoController.getActorId());
				} else {
					myController = this._targetInfoControllers[0];
					this._targetInfoControllers.splice(0,1);
				}
			}
			if (myController) {
				this._targetInfoControllers.push(myController);
			}
		}
		
		// passing in null will let you find the first unused controller
		private function actorIdToControllerIndex(actorId:String):int {
			var len:uint = this._targetInfoControllers.length;
			for (var i:uint = 0; i < len; ++i) {
				var targetInfoController:TargetInfoController = this._targetInfoControllers[i];
				var controllerActor:BaseActor = targetInfoController.getActor();
				var controllerActorId:String = targetInfoController.getActorId();				
				if (actorId == null) {
					if (controllerActor == null && controllerActorId == null) {
						return i;
					}
				} else {
					if (controllerActorId == actorId) {
						return i;					
					}
				}
			}
			return -1;
		}
				
		private function getActorEntry(actor:BaseActor):TargetInfoController {
			var targetInfoController:TargetInfoController = null;
			var controllerIndex:int = this.actorIdToControllerIndex(actor.actorId);
			if (controllerIndex == -1) { // don't have a controller for this actor yet
				// let's see if we have an empty controller to reuse;
				var unusedControllerIndex:int = this.actorIdToControllerIndex(null);
				if (controllerIndex == -1) { // didn't find one, so let's create a new one
					targetInfoController = this.getNewtargetInfoController();
					targetInfoController.setActorInfo(actor);
				}
			} else { // we do have a controller for this actor
				targetInfoController = this._targetInfoControllers[controllerIndex];
			}
			
			return targetInfoController;
		}

		private function getNewtargetInfoController():TargetInfoController {
			var targetInfoController:TargetInfoController = new TargetInfoController(this._flexUiManager, false);					
			this._targetInfoControllers.push(targetInfoController);						
			this._targetInfoControllersNeedingViews.push(targetInfoController);
			if (this._view) {
				this.getNewTargetView();
			}
			return targetInfoController;
		}

		private function getMyActorEntry():TargetInfoController {
			return this.getActorEntry(ActorManager.getInstance().myActor);
		}		
		
		public function updateUser(actor:BaseActor):void{
			if (!actor) {
				return;
			}			
			
			var targetInfoController:TargetInfoController = this.getActorEntry(actor);
			if (targetInfoController.getActor() == null) { // then it was pending
				targetInfoController.setActorInfo(actor);
			}		
		}

		// null == remove any highlighted
		private var _lastHighlightedController:TargetInfoController;
		public function highlightUser(actor:BaseActor):void {

			const index:int = actor ? this.actorIdToControllerIndex(actor.actorId) : -1;
			var targetInfoController:TargetInfoController = (index >= 0) ? _targetInfoControllers[index] : null;
			if (targetInfoController != _lastHighlightedController) {
				if (_lastHighlightedController) {
					_lastHighlightedController.setHighlighted(false);
				}
				_lastHighlightedController = targetInfoController;
				if (_lastHighlightedController) {
					_lastHighlightedController.setHighlighted(true);
				}
			}	
		}
	}
}