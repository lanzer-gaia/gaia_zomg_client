package
{
	import flash.display.Sprite;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	
	public class MapRoom
	{
		   
		public static var TYPE_OPEN:String 		= "a";
		public static var TYPE_WALL:String		= "b";
		public static var TYPE_LOW_WALL:String 	= "c";
		public static var TYPE_WATER:String		= "d";
		public static var TYPE_DEEP_WATER:String= "e";
		public static var TYPE_SAND:String		= "f";
		public static var TYPE_NOFLYZONE:String	= "g";
		
		public var target:Array = new Array();
		public var scale:int = 75;
		public var roomName:String = "";
		public var areaname:String = "";		
		public var roomNum:int = 0;
		public var col:int = 0;
		public var row:int = 0;
		public var precision:int = 8;
		private var _portals:Object = new Object();
		
		public var west:String;
		public var east:String;
		public var south:String;
		public var north:String;
		
		public var data:String;
		
		private var _outputPath:String;
		
		public function MapRoom(outputPath:String) {
			this._outputPath = outputPath;
		}
		
		public function buildData(mcCollision:Sprite, mcPortals:Sprite):void{
			var mcImp:Sprite = mcCollision.getChildByName("mcImpassible") as Sprite;			
			if (mcImp != null){
				var sx:int = precision/2;// (col * 780) + precision/2;
				var sy:int = precision/2;// (row * 505) + precision/2;
				var count:int = 1;
				var lastType:String = "NA";	
				var data:String = "";				
				var i:int = 0;
				
				var totalCol:int = Math.ceil(780/this.precision);
				var totalRow:int = Math.ceil(505/this.precision);				
				for (var y:int = 0; y < totalRow; y++){
					for(var x:int = 0; x < totalCol; x++){
														
						var tx:Number = Math.min( sx + (x*this.precision), 780 );
						var ty:Number = Math.min( sy + (y*this.precision), 505 );
						
						var type:String = TYPE_OPEN
						if (mcImp.hitTestPoint(tx,ty,true)){
							type = TYPE_WALL;
						}
						//trace(this.roomNum, tx, ty, type);
						var portal:Object = this.testPortal(mcPortals, tx, ty);
						if (portal != null){
							type = type.toLocaleUpperCase();
							if (this._portals[portal.id] == null){
								this._portals[portal.id] = new Object();
								this._portals[portal.id].idnum = portal.id;
								this._portals[portal.id].targetname = portal.target;
								this._portals[portal.id].targetroomname = portal.targetRoom;
								this._portals[portal.id].nodelist = "";								
							}
							this._portals[portal.id].nodelist = this._portals[portal.id].nodelist + i + ";"
							
						}	
												
									
						if (type == lastType){
							count ++;							
						}else{							
							if (lastType != "NA"){
								data = data + count+lastType;
								//trace("-----", count+lastType)
							}						
							count = 1;	
							lastType = type;						
						}						
						i++;														
					}
				}
				data = data + (count+lastType);
				
				var file:File = new File();
				file.nativePath = _outputPath + "map-"+this.roomName+".xml";
				var fileStream:FileStream = new FileStream();								
				fileStream.open(file, FileMode.WRITE);
				var outputString:String = '<?xml version="1.0" encoding="utf-8"?>\n';
				var xml:XML = new XML(<maplist/>);
				xml.appendChild(<map name={this.roomName} areaname={this.areaname} resolution={this.precision} roomx={this.col} roomy={this.row} scale={this.scale}/>);
				var mapNode:XML = xml.map[0]; 				
				mapNode.appendChild(<battleroom name={this.roomName}/>);
				mapNode.appendChild(<exits/>);
				var exitsNode:XML = mapNode.exits[0]; 				
				exitsNode.appendChild(<mapexit direction="north"/>);
				exitsNode.appendChild(<mapexit direction="east"/>);
				exitsNode.appendChild(<mapexit direction="south"/>);
				exitsNode.appendChild(<mapexit direction="west"/>);
				var northNode:XML = exitsNode.mapexit.(@direction=="north")[0]; 						 
				var eastNode:XML = exitsNode.mapexit.(@direction=="east")[0]; 						
				var southNode:XML = exitsNode.mapexit.(@direction=="south")[0]; 																												 						
				var westNode:XML = exitsNode.mapexit.(@direction=="west")[0]; 												
				if (this.north) {
					northNode.appendChild(this.north);
				}
				if (this.east) {
					eastNode.appendChild(this.east);
				}		
				if (this.south) {
					southNode.appendChild(this.south);
				}		
				if (this.west) {
					westNode.appendChild(this.west);
				}		
				mapNode.appendChild(<mapdata/>);
				var mapData:XML = mapNode.mapdata[0]; 				
				mapData.appendChild(data);
				mapNode.appendChild(<portallist/>);
				var portalListNode:XML = mapNode.portallist[0]; 				
				for each (var nn:Object in this._portals){
					portalListNode.appendChild(<portal idnum={nn.idnum} nodelist={nn.nodelist} targetname={nn.targetname} targetroomname={nn.targetroomname}/>);
				}
				mapNode.appendChild(<targetlist/>);
				var targetListNode:XML = mapNode.targetlist[0]; 				
				for (var tt:int = 0; tt < this.target.length; tt++){
					var targetX:int = Math.round(this.target[tt].x) - (col*780);
					var targetY:int = Math.round(this.target[tt].y) - (row*505);					
					targetListNode.appendChild(<target name={this.target[tt].name} x={targetX} y={targetY} />);
				}
				
				outputString += xml.toXMLString();
				fileStream.writeUTFBytes(outputString);
				fileStream.close();				
			}				
		}
		
		private function testPortal(mc:Sprite, x:Number, y:Number):Object{
			var obj:Object;
			for (var i:int = 0; i < mc.numChildren; i++){
				var p:Object = mc.getChildAt(i);
				if (p.hitTestPoint(x, y, true)){
					obj = {id:p.id, target:p.target, targetRoom:p.targetRoom}
				}
			}
			return obj;
		}
	}
}