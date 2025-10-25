package
{
	import flash.display.Loader;
	import flash.display.LoaderInfo;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.geom.Matrix;
	import flash.system.LoaderContext;
	import flash.utils.ByteArray;
	
	import mx.controls.SWFLoader;
	
	public class MapLoader extends Sprite
	{
		public static var MAP_BUILD_DONE:String = "MapBuildDone";
		private var _mcCollision:Sprite;
		private var _mcImpassible:Sprite;
		private var _mcStage:Sprite;
		private var _mcInfoLayer:Sprite;
		private var _mcPortals:Sprite;
		private var _rooms:Object = new Object();
		private var _roomList:Array = new Array();	
		private var _prefix:String = "xx";
		private var _roomIndex:int = 0;
		private var _outputPath:String;
		private var _areaname:String ="";
		
		public function MapLoader(outputPath:String) {
			this._outputPath = outputPath;			
		}
		
		
		public function loadMap(prefix:String, url:String):void{
			this._prefix = prefix;
			
//			trace("Load Map : ", this._prefix, url)
			
			var mapSwf:File = new File(url);
		    var stream:FileStream = new FileStream();
			stream.open(mapSwf, FileMode.READ);
			var byteArray:ByteArray = new ByteArray();
			stream.readBytes(byteArray);
			var l:SWFLoader= new SWFLoader();
			var lc:LoaderContext = new LoaderContext();
			lc.allowLoadBytesCodeExecution = true;
			l.loaderContext = lc;
			l.addEventListener(Event.COMPLETE, onMapLoaded);
			l.load(byteArray);
		}
			
		private function onMapLoaded(evt:Event):void{
			var mc:MovieClip = SWFLoader(evt.target).content as MovieClip;			
			this._mcCollision = new Sprite();
			this._mcPortals = new Sprite();
					
			//---- get main Colision movie clip
			if (mc != null){
				this._mcCollision = mc.getChildByName("collisionLayer") as Sprite;
				if (this._mcCollision != null){
					this._mcImpassible = this._mcCollision.getChildByName("mcImpassible") as Sprite;
				}													
				this._mcStage = mc.getChildByName("stageLayer") as Sprite;				
			}			
			
			//-- add mapObject Collision to impassible		
			if (this._mcStage != null && this._mcCollision != null){
				for (var i:int = 0; i < this._mcStage.numChildren; i++){
					var mObj:Sprite = this._mcStage.getChildAt(i) as Sprite;
					if (mObj != null){
						var mcHit:Sprite = mObj.getChildByName("hit") as Sprite;
						if (mcHit != null){														
							var m:Matrix = mcHit.transform.matrix;
							m.concat(mObj.transform.matrix);					
							mcHit.transform.matrix = m;
							mcHit.x -= this._mcImpassible.x;
							mcHit.y -= this._mcImpassible.y;
							this._mcImpassible.addChild(mcHit);												
						}
					}					
				}
			}
			
			var row:int = 0;
			var col:int = 0;
			var roomNum:int = 0;
			//-- Create all the Rooms
			this._mcInfoLayer = mc.getChildByName("infoLayer") as Sprite;
			for (var ii:int = 0; ii < this._mcInfoLayer.numChildren; ii++){
				var objInfo:Object = this._mcInfoLayer.getChildAt(ii);
				if (objInfo == "[object RoomInfo]" && !objInfo.dummyRoom){					
					//trace(objInfo.x, objInfo.y);
					col = Math.floor(objInfo.x/780);
					row = Math.floor(objInfo.y/505);
					roomNum = (row*100)+col+1;
					var mr:MapRoom = new MapRoom(_outputPath);
					mr.row = row;
					mr.col = col;
					mr.roomNum = roomNum;
					//--- Room Name
					if (objInfo.room_name == null || String(objInfo.room_name).length == 0){						
						mr.roomName = this._prefix + "_" + String(roomNum);
					}else{
						mr.roomName = String(objInfo.room_name);
					}
					
					if (objInfo.north){
						mr.north = this._prefix + "_" + (roomNum - 100);
					}
					if (objInfo.south){
						mr.south = this._prefix + "_" + (roomNum + 100);
					}
					if (objInfo.west){
						mr.west = this._prefix + "_" + (roomNum - 1);
					}
					if (objInfo.east){
						mr.east = this._prefix + "_" + (roomNum + 1);
					}
					
					
					//-- Scale
					mr.scale = int(objInfo.room_scale);					
					this._rooms[roomNum] = mr;
					
				}
			}
			
			//-- add Targets			
			var portalList:Array = new Array();
			for (var iii:int = 0; iii < this._mcInfoLayer.numChildren; iii++){
				var obj:Object = this._mcInfoLayer.getChildAt(iii);
				col = Math.floor(obj.x/780);
				row = Math.floor(obj.y/505);	
				roomNum = (row*100)+col+1;					
				if (obj == "[object Target]"){					
					if (this._rooms[roomNum] != null){						
						MapRoom(this._rooms[roomNum]).target.push(obj);
					}	
				}else if (obj == "[object Portal]"){					
					portalList.push(obj);
				}
				
			}
			
			var portalId:int = 100;
			for each (var mcP:Object in portalList){
				mcP.id = portalId;
				this._mcPortals.addChild(Sprite(mcP));
				portalId ++
			}
			
			
			
			
			this._mcCollision.x = this._mcCollision.y = 0;
			this._mcPortals.x = this._mcPortals.y = 0;
			
			this.addChild(this._mcCollision);
			this.addChild(this._mcPortals);
								
			this.dispatchEvent(new Event(Event.COMPLETE));			
						
		}
		
		public function buildMapData(roomsToInclude:Array = null):void{
			this._roomList = new Array();
			this._roomIndex = 0;
			for each (var room:MapRoom in this._rooms){
			if (roomsToInclude == null || roomsToInclude.indexOf(room.roomName) >= 0) {
					this._roomList.push(room);
				}
			}
			
			this.buildRoom();
		}
		
		private function buildRoom():void{
			var room:MapRoom = this._roomList[this._roomIndex];
			room.areaname = this.areaName;
			trace("Move to Room: ", room.roomName)
			this.x = -(room.col * 780)
			this.y = -(room.row * 505)		
			
			this.addEventListener(Event.ENTER_FRAME, onFrame);
		}
		private function onFrame(evt:Event):void{
			this.removeEventListener(Event.ENTER_FRAME, onFrame);			
			var room:MapRoom = this._roomList[this._roomIndex];
			//trace("Build Room ", room.roomName)
			room.buildData(this.mcCollision, this.mcPortals);			
			
			this._roomIndex ++;			
			if (this._roomIndex < this._roomList.length){
				this.buildRoom();
			}else{
				this.dispatchEvent(new Event(MAP_BUILD_DONE));
			}
		}
		
		public function get mcCollision():Sprite{
			return this._mcCollision;
		}
		public function get mcPortals():Sprite{
			return this._mcPortals;
		}
		public function get prefix():String{
			return this._prefix;
		}		
		public function get areaName():String {
			return this._areaname;
		}		
		public function set areaName(name:String):void {
			this._areaname = name;
		}
	}
}