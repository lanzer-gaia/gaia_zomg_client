package com.gaiaonline.battle.map
{
	import com.gaiaonline.battle.utils.RasterizationStore;
	import com.gaiaonline.utils.SpritePositionBubbler;
	
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.Sprite;
	
	public interface IMap extends IMapRoomManager
	{
		function getColliionTypeAt(x:Number,y:Number):uint;
		function getEmoteLayer():Sprite;
		function isMapLoaded():Boolean;
		function getRasterizationStore():RasterizationStore;
		function isNullChamber():Boolean;
		function setCollisionShowing(isShowing:Boolean):void;
		function isCollisionShowing():Boolean;
		function drawCollisionMap():void;
		function getMapDisplayObject():DisplayObjectContainer;
		function isLightsOn():Boolean;
		function setMapHolder(holder:IMapHolder):void;
		function addMask(m:DisplayObject):void;
		function removeMask(m:DisplayObject):void;
		function addActor(displayObject:SpritePositionBubbler):void;
		function removeActor(displayObject:SpritePositionBubbler):void;
	}
}