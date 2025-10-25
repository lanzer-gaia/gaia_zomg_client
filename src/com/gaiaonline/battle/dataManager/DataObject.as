package com.gaiaonline.battle.dataManager
{
	import flash.events.EventDispatcher;
	
	public class DataObject extends EventDispatcher
	{
		static const DATA_LOADED:String = "DataObject_DataLoaded";
		
		
		private var _data:Object = null;
		private var _cmd:String = null;
		private var _loaded:Boolean = false;	
		
		public function DataObject(cmd:String)
		{
			this._cmd = cmd;			
		}
		
		public function get cmd():String{
			return this._cmd;
		}
		
		public function get data():Object{
			return this._data;
		}		
		public function set data(v:Object):void{
			this._data = v;
		}
		
		public function get loaded():Boolean{
			return this._loaded;
		}
		public function set loaded(v:Boolean){
			this._loaded = v;
		}

	}
}