/**
 * There's a consistent sequence of events for Map Sliding and Map Warping.  Most likely you'll want to listen for MAP_ROOM_LEAVE and NEW_ROOM_ENTERED.
 * The event firing comes from GameTransitionManager and nowhere else.
 * 
 * 
 * MapSlide
    - MAP_ROOM_LEAVE*****************
    - MAP_SLIDE_START
    - MAP_SLIDE_COMPLETE
    - NEW_ROOM_ENTERED*****************
 
 * Warp to a new room
    - MAP_WARP_OUT_TRANSITION_START
    - MAP_WARP_OUT_TRANSITION_COMPLETE
    - MAP_ROOM_LEAVE*****************
    - MAP_LOAD_ZONE
    - MAP_DONE
    - NEW_ROOM_ENTERED*****************
    - MAP_WARP_IN_TRANSITION_START
    - MAP_WARP_IN_TRANSITION_COMPLETE

 * Warp within the same room, same instance
    - MAP_WARP_WITHIN_ROOM
 * 
 * */



package com.gaiaonline.battle.map
{
	import com.gaiaonline.battle.utils.BattleUtils;
	import com.gaiaonline.battle.utils.RasterizationStore;
	import com.gaiaonline.display.wordbubble.WordBubbleManager;
	import com.gaiaonline.flexModulesAPIs.globalevent.GlobalEvent;
	import com.gaiaonline.platform.gateway.ICollisionConnector;
	import com.gaiaonline.platform.map.IMapSoundManager;
	import com.gaiaonline.platform.map.ITalkIconManager;
	import com.gaiaonline.platform.map.ITintManager;
	import com.gaiaonline.platform.map.MapFilesFactory;
	import com.gaiaonline.utils.DisplayObjectStopper;
	import com.gaiaonline.utils.DisplayObjectStopperModes;
	import com.gaiaonline.utils.DisplayObjectUtils;
	import com.gaiaonline.utils.FrameTimer;
	import com.gaiaonline.utils.MouseEventProxy;
	import com.gaiaonline.utils.MouseMoveLimiter;
	import com.gaiaonline.utils.SpritePositionBubbler;
	import com.gaiaonline.utils.VisManagerSingleParent;
	
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.events.ProgressEvent;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	public class Map extends Sprite implements IMap
	{
	
		public static const MAP_INITIALIZED:String = "MapInitialized";
		
		// layers		
		private var infoLayer:Sprite;
		private var collisionLayer:Sprite;
		private var _collisionDebugLayer:Sprite;

		private var waterLayer:Sprite;
		
		private var _mainContainer:Sprite;
		private var mcBackLayer:Sprite;
		private var _mcGroundEffect:Sprite;
		private var mcHotSpotLayer:Sprite;
		private var mcBtnLayer:Sprite;
		private var wbContainer:Sprite;	
		private var _emoteLayer:Sprite;
		
		private var _awarenessLayer:Sprite;
		private var debuggingLayer:Sprite;
				
		private var _isMapVisible:Boolean = false;		
		
		// miniMapInfo		
		private var areaScale:Number = 75;
		private var areaName:String = "";
		
		//-------------------------------
		private var mapLoaded:Boolean = false;
		
		// sounds
		private var _soundManager:IMapSoundManager = null;
		
		private var _baseUrl:String = null;
		private var _waterDepthManager:WaterDepthManager = null;
		
		private var _mapLoadManager:MapLoadManager = null;

		private var _stageLayerManager:StageLayerManager = null;

		public function Map(mapRoomManager:MapRoomManager, tintManager:ITintManager, talkIconManager:ITalkIconManager, soundManager:IMapSoundManager, mapLoadManager:MapLoadManager, baseUrl:String, awarenessLayer:Sprite, debugLayer:Sprite=null){
			
			this._baseUrl = baseUrl;			
			
			DisplayObjectUtils.addWeakListener(GlobalEvent.eventDispatcher, GlobalEvent.MAP_LOAD_ZONE, loadZone);
			DisplayObjectUtils.addWeakListener(GlobalEvent.eventDispatcher, GlobalEvent.MAP_DONE, setRoom);
			DisplayObjectUtils.addWeakListener(GlobalEvent.eventDispatcher, GlobalEvent.NEW_ROOM_ENTERED, onNewRoomEntered);
			
			this._awarenessLayer = awarenessLayer;
			this.debuggingLayer = debugLayer;
			
			_waterDepthManager = new WaterDepthManager(this);
			
			_mapRoomManager = mapRoomManager;
			
			_mapLoadManager = mapLoadManager;
			_mapLoadManager.addEventListener(MapLoadManagerEvent.COMPLETE, onMapLoaded, false, 0, true);
			
			_theTintManager = tintManager;
			
			var silManager:SilhouetteManager = new SilhouetteManager(_mapRoomManager);
			
			_soundManager = soundManager;
			
			
			_stageLayerManager = new StageLayerManager(_waterDepthManager, _theTintManager, silManager);
			_projectileManager = new ProjectileManager(_stageLayerManager);
			_lootParticleManager = new LootParticleManager(_stageLayerManager);
			
			_talkIconManager = talkIconManager
			
			init();
		}
		
		private var _mapRoomManager:MapRoomManager = null;
				

		
		
		/**
		 * We really don't want to be setting the currentRoomId and the currentInstanceId all the time from different places.  Let's do it in one place, as early
		 * as possible (mapRoomLeave).
		 * */
		
		private function onNewRoomEntered(event:GlobalEvent):void{
			var data:Object = event.data
			clearOldRoom(data.previousRoomId, data.newRoomId);
		}
		
		private var _mapHolder:IMapHolder = null;
		public function setMapHolder(holder:IMapHolder):void{
			_mapHolder = holder;
			_dialogManager.setBounds(_mapHolder.getMcBound());
		}
		
		public function getRoomById(id:String):MapRoom{
			return _mapRoomManager.getRoomById(id);
		}
		
		private function startListeners():void 
		{
		
			DisplayObjectUtils.addWeakListener(GlobalEvent.eventDispatcher, GlobalEvent.MAP_ADD_GROUND_RING_EFFECT, addRingGroundEffect);
			DisplayObjectUtils.addWeakListener(GlobalEvent.eventDispatcher, GlobalEvent.MAP_REMOVE_GROUND_RING_EFFECT, removeRingGroundEffect);
			DisplayObjectUtils.addWeakListener(GlobalEvent.eventDispatcher, GlobalEvent.MAP_ADD_POINT_RING_EFFECT, addRingPointEffect);
			DisplayObjectUtils.addWeakListener(GlobalEvent.eventDispatcher, GlobalEvent.MAP_REMOVE_POINT_RING_EFFECT, removeRingPointEffect);
			DisplayObjectUtils.addWeakListener(GlobalEvent.eventDispatcher, GlobalEvent.MAP_SET_MOUSE_ENABLED, setMouseEnabled);
			DisplayObjectUtils.addWeakListener(GlobalEvent.eventDispatcher, GlobalEvent.MAP_SET_MOUSE_CHILDREN, setMouseChildren);
				
			DisplayObjectUtils.addWeakListener(GlobalEvent.eventDispatcher, GlobalEvent.MAP_SLIDE_START, onMapSlideStart);
		}
		
		
		private var _mouseMoveLimiter:MouseMoveLimiter;

		private function init():void{
			this.tabEnabled = false;
			this.tabChildren = false;
									
			this.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown, false, 0, true);
			this.addEventListener(MouseEvent.MOUSE_UP, onMouseUp, false, 0, true);
			
			this._mouseMoveLimiter =  new MouseMoveLimiter(this);
			this._mouseMoveLimiter.addListener(onMouseMove);
			
			// init layers	(create all the layers)
			this.initLayers();				
		}
		
		private var _projectileManager:ProjectileManager = null;
		private var _dialogManager:DialogManager = null;
		private var _lootParticleManager:LootParticleManager = null;
		
		private function initLayers():void{
						
			//trace("[MAP] init Layers");			
						
			// main container : back, tint, stage, hotSpots			
			this._mainContainer = new Sprite();			
			this.addChild(this._mainContainer);
			
			// back layer : background images	
			this.mcBackLayer = new Sprite();
			
			// backgorund ring effects;
			this._mcGroundEffect = new Sprite();
			
			
			// stage layer : MapObjs, Actors, Particles;
			
			// hotSpotLayer : 
			this.mcHotSpotLayer = new Sprite();
			this.mcHotSpotLayer.mouseEnabled = false;
			this.mcHotSpotLayer.mouseChildren = false;
			
			//-- Button Layer (for links buttons) 		
			this.mcBtnLayer = new Sprite();
						
			// add to main Container
			this._mainContainer.addChild(this.mcBackLayer);			
			
			//hopefully we'll put this back soon.  temp replacement is in setTintManager
			this._mainContainer.addChild(_theTintManager.getTintLayer());
			
			
			this._mainContainer.addChild(this._mcGroundEffect);

			//hopefully we'll put this back soon.  temp replacement is in setTintManager
			this._mainContainer.addChild(_stageLayerManager.getStageLayer());
			this._mainContainer.addChild(this.mcHotSpotLayer);
			this._mainContainer.addChild(this.mcBtnLayer);
			
			
			// Word bubbles
			this.wbContainer = new Sprite;	
			this._mainContainer.addChild(this.wbContainer);
			this.wbContainer.mouseEnabled = false;
			
			// emoteLayer:
			this._emoteLayer = new Sprite();
			this._mainContainer.addChild(this._emoteLayer);

			this._mainContainer.addChild(_talkIconManager.getTalkIconLayer());		
						
			this.addChild(this._awarenessLayer);
			
			
			this._collisionDebugLayer = new Sprite();
			this._collisionDebugLayer.visible = false;
			this.addChild(this._collisionDebugLayer);
			
			if(debuggingLayer){
				this.addChild( this.debuggingLayer );
			}
			
			_dialogManager = new DialogManager(wbContainer);
		}	
		
		private var _talkIconManager:ITalkIconManager = null;
		private var _theTintManager:ITintManager = null;

		private var _rasterizationStore:RasterizationStore 
		public function getRasterizationStore():RasterizationStore {  // kinda sucks - but it's too hard to pass this to MapObject every time it needs it -kja
			if (!_rasterizationStore) {
				_rasterizationStore = new RasterizationStore();
			}
			return _rasterizationStore;
		}

		private function setMouseChildren(event:GlobalEvent):void
		{
			this._mainContainer.mouseChildren = event.data.enabled;
		}
		
		private function setMouseEnabled(event:GlobalEvent):void
		{
			this._mainContainer.mouseEnabled = event.data.enabled;
		}

		private function loadZone(event:GlobalEvent):void{
			unloadZone();
			
			var zoneToLoad:String = event.data.zone
			
			_rasterizationStore = null;			
					
			_mapLoadManager.startLoad(zoneToLoad);			
			
			this.infoLayer = null;
		
			this.mapLoaded = false;
		}	
		
		private function get zone():String{
			return _mapRoomManager.zone;
		}
		
		//---rings
		private function addRingGroundEffect(event:GlobalEvent):void
		{
			this._mcGroundEffect.addChild(event.data.effect);
		}

		private function removeRingGroundEffect(event:GlobalEvent):void
		{
			var child:DisplayObject = DisplayObject(event.data.effect);
			if(this._mcGroundEffect.contains(child))
			{
				this._mcGroundEffect.removeChild(child);
			}
		}
		private function addRingPointEffect(event:GlobalEvent):void
		{
			this._stageLayerManager.addChild(event.data.effect);
		}

		private function removeRingPointEffect(event:GlobalEvent):void
		{
			var child:DisplayObject = DisplayObject(event.data.effect);
			this._stageLayerManager.removeChild(child);
		}
		
		//--------
		
		private var _backgroundLayerStopper:DisplayObjectStopper;	
		
		private var _isFirstMap:Boolean = true;
		
		private function onMapLoaded(evt:MapLoadManagerEvent):void{

			GlobalEvent.eventDispatcher.dispatchEvent(new Event(GlobalEvent.MAP_LOADED));

			var parent:MovieClip = evt.mapData;

			this.areaScale = parent.getScale ? parent.getScale() : 75;

			// Get the room info from the file and build custom layou if null
			this.infoLayer = Sprite(parent.getChildByName("infoLayer"));
			if (this.infoLayer) {				
				this.infoLayer.x = this.infoLayer.y = 0;
				
				_mapRoomManager.initRoomsFromInfoLayer(infoLayer);
			}

			DisplayObjectUtils.ClearAllChildrens(this.infoLayer);
						
			// build the BackGroundLayer
			var backLayer:Sprite = 	Sprite(parent.getChildByName("backLayer"));			
			if (backLayer) {
				_backgroundLayerStopper = new DisplayObjectStopper(DisplayObjectStopperModes.SHOW_NO_ANIM, true);
				_backgroundLayerStopper.addGarbageStopper(this.mcBackLayer);

				this.initBackGrounds(backLayer);
				backLayer.x = backLayer.y = 0;
			}

			var waterLayer:Sprite = Sprite(parent.getChildByName("waterLayer"));
			_waterDepthManager.initWater(waterLayer);
			
			// buil the GST and Room Tint Layer;
			var size:Point = this.getSize();
			_theTintManager.initTintLayers(size.x, size.y);
			

			// Get mapObject

			this.collisionLayer = Sprite(parent.getChildByName("collisionLayer"));
			var stageLayer:Sprite = Sprite(parent.getChildByName("stageLayer"));
			if (stageLayer) {			
				stageLayer.x = stageLayer.y = 0;
				this.initMapObject(stageLayer);			
			}

			if (this.collisionLayer != null){
				this.collisionLayer.x = this.collisionLayer.y = 0;				
				parent.removeChild(this.collisionLayer);
				DisplayObjectUtils.ClearAllChildrens(this.collisionLayer, 3);
			}
			
			// init SoundObject
			var soundLayer:Sprite = Sprite(parent.getChildByName("soundLayer"));
			if (soundLayer != null)
			{
				soundLayer.x = soundLayer.y = 0;
				this.initSounds(soundLayer);
			};
			DisplayObjectUtils.ClearAllChildrens(soundLayer);

			_theTintManager.setCurrentGSTTint(!_isFirstMap);
			_theTintManager.setLights();
			_isFirstMap = false;
			
			this.mapLoaded = true;
			
			dispatchEvent(new Event(MAP_INITIALIZED));

			startListeners();
			
			BattleUtils.disableMouseOnChildren(this);			
			
		}
		

		
		private function initBackGrounds(backLayer:Sprite):void{
			
			GlobalEvent.eventDispatcher.dispatchEvent(new ProgressEvent(GlobalEvent.MAP_INIT_PROGRESS,false,false,60,100));
			
			DisplayObjectUtils.stopAllMovieClips(backLayer);

			for (var n:int = 0; n < backLayer.numChildren; n++){

				var fileBackImg:MovieClip = backLayer.getChildAt(n) as MovieClip;
				if (fileBackImg)
				{					
					var fCol:int = Math.floor(fileBackImg.x/780);
					var fRow:int = Math.floor(fileBackImg.y/505);
					var r:MapRoom = _mapRoomManager.getRoomAtLayoutPos(fCol, fRow);
					if (r) {
						var fx:int = fileBackImg.x - (fCol*780); // x position in relation to the room
						var fy:int = fileBackImg.y - (fRow*505); // y position in relation to the room
						var lx:int = (r.layoutPos.x*780) + fx;
						var ly:int = (r.layoutPos.y*505) + fy;						
						
						fileBackImg.x = lx;
						fileBackImg.y = ly;
						r.setBack(fileBackImg);
					}
				}			
			}
		}
		
		private function initMapObject(stageLayer:Sprite):void{
			
			GlobalEvent.eventDispatcher.dispatchEvent(new ProgressEvent(GlobalEvent.MAP_INIT_PROGRESS,false,false,80,100));
			
			var mcImpassible:Sprite = Sprite(this.collisionLayer.getChildByName("mcImpassible"));
			if (mcImpassible != null){
				DisplayObjectUtils.ClearAllChildrens(mcImpassible, 3);
			}
			
			if (!stageLayer) {
				return;
			}
			
			for (var n:int = stageLayer.numChildren-1; 0<=n; n--){
				if (stageLayer.getChildAt(n) is Sprite){	

					var fileMapObj:Sprite = Sprite(stageLayer.getChildAt(n));

					if (fileMapObj is Sprite){	
						var fCol:int = Math.floor(fileMapObj.x/780);
						var fRow:int = Math.floor(fileMapObj.y/505);
						var fx:int = fileMapObj.x - (fCol*780); // x position in relation to the room
						var fy:int = fileMapObj.y - (fRow*505); // y position in relation to the room					
									
						var r:MapRoom = _mapRoomManager.getRoomAtLayoutPos(fCol, fRow);
						if (r) {							
							var mc:Sprite = fileMapObj;
	
							var lx:int = (r.layoutPos.x*780) + fx;
							var ly:int = (r.layoutPos.y*505) + fy;
							
							// test bounderies 
							var bounds:Rectangle = fileMapObj.getBounds(fileMapObj.parent);				
														
							mc.x = lx;
							mc.y = ly;
							//trace("NEW MAP OBJECT :", mc.name)
							var mObj:MapObject = new MapObject(this, mc);					
							r.addMapObject(mObj);					
										
							//-- test Top Left					
							var bCol:int = Math.floor(( bounds.left)/780);
							var bRow:int = Math.floor(( bounds.top)/505);
							var adjacent:MapRoom = _mapRoomManager.getRoomAtLayoutPos(bCol, bRow);
																									
							if (adjacent) {								
								adjacent.addMapObject(mObj);
							}						
													
							//-- test Top Right				
							bCol = Math.floor(( bounds.right)/780);
							bRow = Math.floor(( bounds.top)/505);
							adjacent = _mapRoomManager.getRoomAtLayoutPos(bCol, bRow);							
							if (adjacent) {
								adjacent.addMapObject(mObj);
							}						
							
							//-- test Bottom Left			
							bCol = Math.floor(( bounds.left)/780);
							bRow = Math.floor(( bounds.bottom)/505);
							adjacent = _mapRoomManager.getRoomAtLayoutPos(bCol, bRow);
							if (adjacent) {
								adjacent.addMapObject(mObj);
							}						
							
							//-- test Bottom Right			
							bCol = Math.floor(( bounds.right)/780);
							bRow = Math.floor(( bounds.bottom)/505);
							adjacent = _mapRoomManager.getRoomAtLayoutPos(bCol, bRow);
							if (adjacent) {
								adjacent.addMapObject(mObj);
							}						
						}
					}
				}
			}
		}
		private function initSounds(soundLayer:Sprite):void{
			
			GlobalEvent.eventDispatcher.dispatchEvent(new ProgressEvent(GlobalEvent.MAP_INIT_PROGRESS,false,false,90,100));
			
			for (var msId:int = 0; msId < soundLayer.numChildren; msId++){
				
				var ms:Object = soundLayer.getChildAt(msId);				
				if (ms == "[object MapSound]"){
					
					
					// -----------
					////  this as not been testes with custom layout may or may not work
					// -----------
					
					var fCol:int = Math.floor(ms.x/780);
					var fRow:int = Math.floor(ms.y/505);
					var fx:int = ms.x - (fCol*780); // x position in relation to the room
					var fy:int = ms.y - (fRow*505); // y position in relation to the room
					
					var r:MapRoom = _mapRoomManager.getRoomAtLayoutPos(fCol, fRow);
					if (r) {
						var lx:int = (r.layoutPos.x*780) + fx;
						var ly:int = (r.layoutPos.y*505) + fy;
						
						_soundManager.addMapSound(ms, new Point(lx, ly), r.serverRoomId, getCurrentRoomId()); 
					}
				}	
			}
			
			if(!_firstMapLoad){
				GlobalEvent.eventDispatcher.dispatchEvent(new ProgressEvent(GlobalEvent.MAP_INIT_PROGRESS,false,false,100,100));
			}
			_firstMapLoad = false;	
		}
		
		//we need a few tests to see if it's the firstMapLoad scattered throughout the code.  The loading sequence is slightly different
		//for the first map loaded than subsequent map loads.  This is temporary and will go away soon.
		private var _firstMapLoad:Boolean = true;
		
		private function getSize():Point{
			return _mapRoomManager.getSize();
		}
				
		//-----  Room building
		private function buildRoom(roomId:String):void{
			
			var mapRoom:MapRoom = getRoomById(roomId);
			
						
			if ( mapRoom != null){
				
				mapRoom.getCollisionData();
				//--- Load adjacent room Data
				var roomInfoData:RoomInfoData = mapRoom.roomInfo;
				
				var northRoom:MapRoom = getRoomById(roomInfoData.exit_north);
				if (northRoom){
					northRoom.getCollisionData();
				}
				
				var southRoom:MapRoom = getRoomById(roomInfoData.exit_south);
				if (southRoom){
					southRoom.getCollisionData();
				}

				var eastRoom:MapRoom = getRoomById(roomInfoData.exit_east);
				if (eastRoom){
					eastRoom.getCollisionData();
				}
				
				var westRoom:MapRoom  = getRoomById(roomInfoData.exit_west);
				if (westRoom){
					westRoom.getCollisionData();
				}
				 
				// addBackGropund
				var back:MovieClip = mapRoom.getBack();
				if ( back != null && !this.mcBackLayer.contains(back)){
					//trace("Add Background ",back);
					this.mcBackLayer.addChild(back);
					var currentRoom:MapRoom = getCurrentMapRoom();
					if (currentRoom != null){
						back.gotoAndPlay(currentRoom.getBack().currentFrame);
					}
				}				

				// add all new MapObject
				for (var i:int = 0; i < mapRoom.mapObjs.length; i++){
					var mapObj:MapObject = mapRoom.mapObjs[i];

					mapObj.display();

					if (!mapObj.isCustomLight){
						mapObj.setLight(_theTintManager.isLightsOn());
					}
					
					var mc:SpritePositionBubbler = mapObj.getStageMc();
					//trace("MMMMMM", mc, mc.name)
					var shadow:Sprite = mapObj.getShadow();					
					var groundLight:Sprite = mapObj.getGroundLight();
					var hotStop:Sprite = mapObj.getHotSpot();
					//if(shadow && mc) trace("mc: ", mc.x, mc.y, "shadow: ", shadow.x, shadow.y);
					//--- add asset
					this._stageLayerManager.addChild(mc);
					
					//-- add shadow
					_theTintManager.addShadow(shadow);
					
					//-- add ground light
					_theTintManager.addGroundLight(groundLight);
					
					//-- add hotSpot
					if (hotStop != null && !this.mcHotSpotLayer.contains(hotStop)){
						this.mcHotSpotLayer.addChild(hotStop);
					}					
					//-- add Btn
					if (mapObj.btnLink != null && !this.mcBtnLayer.contains(mapObj.btnLink)){
						//trace("=======================", mapObj.btnLink.x, mapObj.btnLink.y);
						this.mcBtnLayer.addChild(mapObj.btnLink);
					}														
				}
				mapRoom.inScope = true;
				_theTintManager.updateTints(roomId);
			}
			
		}				

		private var _cachedRoomArray:Array = [];
		private function clearOldRoom(oldRoomId:String, newRoomId:String):void{
			if(oldRoomId == newRoomId){
				return;
			}
			
			var oldRoom:MapRoom = getRoomById(oldRoomId);
			if (oldRoom != null)
			{
				oldRoom.removeAllObjectSilhouettes();
				
				// Clear Old Back
				var back:Sprite = oldRoom.getBack();
				if (back != null && this.mcBackLayer.contains(back)){					
					this.mcBackLayer.removeChild(back);	
				}
				
				//get list of mapObj form old room that are not in the new room
				_cachedRoomArray.length = 0;
				var objs:Array = _cachedRoomArray;
				var newRoom:MapRoom = getRoomById(newRoomId);
				if (newRoom)
				{
					for (var i:int = 0; i < oldRoom.mapObjs.length; i++){
						
						if ( !newRoom.containMapObj(oldRoom.mapObjs[i]) ){
							objs.push(oldRoom.mapObjs[i]);
						}
					}
				}
				else
				{
					objs = oldRoom.mapObjs;
				}
				
				for (var ii:int = 0; ii < objs.length; ii ++){
					var mapObj:MapObject = objs[ii];					
					
					//--- Remove asset
					var mc:Sprite = mapObj.getStageMc();
					this._stageLayerManager.removeChild(mc);
					mc = null;
					
					//-- Remove shadow
					_theTintManager.removeShadow(mapObj.getShadow());
					
					
					//-- Remove ground light
					_theTintManager.removeGroundLight(mapObj.getGroundLight());
					
					
					//-- Remove hotSpot
					var hotSpot:Sprite = mapObj.getHotSpot();
					if (hotSpot != null && this.mcHotSpotLayer.contains(hotSpot)){
						this.mcHotSpotLayer.removeChild(hotSpot);
						hotSpot = null;
					}
					
					//-- Remove hotSpot
					if (mapObj.btnLink != null && this.mcBtnLayer.contains(mapObj.btnLink)){
						this.mcBtnLayer.removeChild(mapObj.btnLink);					
					}
					
					mapObj.hide();
				}
				oldRoom.inScope = false;
			}
					
		}

		// mouse events ------------
		private function onMouseDown(evt:MouseEvent):void{
			if (this.mapLoaded){				
				GlobalEvent.eventDispatcher.dispatchEvent(new MouseEvent(GlobalEvent.MAP_MOUSE_DOWN, true, false, evt.localX, evt.localY));
			}
		}
		private function onMouseUp(evt:MouseEvent):void{
			if (this.mapLoaded){
				var point:Point = getMapRoomMouseXY();
				if (point)
				{
					GlobalEvent.eventDispatcher.dispatchEvent(new MouseEvent(GlobalEvent.MAP_MOUSE_UP, true, false, point.x, point.y));
				}
			}
		}
		
		private function getMapRoomMouseXY():Point
		{
			var mr:MapRoom = getCurrentMapRoom();
			if (mr)
			{
				var offset:Point = mr.getRoomOffset();
				var scale:Number = mr.scale/100
				var x:Number = (this.mouseX - offset.x) / scale;
				var y:Number = (this.mouseY - offset.y) / scale;
				return new Point(x, y);
			}
			return null;
		}

		private static function dispatchMouseOverStateChange(arg:Object):void
		{
			GlobalEvent.eventDispatcher.dispatchEvent(new GlobalEvent(GlobalEvent.MOUSE_OVER_STATE_CHANGED, arg));
		}
		private var _wasWordBubble:Boolean = false;
		private function onMouseMove(evt:MouseEventProxy):void
		{
			const target:DisplayObject = DisplayObject(evt.original.target);
			
			const isWordBubble:Boolean = this.wbContainer.contains(target) || this._talkIconManager.contains(target);
			if (this._wasWordBubble != isWordBubble)
			{
				this._wasWordBubble = isWordBubble;
				dispatchMouseOverStateChange({isWordBubble:isWordBubble});
			}																			
																			
			// Collision
			const ct:uint = this.getColliionTypeAt(this.mouseX, this.mouseY);				
			if ((ct & CollisionMap.TYPE_WALL) != 0){
				dispatchMouseOverStateChange({isMapCollision:true, isPortal:false});
			}else if ((ct & CollisionMap.TRIGGER_BITMASK) != 0){
				dispatchMouseOverStateChange({isMapCollision:false, isPortal:true, portalType:"portal"});
			}else{
				dispatchMouseOverStateChange({isMapCollision:false});

				// Slide Exit
				var m:MapRoom = getCurrentMapRoom();
				var scale:Number = m.scale
				var offset:Point = m.getRoomOffset();
				var mx:Number = Math.round( (this.mouseX - offset.x) * (100/scale) );
				var my:Number = Math.round( (this.mouseY - offset.y) * (100/scale) );
				var rw:Number = Math.ceil(780*(100/scale));
				var rh:Number = Math.ceil(505*(100/scale));
				var exits:Object = m.getExits();
				//trace(this.getEdgeSize(), (this.mouseX - offset.x), mx, "    ", (this.mouseY - offset.y), my );
				var edgeOpen:Boolean = false;
				
				var roomInfoData:RoomInfoData = m.roomInfo;
				if (mx < this.getEdgeSize() && exits.west 
						&& CollisionMap.TYPE_WALL != this.getColliionTypeAt(offset.x + 1, this.mouseY)){
					///----- WEST Edge.. (check east edge next room)
					var westRoom:MapRoom = getRoomById(roomInfoData.exit_west);					
					if (westRoom != null){
						edgeOpen = westRoom.testEastEdgeOpen(this.mouseY);
					}
					if (edgeOpen){
						dispatchMouseOverStateChange({isPortal:true, portalType:"west"});																									
					}
										
				}else if (mx > (rw-this.getEdgeSize()) && exits.east					
						&& CollisionMap.TYPE_WALL != this.getColliionTypeAt(offset.x + 779, this.mouseY)){
					///----- EAST Edge.. (check west edge next room)
					var eastRoom:MapRoom = getRoomById(roomInfoData.exit_east);						
					if (eastRoom != null){
						edgeOpen = eastRoom.testWestEdgeOpen(this.mouseY);
					}		
					if (edgeOpen){
						dispatchMouseOverStateChange({isPortal:true, portalType:"east"});																														
					}			
					
				}else if (my < this.getEdgeSize() && exits.north 
						&& CollisionMap.TYPE_WALL != this.getColliionTypeAt(this.mouseX, offset.y + 1)){
					///----- NORTH Edge.. (check south edge next room)
					var northRoom:MapRoom = getRoomById(roomInfoData.exit_north);					
					if (northRoom != null){
						edgeOpen = northRoom.testSouthEdgeOpen(this.mouseX);
					}
					if (edgeOpen){
						dispatchMouseOverStateChange({isPortal:true, portalType:"north"});																														
					}
										
				}else if  (my > (rh-this.getEdgeSize()) && exits.south
						&& CollisionMap.TYPE_WALL != this.getColliionTypeAt(this.mouseX, offset.y + 504)){
					///----- SOUTH Edge.. (check north edge next room)
					var southRoom:MapRoom = getRoomById(roomInfoData.exit_south);					
					if (southRoom != null){
						edgeOpen = southRoom.testNorthEdgeOpen(this.mouseX);
					}
					if (edgeOpen){
						dispatchMouseOverStateChange({isPortal:true, portalType:"south"});																														
					}
				}
				if (!edgeOpen){
					dispatchMouseOverStateChange({isPortal:false, portalType:"na"});																														
				}
			}
			if(GlobalEvent.eventDispatcher.hasEventListener(GlobalEvent.MAP_MOUSE_MOVE)){
				var point:Point = getMapRoomMouseXY();
				if (point)
				{
					GlobalEvent.eventDispatcher.dispatchEvent(new MouseEvent(GlobalEvent.MAP_MOUSE_MOVE, true, false, point.x, point.y));
				}
			}
		}
		
		private function getEdgeSize():Number{
			var scale:Number = getCurrentMapRoom().scale
			var serverEdge:int = Math.floor(20 * 100/scale);
			return serverEdge;
			
		}		

		public function isLightsOn():Boolean{
			return _theTintManager.isLightsOn();
		}

		private function setRoom(event:GlobalEvent):void{
			
			var newRoomId:String = event.data.roomId;
						
			var newRoom:MapRoom = getRoomById(newRoomId);
			//newRoom.getCollisionData();
				
			this.buildRoom(getCurrentRoomId());	
		}
		
		private function onMapSlideStart(event:GlobalEvent):void{
			var room:MapRoom = getRoomById(event.data.roomId);
			if(!room){
				throw new Error("We don't have a room for the given room id: " + event.data.roomId);
			}
			
			this.buildRoom(event.data.roomId);
		}
		
		public function addMask(m:DisplayObject):void{	
		  if(this._mainContainer && m.parent != this._mainContainer){		
				this._mainContainer.addChild(m);
				this._mainContainer.mask = m;						
			}
			this._isMapVisible = false;
		}
		
		public function removeMask(m:DisplayObject):void{
			if(this._mainContainer && m.parent == this._mainContainer){	
				this._mainContainer.removeChild(m);						
			}
			this._mainContainer.mask = null;	
			this._isMapVisible = true;
		}	
				
		// Actors -----------------------
		public function addActor(displayObject:SpritePositionBubbler):void{			
			this._theTintManager.updateObject(displayObject);
			this._stageLayerManager.addChild(displayObject);			
		}
		
		public function removeActor(displayObject:SpritePositionBubbler):void {
			_talkIconManager.removeDialog(displayObject);
			this._stageLayerManager.removeChild(displayObject);
		}
		public function getActorPos(serverPoint:Point):Point{
			
			var mr:MapRoom = getCurrentMapRoom();
			var of:Point = new Point(mr.layoutPos.x*780, mr.layoutPos.y * 505);
			var scale:Number = (mr.scale/100);
									
			var np:Point = new Point( (serverPoint.x * scale) + of.x , (serverPoint.y * scale) + of.y );			
			return np;	
		}
		
		
		//---- Collision ---------------------
		
		public function setCollisionShowing(b:Boolean):void {
			this._collisionDebugLayer.visible = b;
		}
		public function isCollisionShowing():Boolean {
			return this._collisionDebugLayer.visible;
		}
		public function drawCollisionMap():void{
			this.clearCollision();
			getCurrentMapRoom().DrawCollisionMap(this._collisionDebugLayer);
		}
		private function clearCollision():void{
			while(this._collisionDebugLayer.numChildren > 0){
				this._collisionDebugLayer.removeChildAt(0);
			}
			this._collisionDebugLayer.graphics.clear();
		}
				
		//----
		public function getColliionTypeAt(x:Number,y:Number):uint {
			var currentRoom:MapRoom = getCurrentMapRoom();
			if (currentRoom) {
				return currentRoom.getCollisionTypeAt(x,y);			
			}
			return CollisionMap.TYPE_WALL;
		}
		
		//-------------------------		
		private function unloadZone():void{
			_projectileManager.clearProjectiles();
			
			_lootParticleManager.removeAllLootParticle();
			
			DisplayObjectUtils.ClearAllChildrens(this.mcBackLayer);
			
			DisplayObjectUtils.ClearAllChildrens(this._mcGroundEffect);
			//DisplayObjectUtils.ClearAllChildrens(this._mcStageLayer);
			DisplayObjectUtils.ClearAllChildrens(this.mcHotSpotLayer);
			DisplayObjectUtils.ClearAllChildrens(this.mcBtnLayer);
			DisplayObjectUtils.ClearAllChildrens(this.wbContainer);
			DisplayObjectUtils.ClearAllChildrens(this._emoteLayer);
			
		}
				
				
		//***************	
		// getter setters		
		public function isMapLoaded():Boolean{
			return this.mapLoaded;
		}
				
		public function getCurrentRoomId():String{
			return _mapRoomManager.getCurrentRoomId();
		}
		
		public function getCurrentMapRoom():MapRoom{
			return _mapRoomManager.getCurrentMapRoom();
		}
		
		public function setBackParam(obj:Object):void{
			_mapRoomManager.setBackParamForAllRooms(obj);
		}
		
		public function isNullChamber():Boolean{
			return MapFilesFactory.getInstance().mapFiles.isNullchamber(this.zone);
		} 
		
	
		
		public function getEmoteLayer():Sprite{
			return _emoteLayer;
		}
		
		public function getMapDisplayObject():DisplayObjectContainer
		{
			return this;
		}
	}
}
	import flash.display.DisplayObjectContainer;
	import flash.display.DisplayObject;
	import com.gaiaonline.utils.DisplayObjectUtils;
	import com.gaiaonline.utils.FrameTimer;
	import flash.display.MovieClip;
	import com.gaiaonline.battle.emotes.TalkIcon;
	import com.gaiaonline.display.wordbubble.BubbleEvent;
	import com.gaiaonline.display.wordbubble.WordBubbleManager;
	import flash.display.Sprite;
	import com.gaiaonline.battle.Loot.LootParticle;
	import flash.events.Event;
	import com.gaiaonline.battle.map.IMapRoomManager;
	import com.gaiaonline.battle.map.MapObject;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import com.gaiaonline.battle.map.MapRoom;
	import flash.display.BitmapData;
	import com.gaiaonline.battle.map.TintUpdate;
	import com.gaiaonline.battle.map.MapIt;
	import com.gaiaonline.utils.VisManagerSingleParent;
	import flash.geom.Rectangle;
	import flash.events.ProgressEvent;
	import com.gaiaonline.battle.map.RoomInfoData;
	import com.gaiaonline.platform.gateway.ICollisionConnector;
	import com.gaiaonline.battle.map.TintManager;
	import com.gaiaonline.utils.SpritePositionChangeEvent;
	import flash.utils.Dictionary;
	import com.gaiaonline.platform.actors.ITintable;
	import com.gaiaonline.platform.actors.ISubmersible;
	import com.gaiaonline.utils.SpritePositionBubbler;
	import com.gaiaonline.battle.newrings.IProjectile;
	import com.gaiaonline.battle.map.IEnvironmentChangeHandler;
	import com.gaiaonline.battle.map.IEnvironmentChanger;
	import com.gaiaonline.battle.newactors.ActorManager;
	import com.gaiaonline.battle.newactors.ActorMoveEvent;
	import com.gaiaonline.battle.utils.BattleUtils;
	import com.gaiaonline.battle.newactors.ActorDisplay;
	import flash.events.MouseEvent;
	import com.gaiaonline.platform.actors.ICarriable;
	import com.gaiaonline.platform.actors.ICarrier;
	import com.gaiaonline.flexModulesAPIs.globalevent.GlobalEvent;
	

