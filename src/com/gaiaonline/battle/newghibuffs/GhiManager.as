package com.gaiaonline.battle.newghibuffs
{
	import com.gaiaonline.battle.GlobalTexts;
	import com.gaiaonline.battle.ui.UiGhiHolder;
	import com.gaiaonline.battle.ui.UiGhiInfo;
	import com.gaiaonline.battle.ui.events.GhiHolderEvent;
	import com.gaiaonline.battle.utils.BattleUtils;
	import com.gaiaonline.flexModulesAPIs.globalevent.GlobalEvent;
	import com.gaiaonline.utils.DisplayObjectUtils;
	
	import flash.text.TextField;	

	public class GhiManager
	{
		private var _ghiHolder:UiGhiHolder = null; // class corresponding to the UI
		private var _ghiInfo:UiGhiInfo = null; // class corresponding to the UI
		private var _noGhiTxt:TextField = null // class corresponding to the UI
		
		private var _selectedSlot:int = -1;
		
		private var _nextSlotNum:uint = 0;
		
		private var _slotToIconMap:Object = new Object();
		
		public function GhiManager(ghiHolder:UiGhiHolder, ghiInfo:UiGhiInfo, noGhiText:TextField) {
			_ghiHolder = ghiHolder;
			_ghiHolder.addEventListener(GhiHolderEvent.GHI_MOUSE_DOWN, onSlotMouseDown, false, 0, true);
			
			_ghiInfo = ghiInfo;			
			
			_noGhiTxt = noGhiText;
			_noGhiTxt.text = GlobalTexts.getNoGhiText();
			
			setInfoVisible(false);
			
			DisplayObjectUtils.addWeakListener(GlobalEvent.eventDispatcher, GlobalEvent.GHI_BUFFS_LOADED, onGhiBuffsUpdated);
		}
		
		public function dispose():void {
			_ghiHolder = null;
			_ghiInfo = null;
			_noGhiTxt = null;
			_slotToIconMap = null;						
		}		
		
		private function setInfoVisible(visible:Boolean):void {
			_ghiInfo.visible = visible;
			_noGhiTxt.visible = !visible;
		}
		
		public function addIcon(icon:GhiBuffIcon, tooltipText:String = null):void {
			// add the item
			var index:uint = getSlotNumForIcon(icon);
			addItemToSlot(icon, index, tooltipText);
			_slotToIconMap[index] = icon;
			setInfoVisible(true);
			ensureItemSelected();						
		}

		private function getSlotNumForIcon(icon:GhiBuffIcon):uint {
			var slotNum:uint = this._nextSlotNum;
			++_nextSlotNum;
			return slotNum;
		}
		
		private function addItemToSlot(icon:GhiBuffIcon, index:uint, tooltipText:String = null):void {
			_ghiHolder.addItemToSlot(icon, index, tooltipText);
			icon.position = index;
		}

		private function onSlotMouseDown(e:GhiHolderEvent):void {
			var icon:GhiBuffIcon = e.ghiBuffIcon; 
			setSelectedSlot(icon.position);
			setGhiInfo(icon);
		}
		
		public function setGhiInfo(icon:GhiBuffIcon):void{
			var obj:Object = new Object();

			obj.ringId = icon.id;
			
			var buff:GhiBuff = GhiBuffsLoadManager.getBuff(obj.ringId);
			obj.ringImageUrl = buff.iconUrl;
			obj.ringName = buff.name;
			obj.description = buff.description;

			obj.stats = new Array();	
			if (buff.stats) {			
				for (var si:int = 0; si < buff.stats.length; si++){
					obj.stats.push({label:buff.stats[si].lable, value:buff.stats[si].value})
				}			
			}
			
			//obj.stats = [{label:"Knockback",value:"Very Strong"},{label:"Base Damage",value:"Weak"},{label:"Crowd Control",value:"Fear"},{label:"Speed",value:"Slow"},{label:"Range",value:"Short"},{label:"Strength",value:"High"}];
						
			_ghiInfo.setGhiInfo(obj);
			
			setInfoVisible(true);										
		}
		
		
		private function setSelectedSlot(slot:int):void{
			_ghiHolder.clearSelectedSlot(_selectedSlot);
			_ghiHolder.setSelectedSlot(slot);
			_selectedSlot = slot;
		}
		
		public function clearSelection():void{
			_ghiHolder.clearSelectedSlot(_selectedSlot)
			_selectedSlot = -1;
		}

		public function getSlotAt(x:Number, y:Number):int{
			var slot:int = -1;
			if (_ghiHolder.visible == true) {
				slot = _ghiHolder.getSlotAt(x, y);
			}
			return slot;		
		}

		public function clearAll():void{
			this.clearSelection();
			_nextSlotNum = 0;			
			_ghiHolder.clearAll();
			BattleUtils.cleanObject(_slotToIconMap);
			setInfoVisible(false);									
		}
		
		public function refresh(ghiBuffs:Array):void {
			this.clearAll();	
			for each (var buff:GhiBuff in ghiBuffs) {	
				if (buff.bitmap) {
					var icon:GhiBuffIcon = new GhiBuffIcon(buff.bitmap);
					icon.id = buff.id;
					addIcon(icon, buff.name);
				}
			}
		}
		
		private function ensureItemSelected():void {
			if (_selectedSlot == -1  && _nextSlotNum > 0) {
				this.setSelectedSlot(0);
				this.setGhiInfo(_slotToIconMap[0]);
			}
		}
		
		private function onGhiBuffsUpdated(evt:GlobalEvent):void {
			this.refresh(GhiBuffsLoadManager.ghiBuffs);				
		}
	}
}