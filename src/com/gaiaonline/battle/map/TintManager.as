package com.gaiaonline.battle.map
{
	import com.gaiaonline.battle.GST;
	import com.gaiaonline.flexModulesAPIs.globalevent.GlobalEvent;
	import com.gaiaonline.platform.actors.ITintable;
	import com.gaiaonline.platform.map.ITintManager;
	import com.gaiaonline.utils.DisplayObjectUtils;
	import com.gaiaonline.utils.RegisterUtils;
	
	import flash.display.BlendMode;
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.geom.Point;
	
	public class TintManager implements ITintManager
	{
		// tint layer
		private var mcTintLayer:Sprite;
		private var mcTintGst:Sprite;
		private var mcTintRoom:Sprite;
		private var mcTintShadow:Sprite;
		private var mcTintGroundLight:Sprite;		
		
		private var _mapTintManager:MapTintManager = null;
		private var _mapGSTTintManager:MapGSTTintManager = null;
		
		private var _mapRoomManager:IMapRoomManager = null;
		
		public function TintManager(mapRoomManager:IMapRoomManager, gst:GST)
		{
			
			_mapRoomManager = mapRoomManager;
			
			// tint layer : gstTintt, roomTint, shadow, groundLight			
			this.mcTintLayer = new Sprite();
			this.mcTintLayer.blendMode = BlendMode.MULTIPLY;
			
			this.mcTintGst = new Sprite();
			
			this.mcTintRoom = new Sprite();
			this.mcTintRoom.alpha = 0;
			
			this.mcTintGroundLight = new Sprite();
						
			this.mcTintShadow = new Sprite();
			this.mcTintShadow.blendMode = BlendMode.DARKEN;
			//this.mcTintShadow.cacheAsBitmap = true;
			
			this.mcTintLayer.addChild(this.mcTintGst);
			this.mcTintLayer.addChild(this.mcTintRoom);
			this.mcTintLayer.addChild(this.mcTintShadow);
			this.mcTintLayer.addChild(this.mcTintGroundLight);
			
			
			
			
			_mapTintManager = new MapTintManager(mapRoomManager, mcTintLayer, mcTintShadow);
			_mapTintManager.addEventListener(MapTintManager.INHABITANTS_TINT_INVALID, onInhabitantsTintInvalid, false, 0, true);
			_mapGSTTintManager = new MapGSTTintManager(mcTintGst, mcTintRoom, _mapTintManager, mapRoomManager, gst);
			
			DisplayObjectUtils.addWeakListener(GlobalEvent.eventDispatcher, GlobalEvent.MAP_DONE, onMapDone);
			DisplayObjectUtils.addWeakListener(GlobalEvent.eventDispatcher, GlobalEvent.MAP_LOAD_ZONE, onLoadZone);
			DisplayObjectUtils.addWeakListener(GlobalEvent.eventDispatcher, GlobalEvent.MAP_SLIDE_COMPLETE, onMapSlideDone);
		}

		private var _environmentChangeHandlers:Array = [];
		public function registerForEnvironmentChanges(handler:IEnvironmentChangeHandler):void{
			RegisterUtils.register(_environmentChangeHandlers, handler);
		}

		private function onInhabitantsTintInvalid(event:Event):void{
			for each(var enviroChangeHandler:IEnvironmentChangeHandler in _environmentChangeHandlers){
				enviroChangeHandler.onEnvironmentChange(this);
			}
		}

		public function updateObject(invalidObj:Object):void{
			var tintable:ITintable = invalidObj as ITintable;
			if(tintable){
				tintObject(tintable);
			}
		}

		private function onMapDone(event:GlobalEvent):void{
			var newRoom:MapRoom = _mapRoomManager.getRoomById(event.data.roomId);

			var tint:Object = newRoom.getRoomTint();
			_mapGSTTintManager.setRoomTint(tint.r, tint.g, tint.b, tint.a);	
			this.mcTintLayer.visible = newRoom.tintBackground;
		}

		public function getTintLayer():Sprite{
			return mcTintLayer;
		}
		
		public function addShadow(shadow:DisplayObject):void{
			if (shadow != null && shadow.parent != this.mcTintShadow){
				shadow.cacheAsBitmap;						
				this.mcTintShadow.addChild(shadow);
			}
		}
		
		public function addGroundLight(groundLight:DisplayObject):void{
			if (groundLight != null && groundLight.parent != this.mcTintGroundLight){						
				this.mcTintGroundLight.addChild(groundLight);
			}
		}

		public function removeShadow(shadow:DisplayObject):void{
			if (shadow != null && shadow.parent == this.mcTintShadow){
				this.mcTintShadow.removeChild(shadow);
			}
		}
		
		public function removeGroundLight(groundLight:DisplayObject):void{
			if (groundLight != null && groundLight.parent == this.mcTintGroundLight){
				this.mcTintGroundLight.removeChild(groundLight);
			}
		}
			
		private function onLoadZone(event:GlobalEvent):void{
			//clear old zone
			_mapTintManager.clearTintData();
			
			DisplayObjectUtils.ClearAllChildrens(this.mcTintGst);
			DisplayObjectUtils.ClearAllChildrens(this.mcTintRoom);
			DisplayObjectUtils.ClearAllChildrens(this.mcTintShadow);
			DisplayObjectUtils.ClearAllChildrens(this.mcTintGroundLight);
		}
		
		private function onMapSlideDone(event:GlobalEvent):void{
			var currentRoom:MapRoom = _mapRoomManager.getCurrentMapRoom();
			var tint:Object = currentRoom.getRoomTint();
			_mapGSTTintManager.updateRoomTint(tint.r, tint.g, tint.b, tint.a);
			_mapTintManager.updateTints(currentRoom.serverRoomId);
			this.mcTintLayer.visible = currentRoom.tintBackground;	
		}
			
		
		public function updateTints(roomId:String):void{
			_mapTintManager.updateTints(roomId);
		}
		
		public function initTintLayers(sX:Number, sY:Number):void{
			this.mcTintGst.graphics.clear();
			this.mcTintGst.graphics.beginFill(0xFFFFFF, 1);
			this.mcTintGst.graphics.drawRect(-780, -505, sX + (780*2), sY + (505*2));
			this.mcTintGst.graphics.endFill();
			
			this.mcTintRoom.graphics.clear();
			this.mcTintRoom.graphics.beginFill(0xFFFFFF, 1);
			this.mcTintRoom.graphics.drawRect(-780, -505, sX + (780*2), sY + (505*2));
			this.mcTintRoom.graphics.endFill();
		}

		public function setCurrentGSTTint(update:Boolean=true):void{
			_mapGSTTintManager.setCurrentGSTTint(update);
		}
		
		public function setLights():void{
			_mapGSTTintManager.setLights();
		}
		
		public function isLightsOn():Boolean{
			return _mapGSTTintManager.isLightsOn();
		}
		
		private function tintObject(tintable:ITintable):void{
			var tintObj:Object;
			switch(tintable.getTintType()){
				case TintTypes.ALL:
					tintObj = _mapTintManager.getTintAtForAvatars(tintable.x, tintable.y);
					break;
				case TintTypes.NO_SHADOWS:
					tintObj = _mapTintManager.getTintAtForMapObjects(tintable.x, tintable.y);
					break;
				case TintTypes.NONE:
					return;
			}
			
			
			if(tintObj){
				tintable.setTint(tintObj.r, tintObj.g, tintObj.b);
			}	
		}
	}
}
	import flash.display.DisplayObjectContainer;
	import flash.events.Event;
	import com.gaiaonline.battle.GST;
	import com.gaiaonline.battle.map.IMapRoomManager;
	import flash.display.Sprite;
	import com.gaiaonline.battle.map.MapRoom;
	import com.gaiaonline.battle.newactors.BaseActor;
	import flash.display.BitmapData;
	import com.gaiaonline.battle.map.MapObject;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import com.gaiaonline.battle.map.TintUpdate;
	import com.gaiaonline.utils.DisplayObjectUtils;
	import flash.events.EventDispatcher;
	import com.gaiaonline.flexModulesAPIs.globalevent.GlobalEvent;
	

