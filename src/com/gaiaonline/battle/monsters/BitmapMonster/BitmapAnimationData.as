package com.gaiaonline.battle.monsters.BitmapMonster
{
	
	public class BitmapAnimationData
	{
		private var _angles:Array = new Array();
		
		public function BitmapAnimationData(angles:Array)
		{
			this._angles = angles;
		}
		
		public function getFrame(angIndex:int, pose:MonsterPoseEnum, state:String, anim:String, frame:int):BitmapFrame{
			
			if (this._angles == null || this._angles[angIndex] == null 
				|| this._angles[angIndex].poses[pose] == null 
				|| this._angles[angIndex].poses[pose][state] == null
				|| this._angles[angIndex].poses[pose][state][anim] == null){
				return null
			}
			if (this._angles[angIndex].poses[pose][state][anim][frame] == null){
				frame = 0;
			}
			return this._angles[angIndex].poses[pose][state][anim][frame];
		}
		
		public function getAnimLength(angIndex:int, pose:MonsterPoseEnum, state:String, anim:String):int{
			if (this._angles == null || this._angles[angIndex] == null 
				|| this._angles[angIndex].poses[pose] == null 
				|| this._angles[angIndex].poses[pose][state] == null
				|| this._angles[angIndex].poses[pose][state][anim] == null){
				return 0
			}			
			return this._angles[angIndex].poses[pose][state][anim].length;
		} 
		
		public function hasPose(pose:MonsterPoseEnum, angIndex:Number):Boolean{
			if (this._angles != null && this._angles[angIndex] != null && this._angles[angIndex].poses[pose] != null){
				return true;
			}else{
				return false;
			}			
		}
		
		public function hasTransition(angIndex:int, pose:MonsterPoseEnum, fromState:int, toState:int):Boolean{
			if (this._angles != null && this._angles[angIndex] != null &&
				this._angles[angIndex].poses[pose] != null &&
				this._angles[angIndex].poses[pose]["s"+toState] != null &&
				this._angles[angIndex].poses[pose]["s"+toState]["ts"+fromState] != null){
					return true;
				}else{
					return false;
				}			
		}
	
		public function getAngleIndex(angle:Number):int{
			if (this._angles == null){
				return 0;
			}
			var index:int = 0;
			
			var ang:Number = angle - 90;			
			if (ang < 0 ){
				ang = ang + 360;
			}
			if (ang > 180){
				ang = 180 - (ang - 180)
			}			
			for (var i:int = 0; i < this._angles.length; i++){
				if (ang >= this._angles[i].angMin && ang < this._angles[i].angMax){
					index = i;
					break;
				}
			}
			return index;
		}
		
		public function dispose():void{
			for(var angIndex:int = 0; angIndex < this._angles.length; angIndex++){
				for each (var pose:Object in this._angles[angIndex].poses){
					for each (var state:Object in pose){
						for each(var anim:Object in state){
							for each(var frame:BitmapFrame in anim){								
								frame.dispose();					
								frame = null;			
							}
						}
						
					}
				}
			}
			
			this._angles = null;
		}			
	}
}