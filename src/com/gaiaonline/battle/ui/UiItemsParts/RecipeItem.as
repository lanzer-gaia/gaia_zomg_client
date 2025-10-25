package com.gaiaonline.battle.ui.UiItemsParts
{
	import flash.display.MovieClip;
	import flash.text.TextField;
	
	public class RecipeItem extends MovieClip
	{
		public var id:int;
		public var bg:MovieClip;
		public var recipeName:TextField;
		public var _items:Array;
		
		public function RecipeItem(rData:Object)
		{
				this.id = rData.recipeId;
				this._items = rData.items;
				var color:String = "#999999";
				if (this.checkRecipeDone(rData.items)){
					color = "#FFFFFF";
				}
				this.recipeName.alpha = 1;
				this.recipeName.htmlText = "<font color=\""+color+"\"><b>"+rData.recipeName.toUpperCase()+"</b></font>";

				// [bgh] DIRTY: strip the rich formatting cause flash is freaking out
				var text:String = recipeName.text;
				this.recipeName.text = "";
				this.recipeName.text = text;
				// END DIRTY
				
				this.bg.alpha = 0;
				this.buttonMode = true;
				this.mouseChildren = false;
			
		}

		private function checkRecipeDone(_items:Array):Boolean{
			var res:Boolean = true;
			for (var i:int=0;i<_items.length;i++){
				var n:int = parseInt(_items[i].needed);
				var t:int = parseInt(_items[i].total);
				if (n>t) {
					res = false;
					break;
				}
			}
			return res;
		}		

	}
}