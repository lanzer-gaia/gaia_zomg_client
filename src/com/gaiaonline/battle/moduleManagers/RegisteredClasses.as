package com.gaiaonline.battle.moduleManagers
{
	// [kejk] roll these different combinations into a module so not compiling in the byte code?
	public class RegisteredClasses
	{
		private var _actorInfo:ActorInfoModuleManager = null;
		private var _targetInfo:TargetInfoModuleManager = null;
		
		private var _chat:ChatModuleManager = null;
		private var _crewList:CrewListModuleManager = null;
		private var _pda:PDAModuleManager = null;
		private var _actionBarModule:ActionBarModuleManager = null;
		private var _clCapModuleManager:ClCapModuleManager = null;
		private var _adminPanelModuleManager:AdminPanelModuleManager = null;
		
		public function RegisteredClasses()
		{			
		}

	}
}