internal class MapTintManager extends EventDispatcher{
	
	public static const INHABITANTS_TINT_INVALID:String = "inhabitantsTintInvalid";
	private static const TINT_SCALE:Number = 0.1;
	
	private var _mapRoomManager:IMapRoomManager = null;
	
	private var bmdAvTint:BitmapData;
	private var bmdObjTint:BitmapData;	
	
	private var mcTintLayer:DisplayObjectContainer = null;
	private var mcTintShadow:DisplayObjectContainer = null;
	
	public function MapTintManager(mapRoomManager:IMapRoomManager, tintLayer:DisplayObjectContainer, shadowTintLayer:DisplayObjectContainer){
		_mapRoomManager = mapRoomManager;
		
		mcTintLayer = tintLayer;
		mcTintShadow = shadowTintLayer;
		
		DisplayObjectUtils.addWeakListener(GlobalEvent.eventDispatcher, GlobalEvent.MAP_UPDATE_TINTS, updateTintsEvent);
	}
	
	public function onTintUpdate(evt:Event):void{

		var currentRoomId:String = _mapRoomManager.getCurrentRoomId();
		if (currentRoomId){
			this.updateTints(currentRoomId);
		}
	}
	
	private function updateTintsEvent(event:GlobalEvent):void
	{
		updateTints(event.data.roomId);
	}
	
