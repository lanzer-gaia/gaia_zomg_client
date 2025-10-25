package com.gaiaonline.battle.utils
{
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	
	// This class essentially implements a more brutal form of DisplayObject.visible - it removes a child from
	// its parent and saves the childindex so that it can be reparented in the same location later.  We did this
	// in order to get non-active tabs off the stage, since they were causing rendering even though they were
	// invisible.  -kja  
	public class DisplayObjectAttacher
	{
		private var _child:DisplayObject;
		private var _savedParent:DisplayObjectContainer;
		public function DisplayObjectAttacher(child:DisplayObject, parent:DisplayObjectContainer = null) // pass in a parent to force an attachment
		{
			_child = child;
			if (parent) {
				parent.addChild(child);
			}
			_savedParent = child.parent;
		}
		static private const NULL_INDEX:int = -1;
		private var _savedIndex:int = NULL_INDEX;
		public function set attached(attach:Boolean):void
		{
			if (attach) {
				if (_child.parent == null && _savedParent != null) {
					//assert(_savedIndex != NULL_INDEX && _savedParent != null);
					_savedIndex = Math.min(_savedParent.numChildren, _savedIndex);
					_savedParent.addChildAt(_child, _savedIndex);
					_savedIndex = NULL_INDEX;
					_savedParent = null;
				}
			}
			else {
				if (_child.parent != null) {
					//assert(_savedIndex == NULL_INDEX && _savedParent == null);
					_savedIndex = _child.parent.getChildIndex(_child);
					_savedParent = _child.parent;
					_savedParent.removeChild(_child);
				}
			}
		}
	}
}