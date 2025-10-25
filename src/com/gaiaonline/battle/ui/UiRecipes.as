package com.gaiaonline.battle.ui
{
	import com.gaiaonline.assets.*;
	import com.gaiaonline.battle.ApplicationInterfaces.ILinkManager;
	import com.gaiaonline.battle.GlobalTexts;
	import com.gaiaonline.battle.gateway.BattleGateway;
	import com.gaiaonline.battle.newactors.BaseActor;
	import com.gaiaonline.battle.ui.UiItemsParts.RecipeItem;
	import com.gaiaonline.battle.ui.components.ScrollBarVer;
	import com.gaiaonline.flexModulesAPIs.globalevent.GlobalEvent;
	import com.gaiaonline.gsi.GSIEvent;
	import com.gaiaonline.utils.DisplayObjectUtils;
	
	import flash.display.MovieClip;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.geom.Rectangle;
	import flash.text.*;
	import flash.ui.Keyboard;

	public class UiRecipes extends MovieClip
	{
		private var initObject:Array;
		private var recipeItems:Array;
		private var recipeId:Number = -1;
		private var actorName:String = null;
		public var colBorder:MovieClip;
		public var recipeDesc:TextField;
		public var recipeDescTitle:TextField;
		public var recipeContainer:MovieClip;
		public var recipeMask:MovieClip;
		public var scrRecipeList:ScrollBarVer;
		public var noRecipesTxt:TextField;

		private var _gateway:BattleGateway = null;
		private var _linkManager:ILinkManager = null;		

		public function UiRecipes(){
		}

		public function init(gateway:BattleGateway, linkManager:ILinkManager):void {
			this._gateway = gateway;
			this._linkManager = linkManager;
			noRecipesTxt.text = GlobalTexts.getNoRecipesText();
			DisplayObjectUtils.addWeakListener(this._gateway, GSIEvent.LOADED, onGsiCallBack);
			DisplayObjectUtils.addWeakListener(GlobalEvent.eventDispatcher, GlobalEvent.PLAYER_CREATED, onPlayerCreated);			

			this.recipeItems = new Array();
			this.initObject = new Array();
			this.refresh(this.initObject);
			this.scrRecipeList.visible = false;			
		}

		private var _cachedArray:Array = [];		
		public function refresh(listRecipes:Array):void{
			
			listRecipes.sortOn("recipeName");

			_cachedArray.length = 0;
			var tmpArray:Array = _cachedArray;
			this.initObject = listRecipes;
			if (this.recipeItems == null) {
				this.recipeItems = new Array();
			}
						
			//--- Clear old recipies.
			while(this.recipeContainer.numChildren > 0){
				this.recipeContainer.removeChildAt(0);
			}			
			if (this.recipeItems.length > 0){
				for (var i:int=0;i<this.recipeItems.length;i++){
					delete this.recipeItems[i];
				}
			}		
			
			this.recipeItems.length = 0;
			var nextY:int  = 0;
			for (var r:int=0;r<listRecipes.length;r++){
				
				var recipeItem:RecipeItem = new RecipeItem(listRecipes[r]);
				
				this.recipeItems.push(recipeItem);
				recipeItem.y = nextY;
				this.recipeItems[r].addEventListener(MouseEvent.MOUSE_OVER,onItemOver, false, 0, true);
				this.recipeItems[r].addEventListener(MouseEvent.MOUSE_OUT,onItemOut, false, 0, true);
				this.recipeItems[r].addEventListener(MouseEvent.CLICK,onItemClick, false, 0, true);
				this.recipeItems[r].addEventListener(KeyboardEvent.KEY_DOWN,onRefresh, false, 0, true);

				this.recipeContainer.addChild(this.recipeItems[r]);
				
				// update the current description as well
				if (this.recipeId != -1 && recipeItem.id == this.recipeId) {
					setSelectedItem(recipeItem);
				} 
				
				nextY+=20;
			}
			
			if (this.recipeId == -1 && listRecipes.length) {
				setSelectedItem(this.recipeItems[0]);
			}
			
			this.scrRecipeList.init(this.recipeContainer, new Rectangle(this.recipeMask.x,this.recipeMask.y,this.recipeMask.width,this.recipeMask.height),true);
			
			noRecipesTxt.visible = (listRecipes.length == 0);
		}
			
		private function onItemOver(evt:MouseEvent):void{
			var recItem:Object = evt.target;
			if (this.recipeId != recItem.id)
				recItem.bg.alpha = 0.2;
		}

		private function onItemOut(evt:MouseEvent):void{
			var recItem:Object = evt.target;
			if (this.recipeId != recItem.id)
				recItem.bg.alpha = 0;
		}
		
		private function onItemClick(evt:MouseEvent):void{
			var recItem:Object = evt.target;
			if (this.recipeId != recItem.id){
				setSelectedItem(recItem);
			} 
		}

		private function setSelectedItem(recItem:Object):void {
			this.delightItem(recipeId);
			recItem.bg.alpha = 0.5;
			this.recipeId = recItem.id;
			this.recipeDesc.htmlText = this.getDesc(recItem._items);
			
			// [bgh] DIRTY: strip the rich formatting cause flash is freaking out
			var text:String = this.recipeDesc.text;
			this.recipeDesc.text = "";
			this.recipeDesc.text = text;
			// END DIRTY
			
			var targetId:int = 0;
			for(var i:int = 0; i<this.recipeItems.length; i++){
				if (recItem.id == this.recipeItems[i].id){
					targetId = i;
					break;
				}
			}
			this.recipeDescTitle.text = this.recipeItems[targetId].recipeName.text;
			
			this.colBorder.alpha = 0.9;			
		}	
			
		// @@ need to add limit on number of times a user can refresh 1x per minute
		private function onRefresh(evt:KeyboardEvent):void {
			if (evt.charCode == Keyboard.ENTER) {
				this.updateRecipeList();
			}
		}
		
		private function onPlayerCreated(e:GlobalEvent):void {
			this.actorName = BaseActor(e.data.actor).actorName;
		}
		
		//******************************************
		// GSI Update Recipes Panel **************************
		//******************************************
		public function updateRecipeList():void{
			this._gateway.gsiInvoke(7011, this._gateway.sessionId, this.actorName);
		}
		
		// GSI CALL BACK
		private function onGsiCallBack(evt:GSIEvent):void{
			switch(evt.gsiMethod){
				case 7011:												
					this.onGsi_7011(evt.gsiData);
					break;				
			}
		}		

		private var _cached7011Array:Array = [];
		private function onGsi_7011(data:Object):void{			
			if (data is Number){
				return;
			}
			_cached7011Array.length = 0;
			var obj:Array = _cached7011Array;
			for (var ri:int = 0; ri < data.length; ri++){
				var recipe:Object = new Object();
				recipe.items = new Array();				

				for (var item:String in data[ri]){					
					var s:Array = String(data[ri][item]).split("|");
					if (item == "1"){
						recipe.recipeName = String(s[5].split("+").join(" ")).replace("Recipe: ", "");
						recipe.recipeId = s[1];
					}else if (item != "a"){
						var rItem:Object = {itemName:s[5].split("+").join(" "),itemId:s[1],needed:s[2],total:s[3]};
						recipe.items.push(rItem);
					}else{
						
					}		
					
				}
				obj.push(recipe);
			}
				
			/*			
			0 [type] => item / result
			1 [item_id] => 17765            
            2 [needed] => 1
            3 [userhas] => 1
            4 [check] => 1
            5 [name] => Recipe: Newspaper
			 */
			this.refresh(obj);
			obj.length = 0;
		}
		
		
		
		private function delightItem(itemId:Number):void{
			for (var i:int=0;i<this.recipeItems.length;i++){
				if (this.recipeItems[i].id == itemId)
					this.recipeItems[i].bg.alpha = 0;
			}
		}
		
		private function getDesc(_items:Array):String{
			var desc:String = "";
			for (var i:int=0;i<_items.length;i++){
				var color:String = "#FFFFFF";
				var n:int = parseInt(_items[i].needed);
				var t:int = parseInt(_items[i].total);
				if (n>t) color = "#FF0000";
				desc += "<b><font color=\""+color+"\">";
				desc += "- "+_items[i].itemName + " "+_items[i].total+"/"+_items[i].needed+"<br>";
				desc += "</font></b>";
			}
			return desc;			
		}

	}
}
