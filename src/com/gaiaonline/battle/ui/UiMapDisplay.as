package com.gaiaonline.battle.ui
{
	import com.gaiaonline.battle.ui.events.UiEvents;
	import com.gaiaonline.utils.DisplayObjectUtils;
	
	import flash.display.BlendMode;
	import flash.display.DisplayObject;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.filters.GlowFilter;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.Dictionary;
	import flash.utils.getTimer;

	[Event(name=UiMapDisplay.DRAG_START, type="flash.events.Event")]
	[Event(name=UiMapDisplay.PHANTOM_MARKER_CLICK, type="com.gaiaonline.battle.ui.events.UiEvents")]
	public class UiMapDisplay extends MovieClip
	{
		static public const DRAG_START:String = "UiMapDisplayEvent.dragStart"; 
		static public const PHANTOM_MARKER_CLICK:String = "UiMapDisplayEvent.phantomMarkerClick"; 

		public var mcMask:MovieClip;
		public var mcMapContainer:MovieClip;
		public var mcBorder:MovieClip;
		
		private var _stores:Dictionary = new Dictionary();  // lookup of MiniMapMarkerType -> MarkerStore

		private var mcMap:Sprite = new Sprite();
		private var mcDots:Sprite = new Sprite();
		private var mcFOW:Sprite = new Sprite();
		private var mcFOWMask:Sprite = new Sprite();
		
		private var _width:Number = 100;
		private var _height:Number = 100;
		
		private var _objects:Array = new Array();		
		private var _playerPos:Point;
		private var _autoCenter:Boolean = true;
		private var _showFOW:Boolean = true;

		private var _tooltipManager:ToolTipOld;
		
		public function UiMapDisplay()
		{
			super();
		}
		
		public function init(tooltipManager:ToolTipOld):void
		{
			this._tooltipManager = tooltipManager;				
			
			this.mcFOW.blendMode = BlendMode.LAYER;
			this.mcFOWMask.blendMode = BlendMode.ERASE;
			this.mcFOWMask.filters = [new GlowFilter(0x000000, 1, 12, 12)]
			this.mcFOW.addChild(this.mcFOWMask);
			
			this.mcMapContainer.addChild(this.mcMap);			
			this.mcMapContainer.addChild(this.mcFOW);
			this.mcMapContainer.addChild(this.mcDots);		
			this.mcMapContainer.addEventListener(MouseEvent.MOUSE_DOWN, onMapMouseDown, false, 0, true);
			
			this.mcMapContainer.buttonMode = true;
			this.mcMapContainer.useHandCursor = true;			
		}
		
		private function onMapMouseDown(evt:MouseEvent):void{

			if (_markerClicked)
			{
				_markerClicked = false;  // because the mousedown on the marker isn't cancelable
				return;
			}

			// Hack alert:  UiMiniMap will listen to this event and unset _autoCenter.  Arguably, that should be a behavior of UiMapDisplay itself.  Wouldn't be hard to change in the future.  -kja
			dispatchEvent(new Event(DRAG_START));
			
			if (!this._autoCenter && this._showFOW && this.stage != null && (this.mcMapContainer.width > this.mcMask.width || this.mcMapContainer.height > this.mcMask.height) ){
				
				var left:Number =  this.mcMask.width/2 - this.mcMapContainer.width/2;;
				var right:Number = 0;
				if (this.mcMapContainer.width > this.mcMask.width){
					left = -this.mcMapContainer.width + this.mcMask.width;
					right = this.mcMapContainer.width - this.mcMask.width
				}
				
				var top:Number =  this.mcMask.height/2 - this.mcMapContainer.height/2;
				var bottom:Number = 0;
				if ( this.mcMapContainer.height > this.mcMask.height ){
					top = -this.mcMapContainer.height + this.mcMask.height;
					bottom = this.mcMapContainer.height - this.mcMask.height	
				}				 
								
				this.mcMapContainer.startDrag(false, new Rectangle(left,top, right, bottom));			
				this.stage.addEventListener(MouseEvent.MOUSE_UP, onMapMouseUp, false, 0, true);
				this.stage.addEventListener(MouseEvent.MOUSE_MOVE, onMapDrag, false, 0, true);
			}
		}
		
		private function onMapDrag(evt:MouseEvent):void {
			updateMarkerPositions();
		}
		private function onMapMouseUp(evt:MouseEvent):void{

			this.mcMapContainer.stopDrag();

			this.stage.removeEventListener(MouseEvent.MOUSE_UP, onMapMouseUp);
			this.stage.removeEventListener(MouseEvent.MOUSE_MOVE, onMapDrag);
			
			updateMarkerPositions();
		}
		
		private var centerPoint:Point = new Point(NaN, NaN);		
		public function resize(resized:Boolean = false, needsRecentering:Boolean = true):void{
			
			if (this._autoCenter && this._playerPos != null){
				if (centerPoint.x != this._playerPos.x || centerPoint.y != this._playerPos.y) {
					needsRecentering = true;
					centerPoint.x = this._playerPos.x;
					centerPoint.y = this._playerPos.y;
				}
			}else{
				centerPoint.x = -this.mcMapContainer.x + this._width/2;
				centerPoint.y = -this.mcMapContainer.y + this._height/2;	
			}			

			if (resized || needsRecentering)
			{
				reposition(resized);
			}
			updateMarkerPositions();			
		}
		
		private function reposition(resized:Boolean):void
		{		
			//-- resize mask
			const mcMaskHeight:Number = this._height; 
			const mcMaskWidth:Number = this._width;
			const currMapContainerX:Number = this.mcMapContainer.x;			
			const currMapContainerY:Number = this.mcMapContainer.y;						
			
			if (resized) {			
				this.mcMask.width = mcMaskWidth;
				this.mcMask.height = mcMaskHeight;
				this.mcBorder.width = mcMaskWidth;
				this.mcBorder.height = mcMaskHeight;
			}

			var mcMapContainerHeight:Number = this.mcMapContainer.height;
			var mcMapContainerWidth:Number = this.mcMapContainer.width;			
			
			if (this._showFOW){			
				// reCenter map	X
				var mapContainerX:Number = mcMaskWidth/2 - mcMapContainerWidth/2;
				if (mcMapContainerWidth >= mcMaskWidth) {
					mapContainerX = -(centerPoint.x - mcMaskWidth/2); 
					if (mapContainerX > 0){
						mapContainerX = 0;					
					}
					if (mapContainerX < -(mcMapContainerWidth - mcMaskWidth)){
						mapContainerX = -(mcMapContainerWidth - mcMaskWidth);
					}
				}
				var exceedsEpsilon:Boolean = this.exceedsEpsilon(mapContainerX - currMapContainerX); 				
				if (exceedsEpsilon) {
					this.mcMapContainer.x = mapContainerX;
				} 					
				
				// reCenter map	Y
				var mapContainerY:Number = (mcMaskHeight/2) - (mcMapContainerHeight/2);
				if (mcMapContainerHeight >= mcMaskHeight) {
					mapContainerY = -(centerPoint.y - mcMaskHeight/2); 
					if (mapContainerY > 0){
						mapContainerY = 0;					
					}
					if (mapContainerY < -(mcMapContainerHeight - mcMaskHeight)){
						mapContainerY = -(mcMapContainerHeight - mcMaskHeight);
					}
				}
				exceedsEpsilon = this.exceedsEpsilon(mapContainerY - currMapContainerY); 				
				if (exceedsEpsilon) {
					this.mcMapContainer.y = mapContainerY;
				} 									
			}else{
				if (mapContainerX != currMapContainerX) {				
					this.mcMapContainer.x = (mcMaskWidth/2) - (mcMapContainerWidth/2);
				}
				if (mapContainerY != currMapContainerY) {				 
					this.mcMapContainer.y = (mcMaskHeight/2) - (mcMapContainerHeight/2);
				}
			}
		}
		
		private function exceedsEpsilon(delta:Number):Boolean {
			return delta > .1 || delta < -.1;
		}

		private function forEachMarker(fn:Function):void
		{ 
			for each (var store:MarkerStore in _stores)
			{
				store.forEachMarker(fn);
			}
		}

		private function playMarker(marker:Marker):void {
			if (marker.stateName != UiMapDisplay.MARKERFRAME_TRIANGLE) {
				marker.mc.gotoAndPlay(UiMapDisplay.MARKERFRAME_NORMAL);
			}			
		}
		
		private var _lastPulse:int = 0;		
		private function pulseMarkers():void {
			
			const time:int = getTimer();
			if (time - _lastPulse > 4000) {
				// instead of let the markers loop over their animation continually, we'll just 'blink' them
				// occasionally.  This greatly reduces performance impact, especially with a lot of markers
				forEachMarker(playMarker);
				_lastPulse = time;
			}	
		}

		private function getMarkerStore(type:MiniMapMarkerType):MarkerStore
		{
			if (!this._stores[type])
			{
				this._stores[type] = new MarkerStore(type);
			}
			return this._stores[type];			
		}
		
		public function setMarkerData(id:String, type:MiniMapMarkerType, name:String, markerX:Number, markerY:Number, voiceData:Object = null):void
		{
			var mf:MarkerStore = getMarkerStore(type);
			var marker:Marker = mf.getInstance(id);
			if (marker == null) {

				marker = mf.addInstance(id);
				
				switch(type) {
				case MiniMapMarkerType.PHANTOM_FRIEND:
					DisplayObjectUtils.addWeakListener(marker.mc, MouseEvent.MOUSE_DOWN, onPhantomFriendMouseDown);
					DisplayObjectUtils.addWeakListener(marker.mc, MouseEvent.ROLL_OVER, onPhantomFriendRollOver);
					DisplayObjectUtils.addWeakListener(marker.mc, MouseEvent.ROLL_OUT, onPhantomFriendRollOut);
					break;
				}

				if (type == MiniMapMarkerType.PLAYER) {
					this.mcDots.addChild(marker.mc);
				}
				else {
					this.mcDots.addChildAt(marker.mc, 0);
				}
			}

			if (marker.name != name)
			{
				// Watch for name changes
				var tooltip:String = (type == MiniMapMarkerType.PHANTOM_FRIEND) ? (name + " - click to move to this player.") : name; 
				this._tooltipManager.addToolTip(marker.mc, tooltip, 100);
				marker.name = name;
			}

			if (type == MiniMapMarkerType.PLAYER) {
				if (this._playerPos) {
					this._playerPos.x = markerX;
					this._playerPos.y = markerY;
				}
				else {
					this._playerPos = new Point(markerX, markerY);
				}
			}			

			marker.setWorldPos(markerX, markerY);
			marker.watermark = _updateWatermark;
			
			if(voiceData)
			{
				if(voiceData.isSpeaking)
				{
					marker.addVoicePulse(voiceData.speakingMCClass);
				}
				else
				{
					marker.removeVoicePulse();
				}
			}
		}

		private var _updateWatermark:uint = 0;
		public function purgeStaleMarkers():void
		{
			for each(var markerLookup:MarkerStore in this._stores) {
				for (var id:String in markerLookup.instances){
					var marker:Marker = markerLookup.getInstance(id); 				
					if (marker.watermark != _updateWatermark){					

						//
						// A marker must be updated every cycle or else we assume it's removed
						this._tooltipManager.removeToolTip(marker.mc);
						this.mcDots.removeChild(marker.mc);
						markerLookup.removeInstance(id);					
					}
				}
			}
			++_updateWatermark;	
		}
		public function applyMarkers():void
		{
			if (this._autoCenter){
				this.resize();
			}

			updateMarkerPositions();
			pulseMarkers();
		}
		
		private var _markerClicked:Boolean = false;
		private function onPhantomFriendMouseDown(e:Event):void
		{
			// Do a backwards lookup to find the actor id of the marker
			var phantomStore:MarkerStore = MarkerStore(getMarkerStore(MiniMapMarkerType.PHANTOM_FRIEND)); 
			for (var id:String in phantomStore.instances)
			{
				if (phantomStore.getInstance(id).mc == e.currentTarget)
				{
					var event:UiEvents = new UiEvents(PHANTOM_MARKER_CLICK, null);
					event.userId = id;  
					dispatchEvent(event);
					_markerClicked = true;
					break;
				} 
			}
		}

		private function onPhantomFriendRollOver(e:Event):void
		{
			DisplayObject(e.target).scaleX = 1.5;
			DisplayObject(e.target).scaleY = 1.5;
		}

		private function onPhantomFriendRollOut(e:Event):void
		{
			DisplayObject(e.target).scaleX = 1.0;
			DisplayObject(e.target).scaleY = 1.0;
		}

		private static const s_convertRadians:Number = 180/Math.PI;
		private static const MARKERFRAME_NORMAL:String = "marker";
		private static const MARKERFRAME_TRIANGLE:String = "hint";
		private function updateMarkerPositions():void
		{
			const mapContainerX:Number = this.mcMapContainer.x;
			const mapContainerY:Number = this.mcMapContainer.y;
			const maskWidth:Number = this.mcMask.width;			
			const maskHeight:Number = this.mcMask.height;

			//
			// For all markers, examine their location and check whether their hint arrow should be shown, hidden, or rotated.
			for each (var store:MarkerStore in _stores)
			{
				for each (var marker:Marker in store.instances)
				{
					var targetX:Number = marker.worldX;
					if (targetX + mapContainerX  < 0)
					{
						targetX = -mapContainerX;
					}
					else if (targetX + mapContainerX > maskWidth)
					{
						targetX = -mapContainerX + maskWidth;
					}
					var excessX:Number = marker.worldX - targetX;   // Hopefully we all have problems with excessX					
					
					var targetY:Number = marker.worldY;
					if (targetY + mapContainerY < 0)
					{
						targetY = -mapContainerY;
					}
					else if (targetY + mapContainerY > maskHeight)
					{
						targetY = -mapContainerY + maskHeight;
					}
					var excessY:Number = marker.worldY - targetY;

					var stateName:String = MARKERFRAME_NORMAL;
					var angle:Number = 0;
					if (excessX != 0 || excessY != 0)
					{
						stateName = MARKERFRAME_TRIANGLE;
						angle = Math.atan2(excessY, excessX)*s_convertRadians + 90; // [kja] using Math.atan2, my proudest moment.  JNew thinks its no big deal.  Screw you, JNew. 
					}
 
					if (marker.stateName != stateName) {
						marker.stateName = stateName;
						marker.mc.gotoAndPlay(stateName);
					}
					if (marker.mc.rotation != angle) {
						marker.mc.rotation  = angle;
					}			
					if (!marker.isAt(targetX, targetY)) {
						marker.setPos(targetX, targetY);
					}
				}	
			}
		}
		
		public function setMapImg(map:Sprite):void{			
			while(this.mcMap.numChildren > 0){
				this.mcMap.removeChildAt(0);
			}
			this.mcMap.addChild(map);
			this.mcMapContainer.x = 0;
			this.mcMapContainer.y = 0;
			this.resize(false, true)							
		}	
					
		public function setSize(width:Number, height:Number):void {
			var dirty:Boolean = (width != this._width || height != this._height);
			if (dirty) {
				this._width = width;
				this._height = height;
				this.resize(dirty);
			}
		}
		
		
		//--- Fog of War (FOW) -----------
		public function resetFogOfWar(showFogOfWar:Boolean):void{
			this.mcFOWMask.graphics.clear();	
					
			this.mcFOW.graphics.clear();
			this.mcFOW.graphics.lineStyle(0,0,0);
			this.mcFOW.graphics.beginFill(0x000000, 1);
			this.mcFOW.graphics.drawRect(0,0,this.mcMap.width, this.mcMap.height);
			this.mcFOW.graphics.endFill();
						
			this._showFOW = showFogOfWar;		
			this.mcFOW.visible = showFogOfWar;			
		}	
			
		public function clearFogOfWar(rect:Rectangle):void{
			this.mcFOWMask.graphics.lineStyle(0,0,0);
			this.mcFOWMask.graphics.beginFill(0x000000, 1);
			this.mcFOWMask.graphics.drawRect(rect.x, rect.y, rect.width, rect.height);
			this.mcFOWMask.graphics.endFill();	
			
		}
		
		public function set autoCenter(v:Boolean):void{
			if (v != this._autoCenter){				
				this._autoCenter = v;
				this.resize();
				this.updateMarkerPositions();
			}	
		}
		public function get autoCenter():Boolean{
			return this._autoCenter;		
		}

		public function set showGroup(v:Boolean):void{
			getMarkerStore(MiniMapMarkerType.GROUP).show = v;
		}
		public function get showGroup():Boolean{
			return getMarkerStore(MiniMapMarkerType.GROUP).show;		
		}
		public function set showFriend(v:Boolean):void{
			getMarkerStore(MiniMapMarkerType.FRIEND).show = v;
			getMarkerStore(MiniMapMarkerType.PHANTOM_FRIEND).show = v;
		}
		public function get showFriend():Boolean{
			return getMarkerStore(MiniMapMarkerType.FRIEND).show;		
		}
		public function set showQuestFlags(v:Boolean):void{
			getMarkerStore(MiniMapMarkerType.QUEST).show = v;
			getMarkerStore(MiniMapMarkerType.AVAILABLE_QUEST).show = v;
		}
		public function get showQuestFlags():Boolean{
			return getMarkerStore(MiniMapMarkerType.QUEST).show;		
		}
	}
}
import flash.display.MovieClip;
import com.gaiaonline.battle.ui.MiniMapMarkerType;
import flash.geom.ColorTransform;
import flash.display.DisplayObjectContainer;
internal class Marker
{
	public var mc:MovieClip;
	public var stateName:String = "";
	public var watermark:int = 0;
	public var name:String = "";
	public function Marker(_mc:MovieClip)
	{
		mc = _mc;
	}

