package com.gaiaonline.battle.ui
{
	import com.gaiaonline.battle.ApplicationInterfaces.IUIFramework;
	import com.gaiaonline.battle.gateway.BattleEvent;
	import com.gaiaonline.battle.gateway.BattleGateway;
	import com.gaiaonline.battle.gateway.BattleMessage;
	import com.gaiaonline.battle.newactors.ActorManager;
	import com.gaiaonline.battle.newactors.BaseActor;
	import com.gaiaonline.battle.ui.events.UiEvents;
	import com.gaiaonline.battle.utils.BattleUtils;
	import com.gaiaonline.flexModulesAPIs.globalevent.GlobalEvent;
	import com.gaiaonline.flexModulesAPIs.minimap.IMinimapEventHandler;
	import com.gaiaonline.objectPool.LoaderFactory;
	import com.gaiaonline.platform.map.MapFilesFactory;
	import com.gaiaonline.utils.DisplayObjectUtils;
	import com.gaiaonline.utils.FrameTimer;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.Loader;
	import flash.display.LoaderInfo;
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.geom.Rectangle;
	import flash.net.URLRequest;
	import flash.utils.Dictionary;
	
	public class MiniMapManager implements IMinimapEventHandler
	{		
		private var areaOffset:Number = 0;
		private var miniMapId:String;
				
		private var friends:Object = {};
		private var phantomFriends:Object = {};
		private var questFlags:Object = {};	
		private var availableQuestFlags:Object = {};		
		private var goofBallPosition:Object = {};
		private var miniMapCustomFlags:Object = {};	
		private var fowRooms:Object = {};	
		private var fowZoneId:String;
		
		private var _gateway:BattleGateway = null;
		private var _uiFramework:IUIFramework = null;
		
		private var _views:Dictionary = new Dictionary(true);		
		
		public function MiniMapManager(gateway:BattleGateway, uiFramework:IUIFramework)
		{
			this._gateway = gateway;
			this._uiFramework = uiFramework;

			MiniMapMarkerType.init(uiFramework);
			DisplayObjectUtils.addWeakListener(GlobalEvent.eventDispatcher, GlobalEvent.MAP_SLIDE_COMPLETE, onMapSlideDone);			
			DisplayObjectUtils.addWeakListener(GlobalEvent.eventDispatcher, GlobalEvent.MAP_DONE, onSetRoom);							
		}

		public function addView(view:UiMapDisplay, local:Boolean):void
		{
			_views[view]= new ViewEntry(view, local);
			view.addEventListener(UiMapDisplay.PHANTOM_MARKER_CLICK, onPhantomMarkerClick, false, 0, true);

			// [kja] not completely well-abstracted yet.  This basically imitates what would have happened to a view
			// had we had it from the start, before initialization happened.  Initialization is asynchronous, the
			// map image needs to be loaded, followed by the fog of war.  This basically re-applies those results
			// to any new incoming map.
			if (_currentLocalMapImage && local)
			{
				setMapImg(view, _currentLocalMapImage);
				view.resetFogOfWar(this._showFogOfWar);
			}
			
			for each (var roomId:String in this.fowRooms)
			{
				clearFogOfWarOnRoom(roomId, view);
			}

			maintainUpdateInterval();
		}
		public function removeView(view:UiMapDisplay):void
		{
			delete _views[view];
			maintainUpdateInterval();
		}

		public function setViewVisible(view:UiMapDisplay, visible:Boolean):void
		{
			ViewEntry(_views[view]).visible = visible;
			
			maintainUpdateInterval();
		}

		// IMinimapEventHandler - accepts events back from the minimap view(s)
		public function onViewVisibilityChange(view:DisplayObject, b:Boolean):void
		{
		}

		private function onMapSlideDone(e:GlobalEvent):void {
			var newRoomId:String = e.data.newRoomId;	
			
			//[flajeu]	adding if clause to checkl if we alrady have this fow room. no need to update and save it to server 
			//(this is to avoid spaming the server every time user change room) 		
			if ( !this.fowRooms[newRoomId] ){
				this.updateLocalMap(newRoomId);				
				this.clearFogOfWarOnRoom(newRoomId);	
			this.saveFogOfWar(BattleUtils.getZoneIdFromRoomId(newRoomId));
		}
		}
		
		private function onSetRoom(e:GlobalEvent):void {
			var newRoomId:String = e.data.roomId;
			this.updateLocalMap(newRoomId);
		}	

		private function maintainUpdateInterval():void
		{
			for each (var ve:ViewEntry in _views)
			{
				if (ve.visible)
				{
					startUpdate();
					return;
				}
			}
			stopUpdate();
		}

		private var _rebuildMarkersTimer:FrameTimer = new FrameTimer(rebuildMarkers);
		private function startUpdate():void
		{
			if (!_rebuildMarkersTimer.running)
			{
				if (!this._gateway.hasEventListener(BattleEvent.MINI_MAP_UPDATE)){
					this._gateway.addEventListener(BattleEvent.MINI_MAP_UPDATE, onServerUpdate, false, 0, true);
				}
				
				var msg:BattleMessage = new BattleMessage("miniMapVisibility", {boolean:true});
				this._gateway.sendMsg(msg);
				
				this._rebuildMarkersTimer.start(500);
			} 
		}
		
		private function stopUpdate():void
		{
			if (_rebuildMarkersTimer.running)
			{
				if (this._gateway.hasEventListener(BattleEvent.MINI_MAP_UPDATE)){
					this._gateway.removeEventListener(BattleEvent.MINI_MAP_UPDATE, onServerUpdate);
				}
				var msg:BattleMessage = new BattleMessage("miniMapVisibility", {boolean:false});
				this._gateway.sendMsg(msg);
				
				this._rebuildMarkersTimer.stop();
			}			
		}
		
		// Call when area change to update the map
		private var _showFogOfWar:Boolean = true;
		public function updateLocalMap(roomId:String):void{
			var mapId:String = MapFilesFactory.getInstance().mapFiles.getMiniMapId(roomId);							
			if (mapId != this.miniMapId)
			{
				this._rebuildMarkersTimer.stop(); 

				this.fowRooms = {};
				this.fowZoneId = BattleUtils.getZoneIdFromRoomId(roomId);
				this.miniMapId = mapId;
				var obj:Object = MapFilesFactory.getInstance().mapFiles.getMiniMap(roomId) as Object;
				var url:String = MapFilesFactory.getInstance().mapFiles.getMiniMapUrl(this.miniMapId) as String;
				if (obj != null && url != null){
					_showFogOfWar = obj.showLocal;
					loadMiniMap(url, obj.showLocal);
				}
				
				// this will clear the existing minimap markers
				applyMarkers();
			}			
		}

		private function loadMiniMap(url:String, showFogOfWar:Boolean):void
		{
			this._showFogOfWar = showFogOfWar;
			var l:Loader = LoaderFactory.getInstance().checkOut();
			l.contentLoaderInfo.addEventListener(Event.COMPLETE, onMiniMapLoaded);
			l.load(new URLRequest(url), this._uiFramework.loaderContextFactory.getLoaderContext());	
		}

		private var _currentLocalMapImage:BitmapData;
		private function onMiniMapLoaded(evt:Event):void
		{
			_currentLocalMapImage = Bitmap(LoaderInfo(evt.target).content).bitmapData;

			initLocalMaps(_currentLocalMapImage);
			loadFogOfWar(this.fowZoneId);			
			
			LoaderInfo(evt.target).loader.contentLoaderInfo.removeEventListener(Event.COMPLETE, onMiniMapLoaded)
			LoaderFactory.getInstance().checkIn(LoaderInfo(evt.target).loader);
		}

		private function initLocalMaps(img:BitmapData):void
		{
			for each (var ve:ViewEntry in _views)
			{
				if (ve.local)
				{
					setMapImg(ve.view, img);
					ve.view.resetFogOfWar(this._showFogOfWar);
				}
			}
		}

		private function setMapImg(view:UiMapDisplay, img:BitmapData):void
		{
			var bmp:Bitmap = new Bitmap(img);
			var mcMap:MovieClip = new MovieClip();
			mcMap.addChild(bmp);

			view.setMapImg(mcMap);
		}

		private function setMarkerData(roomId:String, id:String, type:MiniMapMarkerType, name:String, unscaledX:Number, unscaledY:Number):void {
			
			var obj:Object = MapFilesFactory.getInstance().mapFiles.getMiniMap(roomId);
			if (obj != null){			
				if (obj.showLocal && this.miniMapId == obj.id){
					const lx:Number = (unscaledX * obj.scale) + obj.localPos.x;
					const ly:Number = (unscaledY * obj.scale) + obj.localPos.y;
					setMarkerOnViews(id, type, name, lx, ly, true);
				}
				if (obj.showGlobal){
					const gx:Number = (unscaledX * MapFilesFactory.getInstance().mapFiles.globalXScale) + obj.globalPos.x;
					const gy:Number = (unscaledY * MapFilesFactory.getInstance().mapFiles.globalYScale) + obj.globalPos.y;			
					setMarkerOnViews(id, type, name, gx, gy, false);
				}
			}	
		}

		private function setMarkerOnViews(id:String, type:MiniMapMarkerType, name:String, markerX:Number, markerY:Number, local:Boolean):void
		{
			for each (var ve:ViewEntry in _views)
			{
				if (ve.local == local)
				{
					ve.view.setMarkerData(id, type, name, markerX, markerY);
				}
			}
		}
		
		private function rebuildMarkers():void
		{
			const me:BaseActor = ActorManager.getInstance().myActor;
			if (me && me.actorId)
			{
				//-- get Player and Team Position
				for (var acId:String in ActorManager.getInstance().myActor.myTeam){
					var act:BaseActor = ActorManager.actorIdToActor(acId);
					if (act != null)
					{
						var type:MiniMapMarkerType = (acId == ActorManager.getInstance().myActor.actorId) ? MiniMapMarkerType.PLAYER : MiniMapMarkerType.GROUP;
						setMarkerData(act.roomId, act.actorId, type, act.actorName, act.position.x, act.position.y);
					}
				}

				// get Friends Position
				for (var fid:String in this.friends){
					// teammates handled already above
					if (fid != me.actorId  && !me.isOnMyTeam(fid)){
						var friend:Object = this.friends[fid];
						setMarkerData(friend.roomName, friend.id, MiniMapMarkerType.FRIEND, friend.name, friend.x, friend.y);					
					}
				}
			}
			

			// phantom friends - friends in other instances of the same zone.  Uncomment this to activate it (currently awaiting new assets)!
			for (var pfid:String in this.phantomFriends){
				var pf:Object = this.phantomFriends[pfid];
				setMarkerData(pf.roomName, pf.id, MiniMapMarkerType.PHANTOM_FRIEND, pf.name, pf.x, pf.y); 
			}

			// get Quest Flags
			for (var qid:String in this.questFlags) {
				var quest:Object = this.questFlags[qid];
				setMarkerData(quest.roomName, quest.id, MiniMapMarkerType.QUEST, quest.name, quest.x, quest.y); 
			}
			
			// get available quest flags
			for (var aqid:String in this.availableQuestFlags) {
				var aq:Object = this.availableQuestFlags[aqid];
				setMarkerData(aq.roomName, aq.id, MiniMapMarkerType.AVAILABLE_QUEST, aq.name, aq.x, aq.y);
			}
			
			for (var customMarkerID:String in this.miniMapCustomFlags) {
				var marker:Object = this.miniMapCustomFlags[customMarkerID];
				
				var custom:MiniMapMarkerType = MiniMapMarkerType.getCustomType(marker.type);
				if (custom)
				{
					setMarkerData(marker.roomName, marker.id, custom, marker.name, marker.x, marker.y);
				}
				else
				{
					trace("MISSING custom minimap marker type ", marker.type);
				}
			}
			
			// Goof Ball
			if (this.goofBallPosition != null && this.goofBallPosition.roomName != null){
				setMarkerData(this.goofBallPosition.roomName, this.goofBallPosition.id, MiniMapMarkerType.GOOFBALL, this.goofBallPosition.name, this.goofBallPosition.x, this.goofBallPosition.y);
			}

			applyMarkers();
		}

		private function applyMarkers():void
		{
			for each (var ve:ViewEntry in _views)
			{
				// [kja] the server always sends down the state of all the markers with every update.  So, if we don't
				// want to rebuild all the markers every time (which we don't, for efficiency reasons), we need to use a validation scheme as below
				if (ve.visible)
				{
					ve.view.purgeStaleMarkers();
					ve.view.applyMarkers();
				}
			}
		} 

		//********* Fog Of War
		private function clearFogOfWarOnRoom(roomId:String, view:UiMapDisplay = null):void
		{
			if (!this.fowRooms[roomId] || view)
			{
				this.fowRooms[roomId] = roomId;									
				var obj:Object = MapFilesFactory.getInstance().mapFiles.getMiniMap(roomId);
				if (obj != null && obj.showLocal){
					var w:Number = 780/(obj.roomScale/obj.scale);
					var h:Number = 505/(obj.roomScale/obj.scale);
					var rect:Rectangle = new Rectangle(obj.localPos.x,obj.localPos.y,w,h);
					
					if (view)
					{
						view.clearFogOfWar(rect);
					}
					else
					{
						for each (var ve:ViewEntry in _views)
						{
							if (ve.local)
							{
								ve.view.clearFogOfWar(rect);
							}
						}
					}
				}
			}
		}

		private function saveFogOfWar(zoneId:String):void
		{
			var value:String;
			for each (var roomId:String in this.fowRooms){
				if (value == null){
					value = BattleUtils.getRoomNumFromRoomId(roomId).toString();
				}else{
					value = value + "," + BattleUtils.getRoomNumFromRoomId(roomId);
				}
			}
			
			var obj:Object = new Object();
			obj[zoneId] = value;	
			var msg:BattleMessage = new BattleMessage("putNkvp", obj);
			this._gateway.sendMsg(msg);
		}

		private function loadFogOfWar(zoneId:String):void{
			
			var msg:BattleMessage = new BattleMessage("getNkvp", {keys:[zoneId]});
			msg.addEventListener(BattleEvent.CALL_BACK, onFowCallLoaded);
			this._gateway.sendMsg(msg);
			
			
		}
		private var _cachedRoomsArray:Array = [];
		private function onFowCallLoaded(evt:BattleEvent):void
		{
			BattleMessage(evt.target).removeEventListener(BattleEvent.CALL_BACK, onFowCallLoaded);

			_cachedRoomsArray.length = 0;
			var rooms:Array = _cachedRoomsArray;
			if (evt.battleMessage.responseObj[0] != null && evt.battleMessage.responseObj[0].values[this.fowZoneId] != null){
				rooms = evt.battleMessage.responseObj[0].values[this.fowZoneId].split(",");
			}

			this.rebuildMarkers();			
			this._rebuildMarkersTimer.start(500);

			for each (var room:String in rooms){
				this.clearFogOfWarOnRoom(this.fowZoneId+"_"+room);
			}
			this.clearFogOfWarOnRoom(ActorManager.getInstance().myActor.roomId);
		}

		private function onPhantomMarkerClick(e:UiEvents):void
		{
			var msg:BattleMessage = new BattleMessage("warp2phantom", { actorID: e.userId} );
			this._gateway.sendMsg(msg);
		}

		private static function deserializeLocations(arrayIn:Array, hashOut:Object, defaultName:String = null):void
		{
			for each (var location:Object in arrayIn)
			{
				hashOut[location.id] = 
				{
					id:       location.id,
					name:     (location.name ? location.name : defaultName ),
					roomName: location.roomName,
					x:        location.px,
					y:        location.py
				};
				
				if (location.mmType && location.mmType.length)
				{
					hashOut[location.id].type = location.mmType;
				}
			}
		}
		private function onServerUpdate(evt:BattleEvent):void{

			var res:Object = evt.battleMessage.responseObj[0];			
			if (res.miniMapQuests != null) {
				var availableQflags:Object = {};
				if (res.miniMapQuests.miniMapQuestsFromNPCs != null) {
					deserializeLocations(res.miniMapQuests.miniMapQuestsFromNPCs, availableQflags, "Available Quest");
				}
				
				var qflags:Object = {};
				if (res.miniMapQuests.miniMapQuestsLocations != null) {
					deserializeLocations(res.miniMapQuests.miniMapQuestsLocations, qflags, "Quest Flag");
				}
				
				// [bgh] remove 'updatable' quest locations from the 'available' list so we don't get ? flags onto of the other flags.
				for each (var loc:Object in qflags)
				{
					delete availableQflags[loc.id];
				}
				
				// [bgh] save to member vars
				this.availableQuestFlags = availableQflags;
				this.questFlags = qflags;
			}		

			if (res.miniMapFriends != null) {
				this.friends = {};		
				deserializeLocations(res.miniMapFriends, this.friends);
			}
			
			if (res.miniMapPhantomFriends != null) {
				this.phantomFriends = {};
				deserializeLocations(res.miniMapPhantomFriends, this.phantomFriends);
			}

			if (res.miniMapFlag != null) {
				this.miniMapCustomFlags = {};
				deserializeLocations(res.miniMapFlag, this.miniMapCustomFlags);
			}

			//GOOF BALL POSITION
			if (res.miniMapGoofball != null){
				if (res.miniMapGoofball.roomName != null){
					this.goofBallPosition = {};
					this.goofBallPosition.roomName = res.miniMapGoofball.roomName;
					this.goofBallPosition.name = res.miniMapGoofball.name;
					this.goofBallPosition.x = res.miniMapGoofball.px;
					this.goofBallPosition.y = res.miniMapGoofball.py;
					this.goofBallPosition.id = "GoofBall_"+ActorManager.getInstance().myActor.actorId;
				} else {
					this.goofBallPosition = null;				
				}
			} else {
				this.goofBallPosition = null;				
			}
		}
	}
}
	import com.gaiaonline.battle.ui.UiMapDisplay;
	

class ViewEntry
{
	public var view:UiMapDisplay;
	public var local:Boolean;
	public var visible:Boolean = true;
	public function ViewEntry(view:UiMapDisplay, local:Boolean):void
	{
		this.view = view;
		this.local = local;
	}
}