internal class ZManager{
	
	private const SORT_ORDER:Array = ["y","x"];
	private const SORT_PARAMS:Array = [Array.NUMERIC, Array.NUMERIC];
			
	private var _frameTimer:FrameTimer = null;
	private var _zArrayIsValid:Boolean = false;
	private var _mcStageLayer:DisplayObjectContainer = null;
	
	public function ZManager(stageLayer:DisplayObjectContainer){
		_mcStageLayer = stageLayer
		_frameTimer = new FrameTimer(validateZOrder);
		_frameTimer.startPerFrame();
	}
	
	public function invalidateZOrder():void{
		_zArrayIsValid = false;	
	}		

	private var _cachedZArray:Array = [];	
	private function validateZOrder():void{
		if (!_zArrayIsValid){
			
			var zArray:Array = _cachedZArray;
			
			var childCount:uint = this._mcStageLayer.numChildren;	
			for (var i:int = 0; i < childCount; ++i){										
				zArray.push(this._mcStageLayer.getChildAt(i));		
			}
			
			zArray.sortOn(SORT_ORDER, SORT_PARAMS);	
			
			//is there a chance that when we swap children that we invalidate the previous swap?
			//ie, if we run this loop again, we should come up with the identical results.  Do we?
			
			for (var z:int =0; z < childCount; ++z){
				var mc:DisplayObject = zArray[z];							
				if (z != this._mcStageLayer.getChildIndex(mc)){						
					this._mcStageLayer.setChildIndex(mc, z);
				}
			}	
						
			fixZOrderForPickedUpActors(zArray, childCount);
			
			_zArrayIsValid = true;
			_cachedZArray.length = 0;
		}
	}
	
