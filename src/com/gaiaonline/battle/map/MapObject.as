package com.gaiaonline.battle.map
{
	import com.gaiaonline.battle.ui.events.UiEvents;
	import com.gaiaonline.battle.utils.Rasterization;
	import com.gaiaonline.flexModulesAPIs.globalevent.GlobalEvent;
	import com.gaiaonline.platform.actors.ISilhouetteable;
	import com.gaiaonline.utils.DisplayObjectStopper;
	import com.gaiaonline.utils.DisplayObjectStopperModes;
	import com.gaiaonline.utils.DisplayObjectUtils;
	import com.gaiaonline.utils.SpritePositionBubbler;
	
	import flash.display.Bitmap;
	import flash.display.BlendMode;
	import flash.display.DisplayObject;
	import flash.display.MovieClip;
	import flash.display.SimpleButton;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.geom.ColorTransform;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.Dictionary;
	
	//
	// [kja] MapObject initialization/rasterization:
	//
	// At map load time, the root map stage already contains an instance of each MapObject for the area.  It's unfortunate we
	// have to pay the price of that pre-allocation, that's just due to the current design of the map flas.  In spite of this, we
	// don't need to keep the MapObject resident in memory, so we destroy the instance and save its type for later, so we can
	// create one when the user finally moves to that room ("delayed init").  We don't perform delayed init for all types, although
	// we probably could (there was some complication getting animated map objects to delay init correctly, never figured out why.
	//
	// When delayed initialization happens, we also check to see whether the type has been rasterized, or should be rasterized
	// for the first time.  RasterizationStore helps ensure a mapping between MapObject types and Rasterization instances, so
	// that BitmapData's are shared between common MapObject instances.  
	public class MapObject
	{
		private var _hostMc:SpritePositionBubbler;
		private var _displayMc:Sprite;
		private var _maskMc:Sprite;
		private var _silhouetteHolder:Sprite;
		
		private var _mcGroundLight:Sprite;
		private var _mcShadow:Sprite;
		private var _mcHotSpot:Sprite;
		private var _mcLight:Sprite;
		private var _btnLink:SimpleButton;
		private var _displayShadow:Boolean = true;
		private var _displayGroundLight:Boolean = true;
		private var _state:int = 0;
		private var _colorTransform:ColorTransform;
		
		private var _lightOn:Boolean = false;

		public var name:String;
		
		private var gstLightIgnore:Boolean = false;
		public var displaySilhouette:Boolean = false;
		
		private var _map:IMap = null;
		
		private var _isTintable:Boolean = true;
		
		public function MapObject(map:IMap, mc:Sprite) {
			_map = map;
			if (mc != null){
				this.init(mc);
			}
		}
		
		private function reparentDisplay(disp:Sprite):SpritePositionBubbler {
			// [bgh] create the new parent object for the map object.
			// we do this so that we can do crazy stuff on the display MC
			var hostMc:SpritePositionBubbler = new MapObjectHolder(this);
			hostMc.addChild(disp);
			
			// [BGH] IMPORTANT!!!
			// The order of the code in the rest of this function is important.
			// you have to copy XY from the disp to host before the xform
			// and you can only reset XY on the disp AFTER you copy the xform
			
			// [bgh] move the host movie, and reposition the display MC to be placed correctly
			hostMc.x = disp.x;
			hostMc.y = disp.y;

			// [bgh] take the transform matrix off of the display obj, and put it on the host
			hostMc.transform.matrix = disp.transform.matrix.clone();

			// [kja] the Transform.matrix getter returns a new object, so this is the only way to re-initialize its Matrix  
			disp.transform.matrix = new Matrix();

			// [bgh] at last, we reset the xy on the disp
			disp.x = 0 
			disp.y = 0; 
		
			return hostMc;
		}
		
		private static function createMaskMc(map:IMap, mc:Sprite):Sprite {			
			var maskMc:Sprite = null;
			// [bgh] build the shadow movieclip			
			var rast:Rasterization = map.getRasterizationStore().rasterize(mc); // this fetches the existing rasterization for this type - shared BitmapData's.
			if (rast) {
				var s:MovieClip = new MovieClip();
				s.cacheAsBitmap = true;
				s.addChild(rast.createBitmap());
				return s;
			}


			const maskClass:Class = mc["constructor"];		
			maskMc = new maskClass();
						
			maskMc.transform = mc.transform;
			maskMc.filters = mc.filters;
			// [bgh] we HAVE TO have cacheAsBitmap set to true to use it as a mask
			maskMc.cacheAsBitmap = true; 
			maskMc.opaqueBackground = mc.opaqueBackground;
			if(mc.scale9Grid) {
				var rect:Rectangle = mc.scale9Grid;
				rect.x /= 20;
				rect.y /= 20;
				rect.height /= 20;
				rect.width /= 20;
				maskMc.scale9Grid = rect;
			}
			
			var removingObject:DisplayObject = maskMc.getChildByName("groundLight");
			if(removingObject) {
				maskMc.removeChild(removingObject);
			}
			removingObject = maskMc.getChildByName("shadow");
			if(removingObject) {
				maskMc.removeChild(removingObject);
			}
			removingObject = maskMc.getChildByName("hotSpot");
			if(removingObject) {
				maskMc.removeChild(removingObject);
			}
			removingObject = maskMc.getChildByName("lightProp");
			if(removingObject) {
				maskMc.removeChild(removingObject);
			}
			
			DisplayObjectUtils.stopAllMovieClips(maskMc);
			return maskMc;
		}

		private static const ALLOW_DELAYED_INIT:Boolean = true;
		private var _delayedInit:Object = null;
		private function init(mc:Sprite):void{
			
			//
			// Take ownership of mc.  This means we either release it for gc now to recreate later,
			// or continue with initialization of it (i.e. if it has animation, or is a switch)
			mc.parent.removeChild(mc);

			//
			// Right now we're only doing delayedInit if the item is rasterizable.  We could probably do it more often than that,
			// but it turns out the criteria for delayedInit is really the same. 
			if (ALLOW_DELAYED_INIT && this._map.getRasterizationStore().canRasterize(mc)) {
				
				this.name = mc.name;
				this._colorTransform = mc.transform.colorTransform;
				_delayedInit = 
				{
					objClass: mc["constructor"],
					x: mc.x,
					y: mc.y,
					matrix: mc.transform.matrix.clone(),
					filters:mc.filters.concat()				
				};				
				///--- Save setting from the original swf. (using the constructor does not run first frame code)
				if (mc.hasOwnProperty("gstLightIgnore")){				
					_delayedInit.gstLightIgnore = Object(mc).gstLightIgnore;										
				}
				if (mc.hasOwnProperty("isTintable")){
					_delayedInit.isTintable = Object(mc).isTintable;
				}
				if (mc.hasOwnProperty("displaySilhouette")){
					_delayedInit.displaySilhouette = Object(mc).displaySilhouette;				
				}
			}
			else {
				finishInit(mc);
			}
		}
		
		private function performDelayedInit():void {
			if (!this._displayMc) {			

				var mc:Sprite = new _delayedInit.objClass();
				mc.x = _delayedInit.x;
				mc.y = _delayedInit.y;
				mc.transform.matrix = _delayedInit.matrix;
				mc.filters = _delayedInit.filters;				
				mc.name = this.name;
				
				
				///--- set previously saved setting from the original swf. (using the constructor does not run first frame code)
				if (_delayedInit.hasOwnProperty("gstLightIgnore")){
					Object(mc).gstLightIgnore = _delayedInit.gstLightIgnore;
				}
				if (_delayedInit.hasOwnProperty("isTitnable")){
					Object(mc).isTintable = _delayedInit.isTintable;
				}
				if (mc.hasOwnProperty("displaySilhouette")){
					Object(mc).displaySilhouette = _delayedInit.displaySilhouette;			
				}
				
				finishInit(mc);	
				
			}
		}

		private var _displayObjectStopper:DisplayObjectStopper;
		private function finishInit(mc:Sprite):void {

			var mcHit:Sprite = Sprite(mc.getChildByName("hit"));
			if (mcHit) {
				mc.removeChild(mcHit);
				DisplayObjectUtils.ClearAllChildrens(mcHit);							
			}

			// [bgh] save the display object, and then set cacheAsBitmap on it so that
			// we can use an image mask against it. :-D
			this._displayMc = mc;
			this._displayMc.cacheAsBitmap = true;
			this.name = _displayMc.name;

			// [bgh] reparent the display object.
			// code moved into a separate function because the order is imporant
			this._hostMc = reparentDisplay(_displayMc);

			// [bgh] remove the light prop from inside the display MC.
			// if we leave it in there, then it will affect the display in 
			// aweful ways since we  have changed the blend mode of the 
			// display MC to Layer. Reparenting it onto host will keep
			// the UI looking like what the artists wanted.
			_mcLight = _displayMc.getChildByName("lightProp") as Sprite;
			if(_mcLight) {
				this._mcLight.visible = this._lightOn;	
				_hostMc.addChild(_mcLight);
			}
			
			// [bgh] create a holder for all of the silhouettes, mask this holder
			// with _maskMc when we have people in it
			this._silhouetteHolder = new Sprite();			
			
			this._hostMc.addChild(this._silhouetteHolder);

			this._hostMc.mouseEnabled = false;
			this._hostMc.mouseChildren = false;
			this._hostMc.hitArea = null;
			
			this._btnLink = _displayMc.getChildByName("btnLink") as SimpleButton;		
			if ( this._btnLink != null){						
				this._btnLink = MovieClip(_displayMc).btnLink;
				this._displayMc.removeChild(this._btnLink);				
							
				var poff:Point = new Point(this.btnLink.x, this.btnLink.y);
				
				this.btnLink.x = 0;
				this.btnLink.y = 0;				
				var m:Matrix = this._hostMc.transform.matrix.clone();
				m.concat( this.btnLink.transform.matrix );												
				this.btnLink.transform.matrix = m;
				
				this.btnLink.x = this._hostMc.x + (poff.x  * this._hostMc.scaleX);
				this.btnLink.y= this._hostMc.y + (poff.y *  this._hostMc.scaleY);
																
				this._btnLink.addEventListener(MouseEvent.CLICK, onLinkClick, false, 0, true);
				this._btnLink.addEventListener(MouseEvent.MOUSE_OVER, onLinkMouseOver, false, 0, true);
				this._btnLink.addEventListener(MouseEvent.MOUSE_OUT, onLinkMouseOut, false, 0, true);				
			}
			if (this._displayMc.hasOwnProperty("gstLightIgnore")){				
				this.gstLightIgnore = Object(this._displayMc).gstLightIgnore;				
				this.setLight(this.gstLightIgnore);
			}	
			if (this._displayMc.hasOwnProperty("isTintable")){
				this._isTintable = Object(this._displayMc).isTintable;
			}
			if (this._displayMc.hasOwnProperty("displaySilhouette")){
				this.displaySilhouette = Object(this._displayMc).displaySilhouette;	
			}
				
			for (var i:int = 0; i<this._displayMc.numChildren ; i++){		
				if (this._displayMc.getChildByName("groundLight") != null){					
					this._mcGroundLight = Sprite(this._displayMc.getChildByName("groundLight"));						
					if (this._mcGroundLight.hasOwnProperty("displayGroundLight")){
						this._displayGroundLight = Object(this._mcGroundLight).displayGroundLight
					}
					
					var gm:Matrix = this._mcGroundLight.transform.matrix;
					gm.concat(this._displayMc.transform.matrix);
					gm.concat(this._hostMc.transform.matrix);
					this._mcGroundLight.transform.matrix = gm;										
					
					this._mcGroundLight.visible = this._lightOn && this._displayGroundLight;	
					this._displayMc.removeChild(this._mcGroundLight);
				}
				if (this._displayMc.getChildByName("shadow") != null){											
					this._mcShadow = Sprite(this._displayMc.getChildByName("shadow"));
					if (this._mcShadow.hasOwnProperty("displayShadow")){
						this._displayShadow = Object(this._mcShadow).displayShadow;
					}
					this._mcShadow.visible = this._displayShadow;
					
					var sm:Matrix = this._mcShadow.transform.matrix;
					sm.concat(this._displayMc.transform.matrix);
					sm.concat(this._hostMc.transform.matrix);
					this._mcShadow.transform.matrix = sm;									
										
					this._displayMc.removeChild(this._mcShadow);
					
				}
				if (this._displayMc.getChildByName("hotSpot") != null){																
					this._mcHotSpot = Sprite(this._displayMc.getChildByName("hotSpot"));
					
					var hm:Matrix = this._mcHotSpot.transform.matrix;
					hm.concat(this._displayMc.transform.matrix);
					hm.concat(this._hostMc.transform.matrix);
					this._mcHotSpot.transform.matrix = hm;	
					
					this._mcHotSpot.visible = this._lightOn;	
					this._displayMc.removeChild(this._mcHotSpot);		
				}
			}

			_displayObjectStopper = new DisplayObjectStopper(DisplayObjectStopperModes.SHOW_NO_ANIM, true);
			_displayObjectStopper.addGarbageStopper(this._hostMc, null);
			DisplayObjectUtils.stopAllMovieClips(this._hostMc);

		}

		private var _canRasterize:Boolean = true;
		public function display():void {

			if (_delayedInit) {
				performDelayedInit();
				_delayedInit = null;
			}

			if (_canRasterize)
			{
				_canRasterize = false;

				if (this._displayMc.getChildByName("mcStates") == null) // not a switch
				{
					var filters:Array = this._displayMc.filters.concat();
					this._displayMc.filters = new Array();									
					var rast:Rasterization = this._map.getRasterizationStore().rasterize(this._displayMc);									
					this._displayMc.filters = filters;
					
					if (rast)
					{
						var bmp:Bitmap = rast.createBitmap();
			
						this._displayMc.cacheAsBitmap = false;
						while (this._displayMc.numChildren > 0) {
							this._displayMc.removeChildAt(0);
						}
						this._displayMc.addChild(bmp);
					}
				}
			}
			
			// start animation .. (do not call play on switch)
			if (_displayObjectStopper && this._displayMc.getChildByName("mcStates") == null) {
				DisplayObjectUtils.startAllMovieClips(this._hostMc);
			}
		}
		
		public function hide():void {
			if (_displayObjectStopper) {
				DisplayObjectUtils.stopAllMovieClips(this._hostMc);
			}
		}

		private function onUsableMouseOver(evt:MouseEvent):void{
			if (this._displayMc != null){
				this._displayMc.dispatchEvent(new MouseEvent(evt.type, false, false, evt.localX, evt.localY));
			}
		}
		private function onUsableMouseOut(evt:MouseEvent):void{
			if (this._displayMc != null){
				this._displayMc.dispatchEvent(new MouseEvent(evt.type, false, false, evt.localX, evt.localY));
			}
		}
		private function onUsableClick(evt:MouseEvent):void{
			if (this._displayMc != null){
				var e:UiEvents = new UiEvents("USE", null);			
				e.value = new Object();			
				this._displayMc.dispatchEvent(e);
			}			
		}
		
		
		public function get btnLink():SimpleButton {
			// [bgh] return the value on the MC or false if it is undefined
			return this._btnLink;
		}

		public function get isCustomLight():Boolean {
			// [bgh] return the value on the MC or false if it is undefined
			return Object(_displayMc).isCustomLight || false;
		}

		private function get links():Array {
			// [bgh] return an array of links, or null if there are none
			if (this._displayMc != null){
				return MovieClip(this._displayMc).links;
			}
			return null;
		}
		
		private function onLinkClick(evt:MouseEvent):void{
			if (this.links != null){
				GlobalEvent.eventDispatcher.dispatchEvent(new GlobalEvent(GlobalEvent.LINK_CLICKED, {links:this.links}));
			}	
		}
		
		private function onLinkMouseOver(evt:MouseEvent):void{	
			GlobalEvent.eventDispatcher.dispatchEvent(new GlobalEvent(GlobalEvent.MOUSE_OVER_STATE_CHANGED, {isLink:true}));																														
		}
		private function onLinkMouseOut(evt:MouseEvent):void{
			GlobalEvent.eventDispatcher.dispatchEvent(new GlobalEvent(GlobalEvent.MOUSE_OVER_STATE_CHANGED, {isLink:false}));																														
		}
		
		
		public function setLight(v:Boolean = true):void{
			
			if (this.gstLightIgnore){
				v = true;
			}
			
			if (this._lightOn != v) {
				this._lightOn = v;
				
				if (this._mcLight != null){
					this._mcLight.visible = this._lightOn;				
				}
				
				if (this._mcGroundLight != null){
					this._mcGroundLight.visible = this._lightOn && this._displayGroundLight;				
				}
				if (this._mcHotSpot != null){
					this._mcHotSpot.visible = this._lightOn;				
				}			
			}
		}		
		//-- tint ---------
		
		public function setTint(r:int, g:int, b:int):void{			
			if (this._displayMc != null){				
				var ct:ColorTransform = new ColorTransform(r/256,g/256,b/256,1,0,0,0,0);
				if (this._colorTransform != null){
					ct.concat(this._colorTransform);
				}
				this._displayMc.transform.colorTransform = ct;
			}
		}

		public function getTintType():TintTypes{
			if (this._isTintable){
				return TintTypes.NO_SHADOWS;
			}else{
				return TintTypes.NONE;
			}
		}

		public function get x():Number{
			return _hostMc.x;
		}
		
		public function get y():Number{
			return _hostMc.y;
		}

		public function dispose():void{

			// [bgh] remove the object silhouettes
			removeAllObjectSilhouettes();
			
			if (this._hostMc) {
				this._hostMc.removeChild(this._silhouetteHolder);
			}
			this._silhouetteHolder = null;
			
			// [bgh] clear the black layer
			clearMc(this._maskMc);
			this._maskMc = null;
			
			// [bgh] clear the display
			clearMc(this._displayMc);
			this._displayMc = null;
			
			// [bgh] clear the host
			clearMc(this._hostMc);
			this._hostMc = null;

			clearMc(this._mcGroundLight);			
			this._mcGroundLight = null;

			clearMc(this._mcHotSpot);			
			this._mcHotSpot = null;
			
			clearMc(this._mcShadow);		
			this._mcShadow = null;			
			
			this._objectSilhouettes = null;
			this._displayObjectStopper = null;
			
			this._map = null;
			
			_matrices = null;
			
		}

		private static function clearMc(mc:Sprite):void {
			if (mc != null && mc.parent != null){
				mc.parent.removeChild(mc);
			}
			DisplayObjectUtils.ClearAllChildrens(mc);
		}

		// -- getter setter
		public function getStageMc():SpritePositionBubbler{
			return this._hostMc;
		}
		public function getEventMc():Sprite {
			return this._displayMc;
		}
		
		public function getShadow():Sprite{
			return this._mcShadow;
		}
		public function getGroundLight():Sprite{
			return this._mcGroundLight;
		}
		public function getHotSpot():Sprite{
			return this._mcHotSpot;			
		}
				
		public function get displayShadow():Boolean{
			return this._displayShadow;
		}
		public function get displayGroundLight():Boolean{
			return this._displayGroundLight && this._lightOn;
		}
				
		public function updateState(actorObj:Object, transition:Boolean = false):void{
			
						
			if (this._displayMc != null && Object(this._displayMc).updateState != null ){
				Object(this._displayMc).updateState(actorObj, transition);
				
				var isUsable:Boolean = false;
				if (actorObj.aids != null){
					isUsable = (actorObj.aids.indexOf("Usable") >= 0);					
							
					if (isUsable && this._hostMc != null && this._displayMc != null){													
						this._hostMc.hitArea = this._displayMc.hitArea;	
						this._hostMc.mouseChildren = false;	
						this._hostMc.mouseEnabled = true;
						
						this._hostMc.addEventListener(MouseEvent.MOUSE_OVER, onUsableMouseOver, false, 0, true);
						this._hostMc.addEventListener(MouseEvent.MOUSE_OUT, onUsableMouseOut, false, 0, true);
						this._hostMc.addEventListener(MouseEvent.CLICK, onUsableClick, false, 0, true);		
						 															
					}else{				
						this._hostMc.mouseEnabled = false;
						this._hostMc.mouseChildren = false;
						this._hostMc.hitArea = null;
						
						this._hostMc.removeEventListener(MouseEvent.MOUSE_OVER, onUsableMouseOver);
						this._hostMc.removeEventListener(MouseEvent.MOUSE_OUT, onUsableMouseOut);
						this._hostMc.removeEventListener(MouseEvent.CLICK, onUsableClick); 
					}
				}			
			}
			
			if (actorObj.state != null){
				this._state = actorObj.state;
			}
		}
	
		// [bgh] a hashmap to hold object silhouettes in. If the actor goes behind us
		// we need to add the silhouette we create for them into the hash
		// the hash is actorId -> silhouette
		private var _objectSilhouettes:Dictionary = new Dictionary(true);

		// [bgh] convenience function for removing a object silhouette
		public function removeObjectSilhouette(silhouetteable:ISilhouetteable):void {
			removeObjectSilhouetteById(silhouetteable);
		}
		
		// [bgh] remove the silhouette and the event listeners
		private function removeObjectSilhouetteById(actor:ISilhouetteable):void {

			var silhouette:Sprite = _objectSilhouettes[actor];
			if(null!=silhouette && silhouette.parent == _silhouetteHolder) {
				_silhouetteHolder.removeChild(silhouette);
				delete _objectSilhouettes[actor];
			}
		}
		
		private static const SILHOUETTE_COLOR_TRANSFORM:ColorTransform = new ColorTransform(0, 0, 0, 0, 0, 0, 0, 96);
		
		// [bgh] a function to create the silhouette of the given actor
		private function createSilhouette(silhouetteable:ISilhouetteable):Sprite {
//			this.moveCounter= 0;

			// [bgh] create the actor and transform it into a transparent black (37.5% alpha)
			var silhouette:Sprite = silhouetteable.getCopyOfSpriteToBeSilhouetted();
			if(silhouette) {
				silhouette.transform.colorTransform = SILHOUETTE_COLOR_TRANSFORM;
				
				// [bgh] blend mode = layer so that they alphas don't add on each other
				silhouette.blendMode = BlendMode.LAYER;
				
				// [bgh] save the silhouette into the hash
				_objectSilhouettes[silhouetteable] = silhouette;
			}

			// [bgh] add it to the holder and return it.
			if(null != silhouette) {
				_silhouetteHolder.addChild(silhouette);
			} else {
				trace("SILHOUETTE IS NULL FIX ME!!!");
			}			

			
			return silhouette;
		}
		
		private var originReuse:Point = new Point(0, 0);
		
		private var _matrices:Dictionary = new Dictionary(true);
		
		public function updateSilhouette(silhouettable:ISilhouetteable, scalingDirty:Boolean):void{
			// [bgh] the actor and their silhouette

			

			var silhouette:Sprite = _objectSilhouettes[silhouettable];
			if (silhouette) {
				
				//cheap check.  Might as well remove it if we can.  Also, when actors die, or become
				//unselected it is quickly removed.
				if(!silhouettable.displaySilhouette || !silhouettable.parent){
					removeObjectSilhouette(silhouettable);
					return;
				}
				
				// [bgh] turn the silhouette visible, it could have been turned invis
				this.setSilhouetteVisible(silhouette, true);

				if (scalingDirty) {					
					// [bgh] transform the silhouette to be in a untransformed state.
					
					if(!_matrices[silhouettable]){
						_matrices[silhouettable] = new Dictionary(true);
					}
					
					var silhouetteMatrix:Matrix = _matrices[silhouettable][silhouettable.scale.x + "_" + silhouettable.scale.y];
					
					if(!silhouetteMatrix){
						
						var actorDisplay:Sprite = silhouettable.getDisplaySprite();
						silhouetteMatrix = actorDisplay.transform.matrix.clone();
						silhouetteMatrix.concat(this.invertedHostMatrix);					
						
						
						_matrices[silhouettable][silhouettable.scale.x + "_" + silhouettable.scale.y] = silhouetteMatrix
					}
					silhouette.transform.matrix = silhouetteMatrix;
				}
				
				originReuse.x = silhouettable.actorFootX * silhouettable.scale.x;
				originReuse.y = silhouettable.actorFootY * silhouettable.scale.y;
	
				originReuse.y += silhouettable.zpos * silhouettable.scale.y;

				// [bgh] a little bit of magic to position the silhouette correctly
				var globalActorPoint:Point = silhouettable.localToGlobal(originReuse);
				var dispMaskPoint:Point = _silhouetteHolder.globalToLocal(globalActorPoint);
				
				silhouette.x = dispMaskPoint.x;
				silhouette.y = dispMaskPoint.y;
			}
		}
		
		private var _silhouetteVisible:Boolean = false;		
		private function setSilhouetteVisible(silhouette:Sprite, visible:Boolean):void {
			if (_silhouetteVisible != visible) {
				silhouette.visible = visible;
				this._silhouetteVisible = visible;
			}
		}
		
		private var _invertedHostMatrix:Matrix = null;
		private function get invertedHostMatrix():Matrix {
			if (_invertedHostMatrix == null) {
				_invertedHostMatrix = _hostMc.transform.matrix;
				_invertedHostMatrix.invert(); 
			}
			return _invertedHostMatrix;
		}
		
		public function quickIntersectionTest(silhouetteable:ISilhouetteable):Boolean{
			var objMc:Sprite = getStageMc();
			if (objMc != null && objMc.y > silhouetteable.y){
				return true;
			}
			return false;
		}
		
		private function fullIntersectionTest(silhouetteable:ISilhouetteable):Boolean{
			return silhouetteable.hitTestObject(_displayMc);
		}
		
		
		//removes invalid silhouettes
		//adds new ones if necessary.
		public function checkSilhouettes(silhouetteable:ISilhouetteable):Boolean {
			// [bgh] some early sanity checks and quick exits
			if(null == _hostMc.parent) {
				return false;
			}
		
			// [bgh] get the silhouette out of the map
			var silhouette:Sprite = _objectSilhouettes[silhouetteable];
			
			// [bgh] if our rectangles intersect, we need to have a silhouette for that actor
			if (silhouetteable.displaySilhouette && quickIntersectionTest(silhouetteable) && fullIntersectionTest(silhouetteable)) {				
				if(!this._maskMc) {
					// [bgh] set up the bitmap caching
					this._silhouetteHolder.cacheAsBitmap = true;
					
					// [bgh] add the black MC under the displayMc on the display list
					this._maskMc = createMaskMc(this._map, _displayMc);
					if (this._maskMc  != null && Object(this._maskMc ).updateState != null ){
						Object(this._maskMc ).updateState({state:this._state});
					}
					this._hostMc.addChild(this._maskMc);
					this._silhouetteHolder.mask = this._maskMc;
				}
				
				
//				var scalingDirty:Boolean = actor.scalingDirty;
				var scalingDirty:Boolean = silhouetteable.scalingDirty;

				// [bgh] if we do not have a silhouette, create one
				if(!silhouette) {
					// [bgh] the first time an actor hits us, we won't have a silhouette for them
					// we need to call the first MOVE on them, after that, we'll get updates
					// in the onActorMove function when they move. This helps us not to do a
					// lot of processing on EVERY frame.
					createSilhouette(silhouetteable);
					const scale:Point = silhouetteable.scale; 
					
					scalingDirty = true;
				}
				
				// [bgh] if we turned the silhouette invisible, and now we need it on, turn it on
				if(silhouette && !silhouette.visible) {
					scalingDirty = true;
				}
				
				updateSilhouette(silhouetteable, scalingDirty);
				silhouetteable.scalingDirty = false;
				return true;
				
			} else if(silhouette) {
				// [bgh] if we do not intersect with them, turn their silhouette invis
				this.setSilhouetteVisible(silhouette, false);
				removeObjectSilhouette(silhouetteable);
				return false;
			}
			
			return false;
		}

		// [bgh] remove ALL of the silhouettes that we have
		public function removeAllObjectSilhouettes():void {
			for (var actor:Object in _objectSilhouettes) {
				removeObjectSilhouetteById(ISilhouetteable(actor));
			}
			
			// [bgh] set up the bitmap caching
			if(null!=_silhouetteHolder) {
				this._silhouetteHolder.cacheAsBitmap = false;
				this._silhouetteHolder.mask = null;
			}
			
			if(null != this._maskMc && this._hostMc.contains(this._maskMc)) {
				this._hostMc.removeChild(this._maskMc);
			}
			if(null != this._maskMc) {
				this._maskMc = null;
			}
		}
	}
}
