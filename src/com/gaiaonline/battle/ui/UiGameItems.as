package com.gaiaonline.battle.ui
{
	import com.gaiaonline.battle.ApplicationInterfaces.ILinkManager;
	import com.gaiaonline.battle.ApplicationInterfaces.IUIFramework;
	import com.gaiaonline.battle.Globals;
	import com.gaiaonline.battle.ItemLoadManager.GameItemIconCustomization;
	import com.gaiaonline.battle.ItemLoadManager.IItemLoader;
	import com.gaiaonline.battle.ItemLoadManager.ItemIcon;
	import com.gaiaonline.battle.ui.uiitemdisplay.ItemDisplay;
	
	import flash.display.MovieClip;
	
	public class UiGameItems extends MovieClip
	{		
		public var itemDisplay:ItemDisplay;
		private var items:Object = new Object();
		
		private var _uiFramework:IUIFramework = null;
		private var _linkManager:ILinkManager = null;		
		
		public function UiGameItems() {	
			super();
		}
		
		public function init(uiFramework:IUIFramework, linkManager:ILinkManager):void {			
			this._uiFramework = uiFramework;
			this._linkManager = linkManager;
			this.itemDisplay.init(this._uiFramework.assetFactory);
			this.itemDisplay.numColumn = 15;
			this.itemDisplay.extraRows = 0;
			this.itemDisplay.minimumRows = 7;
						
		}
		
		
		public function updateItems(itemArray:Array):void{
			if (this._uiFramework.loadUserItems) {			
				this.itemDisplay.clearAll();
				if (itemArray == null){				
					return;	
				} 
				for (var i:int = 0 ; i < itemArray.length; i++){	
					
					var itemId:String = itemArray[i].id;
					var name:String = itemArray[i].name;
					var url:String = this._linkManager.getLink("images") + itemArray[i].itemThumbFile;				
					var num:int = itemArray[i].count;
					
					var il:ItemLoader;
					if (this.items[itemArray[i].id] == null){
						il = new ItemLoader(this._uiFramework.loaderContextFactory, itemId, name, url);
						this.items[itemArray[i].id] = {itemLoader:il};		
					}else{
						il = this.items[itemArray[i].id].itemLoader;
					}
					
					var ic:ItemIcon = new ItemIcon(this._uiFramework, GameItemIconCustomization.getInstance(), itemId, i, il);
					ic.displayNum = true;
					ic.quantity = num;
					this.itemDisplay.addItemIcon(ic, i);
					
					this.items[itemArray[i].id].itemIcon = ic;
						
				}				
			}
		}
		
		public function updateItemCount(itemId:String, offset:int):void{			
			if (this.items[itemId] != null && this.items[itemId].itemIcon != null){
				var ic:ItemIcon = this.items[itemId].itemIcon as ItemIcon;				
				ic.quantity += offset;				
			}
		}
		public function containItem(itemId:String):Boolean{
			return this.items[itemId] != null;
		}
	}	
}

	import com.gaiaonline.battle.ItemLoadManager.IItemLoader;
	import flash.events.EventDispatcher;
	import flash.display.DisplayObject;
	import flash.display.Loader;
	import com.gaiaonline.battle.StepLoader;
	import flash.net.URLRequest;
	import com.gaiaonline.battle.Globals;
	import flash.events.Event;
	import flash.display.Bitmap;
	import flash.display.LoaderInfo;
	import com.gaiaonline.battle.ItemLoadManager.ItemLoadEvent;
	import com.gaiaonline.battle.ItemManager.ItemManagerEvent;
	import com.gaiaonline.objectPool.LoaderFactory;
	import flash.system.LoaderContext;
	import com.gaiaonline.utils.factories.ILoaderContextFactory;
	

	class ItemLoader extends EventDispatcher implements IItemLoader{
		
		private var _bm:Bitmap;
		private var _name:String;
		private var _loaded:Boolean = false;
		
		public function ItemLoader(loaderContextFactory:ILoaderContextFactory, itemId:String, name:String, url:String){
			this._name = name;
			var l:Loader = LoaderFactory.getInstance().checkOut();
			l.contentLoaderInfo.addEventListener(Event.COMPLETE, onIconLoaded);
			StepLoader.add(l, new URLRequest(url), loaderContextFactory.getLoaderContext());
		}
		private function onIconLoaded(evt:Event):void{
			this._bm = LoaderInfo(evt.target).content as Bitmap;
			this._loaded = true;
			this.dispatchEvent(new ItemLoadEvent(ItemLoadEvent.ITEM_LOADED));
			LoaderInfo(evt.target).loader.contentLoaderInfo.removeEventListener(Event.COMPLETE, onIconLoaded);
			
			LoaderFactory.getInstance().checkIn(LoaderInfo(evt.target).loader);
		}
		
		public function get itemName():String{
			return this._name;
		}
		public function get itemDescription():String{
			return this._name;
		}
		public function get loaded():Boolean{
			return this._loaded;
		}
		public function getNewItemDisplay():DisplayObject{
			return this._bm;
		}
	}

	