	private function fixZOrderForPickedUpActors(zArray:Array, len:uint):void {
		for (var z:int = 0; z < len; z++){
			
			var pickedUp:ICarriable = zArray[z] as ICarriable;
			
			if(pickedUp){
				
				var pickedUpBy:ICarrier = pickedUp.getPickedUpBy()
				
				if(pickedUpBy){
					var pickedUpByDispObj:DisplayObject = pickedUpBy as DisplayObject;
				
					if(pickedUpByDispObj && pickedUpByDispObj.parent == _mcStageLayer){
						
						if(pickedUpBy.shouldBeInFront()){
							this._mcStageLayer.addChildAt(pickedUp as DisplayObject, this._mcStageLayer.getChildIndex(pickedUpByDispObj));	
						}
						else{
							this._mcStageLayer.addChildAt(pickedUp as DisplayObject, this._mcStageLayer.getChildIndex(pickedUpByDispObj) - 1);
						}
					}
				}
				
			}
		}
	}
}

internal class ProjectileManager{
	
	private var _stageLayerManager:StageLayerManager = null;
	
	private var projectiles:Array = new Array();
	
	public function ProjectileManager(stageLayerManager:StageLayerManager){
		_stageLayerManager = stageLayerManager;
		
		DisplayObjectUtils.addWeakListener(GlobalEvent.eventDispatcher, GlobalEvent.MAP_ADD_PROJECTILE, addProjectile);
		DisplayObjectUtils.addWeakListener(GlobalEvent.eventDispatcher, GlobalEvent.MAP_REMOVE_PROJECTILE, removeProjectile);
		DisplayObjectUtils.addWeakListener(GlobalEvent.eventDispatcher, GlobalEvent.MAP_CLEAR_PROJECTILES, clearProjectiles);
		
	}
	
