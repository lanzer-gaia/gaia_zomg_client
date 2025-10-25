package com.gaiaonline.battle.ui
{
	import com.gaiaonline.battle.ApplicationInterfaces.IUIFramework;
	
	public class MiniMapMarkerType
	{
		static public var PLAYER:MiniMapMarkerType;
		static public var GROUP:MiniMapMarkerType;
		static public var FRIEND:MiniMapMarkerType;
		static public var PHANTOM_FRIEND:MiniMapMarkerType;  // friends in a different instance of the current zone - useful for warping to them 
		static public var QUEST:MiniMapMarkerType;
		static public var AVAILABLE_QUEST:MiniMapMarkerType;
		static public var GOOFBALL:MiniMapMarkerType;
		static private var UNKNOWN:MiniMapMarkerType;   // useful as a marker if the server (groovy) screws up a type name 

		static private var s_inited:CONSTRUCTORHIDER;   // doubles as an init flag and constructor hider
		static private var s_uiFramework:IUIFramework;
		public static function init(fw:IUIFramework):void
		{
			if (!s_inited)
			{
				s_uiFramework = fw;
				s_inited = new CONSTRUCTORHIDER();

				PLAYER = new MiniMapMarkerType(s_inited, "markerPlayer");
				GROUP = new MiniMapMarkerType(s_inited, "markerGroup");
				FRIEND = new MiniMapMarkerType(s_inited, "markerFriend");
				PHANTOM_FRIEND = new MiniMapMarkerType(s_inited, "markerPhantomFriend");
				QUEST = new MiniMapMarkerType(s_inited, "markerQuest");
				AVAILABLE_QUEST = new MiniMapMarkerType(s_inited, "markerAvailableQuest");
				GOOFBALL = new MiniMapMarkerType(s_inited, "markerGoofBall");
				UNKNOWN = new MiniMapMarkerType(s_inited, "markerOther");
			}
		}
		
		static private var s_custom:Object = {};
		public static function getCustomType(typeName:String):MiniMapMarkerType
		{
			if (!s_inited)
			{
				throw "not yet inited";
			}

			if (!s_custom[typeName] && typeName && typeName.length)
			{
				s_custom[typeName] = new MiniMapMarkerType(s_inited, typeName); 		
			}
			
			const retval:MiniMapMarkerType = s_custom[typeName];
			return retval ? retval : UNKNOWN; 
		}
		
		private var _class:Class;
		public function MiniMapMarkerType(hider:CONSTRUCTORHIDER, className:String)
		{
			if (!hider)
			{
				throw "this class is factory-generated only";
			}
			_class = s_uiFramework.assetFactory.getClass(className);
			if (!_class)
			{
				_class = s_uiFramework.assetFactory.getClass("markerNew");
				if (!_class)
				{
					throw "Minimap marker type unresolved";
				}
			}
		}
		public function getClass():Class { return _class; }
	}
}
internal class CONSTRUCTORHIDER 
{};