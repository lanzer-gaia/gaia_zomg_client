package com.gaiaonline.battle.ui
{
	import mx.collections.ArrayCollection;
	import mx.core.Container;
	import mx.events.ModuleEvent;
	import mx.modules.IModuleInfo;
	import mx.modules.ModuleManager;
	
	import qs.caching.ContentCache;
	
	public class FlexUIManagerImpl implements IFlexUiManager {

		private var _modules:Object = {};
		public function FlexUIManagerImpl() {}

		public function getArrayCollection():Object {
			return new ArrayCollection();
		}

		public function getModule(modulePath:String, handler:IAsyncCreationHandler):void
		{
			if (!_modules[modulePath])
			{
				_modules[modulePath] = new ModuleRequestList(modulePath);
			}
			ModuleRequestList(this._modules[modulePath]).add(handler);
		}

		// General utilities		
		public function clearContentCache(cacheName:String):void {				
			var cacheContent:ContentCache = ContentCache.getCache(cacheName);
			cacheContent.clear();
		}				
		
		public function initializeContainer(container:Object):void {
			Container(container).initialize();
		}		
	}
}
	import mx.modules.IModuleInfo;
	import mx.events.ModuleEvent;
	import mx.modules.ModuleManager;
	import flash.events.EventDispatcher;
	import flash.display.DisplayObject;
	import flash.events.Event;
	import com.gaiaonline.battle.ui.IAsyncCreationHandler;
	
class ModuleLoadEvent extends Event
{
	public static const READY:String = "ready";
	public var moduleID:String;
	public function ModuleLoadEvent(moduleID:String)
	{
		super(READY);
		this.moduleID = moduleID;
	}
}
class ModuleEntry extends EventDispatcher
{
	private var _path:String;
	private var moduleInfo:IModuleInfo;
	
	public function ModuleEntry(path:String):void
	{
		this._path = path;
	}
	public function get path():String
	{
		return this._path;
	}
	public function getModule():void
	{
		this.moduleInfo = ModuleManager.getModule("flexModules/" + path);
		this.moduleInfo.addEventListener(ModuleEvent.READY, onModuleReady, false, 0, true);
		this.moduleInfo.load();
	}
	public function create():DisplayObject
	{
		if (this.moduleInfo)
		{
			return DisplayObject(this.moduleInfo.factory.create());
		}
		throw "Module " + path + " invoked before load complete";
	}
	private function onModuleReady(e:ModuleEvent):void
	{
		dispatchReadyEvent();
	}
	private function dispatchReadyEvent():void
	{
		dispatchEvent(new ModuleLoadEvent(path));				
	}
}

class ModuleRequestList
{
	private var moduleEntry:ModuleEntry;
	private var pendingRequests:Array = [];
	public function ModuleRequestList(modulePath:String):void
	{
		this.moduleEntry = new ModuleEntry(modulePath);
		this.moduleEntry.addEventListener(ModuleLoadEvent.READY, onModuleReady, false, 0, true);
	}
	public function add(handler:IAsyncCreationHandler):void
	{
		pendingRequests.push(handler);
		moduleEntry.getModule();
	}
	private function onModuleReady(e:ModuleLoadEvent):void
	{
		for each (var handler:IAsyncCreationHandler in pendingRequests)
		{
			if (handler)
			{
				handler.onCreation(moduleEntry.create(), moduleEntry.path);
			} 
		}
		pendingRequests.length = 0;
	}
}