	//**** Projectiles ----------------
		private function addProjectile(event:GlobalEvent):void{
			var projectile:SpritePositionBubbler = event.data.projectile;
			
			if( !(projectile is IProjectile) ){
				throw new Error("Projectile isn't of type IProjectile!");
			}
			
			this._stageLayerManager.addChild(projectile);
			this.projectiles.push(projectile);
		}
		public function clearProjectiles(ignoredEvent:GlobalEvent=null):void{
			for each(var projectile:IProjectile in projectiles){
				this._stageLayerManager.removeChild(projectile as DisplayObject);
				projectile.dispose();
			}
			this.projectiles.length = 0;
		}	
		private function removeProjectile(event:GlobalEvent):void {
			var projectile:IProjectile = event.data.projectile as IProjectile
			var index:int = this.projectiles.indexOf(projectile);
			if (index >0){				
				this.projectiles.splice(index,1)
			}
			projectile.dispose();
		}
	
	
}

internal class DialogManager{
	

	private var wbManager:WordBubbleManager = null;
	
	
	private var _wbContainer:Sprite = null;
	
	public function DialogManager(wbContainer:Sprite){
		_wbContainer = wbContainer;
		wbManager = new WordBubbleManager(_wbContainer);
		
		DisplayObjectUtils.addWeakListener(GlobalEvent.eventDispatcher, GlobalEvent.MAP_ADD_TEXT, addText);
		DisplayObjectUtils.addWeakListener(GlobalEvent.eventDispatcher, GlobalEvent.MAP_REMOVE_TEXT, removeText);
		DisplayObjectUtils.addWeakListener(GlobalEvent.eventDispatcher, GlobalEvent.MAP_ROOM_LEAVE, onMapRoomLeave);
	}

