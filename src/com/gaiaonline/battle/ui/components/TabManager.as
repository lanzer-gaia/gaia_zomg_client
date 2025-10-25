package com.gaiaonline.battle.ui.components
{
	import flash.display.MovieClip;
	import flash.events.EventDispatcher;
	import flash.events.MouseEvent;
	
	public class TabManager extends EventDispatcher
	{
		public static const SELECTED_TAB_CHANGE:String ="SelectedTabChange";
		
		private var tabs:Array = new Array();
		public var activeTabIndex:int = -1;
		
		// Historically, TabManager would use the .visible property of the DisplayObject to manage hiding/showing, but this
		// has been found to still allow render updates to leak in from inactive tabs.  unparentOnDeactivate will fully remove
		// the DisplayObject from the stage instead to more forcefully prevent any stage redrawing.
		// If you're creating a new tabbed interface since this feature was introduced, you'll almost
		// certainly want to set unparentOnDeactivate to true; but we've let older tabbed UIs set it to false for compatibility issues. 
		private var _unparentOnDeactivate:Boolean = false;
		public function TabManager(unparentOnDeactivate:Boolean = true):void{
			_unparentOnDeactivate = unparentOnDeactivate;
		}
		
		public function addTabs(btn:TabButton, mcTab:MovieClip, active:Boolean = false):int {
			
			var index:int = this.tabs.push(new TabEntry(btn, mcTab, active, _unparentOnDeactivate)) - 1;
			btn.isActive = active;
			if (mcTab != null){
				mcTab.visible = active;
			}		
			btn.addEventListener(MouseEvent.CLICK, onBtnClick, false, 0, true);				
			if (active){
				this.setActive(index);
			}
			
			return index;
		}
		
		private function onBtnClick(evt:MouseEvent):void{
			var btn:TabButton = evt.currentTarget as TabButton;
			if (btn.isEnabled) {
				var lastIndex:int = this.activeTabIndex;
				activateTabByButton(TabButton(evt.currentTarget));
				
				this.dispatchEvent(new TabEvent(SELECTED_TAB_CHANGE, lastIndex, this.activeTabIndex));
			}
		}
		
		public function setActive(tabIndex:int):void{
			if (tabIndex >= 0) {
				activateTabByButton(TabEntry(this.tabs[tabIndex]).btn);
			}
		}
		
		private function activateTabByButton(tabButton:TabButton):void
		{
			for (var i:int = 0; i< this.tabs.length; ++i) {
				var tab:TabEntry = TabEntry(this.tabs[i]);
				var isActive:Boolean = tab.btn == tabButton;
			
				tab.btn.isActive = isActive;
				if (tab.mcTab != null){
					tab.mcTab.visible = isActive;
				}
				if (isActive) {
					this.activeTabIndex = i;
				}
				tab.activate(isActive);
			}
		}

		public function dispose():void {
			this.tabs = null;
		}	
		
	}
}
import com.gaiaonline.battle.ui.components.TabButton;
import flash.display.MovieClip;
import flash.display.DisplayObjectContainer;
import com.gaiaonline.battle.utils.DisplayObjectAttacher;
internal class TabEntry
{
	public var btn:TabButton;
	public var mcTab:MovieClip;
	private var _attacher:DisplayObjectAttacher = null;  // effectively acts as the flag that implements TabManager's unparentOnDeactivate mode
	public function TabEntry(_btn:TabButton, _mcTab:MovieClip, _active:Boolean, _unparentInactive:Boolean)
	{
		btn = _btn;
		mcTab = _mcTab;
		
		if (_unparentInactive && _mcTab != null) {
			_attacher = new DisplayObjectAttacher(_mcTab);
			activate(_active);
		}
	}
	
	private var _childIndex:int = -1;
	public function activate(bActivate:Boolean):void
	{
		if (_attacher != null) {
			_attacher.attached = bActivate;
		} 
	}
}