	public function getTintAtForMapObjects(x:Number, y:Number):Object{
		
		var layoutPos:Point = _mapRoomManager.getCurrentMapRoom().layoutPos;
		
		//KAI: this right?			
		x = x - ((layoutPos.x - 1) * 780);
		y = y - ((layoutPos.y - 1) * 505);
		
		
		if (this.bmdObjTint != null){
			var c:int = this.bmdObjTint.getPixel(x*TINT_SCALE,y*TINT_SCALE);				
			var r:int = c >> 16;
			var g:int = c >> 8 & 0xFF;
			var b:int = c & 0xFF;	
		}		
		
		var tint:Object = {r:r, g:g, b:b};
		
		if (!(tint.r == 0 && tint.g == 0 && tint.b == 0)) {
			return tint;
		}
		return null;
	}
	
	public function updateTints(roomId:String = null):void{
		if (roomId == null){
			roomId = _mapRoomManager.getCurrentRoomId();					
		}				
		this.buildTintData(roomId);
	}
	
	private function buildTintData(roomId:String):void{
		try
		{
			tryBuildTintData(roomId);
		}
		catch (error:ArgumentError)
		{
			// [bgh] because of the possible InvalidBitmapData error
			// this was causing the BSoD (black screen of death)
			trace(error);
		}
	}
	
	
	
	private function tryBuildTintData(roomId:String):void{
		// We're getting an InvalidBitmapData exception sometimes, and we think it's from a mcTintLayer that 
		// is not init'd yet. [Mark and Fred, crossing our fingers]
				
		var mRoom:MapRoom = _mapRoomManager.getRoomById(roomId);
		if (mRoom != null &&
			this.mcTintLayer != null && 
			this.mcTintLayer.width > 0 && 
			this.mcTintLayer.height > 0) {

			mRoom.setShadowForTint(true);
			mRoom.setGroundLightForTint(true);
			
			/**
			 * The reason we have two bitmaps:
			 * Basically, we don't want objects to be affected by their own shadows.  So, they look at a bitmapData (bmdObj) that doesn't 
			 * have any shadow information.  Avatars, need to be affected by shadows and lights so use bmdAv which has both
			 * [jtn] [bgh]
			 * */
			
			// 780 x 505 is the size of a room.
			if(this.bmdAvTint == null)
			{
				this.bmdAvTint = new BitmapData(780 * TINT_SCALE, 505 * TINT_SCALE,true,0xFFFFFFFF);					
			}
			
			//this is the size of 3x3 rooms.
			if(this.bmdObjTint == null)
			{
				this.bmdObjTint = new BitmapData(2340 * TINT_SCALE,1515 * TINT_SCALE,true,0xFFFFFFFF);
			}

			clearTintData();
			
			var avatarTintMatrix:Matrix = this.mcTintLayer.transform.matrix.clone();			
			avatarTintMatrix.tx = -( mRoom.layoutPos.x * 780);
			avatarTintMatrix.ty = -( mRoom.layoutPos.y * 505);
			avatarTintMatrix.scale(TINT_SCALE, TINT_SCALE);
			this.bmdAvTint.draw(this.mcTintLayer,avatarTintMatrix);
			
			var mapObjectTintMatrix:Matrix = this.mcTintLayer.transform.matrix.clone();
			mapObjectTintMatrix.tx = -( (mRoom.layoutPos.x-1) * 780);
			mapObjectTintMatrix.ty = -( (mRoom.layoutPos.y-1) * 505);
			mapObjectTintMatrix.scale(TINT_SCALE, TINT_SCALE);
			
			this.mcTintShadow.visible = false;
			this.bmdObjTint.draw(this.mcTintLayer,mapObjectTintMatrix);				
			this.mcTintShadow.visible = true;
			
			mRoom.setShadowForTint(false);
			mRoom.setGroundLightForTint(false);	
		}
		else{
			clearTintData();
		}
		
		dispatchInvalidTint();			
	}
	
	private function dispatchInvalidTint():void{
		//[jtn] we need to dispatch an event, so StageLayerManager knows that tints are invalid
		dispatchEvent(new Event(INHABITANTS_TINT_INVALID));		
	}
	
	public function clearTintData():void
	{
		if(bmdAvTint){
			this.bmdAvTint.fillRect(bmdAvTint.rect,0xFF000000);
		}
		
		if(bmdObjTint){
			this.bmdObjTint.fillRect(bmdObjTint.rect,0xFF000000);
		}
		dispatchInvalidTint()
	}
		