	private function onMapRoomLeave(event:GlobalEvent):void{
		wbManager.clear();
	}

	public function setBounds(mcBounds:Sprite):void{
		wbManager.setBounds(mcBounds);
	}

	private function addText(event:GlobalEvent):void
	{
		var data:Object = event.data;
		
		var actor:Sprite = data.actor;
		var actorBounds:Sprite = data.actorBounds;
		var actorName:String = data.actorName;
		var message:String = data.message;
		var channel:String = data.channel || "";
		
		this.wbManager.addText(actorName, message, actor, actorBounds, channel);			
	}
	
	private function removeText(evt:GlobalEvent):void{
		trace("[Map removeText] remove Text Bubble")
		this.wbManager.removeText(evt.data.actor);
	}
}


internal class LootParticleManager{
	
	private var lootParticles:Array = new Array();
	private var _stageLayerManager:StageLayerManager = null;
	
	public function LootParticleManager(stageLayerManager:StageLayerManager){
		_stageLayerManager = stageLayerManager;
		DisplayObjectUtils.addWeakListener(GlobalEvent.eventDispatcher, GlobalEvent.LOOT_PARTICLE_ANIM_DONE, onParticleDone);
		DisplayObjectUtils.addWeakListener(GlobalEvent.eventDispatcher, GlobalEvent.MAP_ADD_LOOT_PARTICLES, addLootParticles);
	}

