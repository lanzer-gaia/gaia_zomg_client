package com.gaiaonline.battle.newactors
{
	import com.gaiaonline.battle.ApplicationInterfaces.IAssetFactory;
	import com.gaiaonline.battle.ApplicationInterfaces.IUIFramework;
	import com.gaiaonline.battle.gateway.BattleGateway;
	import com.gaiaonline.battle.newrings.RingAnim;
	import com.gaiaonline.objectPool.IObjectPoolCleanUp;
	import com.gaiaonline.objectPool.IObjectPoolDeconstructor;
	import com.gaiaonline.objectPool.IObjectPoolFactory;
	import com.gaiaonline.objectPool.IObjectPoolInitializer;
	import com.gaiaonline.objectPool.LoaderFactory;
	import com.gaiaonline.objectPool.ObjectPool;
	import com.gaiaonline.utils.BitmapCache;
	import com.gaiaonline.utils.DisplayObjectUtils;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Loader;
	import flash.display.LoaderInfo;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.TimerEvent;
	import flash.geom.Matrix;
	import flash.net.URLRequest;
	import flash.system.LoaderContext;
	import flash.utils.Timer;
	
	public class AvatarDisplay extends ActorDisplay implements IObjectPoolFactory, IObjectPoolDeconstructor, IObjectPoolInitializer, IObjectPoolCleanUp
	{
		private var img:Bitmap;
		private var avs:Array = new Array();
		private var _reloadTimer:Timer;
		private var _reloadTime:int = 500;
		private var _avatarPool:ObjectPool;
		private var _isSittng:Boolean = false;
		
		private var _faceDirectionInitted:Boolean = false;
		private var _facingUp:Boolean = false;
		
		private var targetInfoPotraitArray:Array = new Array(); 
		private var dialogPotraitArray:Array = new Array(); 		
															   			
		// set this to null to deactivate bitmap caching
		private static const s_bitmapCache:BitmapCache = new BitmapCache(20*1000, 2*60*1000);		

		public function AvatarDisplay(assetFactory:IAssetFactory, baseUrl:String, baseActorId:String = null) {
			this.actorBtn = MovieClip(assetFactory.getInstance("AvatarBtn"));
			this.assetFactory = assetFactory;  // [kja] dirtier than livestock porn.  See my note below. 
			
			var shadowBitmap:Bitmap = this.getNewShadowBitmap();
			shadowBitmap.x = -shadowBitmap.width/2; 
			shadowBitmap.y = -shadowBitmap.height/2; 			
			this.addChild(shadowBitmap);
			
			// create bounding box
			this.mcBound = new Sprite();
			this.setMcBound(false);		
			this.mcBound.visible = false;
			this.addChild(this.mcBound);
			this.mcBound.name = "mcBound";
						
			this.img = getNewDefaultAvStrip();
			
			this._avatarPool = new ObjectPool(this, null, null, 10);
			
			// [kja] ack - I tried moving this to the top of the constructor (where it should be, and where AS3 should actually *force* it to be),
			// but it causes bugs because the ActorDisplay constructor requires our constructor called first.
			super(assetFactory, baseUrl, baseActorId);

			this._frameQueueList.addFrameQueue(fnCallAnimation);
			this._frameQueueList.addFrameQueue(fnSetDir);
						
			this.clearPortraitArray(this.dialogPotraitArray);
			this.clearPortraitArray(this.targetInfoPotraitArray);									
		}
		
		private static var s_defaultAvatarStripData:BitmapData = null;
		private function getNewDefaultAvStrip():Bitmap
		{
			if (!s_defaultAvatarStripData)
			{
				const c:Class = this.assetFactory.getClass("DefaultAvStrip");
				s_defaultAvatarStripData = new c(0, 0) as BitmapData;
			}
			return new Bitmap(s_defaultAvatarStripData);
		}

		private static var s_shadowBitmapData:BitmapData = null;
		private function getNewShadowBitmap():Bitmap
		{
			if (!s_shadowBitmapData)
			{		
				const shadowClass:Class = this.assetFactory.getClass("AvatarShadow");
				s_shadowBitmapData = new shadowClass(0, 0) as BitmapData;
			}
			
			var bitmap:Bitmap = DisplayObjectUtils.createClearAllChildrensImmuneBitmap(s_shadowBitmapData);
			bitmap.scaleX = bitmap.scaleX * .5;
			bitmap.scaleY = bitmap.scaleY * .5;
			return bitmap;
		}

		private function setMcBound(sitting:Boolean = false):void{
			var mcx:int = -49;
			var mcy:int = -119;
			if (sitting){
				mcy = -99;
			}
			if (this.mcBound != null){
				this.mcBound.graphics.clear();
				this.mcBound.graphics.beginFill(0x0000ff);
				this.mcBound.graphics.drawRect( mcx, mcy, 67, 60);
				this.mcBound.graphics.endFill();
			}
		}	
			
		private function onAvRemovedFromStage(evt:Event):void{			
			if (this.parent is BaseActor && !BaseActor(this.parent).pickedUpBy){			
				var i:int = this.avs.indexOf(evt.target);				
				if (i >=0){
					if (!this._avatarPool.checkIn(this.avs[i])){
						DisplayObjectUtils.ClearAllChildrens(this.avs[i]);
						this.avs[i].dispose();
					}			
					this.avs[i].removeEventListener(Event.REMOVED_FROM_STAGE, onAvRemovedFromStage);					
					this.avs.splice(i,1);
				}	
			}	
							
		}
		
		private function sit():void{
			this._isSittng = true;
			this.setMcBound(true);
			if(avs) {
				for (var i:int = 0; i < this.avs.length; i++){
					this.avs[i].sit();
				}
			}
			if(this.actorBtn) {
				if (this.direction >=180 && this.direction < 360){ // up
					this.actorBtn.gotoAndStop(3);
				}else{
					this.actorBtn.gotoAndStop(4);
				}
			}
		}
		
		private function stand():void{
			this._isSittng = false;			
			this.setMcBound(false);
			if(avs) {
				for (var i:int = 0; i < this.avs.length; i++){
					this.avs[i].stand();
				}
			}
			if(this.actorBtn) {
				if (this.direction >=180 && this.direction < 360){ // up
					this.actorBtn.gotoAndStop(2);
				}else{
					this.actorBtn.gotoAndStop(1);
				}
			}
		}
		private function walk():void{
			this._isSittng = false;
			this.setMcBound(false);
			if(avs) {
				for (var i:int = 0; i < this.avs.length; i++){
					this.avs[i].walk();
				}
			}
			if(this.actorBtn) {
				if (this.direction >=180 && this.direction < 360){ // up
					this.actorBtn.gotoAndStop(2);
				}else{
					this.actorBtn.gotoAndStop(1);
				}
			}
		}
		
		private var _faceUpRepeat:uint = 0;
		private var _faceDownRepeat:uint = 0;		
		private function faceUp():void{			
			if (!this._faceDirectionInitted || !this._facingUp) {
				if(avs) {
					for (var i:int = 0; i < this.avs.length; i++){
						this.avs[i].faceUp();
					}
				}
				if(this.actorBtn) {
					if (this.actorBtn.currentFrame == 1){
						this.actorBtn.gotoAndStop(2);
					}else if (this.actorBtn.currentFrame == 3){
						this.actorBtn.gotoAndStop(4);
					}
				}
				this._facingUp = true;							
				this._faceDirectionInitted = true;
			} 
		}
		
		private function faceDown():void{			
			if (!this._faceDirectionInitted || this._facingUp) {
				if(avs) {					
					for (var i:int = 0; i < this.avs.length; i++){
						this.avs[i].faceDown();
					}
				}
				if(this.actorBtn) {
					if (this.actorBtn.currentFrame == 2){
						this.actorBtn.gotoAndStop(1);
					}else if (this.actorBtn.currentFrame == 4){
						this.actorBtn.gotoAndStop(3);
					}
				}
				this._facingUp = false;			
				this._faceDirectionInitted = true;				
			}
		}
		
		/// overides -------------	
		private static var s_defaultAvatarAnim:Sprite;
		private function getNewGenericAvatarAnim():Sprite
		{
			if (!s_defaultAvatarAnim)
			{
				s_defaultAvatarAnim = assetFactory.getInstance("GenericAvatarAnim") as Sprite;
			}		
			return s_defaultAvatarAnim;
		}
		public override function loadActor(gateway:BattleGateway, uiFramework:IUIFramework, url:String):void{
			this._uiFramework = uiFramework;			
			super.loadActor(gateway, uiFramework, url);
			if (this.isDispose){
				return;
			}

			this.url = url;

			///---- init with default Strip
			this.genericAnim = new RingAnim(this.baseUrl, this._gateway, this._uiFramework, this, "GenericAvatar", "caster", getNewGenericAvatarAnim());
			this.genericAnim.addEventListener(RingAnim.PRIORITY_CHANGE, onAnimPriorityChange);				
			this.genericHit.y = -90;
			this.genericHit.x = 0;						
			this.reticle.width = 125;
			this.reticle.height = this.reticle.width * 0.5;
			this.animList.push(this.genericAnim);				
			
			///---- This is to 'pool' the image for a small amount of time.
			if (s_bitmapCache)
			{
				const bmp:Bitmap = s_bitmapCache.lookup(this.url);
				if (bmp)
				{
					this.img = bmp;
					this._isLoaded = true;
					this.updateBitmap();	
				}
			}
			if (this.url && !this._isLoaded)
			{					
				var l:Loader = LoaderFactory.getInstance().checkOut();
				var loaderContext:LoaderContext = this._uiFramework.loaderContextFactory.getLoaderContext();
				if (loaderContext != null) {
					loaderContext.checkPolicyFile = true;
				}
				l.contentLoaderInfo.addEventListener(Event.COMPLETE, onActorLoaded);
				l.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, onErrorLoading);
				l.contentLoaderInfo.addEventListener(IOErrorEvent.NETWORK_ERROR, onErrorLoading);
				l.contentLoaderInfo.addEventListener(IOErrorEvent.VERIFY_ERROR, onErrorLoading);
				l.contentLoaderInfo.addEventListener(IOErrorEvent.DISK_ERROR, onErrorLoading);
					
				l.load(new URLRequest(this.url), loaderContext);				
			}
		}
					
		protected override function onActorLoaded(evt:Event):void{
			if (this.isDispose){
				return;
			}
			this.img = Bitmap(LoaderInfo(evt.target).content);

			this.updateBitmap();								
			
			LoaderInfo(evt.target).loader.contentLoaderInfo.removeEventListener(Event.COMPLETE, onActorLoaded);
			LoaderInfo(evt.target).loader.contentLoaderInfo.removeEventListener(IOErrorEvent.IO_ERROR, onErrorLoading);
			LoaderInfo(evt.target).loader.contentLoaderInfo.removeEventListener(IOErrorEvent.NETWORK_ERROR, onErrorLoading);
			LoaderInfo(evt.target).loader.contentLoaderInfo.removeEventListener(IOErrorEvent.VERIFY_ERROR, onErrorLoading);
			LoaderInfo(evt.target).loader.contentLoaderInfo.removeEventListener(IOErrorEvent.DISK_ERROR, onErrorLoading);			
			LoaderFactory.getInstance().checkIn(LoaderInfo(evt.target).loader);

			super.onActorLoaded(evt);
		}

		private function updateBitmap():void {
			//-- Update curent avatars (some may not be pooled)
			if (this.avs != null){
				for(var i:int = 0; i < this.avs.length; i++){				
					BaseAvatar(this.avs[i]).updateBitmapData(this.img.bitmapData);
				}
			}

			//--- update all avatars in pool;
			var avPool:Array = this._avatarPool.getAllObject();
			for (var ii:int = 0; ii < avPool.length; ii++){
				BaseAvatar(avPool[ii]).updateBitmapData(this.img.bitmapData);
			}
		}
		
		protected override function onErrorLoading(evt:IOErrorEvent):void{
			if (this.isDispose){
				return;
			}
			
			super.onErrorLoading(evt);
			
			trace("Error laoding AV:", this.url)
			this._reloadTimer = new Timer(this._reloadTime);
			this._reloadTimer.addEventListener(TimerEvent.TIMER, onLoadTimer, false, 0, true);
			this._reloadTimer.start();
			this._reloadTime *= 2
			
//			if (evt.text.indexOf("Load Never Completed") && Globals.playerInfo.isDev()){
//				throw "Avatar Load Never Completed '503 ?? for url : " + this.url + " Please Copy paste this message to ryan (swarf) .. only devs will see this message." ;
//			}
//			
			
		} 
		private function onLoadTimer(evt:TimerEvent):void{
			this._reloadTimer.removeEventListener(TimerEvent.TIMER, onLoadTimer);
			this._reloadTimer = null;
			trace("Retry loading Av:",this.url);	
			if (this.url != null){					
				var l:Loader = LoaderFactory.getInstance().checkOut();
				var loaderContext:LoaderContext = this._uiFramework.loaderContextFactory.getLoaderContext();
				if (loaderContext != null) {
					loaderContext.checkPolicyFile = true;
				}
				l.contentLoaderInfo.addEventListener(Event.COMPLETE, onActorLoaded);
				l.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, onErrorLoading);
				l.contentLoaderInfo.addEventListener(IOErrorEvent.NETWORK_ERROR, onErrorLoading);
				l.contentLoaderInfo.addEventListener(IOErrorEvent.VERIFY_ERROR, onErrorLoading);
				l.contentLoaderInfo.addEventListener(IOErrorEvent.DISK_ERROR, onErrorLoading);
											
				l.load(new URLRequest(this.url), loaderContext);				
			}
		}
		
		public override function mcTestHitPoint(x:int, y:int):Boolean{
			if (this.isDispose){
				return false;
			}
			return this.actorBtn.hitTestPoint(x, y, true);
		}
						
		public override function getNewActor(pooling:Boolean = true):Sprite{
			if (this.isDispose){
				return null;
			}
			if (this.avs != null && this.img != null ){
				
				var av:BaseAvatar;
				if (pooling){
					av = this._avatarPool.checkOut(this);
				}else{
					av = new BaseAvatar(this.img.bitmapData);
				}
				
				this._faceDirectionInitted = false;
				
				this.avs.push(av);
				av.addEventListener(Event.REMOVED_FROM_STAGE, onAvRemovedFromStage);				
				av.mouseEnabled = false;										
				this.playAnim(this.currentActorAnim, null, true);
				return av;	
			}
			return null;
		}

		private static var s_getTargetInfoPotraitMatrix:Matrix = new Matrix(1.6,0,0,1.6,-840, -40);				
		private static var s_getDialogPotraitMatrix:Matrix = new Matrix(1,0,0,1,-480-30,-1-10);										
	
		public override function getDialogPortrait():Sprite {
			return this.getPortrait(s_getDialogPotraitMatrix, this.dialogPotraitArray);
		}
		
		public override function getTargetInfoPortrait():Sprite{		
			return this.getPortrait(s_getTargetInfoPotraitMatrix, this.targetInfoPotraitArray);			
		}		
		
		private function getPortrait(matrix:Matrix, arrayForCaching:Array):Sprite{		
			if (this.isDispose){
				return null;
			}	
			var s:Sprite = new Sprite();
			if (this.avs != null && this.img != null ){
				this.drawPortrait(s,matrix);	
				if (!this.isLoaded){
					arrayForCaching.push(s);
				}
			}else{
				arrayForCaching.push(s);
			}					
			return s;		
		}

		private function drawPortrait(s:Sprite, matrix:Matrix):void {
			if (s != null && this.avs != null && this.img != null ){
				var av:BaseAvatar = new BaseAvatar(this.img.bitmapData);				
				s.graphics.clear();
				s.graphics.beginBitmapFill(this.img.bitmapData, matrix);
				s.graphics.drawRect(0,0,80,80);		
				s.graphics.endFill();
			}
		}

		protected override function refreshPortraits():void {
			this.refreshPotraitArray(this.dialogPotraitArray, s_getDialogPotraitMatrix);
			this.refreshPotraitArray(this.targetInfoPotraitArray, s_getTargetInfoPotraitMatrix);			
		}
		
		private function refreshPotraitArray(array:Array, matrix:Matrix):void {
			for (var i:int = 0; i < array.length; i++){
				var s:Sprite = array[i] as Sprite;
				if (s != null && this.avs != null && this.img != null ){
					this.drawPortrait(s, matrix);
				}
			}
			array.length = 0;
		}
		
		public override function setDirection(angle:Number):void{
			if (this.isDispose){
				return;
			}
			super.setDirection(angle);		
			this._frameQueueList.addToFrameQueue(fnSetDir, angle, true);						
		}
		private function fnSetDir(data:Object):void{			
			if (this.direction >= 180 && this.direction < 360){				
				this.faceUp();
			}else{				
				this.faceDown();
			}	
		}		
		
		private static const nonRepeatableAnims:Array = ["sit", "notKo", "idle", "walk", "ko", "linkDead"];
		public override function playAnim(action:String, param:Object = null, allowRepeatAnim:Boolean = false):void {
			if (this.isDispose){
				return;
			}
			
			if (action == "stand") {
				action = "idle";
			}
			if (allowRepeatAnim || (AvatarDisplay.nonRepeatableAnims.indexOf(this.currentActorAnim) == -1) ||  (this.currentActorAnim != action)) {
				super.playAnim(action);
				this._frameQueueList.addToFrameQueue(fnCallAnimation, this.currentActorAnim, true);		
			}
		}
		private function fnCallAnimation(data:Object):void{			
			switch (this.currentActorAnim){							
					case "sit":						
						this.sit();
						break;
					
					case "notKo":
						if (this.genericAnim != null){
							this.genericAnim.playAnim("idle");
						}
						break;				
					
					case "idle":
					case "stand":					
						this.stand();
						break;
					
					case "walk":
						this.walk();
						break;
						
					case "hit":
						if (this.genericAnim != null){
							this.genericAnim.playAnim("hit");
						}
						break;
					
					case "ko":
						if (this.genericAnim != null){
							this.genericAnim.playAnim("ko");
						}
						break;
					
					case "LinkDead":
						if (this.genericAnim != null){
							this.genericAnim.playAnim("LinkDead");
						}
						break;
					default: 
						if (!this._isSittng){
							this.stand();
						}else{
							this.sit();
						}
						break;
				}	
		}
				
		public override function dispose():void
		{
			if (this.img && this.url && s_bitmapCache)
			{
				s_bitmapCache.add(url, img); // just add the image back
			}
			this.img = null;
			
			if(avs) {
				for (var i:int = 0; i < this.avs.length; i++){
					DisplayObjectUtils.ClearAllChildrens(this.avs[i]);
					this.avs[i].removeEventListener(Event.REMOVED_FROM_STAGE, onAvRemovedFromStage);				
					this.avs[i].dispose();
					this.avs[i] = null;	
				}
			}
			this.avs = null;
			
			this._avatarPool.dispose(this);
			
			this.targetInfoPotraitArray = null;
			this.dialogPotraitArray = null;		
			
			super.dispose();
		}
		
		override public function get actorFootX():Number{
			return -71;
		}
		
		override public function get actorFootY():Number{
			return -139;
		}
		
		///****************** Pool factory 
		public function create():*{			
			return new BaseAvatar(this.img.bitmapData);
		}
		public function deconstruct(obj:*):void{
			if (obj != null){			
				DisplayObjectUtils.ClearAllChildrens(BaseAvatar(obj));
				BaseAvatar(obj).dispose();
			}
		}

		public function initializeObjectPool(obj:*, args:Array = null):void {}		
		public function objectPoolCleanUp(obj:*):void {}	
	}
}