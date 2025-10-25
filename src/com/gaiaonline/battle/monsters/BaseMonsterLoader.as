package com.gaiaonline.battle.monsters
{
	import com.gaiaonline.battle.ApplicationInterfaces.IUIFramework;
	import com.gaiaonline.battle.map.MapRoom;
	import com.gaiaonline.battle.monsters.BitmapMonster.BitmapAnimationData;
	import com.gaiaonline.battle.monsters.BitmapMonster.MonsterMainBitmapConverter;
	import com.gaiaonline.battle.monsters.BitmapMonster.MonsterMainSprite;
	import com.gaiaonline.battle.newrings.RingLoadManager;
	import com.gaiaonline.objectPool.LoaderFactory;
	import com.gaiaonline.objectPool.ObjectPool;
	import com.gaiaonline.utils.DisplayObjectStopper;
	import com.gaiaonline.utils.DisplayObjectStopperModes;
	import com.gaiaonline.utils.DisplayObjectUtils;
	
	import flash.display.Loader;
	import flash.display.LoaderInfo;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.net.URLRequest;
	
	public class BaseMonsterLoader extends EventDispatcher
	{
		private var _garbageStopper:DisplayObjectStopper = new DisplayObjectStopper(DisplayObjectStopperModes.SHOW_NO_ANIM, true); 
				
		public var name:String;
		public var loaded:Boolean = false;
		public var baseMonster:*;
		
		public var isGlow:Boolean = false;
		public var flip:Boolean = true;
		public var hasAggro:Boolean = false;
		
		private var _url:String;
		private var _loading:Boolean = false;
		
		private var _baseMonsterPool:ObjectPool;
		private var _baseMonsterFactory:BaseMonsterFactory;
		
		private var _actorBtnPool:ObjectPool;
		private var _actorBtnFactory:ActorBtnFactory;
		
		private var _uiFramework:IUIFramework = null;
		private var _actorAssets:* = null;
		private var _scale:Number = 1;
		private var _useRasterize:Boolean = false;
		
		public function get scale():Number{
			return this._scale;
		}
		
		public function BaseMonsterLoader(uiFramework:IUIFramework, url:String, useRasterize:Boolean=false)
		{
			this._url = url;
			this._uiFramework = uiFramework;
			this._useRasterize = useRasterize;
						
			var m:MapRoom = this._uiFramework ? this._uiFramework.map.getCurrentMapRoom() : null;
			if (m != null){
				this._scale = m.scale/100;
			}		
			
			var a:Array = url.split("/");
			this.name = a[a.length-1].split(".")[0];	
		}
				
		public function load():void{
			if (!this._loading){
				this._loading = true;
				var l:Loader = LoaderFactory.getInstance().checkOut();
				l.contentLoaderInfo.addEventListener(Event.COMPLETE, onBaseMonsterLoaded, false, 0, true);
				l.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, onErrorLoading, false, 0, true);
				l.load(new URLRequest(this._url), this._uiFramework.loaderContextFactory.getLoaderContext());				
			}				
		}
		
		
		private var _bitmapAnimationData:BitmapAnimationData;
		private var _monsterMainBitmapConverter:MonsterMainBitmapConverter;
		private var _isBitmapReady:Boolean = false;
		
		private function onBaseMonsterLoaded(evt:Event):void{
			var monsterLoaderInfo:LoaderInfo = LoaderInfo(evt.target);
			monsterLoaderInfo.removeEventListener(Event.COMPLETE, onBaseMonsterLoaded);
			monsterLoaderInfo.removeEventListener(IOErrorEvent.IO_ERROR, onErrorLoading);
			
			this.baseMonster = monsterLoaderInfo.content;
			///--- Remove and Stop anny Animation that may be on the main timeline of the SWF.
			this._garbageStopper.addGarbageStopper(this.baseMonster);
			DisplayObjectUtils.stopAllMovieClips(this.baseMonster);					
			
			if (this.baseMonster.hasOwnProperty("isBitmapReady")){
				this._isBitmapReady = this.baseMonster.isBitmapReady;				
			}else{
				this._isBitmapReady = false;
			}	
			
			LoaderFactory.getInstance().checkIn(monsterLoaderInfo.loader);
					
			if (this._isBitmapReady && this._useRasterize){			
				this._monsterMainBitmapConverter = new MonsterMainBitmapConverter(this._scale);
				this._monsterMainBitmapConverter.addEventListener(Event.COMPLETE, onConvertionComplete);							
				this._monsterMainBitmapConverter.convert(this.baseMonster.getNewMonster());
				//this.baseMonster = new MonsterMainSprite(this._bitmapAnimationData, monsterLoaderInfo.content);
			}else{
				this.onConvertionComplete(null);
			}		
						
		}
		private function onConvertionComplete(evt:Event):void{
			if (this._isBitmapReady && this._useRasterize){				
				this._bitmapAnimationData = this._monsterMainBitmapConverter.bitmapAnimationData;
				this.baseMonster = new MonsterMainSprite(this._bitmapAnimationData, this.baseMonster);
			}else{
				this.baseMonster = new MonsterMain2(this.baseMonster);
			}
											
			this.init();
			//--- Check for Ring
			if (this.baseMonster.hasOwnProperty("getRing")){
				var rmc:MovieClip = this.baseMonster.getRing();
				if (rmc != null){					
					RingLoadManager.createSimpleRing(this.name, rmc);
				}							
			}
			
			this._baseMonsterFactory = new BaseMonsterFactory(this.baseMonster, this._isBitmapReady, this._bitmapAnimationData);
			this._baseMonsterPool = new ObjectPool(this._baseMonsterFactory, this._baseMonsterFactory, this._baseMonsterFactory, 6);
			
			this._actorBtnFactory = new ActorBtnFactory(this.baseMonster);
			this._actorBtnPool = new ObjectPool(this._actorBtnFactory, this._actorBtnFactory, this._actorBtnFactory, 5);
			
						
			this.loaded = true;
			this._loading = false;			
			this.dispatchEvent(new Event(Event.COMPLETE));	
		}
			
		
		private function onErrorLoading(evt:IOErrorEvent):void{
			trace("ERROR LOADING MONSTER :",evt.text, this.name, this._url);
			this.loaded = false;
			this._loading = false;				
			this.dispatchEvent(new Event(Event.COMPLETE));	
			this.dispatchEvent(new Event(Event.COMPLETE));	
		}

		private function init():void{						
			if (this.baseMonster.isGlow != null){
				this.isGlow = this.baseMonster.isGlow;
			}
			if (this.baseMonster.flip != null){
				this.flip = this.baseMonster.flip;
			}			
			this.hasAggro = this.baseMonster.hasAggro;		
		}
		
		
		//-------------------------------
		public function getNewMonster():*{
			if(this.baseMonster != null){
				return this.baseMonster.getNewMonster();						
			}else{
				return null;
			}
		}
		
		private function getNewGenericMonster():MovieClip
		{
			return this._uiFramework.assetFactory.getInstance("MonsterMain", false) as MovieClip;
		}
		public function checkOutMonster(baseActorId:String):*{	
			var obj:*		
			if (this._baseMonsterPool != null){
				obj = this._baseMonsterPool.checkOut();
			}else{
				obj = getNewGenericMonster();
			}
			//trace("[BaseMonsterLoader checkOutMonster] from pool", obj.name)
			if (obj.hasOwnProperty("init")){
				if (obj.hasOwnProperty("baseActorId")){
					obj.baseActorId = baseActorId;
				}				
				obj.init();
			}
			return obj;
		}
		public function checkInMonster(obj:*):Boolean{
			var r:Boolean = false;
			if (this._baseMonsterPool != null){
				r = this._baseMonsterPool.checkIn(obj);
				//trace("checkIn", this.name, this._baseMonsterPool.objectCount, this._baseMonsterPool.usedCount, this._baseMonsterPool.unUsedCount);
			}
			return r;
		}
		
		//-------------------------------
		public function getPortrait():Sprite{
			
			var s:Sprite = new Sprite();			
			if(this.baseMonster != null && this.baseMonster.getPortrait != null){
				var p:Sprite = Sprite(this.baseMonster.getPortrait());
				s.addChild(p);
			}
			return s;
			
		}

		private function getNewGenericMonsterActorBtn():MovieClip
		{
			return this._uiFramework.assetFactory.getInstance("actorBtn", false) as MovieClip;
		}

		//------------------------------
		public function checkOutActorBtn():MovieClip{
			var obj:MovieClip;
			if (this._actorBtnPool != null){
				obj = MovieClip(this._actorBtnPool.checkOut());
			}else{
				obj = getNewGenericMonsterActorBtn();
			}
			//trace("checkOut actorBtn", this.name, this._actorBtnPool.objectCount, this._actorBtnPool.usedCount, this._actorBtnPool.unUsedCount);		
			return obj
		}
		public function checkInActorBtn(obj:*):Boolean{
			var r:Boolean = false;
			if (this._actorBtnPool != null){
				r = this._actorBtnPool.checkIn(obj);
				//trace("checkIn actorBtn", this.name, this._actorBtnPool.objectCount, this._actorBtnPool.usedCount, this._actorBtnPool.unUsedCount);
			}
			return r;
		}
		
		//-----------------------------------
		public function getNewProjectile():MovieClip{
			if (this.baseMonster != null && this.baseMonster.getNewProjectile != null){
				return MovieClip(this.baseMonster.getNewProjectile());
			}else{
				return null;
			}
		}
	
		public function get useButtonOnly():Boolean{
			var v:Boolean = false;
			if (this.baseMonster != null && this.baseMonster.hasOwnProperty("useButtonOnly") ){					
				v = this.baseMonster.useButtonOnly;
			}
			return v;
		}
		
		public function get displaySilhouette():Boolean{
			var v:Boolean = true;
			if (this.baseMonster != null && this.baseMonster.hasOwnProperty("displaySilhouette") ){					
				v = this.baseMonster.displaySilhouette;
			}
			return v;
		}
		
		public function dispose():void{			
			//this._baseMonsterPool.dispose();
			this._baseMonsterFactory = null;
			this._baseMonsterPool = null;			
			this.baseMonster = null;
			if(this._bitmapAnimationData)
			{
				this._bitmapAnimationData.dispose();
			}
			this._uiFramework = null;
			this._garbageStopper = null;
		}
	}
}
	//******** Pool Factories
		
	import com.gaiaonline.objectPool.IObjectPoolFactory;
	import com.gaiaonline.objectPool.IObjectPoolDeconstructor;
	import com.gaiaonline.objectPool.IObjectPoolCleanUp;
	import com.gaiaonline.battle.monsters.BitmapMonster.BitmapAnimationData;
	import com.gaiaonline.battle.monsters.BitmapMonster.MonsterMainSprite;
	
	class BaseMonsterFactory implements IObjectPoolFactory, IObjectPoolDeconstructor, IObjectPoolCleanUp{
		private var _baseMonster:*;
		private var _isBitmapReady:Boolean = false;
		private var _bitmapAnimationData:BitmapAnimationData; 
		
		public function BaseMonsterFactory(baseMonster:*, isBitmapReady:Boolean = false, bitmapAnimationData:BitmapAnimationData = null){
			this._baseMonster = baseMonster;
			this._isBitmapReady = isBitmapReady;
			this._bitmapAnimationData = bitmapAnimationData;
		}		
		public function create():*{
			return this._baseMonster.getNewMonster();			
		}
		public function deconstruct(obj:*):void{
			if (obj != null){			
				//DisplayObjectUtils.ClearAllChildrens(BaseAvatar(obj));
				obj.dispose();
			}
		}		
		public function objectPoolCleanUp(obj:*):void{
			obj.x -= 71;
			obj.y -= 139;			
			if (Object(obj).hasOwnProperty("reset")){
				obj.reset();			
			}
		}
	}
	
	class ActorBtnFactory implements IObjectPoolFactory, IObjectPoolDeconstructor, IObjectPoolCleanUp{
		private var _baseMonster:*;
		public function ActorBtnFactory(baseMonster:*){
			this._baseMonster = baseMonster;
		}		
		public function create():*{
			return this._baseMonster.getActorBtn();
		}
		public function deconstruct(obj:*):void{
			
		}		
		public function objectPoolCleanUp(obj:*):void{
			
		}
	}
	
	


