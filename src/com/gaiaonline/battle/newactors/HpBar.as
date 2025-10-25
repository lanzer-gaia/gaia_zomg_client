package com.gaiaonline.battle.newactors
{
	import com.gaiaonline.flexModulesAPIs.globalevent.GlobalEvent;
	import com.gaiaonline.utils.DisplayObjectUtils;
	import com.gaiaonline.utils.VisManagerSingleParent;
	
	import flash.display.MovieClip;
	import flash.text.TextField;
	
	public class HpBar extends MovieClip
	{			
		private var maxHp:int = 100;
		private var hp:int = 100;	
		
		private var _actorId:String = null;
		
		private var exhaustion:int = 0;
		private var maxExhaustion:int = 100;
		
		private var _type:int = 0; // 0=player  1=monster 2=Npc  3=spawn  4=env usable 5=critter
		private var _crewState:String = null;
	
		private var _isForGuest:Boolean = false;
				
		private var visManager:VisManagerSingleParent = null;

		public var txtName:TextField;
		public var hpBar:MovieClip;
		public var exhaustionBar:MovieClip;		
		public var mcInCrewState:MovieClip;
		public var hpbar:MovieClip;
						
		public function HpBar():void {
			this.mouseEnabled = false;
			this.mouseChildren = false;
		}
		
		public function init(actorId:String):void {
			this._actorId = actorId;
			this.visManager = new VisManagerSingleParent(this);			
			this.updateHpBar();
			this.updateExhaustion();
			DisplayObjectUtils.addWeakListener(GlobalEvent.eventDispatcher, GlobalEvent.IN_CREW_STATE_UPDATE, onInCrewStateUpdate);
			DisplayObjectUtils.addWeakListener(GlobalEvent.eventDispatcher, GlobalEvent.USER_LEVEL_SET, onUserLevelSet);			
		}		
		
		private function onInCrewStateUpdate(e:GlobalEvent):void {
			if (e.data.actorId == this._actorId) {
				var newCrewState:String = e.data.inCrewState;
				if (this._crewState != newCrewState) {
					this._crewState = newCrewState;
					this.setInCrewState(this._crewState);
				}
			}				
		}

		private function onUserLevelSet(e:GlobalEvent):void {
			if (e.data.actorId == this._actorId) {
				this._isForGuest = e.data.isGuest;
				this.setInCrewState(this._crewState);					
			}
		}
			
		public function setMaxHp(maxHp:int):void{
			if (this.maxHp != maxHp) {
				this.maxHp = maxHp;
				this.updateHpBar();
			}
		}
		public function setHp(hp:int):void{
			if (this.hp != hp) {
				this.hp = hp;
				this.updateHpBar();
			}
		}
		private function updateHpBar():void{
			if (this.hpbar && this.hpbar.bar) {
				this.hpbar.bar.scaleX = (this.hp/this.maxHp);
			}			
		}
		
		public function setExhaustion(exhaustion:int):void{
			if (this.exhaustion != exhaustion) {
				this.exhaustion = exhaustion
				this.updateExhaustion();
			}
		}
		public function setMaxExhaustion(max:int):void{
			if (this.maxExhaustion != max) {
				this.maxExhaustion = max;
				this.updateExhaustion();
			}
		}
		
		private function updateExhaustion():void{
			var p:Number = (this.maxExhaustion - this.exhaustion)/this.maxExhaustion;
			if (this.exhaustionBar.scaleX != p) {				
				this.exhaustionBar.scaleX = p//(this.exhaustion/this.maxExhaustion);
			}			
		}
		
		public function setName(actorName:String):void{
			if (this.txtName.text != actorName) {
				this.txtName.text = actorName;
			}			
		}
		
		
		public function setNameColor(c:int):void{
			if (this.txtName.textColor != c) {
				this.txtName.textColor = c;
			}
		}
		
		private function setNameVisible(visible:Boolean):void {
			this.visManager.setVisible(this.txtName, visible);			
		}

		private function setExhaustionBarVisible(visible:Boolean):void {
			this.visManager.setVisible(this.exhaustionBar, visible);			
		}

		private function setHPBarVisible(visible:Boolean):void {
			this.visManager.setVisible(this.hpbar, visible);			
		}

		private function setInCrewStateVisible(visible:Boolean):void {
			this.visManager.setVisible(this.mcInCrewState, visible);			
		}
		
		public function setDisplay(showName:Boolean = true, showExhaustion:Boolean = true, showHp:Boolean = true, showInCrewState:Boolean = true):void{
			var yName:int = -5;
			if (showHp){
				yName = 1;				
			}
			this.setHPBarVisible(showHp);
			
			if (showExhaustion){
				yName = 2;
			}
			
			this.setExhaustionBarVisible(showExhaustion);
			this.setInCrewStateVisible(showInCrewState);
			
			this.txtName.y = yName;
			this.setNameVisible(showName);
		}
		
		
		public function setType(type:int):void {
			if (this._type != type) {
				this._type = type;
				if (this._type == 1){ // monster
					this.setNameVisible(false);
					this.txtName.y = 2;
					this.setExhaustionBarVisible(false);
					this.setHPBarVisible(true);
					this.setInCrewStateVisible(false);
				}else if (this._type == 2){ // Npc
					this.setNameVisible(true);
					this.txtName.y = -5;
					this.setExhaustionBarVisible(false);
					this.setHPBarVisible(false);
					this.setInCrewStateVisible(false);							
				}else{
					this.setNameVisible(true);
					this.txtName.y = 2;
					this.setExhaustionBarVisible(true);
					this.setHPBarVisible(true);
					this.setInCrewStateVisible(true);															
				}
			}
		}
		
		
		public function setInCrewState(inCrewState:String):void{			
			if (this._type != 0 || this._isForGuest) { // not a player; this is just a safety guard
				this.setInCrewStateVisible(false);
				return;
			}
			
			if (this.mcInCrewState) {			
				switch (inCrewState){
					case BaseActor.CREW_STATE_LOOKING:
						this.setInCrewStateVisible(true);					
						this.mcInCrewState.gotoAndStop("lookingForCrew");
						break;
					case BaseActor.CREW_STATE_IN:
						this.setInCrewStateVisible(true);										
						this.mcInCrewState.gotoAndStop("inACrew");
						break;
					default: 
						this.setInCrewStateVisible(false);										
						break;
				}
			}
		}		
	}
}