package com.gaiaonline.battle.utils
{
	import com.gaiaonline.battle.ui.components.ScrollBarVer;
	
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.InteractiveObject;
	import flash.display.SimpleButton;
	import flash.display.Stage;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.events.TextEvent;
	import flash.geom.Point;
	import flash.text.TextField;
	import flash.text.TextFieldType;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;
	
	public class BattleUtils
	{
		public function BattleUtils() { throw "Instantiability denied"; }

		public static var ALLOW_DISABLE_MOUSE_ON_CHILDREN:Boolean = true;
		public static function disableMouseOnChildren(obj:DisplayObject):void {

			if (!ALLOW_DISABLE_MOUSE_ON_CHILDREN) {
				return;
			}

			if (obj is InteractiveObject)
			{
				var exclusion:Boolean = 
				((obj is TextField) && (TextField(obj).type == TextFieldType.INPUT)) ||
				(obj is SimpleButton) ||
				(obj is ScrollBarVer);
				
				if (!exclusion &&
					!obj.hasEventListener(TextEvent.LINK) &&
					!obj.hasEventListener(MouseEvent.CLICK) &&
				    !obj.hasEventListener(MouseEvent.MOUSE_DOWN) &&
				    !obj.hasEventListener(MouseEvent.MOUSE_MOVE) &&
				    !obj.hasEventListener(MouseEvent.ROLL_OVER) &&
				    !obj.hasEventListener(MouseEvent.ROLL_OUT) &&
				    !obj.hasEventListener(MouseEvent.MOUSE_OVER) &&
				    !obj.hasEventListener(MouseEvent.MOUSE_OUT))
				{
					InteractiveObject(obj).mouseEnabled = false;
				}
			}
			var objAsParent:DisplayObjectContainer = obj as DisplayObjectContainer;
			if (objAsParent && !(obj is ScrollBarVer))
			{
				const numChildren:int = objAsParent.numChildren;
				for (var i:int; i < numChildren; ++i)
				{
					var child:DisplayObject = objAsParent.getChildAt(i);
					disableMouseOnChildren(child);
				}
			}
		}
		
		public static function enableScrollMouseEvents(scrollBar:*):void {
			// why bother doing this?  Because the parent of scrollBar is showing extreme prejudice towards mouseEnabled=true and 
			// turning it off in a lot of children automatically.  This is hacky, but the fact that Flash leaves mouseEnabled
			// on by default shows that it wasn't intended to be used with 1000's of display objects at once like we have.  -kja
			scrollBar.mouseEnabled = true;
			scrollBar.scrUp.mouseEnabled = true;
			scrollBar.scrDown.mouseEnabled = true;
			scrollBar.dragBtn.mouseEnabled = true;
		}
		
		//
		// Shown to be faster than Point.distance in profiling
		public static function distanceBetweenPoints(point1:Point, point2:Point):Number {
			var x:Number = point2.x - point1.x;
			x *= x;
			
			var y:Number = point2.y - point1.y;
			y *= y;

			return Math.sqrt(x + y);
		}		
		
		public static function keepItemOnStage(stage:Stage, item:DisplayObject):void {
			if (!stage) {
				return;
			}
			if (item.x + item.width > stage.stageWidth) {
				item.x = stage.stageWidth- item.width;
			}
			if (item.y + item.height > stage.stageHeight) {
				item.y = stage.stageHeight - item.height;
			}
		}
		
		public static function killEvent(e:Event):void {
			e.stopImmediatePropagation();
			e.stopPropagation();
			e.preventDefault();
		}
		
		public static function getZoneIdFromRoomId(roomId:String):String {
			return roomId.split("_")[0];			
		}
		
		public static function getRoomNumFromRoomId(roomId:String):uint {
			return roomId.split("_")[1];			
		}		
		
		public static function cleanObject(o:Object):void {
			if (o == null) {
				o = new Object();
				return;
			}
			var foundProps:uint = 0;
			do {
				foundProps = 0;
				for (var key:Object in o) {
					++foundProps;
					delete o[key];
				}
			} while (foundProps > 0);
		}
		
		public static function cleanDictionary(dict:Dictionary):void {
			cleanObject(dict);
		}	
		

		// This is copied directly from ObjectUtil.as, but since it lives in the mx namespace, CS3 has problems compiling against
		// ObjectUtil.as.  I'm just moving the function here to make it easier to access.  Really, we should make a Flex utils interface
		// we can hide mx stuff behind.  Well, really, we should decouple our compilations units so that, say, UI elements don't have built
		// into them our communication details, or so that our fla's aren't built so that they link directly against .as files (but rather just
		// produce assets that get consumed).
		//
		// -- Mark Rubin
	    /**
	     *  Copies the specified Object and returns a reference to the copy.
	     *  The copy is made using a native serialization technique. 
	     *  This means that custom serialization will be respected during the copy.
	     *
	     *  <p>This method is designed for copying data objects, 
	     *  such as elements of a collection. It is not intended for copying 
	     *  a UIComponent object, such as a TextInput control. If you want to create copies 
	     *  of specific UIComponent objects, you can create a subclass of the component and implement 
	     *  a <code>clone()</code> method, or other method to perform the copy.</p>
	     * 
	     *  @param value Object that should be copied.
	     * 
	     *  @return Copy of the specified Object.
	     */ 
	    public static function copy(value:Object):Object
	    {
	        var buffer:ByteArray = new ByteArray();
	        buffer.writeObject(value);
	        buffer.position = 0;
	        var result:Object = buffer.readObject();
	        return result;
	    }
		
	}
}