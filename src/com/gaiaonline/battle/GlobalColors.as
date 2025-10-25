package com.gaiaonline.battle
{
	public class GlobalColors
	{
		public static const WHITE:Number = 0xFFFFFF;
		public static const PROMPT_COLOR:Number = 0x999999;

		public static const PINK:Number = 0xF37C7D;
		public static const BLUE:Number = 0x5E5EFF;
		public static const DARK_GREEN:Number = 0x29BC47;
		public static const ORANGE:Number = 0xFF8A00;
		public static const RED:Number = 0xED2622;
		public static const DARK_PURPLE:Number = 0xBA8EFF;
		public static const LIGHT_PURPLE:Number = 0xDAC3FE;	
		public static const LIGHT_GREEN:Number = 0xBBFFC9;


		public static const VERY_LIGHT_GREEN:Number = 0x006606;		
		public static const BEIGE:Number = 0x7F6B00;				
		public static const LIGHT_BLUE:Number = 0x007F7F;
		public static const LIGHT_VIOLET:Number = 0x5B00B8;
		public static const LIGHT_SALMON:Number = 0x950000;


		public static const CON_PURPLE:Number = 0xBA8EFF;
		public static const CON_BLUE:Number = 0x50BAF6;
		public static const CON_GREEN:Number = 0x29BC47;
		public static const CON_YELLOW:Number = 0xffc410;
		public static const CON_RED:Number = 0xed2622;

		public static const AREA_CHANNEL:Number = GlobalColors.PINK;
		public static const ROOM_CHANNEL:Number = GlobalColors.WHITE;
		public static const TEAM_CHANNEL:Number = GlobalColors.BLUE;						
		public static const CLAN_CHANNEL:Number = GlobalColors.ORANGE;
		public static const WHISPER_CHANNEL:Number = GlobalColors.LIGHT_PURPLE;
		public static const SERVER_CHANNEL:Number = GlobalColors.CON_YELLOW;
		public static const DIALOG:Number = GlobalColors.DARK_GREEN;		

		public function GlobalColors() {
		}
		
		private static const _CLCapColor:Number = 0x797979;
		public static function get CLCapColor():Number {
			return _CLCapColor;	
		}		
	}
}