	private function addLootParticles(event:GlobalEvent):void {
		var particles:Array = event.data.particles;
		for (var i:int = 0; i < particles.length; i++){					
			_stageLayerManager.addChild(LootParticle(particles[i]));
			this.lootParticles.push(particles[i]);
		}			
	}
	private function onParticleDone(evt:GlobalEvent):void{
		this.removeLootParticle(LootParticle(evt.data.particle));
	}
	private function removeLootParticle(particle:LootParticle):void{
//		if (this._stageLayerManager.contains(particle)){	
			this._stageLayerManager.removeChild(particle);				
//		}
		var index:int = this.lootParticles.indexOf(particle);
		this.lootParticles.splice(index, 1);
		GlobalEvent.eventDispatcher.dispatchEvent(new GlobalEvent(GlobalEvent.LOOT_PARTICLE_FINISHED, {particle:particle}));
	}
	public function removeAllLootParticle():void{
		for (var i:int = 0; i < this.lootParticles.length; i++){
			DisplayObjectUtils.ClearAllChildrens(this.lootParticles[i]);			
			this._stageLayerManager.removeChild(LootParticle(this.lootParticles[i]));
		}
		this.lootParticles.length = 0;			
	}
}

internal class WaterDepthManager implements IEnvironmentChanger{
	
