package com.gaiaonline.battle.Loot
{
	import com.gaiaonline.battle.ApplicationInterfaces.ILinkManager;
	import com.gaiaonline.battle.ApplicationInterfaces.IUIFramework;
	import com.gaiaonline.battle.gateway.BattleEvent;
	import com.gaiaonline.battle.gateway.BattleGateway;
	import com.gaiaonline.battle.gateway.BattleMessage;
	import com.gaiaonline.battle.map.MapRoom;
	import com.gaiaonline.battle.newactors.ActorManager;
	import com.gaiaonline.battle.newactors.BaseActor;
	import com.gaiaonline.battle.ui.AlertTypes;
	import com.gaiaonline.flexModulesAPIs.globalevent.GlobalEvent;
	import com.gaiaonline.objectPool.ObjectPool;
	import com.gaiaonline.utils.DisplayObjectUtils;
	
	import flash.display.DisplayObject;
	import flash.events.TimerEvent;
	import flash.geom.Point;
	import flash.utils.Dictionary;
	import flash.utils.Timer;
	
	public class LootManager
	{		
		public static var LootUrl:Object = new Object();
		
		private var _lootParticlePool:ObjectPool;
		private var _lootParticlePoolFactory:LootParticlePoolFactory = new LootParticlePoolFactory();
				
		private var lootBatch:Array = new Array();
		
		private var _gateway:BattleGateway = null;
		private var _uiFramework:IUIFramework = null;
		private var _linkManager:ILinkManager = null;
		private var _lootTimers:Dictionary = new Dictionary(true);			
		
		public function LootManager(gateway:BattleGateway, uiFramework:IUIFramework, linkManager:ILinkManager){
			this._gateway = gateway;
			this._uiFramework = uiFramework;
			this._linkManager = linkManager;			
			
			LootUrl["gld"]= {id:"gld", url:this._linkManager.baseURL + "sprites/goldcoin1.swf", type:"gold", name:"gold"};
			LootUrl["gld10"]= {id:"gld10", url:this._linkManager.baseURL + "sprites/goldcoin10.swf", type:"gold", name:"gold"};
			LootUrl["gld100"]= {id:"gld100", url:this._linkManager.baseURL + "sprites/goldcoin100.swf", type:"gold", name:"gold"};						
			_lootParticlePool = new ObjectPool(_lootParticlePoolFactory, _lootParticlePoolFactory, _lootParticlePoolFactory, 15); 
			DisplayObjectUtils.addWeakListener(this._gateway, BattleEvent.ITEM_INFO, onUrl);
			DisplayObjectUtils.addWeakListener(GlobalEvent.eventDispatcher, GlobalEvent.LOOT_PARTICLE_FINISHED, onLootParticleFinished);
						
		}
		
		public function addLoots(msg:Object, target:DisplayObject):void{
			
			if (msg != null){
				var batch:Object = new Object();
				batch.point = new Point(msg.lx, msg.ly);
				batch.items = new Array();
				batch.target = target;
				var gldTotal:int = 0;
				for (var p:String in msg){				
					if (p != "lx" && p != "ly" && p != "cmd" && p != "er" && p != "bmt" && p != "cid" && p != "id" && p != "purchased"){
						var obj:Array = String(msg[p]).split(",");						
						if (obj[0] == "gld"){
							gldTotal += obj[1];
						}
						if (msg.id == ActorManager.getInstance().myActor.actorId){
							var item:Object = {id:obj[0], qt:obj[1], done:LootUrl[obj[0]] != null, purchased: "true" == msg['purchased']};
							batch.items.push(item);					
						}
					}
				}			
				
				if (!this.checkBatch(batch)){
					this.lootBatch.push(batch);
					this.addGsiRequest(batch);
				}else{
					this.playLoots(batch);
				}
				
				if (target is BaseActor && msg.id != ActorManager.getInstance().myActor.actorId){ 
					BaseActor(target).updateGoldLootDisplay(gldTotal);
				}
			}
		}	
		
		private function checkBatch(obj:Object):Boolean{
			var ok:Boolean = true;			
			for (var i:int = 0; i < obj.items.length; i++){				
				if (!obj.items[i].done){
					ok = false;
					break;
				}
			}			
			return ok;
		}
		
		private function addGsiRequest(obj:Object):void{
			var fetchItems:Array = [];
			for (var i:int = 0; i < obj.items.length; i++){				
				if (!obj.items[i].done){
					//----- call GSI to get Item Info					
					fetchItems.push(obj.items[i].id);							
				}
			}
			if(fetchItems.length) {
				var msg:BattleMessage = new BattleMessage("getItemInfo",{ids:fetchItems});
				this._gateway.sendMsg(msg);
			}
		}
		
		private function onUrl(evt:BattleEvent):void{
			if (evt.battleMessage != null && evt.battleMessage.responseObj != null){
				
				var itemList:Array = evt.battleMessage.responseObj as Array;
				if (itemList != null){				
					for (var i:int = 0; i <itemList.length; i++){
						var item:Object = itemList[i];
						if (item.bmt == "itemInfo" && item.id != null){
							LootUrl[item.id] = {id:item.id, url:this._linkManager.getLink("images") + item.itemThumbFile, type:item.itemClass, name:item.name};
							/* if (item.id == 100257){
								LootUrl[item.id].type = "orb"
							}	 */			
							this.updateLootBatch(item.id);			
						}
					}
				}
			}
		}
		
		private var _batchToDelete:Array;
		private function updateLootBatch(itemId:String):void{
			if (!_batchToDelete) {
				this._batchToDelete = new Array();
			} else {
				this._batchToDelete.length = 0;
			}
			
			for (var i:int = 0; i < this.lootBatch.length; i++){
				var batch:Object = this.lootBatch[i];
				for (var ii:int = 0; ii < batch.items.length; ii++){
					if (batch.items[ii].id == itemId){
						batch.items[ii].done = true;
					}
				}
				
				if (this.checkBatch(batch)){
					this.playLoots(batch);
					_batchToDelete.push(batch);
				}								
			}
			
			
			for (var di:int = 0; di < _batchToDelete.length; di++){
				var index:int = this.lootBatch.indexOf(_batchToDelete[di]);
				if (index >= 0){
					this.lootBatch.splice(index, 1);
				}
				
			}
			
		}
					
		private var _lootsMapOffset:Point = new Point(NaN, NaN);
		private function playLoots(obj:Object):void{									
			var m:MapRoom = this._uiFramework.map.getCurrentMapRoom();			
			var scale:Number = 0.75;
			this._lootsMapOffset.x = 0;
			this._lootsMapOffset.y = 0;

			if (m != null){
				scale = m.scale/100;
				this._lootsMapOffset = m.getRoomOffset().clone();
			}
			
			var x:Number = Math.round(int(obj.point.x) * scale) + this._lootsMapOffset.x;
			var y:Number = Math.round(int(obj.point.y) * scale) + this._lootsMapOffset.y;								
			var lootPoint:Point = new Point(x, y);		
					
			var timer:Timer = new Timer(120);
			var particlesQue:Array = new Array();			
			var callInventory:Boolean = false;
			
			for (var i:int = 0; i < obj.items.length; i++){
				var item:Object = obj.items[i];				
				if (LootUrl[item.id] != null){
					this.notify(LootUrl[item.id], item.qt, item.purchased);
					
					if (item.id == "gld"){
						
						var total:int = item.qt;
						var count:int = Math.floor(total/100) + Math.floor((total%100)/10) + (total%100)%10;
						var v:int = 100;
						for (var ii:int = 0; ii < count; ii++){	
							while( total/v < 1){
								v = v/10;
							}	
							total -= v;	
													
							var itemId:String = "gld";
							if (v > 1){
								itemId += v.toString();
							}
							particlesQue.push({url:LootUrl[itemId].url, lootPoint:lootPoint, target:obj.target, scale:scale, value:v, id:"gld"});	
						}						
						
					}else{	
						callInventory = true;
						for (var iii:int=0; iii < item.qt; iii++){									
							particlesQue.push({url:LootUrl[item.id].url, lootPoint:lootPoint, target:obj.target, scale:scale, value:1, id:item.id});					
						}
					}
				}				
			}
			
			this._lootTimers[timer] = particlesQue;			
			timer.addEventListener(TimerEvent.TIMER, onLootTimer);
			timer.start();		
			
			//GlobalEvent.eventDispatcher.dispatchEvent(new GlobalEvent(GlobalEvent.MAP_ADD_LOOT_PARTICLES, {particles:particles}));
			
			///---- Update Loot Inventory			
			if (callInventory){				
				//var bm:BattleMessage = new BattleMessage(BattleEvent.INVENTORY_INFO, null);
				//this._gateway.sendMsg(bm);
				GlobalEvent.eventDispatcher.dispatchEvent(new GlobalEvent(GlobalEvent.INVENTORY_UPDATE, obj));
			}
		}	
		private function onLootTimer(evt:TimerEvent):void{
			if (this._lootTimers[evt.target] != null){
				var particleQue:Array = this._lootTimers[evt.target];		
				var particles:Array = new Array();		
				if (particleQue.length > 0){								
					for (var i:int = 0; i < Math.max(1, particleQue.length/3); i++){				
						var part:Object = particleQue.shift();
						var angle:int = (Math.random() * 180) - 90;
						var pt:LootParticle = _lootParticlePool.checkOut(_lootParticlePoolFactory, [this._uiFramework.loaderContextFactory, part.url, part.lootPoint, part.target, angle, part.scale, part.value, part.id]); 
						particles.push(pt);																			
					}
					GlobalEvent.eventDispatcher.dispatchEvent(new GlobalEvent(GlobalEvent.MAP_ADD_LOOT_PARTICLES, {particles:particles}));
				}else{					
					Timer(evt.target).stop();
					Timer(evt.target).removeEventListener(TimerEvent.TIMER, onLootTimer);
					delete this._lootTimers[evt.target];					
				}		
			}else{
				Timer(evt.target).stop();
				Timer(evt.target).removeEventListener(TimerEvent.TIMER, onLootTimer);
			}
		}
		
			
		private function notify(obj:Object, quantity:Number = 0, purchased:Boolean = false):void{
			
			/// ring,consumable,loot,game,normal,orb,gold;
				
			if (obj != null && obj.type != null){
				switch(obj.type){
					case "recipe":
						GlobalEvent.eventDispatcher.dispatchEvent(new GlobalEvent(GlobalEvent.ALERT, {type:AlertTypes.RECIPE_FOUND, textParam:obj.name}));																						
						break;
					
					case "gold":
						GlobalEvent.eventDispatcher.dispatchEvent(new GlobalEvent(GlobalEvent.ALERT, {type:AlertTypes.RING_EQUIP}));																												
						break;
						
					case "ring":
						GlobalEvent.eventDispatcher.dispatchEvent(new GlobalEvent(GlobalEvent.ALERT, {type:AlertTypes.LOOT_RING}));																																	
						break;
					case "orb":
						GlobalEvent.eventDispatcher.dispatchEvent(new GlobalEvent(GlobalEvent.ALERT, {type:AlertTypes.LOOT_RARE}));																																							
						// all orbs count  and display update should be handle in the playerInfo totalOrbs
						var myActor:BaseActor = ActorManager.getInstance().myActor;
						var orbDrop:Orbs = new Orbs(0, 0);
						// XXX extract the ID into the Orbs class
						if(obj.id == 100257)
						{
							orbDrop.increase(new Orbs(0, quantity));
						}
						else
						{
							orbDrop.increase(new Orbs(quantity, 0));
						}
						myActor.totalOrbs.increase(orbDrop);
						myActor.totalCharge += quantity;
						break;
					case "consumableFound": // drop through
					case "consumable":						
						if(!purchased)
						{
							GlobalEvent.eventDispatcher.dispatchEvent(new GlobalEvent(GlobalEvent.ALERT, {type:AlertTypes.POWER_UP_FOUND}));																																													
						}
						else
						{
							GlobalEvent.eventDispatcher.dispatchEvent(new GlobalEvent(GlobalEvent.ALERT, {type:AlertTypes.POWER_UP_PURCHASED}));																																													
						}
						break;						
					
					case "crystal":
						GlobalEvent.eventDispatcher.dispatchEvent(new GlobalEvent(GlobalEvent.ALERT, {type:AlertTypes.RING_EQUIP}));																																												
						break
					default:
						break;
				}	
			}		
		}
	
		private function onLootParticleFinished(evt:GlobalEvent):void {
			var lootParticle:LootParticle = evt.data.particle;
			if (lootParticle.id == "gld"){			
				ActorManager.getInstance().myActor.updateGoldLootDisplay(lootParticle.value);
			}
			this._lootParticlePool.checkIn(lootParticle, _lootParticlePoolFactory);			
		}
	}
}
	
import com.gaiaonline.battle.Loot.LootParticle;
import com.gaiaonline.objectPool.IObjectPoolFactory;
import com.gaiaonline.objectPool.IObjectPoolDeconstructor;
import com.gaiaonline.objectPool.IObjectPoolCleanUp;
import com.gaiaonline.objectPool.IObjectPoolInitializer;
	

class LootParticlePoolFactory implements IObjectPoolFactory, IObjectPoolDeconstructor, IObjectPoolCleanUp, IObjectPoolInitializer {
	public function LootParticlePoolFactory(){
	}		
	public function create():* {
		return new LootParticle();
	}
	public function deconstruct(obj:*):void{
		var particle:LootParticle = LootParticle(obj);
		if (particle != null){			
			particle.destruct();
		}
	}		
	public function objectPoolCleanUp(obj:*):void{
		var particle:LootParticle = LootParticle(obj);
		if (particle != null){			
			particle.reset();
		}
	}
	public function initializeObjectPool(obj:*, args:Array = null):void {
		var particle:LootParticle = LootParticle(obj);
		if (particle != null) {
			particle.dropLoot.apply(obj, args);
		}
	}	
}