	public function getTintAtForAvatars(x:int, y:int):Object {
		if (_mapRoomManager.getCurrentRoomId() != null) {
			var mapRoom:MapRoom = _mapRoomManager.getCurrentMapRoom(); 
					
			if (this.bmdAvTint != null && mapRoom != null) {
				var layoutPos:Point = mapRoom.layoutPos;
				
				var localX:Number = x - (layoutPos.x * 780);
				var localY:Number = y - (layoutPos.y * 505);
				
				var c:int = this.bmdAvTint.getPixel(localX * TINT_SCALE, localY * TINT_SCALE);					
				
				var r:int = c >> 16;
				var g:int = c >> 8 & 0xFF;
				var b:int = c & 0xFF;
				var tint:Object = {r:r, g:g, b:b};
				
				if (!(tint.r == 0 && tint.g == 0 && tint.b == 0)) {
					return tint;
				}
			}
		}
		return null;								
	}	
	
}

internal class MapGSTTintManager{
	
	//-- tintUpdate
	private var gstTint:TintUpdate;
	private var roomTint:TintUpdate;
	
	private var _mapRoomManager:IMapRoomManager = null;
	private var _mapTintManager:MapTintManager = null;
	
	private var _gst:GST = null;
	
	public function MapGSTTintManager(gstTintLayer:Sprite, roomTintLayer:Sprite, mapTintManager:MapTintManager, mapRoomManager:IMapRoomManager, gst:GST){
		_mapTintManager = mapTintManager;
		_mapRoomManager = mapRoomManager;
		
		_gst = gst;
		
		this.gstTint = new TintUpdate(gstTintLayer, 240000, 6000);
		this.gstTint.addEventListener("TINT_UPDATE", _mapTintManager.onTintUpdate, false, 0, true);
		this.gstTint.name = "GST";		
		
		this.roomTint = new TintUpdate(roomTintLayer, 12000, 1000);
		this.roomTint.addEventListener("TINT_UPDATE", _mapTintManager.onTintUpdate, false, 0, true);
		this.roomTint.name = "Room";
		
		DisplayObjectUtils.addWeakListener(GlobalEvent.eventDispatcher, GlobalEvent.MAP_GST_TINT_UPDATE, onGSTTintEvent);
		DisplayObjectUtils.addWeakListener(GlobalEvent.eventDispatcher, GlobalEvent.MAP_SET_LIGHTS, setLightsOnEvent);
	}
	
	public function updateRoomTint(r:int, g:int, b:int, per:int):void{
		roomTint.updateTint(r, g, b, per);
	}
	
	public function setRoomTint(r:int, g:int, b:int, per:int):void{
		roomTint.setTint(r, g, b, per);
	}
		// -- Gst Tint ----------------
	private var lightOn:Boolean = false;
	
	private function onGSTTintEvent(event:GlobalEvent):void {
		// event.data={r:tint.r, g:tint.g, b:tint.b, update:update}
		var r:int = event.data.r;
		var g:int = event.data.g;
		var b:int = event.data.b;
		var update:Boolean = event.data.update;
		setGSTTint(r, g, b, update);
	}
	
	public function setCurrentGSTTint(update:Boolean=true):void{
		var tint:Object = _gst.getCurrentTint();					
		if (tint != null){				
			setGSTTint(tint.r, tint.g, tint.b, update);
		}
	}
	
	private function setGSTTint(r:int = 255,g:int = 255, b:int = 255, update:Boolean = true):void
	{
		if (update){
			this.gstTint.updateTint(r,g,b,100);
		}else{
			this.gstTint.setTint(r,g,b,100);
		}
	}
	
	private function setLightsOnEvent(event:GlobalEvent):void {
		var value:Boolean = event.data.on;
		setLightsOn(value);			
	}
	
	public function setLights():void{
		setLightsOn(_gst.lightsOn);
	}
	
	private function setLightsOn(value:Boolean):void{
		
		//trace("Map Light" , this.lightOn, value)
		if (this.lightOn == value){
			return;
		}
		
		this.lightOn = value;
		
		var mapRoom:MapRoom = _mapRoomManager.getCurrentMapRoom();
		if ( mapRoom != null){
			// add all new MapObject
			for (var i:int = 0; i < mapRoom.mapObjs.length; i++){
				var mapObj:MapObject = mapRoom.mapObjs[i];
				if (!mapObj.isCustomLight){
					mapObj.setLight(this.lightOn);
				}
			}
		}
	}
	public function isLightsOn():Boolean{
		return this.lightOn;
	}
	
}