	public static var CURRENT_WATER_SCALE:Number = 1;
	private static const DEFAULT_WATER_SCALE:Number = .1;
	private static const WATER_RETRY_SCALE:Number = .9; //must be less than 1!
	private static const WATER_RETRYS:uint = 10;
	
	private var _mapRoomManager:IMapRoomManager
	
	public function WaterDepthManager(mapRoomManager:IMapRoomManager){
		_mapRoomManager = mapRoomManager
	}
	
	public function registerForEnvironmentChanges(handler:IEnvironmentChangeHandler):void{
		//current we don't dynamically change the water depth while we play.  If we wanted to handle this, then it's easy.
		//We have to store the handlers here, and update them when the water depth changes.
	}
	
	public function updateObject(invalidObj:Object):void{
		var submersible:ISubmersible = invalidObj as ISubmersible;
		if(submersible && submersible.depthEnabled){
			submersible.setWaterDepth(getDepthAtPoint(submersible.x, submersible.y));
		}
	}
	
	
		/**
	 * The waterlayer determines how deep different parts of the water are.  Black values are very deep, and white values
	 * are land.  Gray is somewhere in between.
	 * 
	 * This function takes the waterlayer, scales it to CURRENT_WATER_SCALE, and takes a bitmap snapshot of it.
	 * All MapRooms refer to the same bitmapdata
	 * */
	
	private var bmdWater:BitmapData = null;
	
	public function initWater(waterLayer:Sprite):void{
		if (waterLayer != null){
			waterLayer.x = waterLayer.y = 0;
		}
		bmdWater = createWaterBitmap(waterLayer, DEFAULT_WATER_SCALE);
		DisplayObjectUtils.ClearAllChildrens(waterLayer);

	}
	
