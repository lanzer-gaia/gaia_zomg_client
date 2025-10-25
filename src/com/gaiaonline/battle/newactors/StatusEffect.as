package com.gaiaonline.battle.newactors
{
	import com.gaiaonline.battle.newrings.RingAnim;
	
	public class StatusEffect
	{
		
		private var status:Object = new Object();
		private var actor:BaseActor;
		
		public function StatusEffect(baseActor:BaseActor){
			this.actor = baseActor;			
		}
				
		public function playStatus(animationId:String = null, playEffectStartAnim:Boolean = true):void{				
			if (animationId != null && this.status[animationId] == null){
				var ra:RingAnim = this.actor.playEffectAnim(animationId, "effect", playEffectStartAnim) as RingAnim;
				this.status[animationId] = {count:1, anim:ra};				
				
			}else if (animationId != null){
				this.status[animationId].count += 1;
			}			
					
		}
		
		
		public function stopStatus(animationId:String):void{
			if (animationId != null && this.status[animationId] != null){				
				this.status[animationId].count -= 1;				
				//if (this.status[animationId].count <= 0){	
					if (this.status[animationId].anim != null){				
						RingAnim(this.status[animationId].anim).dispell();
					}
					delete this.status[animationId];
				//}
			}
			
		}
		
		public function refresh():void{			
			for (var animationId:String in this.status){
				if (this.status[animationId].anim == null){
					trace(" - ", animationId)
					var ra:RingAnim = this.actor.playEffectAnim(animationId) as RingAnim;
					this.status[animationId].anim = ra;				
				}
			}
		}		
		
		public function dispose():void{
			for (var id:String in this.status){
				RingAnim(this.status[id].anim).dispell();
				delete this.status[id];
			}
			this.status = null;
		}
	}
}