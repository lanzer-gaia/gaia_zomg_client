package com.gaiaonline.battle.map
{
import com.gaiaonline.platform.gateway.ICollisionConnector;
import com.gaiaonline.platform.gateway.IResponseHandler;

import flash.geom.Point;

public class MapIt implements IResponseHandler
{		
	// STATIC CONSTANTS
	public static const gameWidth:Number  = 780; // 
	public static const gameHeight:Number = 505; //
	
	// INSTANCE MEMBERS
	private var roomName:String  = "";
	private var cMap:CollisionMap;
	private var numRows:Number = 0;
	private var rowLength:Number = 0;
	private var mapResolution:Number = 8; // todo super sampling?
	private var roomScale:Number;
	
	// to use Mapt It with the GameGateWay
	private var hasCollisionData:Boolean = false;
	private var _gateway:ICollisionConnector;
	
	
	public function MapIt( rname:String, gateway:ICollisionConnector )
	{
		this.roomName = rname;
		this._gateway = gateway;
		this.cMap = new CollisionMap();
		setResolution(this.mapResolution);
	}
	

	public function dispose():void{
		this.cMap.dispose();
	}

	private function setResolution(res:Number):void
	{
		this.mapResolution = res;
		this.rowLength = Math.ceil(gameWidth  / this.mapResolution);
		this.cMap.setResolution(this.mapResolution);
	}
	
	public function isCollisionMapOk():Boolean
	{
		return this.hasCollisionData;
	}
	
	public function getCollisionMap():CollisionMap
	{
		return cMap;
	}
	
	public function getRoomScale():Number
	{
		return this.roomScale;
	}
	
	public function getMapDataFromServer():void
	{
		_gateway.getCollisionData(this.roomName, this);
	}
	
	public function onResponse(data:Object):void{
		processScaleAndResData( data );
		processIncomingTargets( data );
		processIncomingMapRLE(  data );
		this.hasCollisionData = true;
	}
	
	public function processScaleAndResData( resObj:Object ):void
	{
		this.roomScale = resObj.scl;
		
		this.cMap.setRoomScale( roomScale );
		this.setResolution( parseInt( resObj.res ) );
		this.cMap.setResolution( this.mapResolution );
	}

	
	// look at the incoming map collision data, set all the nodes
	// in our CollisionMap Object. Then issue the callback to the
	// that says we are done and passes back the CollisionMap
	private static const zeroCharCode:Number = "0".charCodeAt(0);
	private function processIncomingMapRLE(resObj:Object):void
	{
		const dataString:String = resObj["map"];
		const len:uint = dataString.length;
	
		var nodeCounter:Number = 0;
		var c:Number = 0;;
		var runLength:Number = 0;
		
		for (var i:uint = 0; i < len; i++)
		{
			c = dataString.charCodeAt(i);
			
			if (isDigit(c))
			{
				runLength *= 10;
				runLength += (c - zeroCharCode);  
			}
			else
			{
				for (var j:int = 0; j < runLength; j++)
				{
					this.cMap.setNodeFromCharCode(nodeCounter % rowLength, nodeCounter / rowLength, c);
					++nodeCounter;
				}
				runLength = 0;
			}
		}
	}
	

	// look at the target data and set up some targets
	private function processIncomingTargets(resObj:Object):void
	{
		var targetString:String = resObj["trg"];
		
		//create an array
		var targetArray:Array = new Array();
		targetArray = targetString.split("|");
		
		// make targets, set them in the collision map where they belong
		for (var i:int = 0; i < targetArray.length; i += 3)
		{
			var targetName:String = targetArray[i];
			var newTargetX:Number = parseInt(targetArray[i+1]);
			var newTargetY:Number = parseInt(targetArray[i+2]);
			this.cMap.saveTarget( targetName, newTargetX, newTargetY );
		}
	}
	
	private static const nineCharCode:Number = "9".charCodeAt(0);

	private function isDigit(charCode:Number):Boolean
	{
		return (charCode >= zeroCharCode && charCode <= nineCharCode)
	}
}
}