	private var _worldX:Number = 0;
	private var _worldY:Number = 0;
	public function setWorldPos(x:Number, y:Number):void
	{
		_worldX = x;
		_worldY = y;
	}
	public function get worldX():Number
	{
		return _worldX;
	}
	public function get worldY():Number
	{
		return _worldY;
	}
	
	private var _pulse:MovieClip = null;
	public function addVoicePulse(pulse:Class):void
	{
		if(null == _pulse)	
		{
			_pulse = new pulse();
			mc.addChild(_pulse);
		}
	}
	
	public function removeVoicePulse():void
	{
		if(null != _pulse)
		{
			if(_pulse.parent == mc)
			{
				mc.removeChild(_pulse);
			}
			_pulse = null;
		}
	}
	
	//
	// We're caching these values to avoid calling the DisplayObject.x and y setters when we don't have to.  Also,
	// those setters sometimes round to a slightly different value, so this is the reliable way to know if the
	// position's changed
	private var _cachedX:Number = 0;
	private var _cachedY:Number = 0;
	public function setPos(x:Number, y:Number):void
	{
		_cachedX = x;
		_cachedY = y;
		mc.x = x;
		mc.y = y;
	}
	public function isAt(x:Number, y:Number):Boolean
	{
		return _cachedX == x && _cachedY == y;
	}
}

internal class MarkerStore
{
	private var _type:MiniMapMarkerType;
	private var _show:Boolean;
	private var _instances:Object = {};
	public function MarkerStore(type:MiniMapMarkerType):void
	{
		_type = type;
		_show = true;
	}
	public function addInstance(id:String):Marker
	{
		var assetType:Class = _type.getClass();
		var newMarker:Marker = new Marker(new assetType());
		newMarker.mc.visible = _show; 

		_instances[id] = newMarker; 
		return newMarker;
	}	
	public function getInstance(id:String):Marker
	{
		return _instances[id];
	}
	public function removeInstance(id:String):void
	{
		_instances[id] = null;
		delete _instances[id];
	}
	public function get instances():Object  // a breach in encapsulation - use judiciously
	{
		return _instances;
	}
	public function get show():Boolean
	{
		return _show;
	}
	public function set show(s:Boolean):void
	{
		if (_show != s)
		{
			_show = s;
			for each (var m:Marker in _instances)
			{
				m.mc.visible = s;
			}	
		}
	}
	public function forEachMarker(fn:Function):void
	{
		for each (var m:Marker in _instances){
			fn(m);
		}	
	}
}