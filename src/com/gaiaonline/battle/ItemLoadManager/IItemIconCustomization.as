package com.gaiaonline.battle.ItemLoadManager
{
	public interface IItemIconCustomization
	{
		function getLockedSlotTooltipText():String;
		function getDefaultTooltip(itemIcon:ItemIcon):String;
		function getItemUpdateEventType():String; 					
	}
}