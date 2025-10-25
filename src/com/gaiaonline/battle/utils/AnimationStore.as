package com.gaiaonline.battle.utils
{
	import com.gaiaonline.utils.DisplayObjectUtils;
	
	import flash.display.DisplayObject;
	import flash.display.MovieClip;
	import flash.utils.Dictionary;
	
	public class AnimationStore
	{
		private var _animations:Dictionary = new Dictionary(true);
		private var _size:int = 0;
		private static function storeTimelinedMovieClipsFunctor(functor:Object, parent:DisplayObject, child:DisplayObject):Boolean
		{
			var mc:MovieClip = child as MovieClip;
			if (mc && mc.totalFrames > 1) {
				functor.animations[mc] = true;
				++functor.count;
			}
			return true;  // let recursion proceed
		}

		public function AnimationStore(parent:DisplayObject)
		{
			//
			// Store a weak reference to all MovieClips that have a timeline 
			var functor:Object =
			{
				animations: _animations,
				onObject:   storeTimelinedMovieClipsFunctor,
				count:      0
			};
			DisplayObjectUtils.recurse(functor, parent);
			
			_size = functor.count;
		}
		public function playAll():void
		{
			for (var mc:Object in _animations) {
				DisplayObjectUtils.playAssetMovieClip(MovieClip(mc));
			}
		}
		public function stopAll():void
		{
			for (var mc:Object in _animations) {
				DisplayObjectUtils.stopAssetMovieClip(MovieClip(mc));
			}
		}
		public function get size():int
		{
			return _size;
		}
	}
}