	private function createWaterBitmap(waterLayer:Sprite, scale:Number):BitmapData{
		if(!waterLayer){
			
			if(bmdWater){
				this.bmdWater.dispose();
				this.bmdWater = null;
			}
			return null;
		}
		waterLayer.width *= scale;
		waterLayer.height *= scale;
		
		waterLayer.x *= scale;
		waterLayer.y *= scale;
		
		CURRENT_WATER_SCALE = scale;
		
		var waterLayerBounds:Rectangle = waterLayer.getBounds(waterLayer.parent);
		var bitmapData:BitmapData = null;
		
		if(WATER_RETRY_SCALE >=1){
			throw new Error("WaterRetryScale must be less than 1!");
		}
		
		try{
			bitmapData = new BitmapData(waterLayerBounds.left + waterLayerBounds.width, 
										waterLayerBounds.top + waterLayerBounds.height, 
										false, 0xFFFFFFFF);
		}
		//if our bitmapData is too big, we'll retry with smaller dimensions
		catch(error:ArgumentError){
			if(scale < (Math.pow(WATER_RETRY_SCALE, WATER_RETRYS-1) * DEFAULT_WATER_SCALE)){
				return new BitmapData(1, 1, false, 0xFFFFFFFF);
			}
			var s:Number = scale;
			var test:Number = (Math.pow(WATER_RETRY_SCALE, WATER_RETRYS) * DEFAULT_WATER_SCALE);
			return createWaterBitmap(waterLayer, scale * WATER_RETRY_SCALE);
		}
		
		bitmapData.draw(waterLayer, waterLayer.transform.matrix); 
		return bitmapData;
	}
	
	private function getDepthAtPoint(x:Number, y:Number):Number{
		


		var d:Number = 0;
		var p:int = 0;			
		var room:MapRoom = _mapRoomManager.getCurrentMapRoom();
		
		if (room != null && this.bmdWater != null){			
			
			x *= CURRENT_WATER_SCALE;
			y *= CURRENT_WATER_SCALE;
			
			//-- [fred] i changed <= to <  last pixel of the bitmap is invalide (back line is sometime added)
			if(x < bmdWater.width && y < bmdWater.height){
				p = this.bmdWater.getPixel(x,y);
				var b:int = p & 0xFF;				
				d = (255- b)/255;
			}						
		}
		
		return d;
	}	
}

internal class StageLayerManager implements IEnvironmentChangeHandler{
	
	private var _stageLayer:DisplayObjectContainer = null;
	private var _invalidActorTimer:FrameTimer = new FrameTimer(onInvalidTimer);
	private var _zOrderManager:ZManager = null;
	
//		there are occasions where an environmentChanger needs to invalidate something even though it has been
//		removed or GCed.  ie silhouetting.  It'll be cleared soon anyways, so the dictionary uses strong keys.
	private var _invalidInhabitants:Dictionary = new Dictionary(false);
	
	private var _environmentChangersForSome:Array = [];
	private var _environmentChangersForAll:Array = [];
	
	public function StageLayerManager(...environmentChangers){
		
		for each(var obj:Object in environmentChangers){
			var enviroChanger:IEnvironmentChanger = obj as IEnvironmentChanger;
			if(enviroChanger){
				_environmentChangersForSome.push(enviroChanger);
				enviroChanger.registerForEnvironmentChanges(this);
			}
			else{
				throw new Error("Invalid Environment Changer.  All EnvironmentChangers must implement IEnvironmentChanger");
			}
		}
		
		_stageLayer = new Sprite();
		_zOrderManager = new ZManager(_stageLayer)
		
		_stageLayer.addEventListener(SpritePositionChangeEvent.POSITION_CHANGE, onChildPositionChange, false, 0, true);
		_stageLayer.addEventListener(SpritePositionChangeEvent.INVALIDATE_PROPERTIES, onInvalidateProperties, false, 0, true);
		_invalidActorTimer.startPerFrame();
		
	}
	
	public function onEnvironmentChange(changer:IEnvironmentChanger):void{
		var index:uint = _environmentChangersForSome.indexOf(changer);
		if(index > -1){
			_environmentChangersForSome.splice(index, 1);
		}
		
		var allIndex:uint = _environmentChangersForAll.indexOf(changer);
		if(allIndex > -1){
			_environmentChangersForAll.push(changer);
		}
	}
	
	public function getStageLayer():DisplayObject{
		return _stageLayer
	}
	
	public function addChild(displayObject:SpritePositionBubbler):DisplayObject{
		if(displayObject){
			
			if( !(displayObject is SpritePositionBubbler)){
				throw new Error("Consider using SpritePositionBubbler.  Talk to newtang");
			}
			
			if( !(displayObject is ITintable)){
				//throw new Error ("Not tintable?!");
			}
			
			
			invalidate(displayObject);
			return _stageLayer.addChild(displayObject);
		}
		return null;
	}
	
	public function removeChild(displayObject:DisplayObject):DisplayObject{
//		there are occasions where an environmentChanger needs to invalidate something even though it has been
//		removed.  ie silhouetting
//
//
//		if(_invalidInhabitants[displayObject]){
//			delete _invalidInhabitants[displayObject]
//		}
		
		if(displayObject.parent == _stageLayer){
			return _stageLayer.removeChild(displayObject);
		}
		
		return null;
	}
	
	private function onChildPositionChange(event:SpritePositionChangeEvent):void{
		event.stopPropagation();
		invalidate(event.spritePositionInvalidator);
	}
	
	private function onInvalidateProperties(event:SpritePositionChangeEvent):void{
		event.stopPropagation();
		_invalidInhabitants[event.spritePositionInvalidator] = true;
	}
	
	private function invalidate(dispObj:DisplayObject):void{
		_invalidInhabitants[dispObj] = true;
		_zOrderManager.invalidateZOrder();
	}
	

	private function onInvalidTimer():void{
		
		for(var inhabitant:Object in _invalidInhabitants){
			for each(var enviroChanger:IEnvironmentChanger in _environmentChangersForSome){
				enviroChanger.updateObject(inhabitant);
			}
		}
		
		BattleUtils.cleanDictionary(_invalidInhabitants);
		
		
		if(_environmentChangersForAll.length > 0){
			var childCount:uint = _stageLayer.numChildren;
			
			var allEnviroChanger:IEnvironmentChanger;
			while(allEnviroChanger = _environmentChangersForAll[0]){
				for(var i:uint = 0; i<childCount; ++i){
					allEnviroChanger.updateObject(_stageLayer.getChildAt(i));
				}
				
				_environmentChangersForSome.push(_environmentChangersForAll.shift());
			}
		}
	}
}

final class MouseOverStateChange
{
	
}
