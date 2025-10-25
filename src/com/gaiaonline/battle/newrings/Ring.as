package com.gaiaonline.battle.newrings
{
	import com.gaiaonline.battle.ItemLoadManager.IItemLoader;
	import com.gaiaonline.flexModulesAPIs.globalevent.GlobalEvent;
	import com.gaiaonline.utils.DisplayObjectUtils;
	
	import flash.display.Bitmap;
	import flash.display.DisplayObject;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.EventDispatcher;
	import flash.events.KeyboardEvent;
	
	public class Ring extends EventDispatcher implements IItemLoader
	{
		public static var LOADED:String = "RingLoaded";		
		
		public var ringId:String;
		public var isFullRing:Boolean = false;
		public var name:String ="";
		public var description:String = "";
		public var type:int = 0; // 0 = passive 
		public var targetType:int = 0; // 0=none, 1=Self only, 2=Friends Only, 3=Friends && Self, 4=Enemy only
		public var rage:Object = new Object();
		public var exhaustion:Number = 0;
		public var chargeLevel:Number = 1;
		public var itemThumbNail:String = null;
		
		public var projectileSpeed:Number = 0;
		public var isProjectile:Boolean = false;		
		
		//-----		
		public var animUrl:String;
		public var iconUrl:String;			
		public var mcAnimRef:Sprite;
		public var mcProjectile:MovieClip;
		public var bmIcon:Bitmap;	
		public var isAnimLoaded:Boolean = false;				
		public var isIconLoaded:Boolean = false;
		public var isLoadingAnim:Boolean = false;
		public var timeUsedAtLoadTime:Number = 0;
		
		public var stats:Array = new Array();
		
		private var _isPointTarget:Boolean = false;
		
		private var _notEnabledSoundPlayed:Boolean = false;
		
		private var _selectedActorId:String = null;
		private var _allowAreaRingsOnly:Boolean = false;
		
		public function get isPointTarget():Boolean {
			// [bgh] PBAoE rings are point target, but have no range.
			return _isPointTarget && this.range != 0;
		}
		public function set isPointTarget(ipt:Boolean):void {
			_isPointTarget = ipt;
		}

		private var _ringLoader:RingLoader;  // [kja] storing this ONLY to prevent it from gc'ing.  Ring/RingLoader design needs review 
		public function maintainLoaderReference(rl:RingLoader):void
		{
			_ringLoader = rl;
		}

		//----------------------------------------------------------			
		public function Ring(ringId:String, mcRef:Sprite = null){
			this.ringId = ringId;	
			
			if (mcRef != null){
				
				// clear odl anim;
				if (this.mcAnimRef != null){
					DisplayObjectUtils.ClearAllChildrens(this.mcAnimRef);
				}				
				// set mcAnimRef
				this.mcAnimRef = mcRef;						
				this.isAnimLoaded = true;
			}
			DisplayObjectUtils.addWeakListener(GlobalEvent.eventDispatcher, GlobalEvent.ACTOR_SELECTED, onActorSelected);
			DisplayObjectUtils.addWeakListener(GlobalEvent.eventDispatcher, GlobalEvent.ALLOW_AREA_RINGS_ONLY, onAllowAreaRingsOnly);													
		}		
		
		private function onAllowAreaRingsOnly(e:GlobalEvent):void {
			_allowAreaRingsOnly = e.data;
		}
		
		public function get onlyAllowAreaRings():Boolean {
			return _allowAreaRingsOnly;
		}
		
		private function onActorSelected(e:GlobalEvent):void {
			this._selectedActorId = e.data.actorId;
		}
		
		// Getter Setters
		public function get range():Number{
			var r:Number = 0;
			if (this.rage != null && this.rage[0] != null && this.rage[0].range != null){
				r = this.rage[0].range;// * 10;
			}
			return r;
		}

		public function getNewRingIcon():RingIcon{
			var rIco:RingIcon = new RingIcon(this.bmIcon);
			rIco.ringId = this.ringId;
			return rIco;
		}


		public function usesTargets():Boolean {
			// [bgh] a ring needs a target if it has range
			// @@@ [bgh] FIRE RAIN RING! (remove id check later)
			var hasRange:Boolean = (0!=this.range); 
			return hasRange;
		}
	
		
		private function onKeyUp(e:KeyboardEvent):void {
			e.target.stage.removeEventListener(KeyboardEvent.KEY_UP, onKeyUp);
			this._notEnabledSoundPlayed = false;
		}
		
		
		//---- IItemLoader
		public function get itemName():String{
			return this.name;
		}
		public function get itemDescription():String{
			return this.description;
		}
		public function get loaded():Boolean{
			return this.isIconLoaded;
		}
		public function getNewItemDisplay():DisplayObject{
			var bm:Bitmap = new Bitmap(this.bmIcon.bitmapData);
			return bm;
		}	
	}
}