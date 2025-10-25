package com.gaiaonline.battle.jabberchat
{
	import com.gaiaonline.battle.gateway.BattleEvent;
	import com.gaiaonline.battle.gateway.BattleMessage;
	import com.gaiaonline.flexModulesAPIs.gatewayInterfaces.IBattleEvent;
	import com.gaiaonline.flexModulesAPIs.gatewayInterfaces.IBattleGateway;
	import com.hurlant.crypto.tls.TLSConfig;
	import com.hurlant.crypto.tls.TLSEngine;
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.TimerEvent;
	import flash.system.Security;
	import flash.utils.Dictionary;
	import flash.utils.Timer;
	
	import org.igniterealtime.xiff.conference.JabberRoom;
	import org.igniterealtime.xiff.core.UnescapedJID;
	import org.igniterealtime.xiff.core.XMPPTLSConnection;
	import org.igniterealtime.xiff.data.Message;
	import org.igniterealtime.xiff.data.Presence;
	import org.igniterealtime.xiff.events.ConnectionSuccessEvent;
	import org.igniterealtime.xiff.events.DisconnectionEvent;
	import org.igniterealtime.xiff.events.IncomingDataEvent;
	import org.igniterealtime.xiff.events.LoginEvent;
	import org.igniterealtime.xiff.events.MessageEvent;
	import org.igniterealtime.xiff.events.OutgoingDataEvent;
	import org.igniterealtime.xiff.events.PresenceEvent;
	import org.igniterealtime.xiff.events.RoomEvent;
	import org.igniterealtime.xiff.events.XIFFErrorEvent;
	
	public class JabberGateway extends EventDispatcher
	{
		private static var _instance:JabberGateway
		public static function getInstance(battleGateway:IBattleGateway = null):JabberGateway{
			if (!_instance && battleGateway){
				_instance = new JabberGateway(battleGateway);		
			}
			return _instance;
		}
		
		//*****************************************************
		//*****************************************************	
		
		public static const MESSAGE_RECEIVED:String = "JabberGatewayMessageRecieved";
		
		private var _battleGateway:IBattleGateway;
		private var _connection:XMPPTLSConnection;
		private var _server:String;
		private var _password:String;
		private var _userId:String;
		
		private var _userIdMap:Dictionary = new Dictionary(true);
		private var _userSquashNameMap:Dictionary = new Dictionary(true);
		
		private var _sendMsgQueue:Dictionary = new Dictionary(true);
		private var _receivedMsgQueue:Dictionary = new Dictionary(true);
		
		private var _connectionTimer:Timer;
		private var _reconnect:Boolean = true;
				
		private var _channels:Dictionary = new Dictionary(true);
		private var _roomNamesToChannel:Dictionary = new Dictionary(true);
		
		public function JabberGateway(battleGateway:IBattleGateway)
		{	
			trace("[JabberGateway constructor]")	
			this._battleGateway = battleGateway;
			this._battleGateway.addEventListener(BattleEvent.ZOMG_LOGIN, onZomgLogin);
			this._battleGateway.addEventListener(BattleEvent.CONNECTION_LOST, onBattleGatewayConnectionLost);
			this._battleGateway.addEventListener(BattleEvent.USER_LOOKUP, onUserInfo);
			this._battleGateway.addEventListener(BattleEvent.JABBER_CHAT_ROOM_SPECS, onJabberChatRoomSpec);
			
			
			this._connection = new XMPPTLSConnection;
			_connection.port = 5222;
			
			//****** this should not bee need once we have the real certificate from the site
			var tlsConfig:TLSConfig = new TLSConfig(TLSEngine.CLIENT);
			tlsConfig.trustAllCertificates = true;
			_connection.config = tlsConfig;
			
			_connection.tls = true;
			
			_connection.addEventListener(DisconnectionEvent.DISCONNECT, onDisconnect);
			_connection.addEventListener(PresenceEvent.PRESENCE, onPresence);
			_connection.addEventListener(MessageEvent.MESSAGE, onMessage);
			_connection.addEventListener(OutgoingDataEvent.OUTGOING_DATA, onOutgoingData);
			_connection.addEventListener(ConnectionSuccessEvent.CONNECT_SUCCESS, onConnected);
			_connection.addEventListener(IncomingDataEvent.INCOMING_DATA, onIncommingData);
			_connection.addEventListener(LoginEvent.LOGIN, onLogin);
			_connection.addEventListener(XIFFErrorEvent.XIFF_ERROR, onError);	
			
			this._connectionTimer = new Timer(30000);
			this._connectionTimer.addEventListener(TimerEvent.TIMER, onConnectionTimer);
			
		}	
		
		public function sendMsg(msg:JabberMessage):void{
			
			if (this._connection.isLoggedIn()){
				if (this._userSquashNameMap[msg.squashName] != null && this._userSquashNameMap[msg.squashName].status == "done"){
					msg.displayName = this._userSquashNameMap[msg.squashName].displayName;
					
					if (msg.channel == null) {/// whisper
						this.sendJabberMsg(this._userSquashNameMap[msg.squashName].value, msg.txt);
						msg.dispatchEvent(new Event(JabberMessage.MESSAGE_READY));
					}else{ ///  send to a room
						this.sendJabberMsgToChannel(msg.channel, msg.txt);
					}			
					
				}else{
					this.addToSendQueue(msg);
					if (this._userSquashNameMap[msg.squashName] == null){
						this.getUserInfo(msg.squashName);
					}
				}
			}else{
				msg.isError = true;
				msg.txt = "You are not loged into Jabber";
				msg.dispatchEvent(new Event(JabberMessage.MESSAGE_READY));
				
				//var je:JabberEvent = new JabberEvent(MESSAGE_RECEIVED);
				//je.errorMsg = "You are not loged into Jabber";
				//this.dispatchEvent(je);		
			}
		}
		
		private function sendJabberMsg(userId:String, msg:String):void{
			var jid:UnescapedJID = new UnescapedJID(userId+"@"+this._server);
			var jMsg:Message = new Message(jid.escaped , null, msg , null, Message.TYPE_CHAT);			
			this._connection.send( jMsg );
		}
		
		private function sendJabberMsgToChannel(channel:String, msg:String):void{
			var room:JabberRoom = this._channels[channel] as JabberRoom;				
			if (room){
				trace(room.isActive);
				room.sendMessage(msg);				
			}
		}
		
		
		
		public function disconnect():void{
			this._connection.disconnect();
		}
		
		//*****************************************************
		//****  Battle Sever methods
		//*****************************************************
		private function onJabberChatRoomSpec(evt:IBattleEvent):void{
			
			trace("[JabberGateway onJabberChatRoomSpec]")
			for each (var obj:Object in evt.battleMessage.responseObj){
				
				
				if (!this._channels[obj.chatChannel]){
					var room:JabberRoom = new JabberRoom(this._connection);
					room.roomJID = new UnescapedJID( obj.name );					
					this._channels[obj.chatChannel] = room;
					this._roomNamesToChannel[room.roomName] = obj.chatChannel;
					
					room.addEventListener(RoomEvent.GROUP_MESSAGE, onRoomGroupMessage);
					
					room.addEventListener(RoomEvent.ADMIN_ERROR, onRoomError);
					room.addEventListener(RoomEvent.BANNED_ERROR, onRoomError);
					room.addEventListener(RoomEvent.LOCKED_ERROR, onRoomError);
					room.addEventListener(RoomEvent.MAX_USERS_ERROR, onRoomError);
					room.addEventListener(RoomEvent.PASSWORD_ERROR, onRoomError);
					room.addEventListener(RoomEvent.REGISTRATION_REQ_ERROR, onRoomError);
					room.addEventListener(RoomEvent.NICK_CONFLICT, onRoomNickConflict);
					
					if (this._connection.isLoggedIn()){
						room.join();
					}
					
				}
			}
		
		}
		
		private function onZomgLogin(evt:IBattleEvent):void{
			trace("[JabberGateway onZomgLogin]")			
			///****** test			
			//this.addUser("fredtest", "fredtest");
			
			var data:Object = evt.battleMessage.responseObj[0];
			
			this._server = data.xmppServer; //"zomg-chat-dev.gaiaonline.com";
			this._userId = data.id; //1974013
			this._password = data.xmppPass;//"11470997c6ffd7fb464222ef329e81fe"
			
			Security.loadPolicyFile("xmlsocket://" + this._server + ":5222");
			
						
			_connection.useAnonymousLogin = false;
			_connection.username = this._userId;
			_connection.password = this._password;
			_connection.server = this._server;					
			_connection.connect();
		}
		
		private function getUserInfo(userInfo:String):void{
			///******** send server request
			var msg:BattleMessage = new BattleMessage("userLookup", {lookup:userInfo});
			this._battleGateway.sendMsg(msg);
		}
		
		private function onUserInfo(evt:IBattleEvent):void{
			
			if (evt.battleMessage.responseObj[0].error){				
				/*
				var je:JabberEvent = new JabberEvent(MESSAGE_RECEIVED);
				je.errorMsg = evt.battleMessage.responseObj[0].errorMessage;
				this.dispatchEvent(je);
				*/
				
				//****** clean the queue and update msg with error
				if (evt.battleMessage.responseObj[0].lookup){
					var lookup:String = JabberMessage.getSquashName(evt.battleMessage.responseObj[0].lookup);						
					if (this._sendMsgQueue[lookup]){
						for each(var msg:JabberMessage in this._sendMsgQueue[lookup]){
							msg.isError = true;
							msg.txt = evt.battleMessage.responseObj[0].errorMessage;						
							msg.dispatchEvent(new Event(JabberMessage.MESSAGE_READY));
						}
						delete this._sendMsgQueue[lookup];
					}
				}
				
			}else{			
				var displayName:String = evt.battleMessage.responseObj[0].name
				var userId:String = evt.battleMessage.responseObj[0].id;
				var squashName:String = JabberMessage.getSquashName(displayName);
				
				this._userIdMap[userId] = {value:squashName, status:"done", displayName:displayName};
				this._userSquashNameMap[squashName] = {value:userId, status:"done", displayName:displayName};
				
				this.clearQueue(squashName, userId, displayName);
			}
			
		}
					
		
		private function onBattleGatewayConnectionLost(evt:IBattleEvent):void{
			this._reconnect = false;
			this.disconnect();
		}
		
		//*****************************************************
		//****  Queue methods
		//*****************************************************
		private function addToSendQueue(msg:JabberMessage):void{
			if (!this._sendMsgQueue[msg.squashName]){
				this._sendMsgQueue[msg.squashName] = new Array();
			}
			this._sendMsgQueue[msg.squashName].push(msg);
		}
		
		private function addToReceivedQueue(userId:String, msg:String, timeStamp:Date = null, channel:String = null):void{
			if (!this._receivedMsgQueue[userId]){
				this._receivedMsgQueue[userId] = new Array();
			}
			this._receivedMsgQueue[userId].push({timeStamp:timeStamp, msg:msg, channel:channel});
		}
				
		private function clearQueue(squashName:String, userId:String, displayName:String):void{
			
			//****** send msg
			if (this._sendMsgQueue[squashName]){
				for each(var msg:JabberMessage in this._sendMsgQueue[squashName]){
					msg.displayName = displayName;
					if (msg.channel == null){
						this.sendJabberMsg(userId, msg.txt);
						msg.dispatchEvent(new Event(JabberMessage.MESSAGE_READY));
					}else{
						this.sendJabberMsgToChannel(msg.channel, msg.txt);
					}				
				}
				delete this._sendMsgQueue[squashName];
			}
			
			//*** received msg
			if (this._receivedMsgQueue[userId]){
				for each(var receivedMsg:Object in this._receivedMsgQueue[userId]){
					var je:JabberEvent = new JabberEvent(MESSAGE_RECEIVED);
					je.fromUserId = userId;
					je.fromUserName = squashName;
					je.msg = receivedMsg.msg;
					je.timeStamp = receivedMsg.timeStamp;
					je.channel = receivedMsg.channel;
					this.dispatchEvent(je);
				}
				delete this._receivedMsgQueue[userId];
			}
		}
				
		//*****************************************************
		//****  Jabber Rooms Event Handlers
		//*****************************************************
		private function onRoomGroupMessage(evt:RoomEvent):void{
			
			var room:JabberRoom = evt.target as JabberRoom;
			if (room){
				var userId:String = evt.nickname;
								
				if (this._userIdMap[userId] != null && this._userIdMap[userId].status == "done"){				
					var je:JabberEvent = new JabberEvent(MESSAGE_RECEIVED);
					je.fromUserId = userId;
					je.fromUserName = this._userIdMap[userId].displayName;
					je.msg = evt.data.body;
					je.timeStamp = evt.data.time;
					je.channel = this._roomNamesToChannel[room.roomName];
					this.dispatchEvent(je);				
				}else{
					this.addToReceivedQueue(userId, evt.data.body, evt.data.time, this._roomNamesToChannel[room.roomName]);
					if (this._userIdMap[userId] == null){
						this.getUserInfo(userId);
					}
				}
			}
		}
		
		
		private function onRoomError(evt:RoomEvent):void{
			trace("[JabberGateway onRoomError] ", evt.type, evt.errorCode, evt.errorType, evt.errorCondition, evt.errorMessage)
		}
		private function onRoomNickConflict(evt:RoomEvent):void{
			trace("[JabberGateway onRoomNickConflict] ")
		}
		
		public function containChannel(channelName:String):Boolean{
			return this._channels[channelName] != null;
		}
		
		//*****************************************************
		//****  Jabber Connection Event Handlers
		//*****************************************************
		private function onLogin(e:LoginEvent):void
		{
			trace("[JabberGateway onLogin]");
			var presence:Presence = new Presence( null, _connection.jid.escaped, Presence.SHOW_CHAT, null, null, 1);
			_connection.send(presence);
			
			for each (var room:JabberRoom in this._channels){
				if (!room.isActive){
					room.join();
				}
			}
		}
		
		private function onMessage(evt:MessageEvent):void{
			trace("[JabberGateway onMessage]", evt.data.from +": " + evt.data.body);	
			
			var userId:String = evt.data.from.toString().split("@")[0];
			if (this._roomNamesToChannel[userId]){ // check that this is not a room chat 
				return;
			}
			
			if (this._userIdMap[userId] != null && this._userIdMap[userId].status == "done"){				
				var je:JabberEvent = new JabberEvent(MESSAGE_RECEIVED);
				je.fromUserId = userId;
				je.fromUserName = this._userIdMap[userId].displayName;
				je.msg = evt.data.body;
				je.timeStamp = evt.data.time;
				this.dispatchEvent(je);				
			}else{
				this.addToReceivedQueue(userId, evt.data.body, evt.data.time);
				if (this._userIdMap[userId] == null){
					this.getUserInfo(userId);
				}
			}
		}
		
		
		
						
		
		private function onOutgoingData(evt:OutgoingDataEvent):void{	
			trace("[JabberGateway onOutgoingData]", evt.data);			
		}
		private function onIncommingData(evt:IncomingDataEvent):void{
			trace("[JabberGateway onIncommingData]", evt.data);
		}
		private function onConnected(evt:ConnectionSuccessEvent):void{
			//trace("[JabberGateway onConnected]");
			this._connectionTimer.stop();
		}
		private function onDisconnect(evt:DisconnectionEvent):void{
			//trace("[JabberGateway onDisconnect]");
			
			var je:JabberEvent = new JabberEvent(MESSAGE_RECEIVED);			
			je.errorMsg = "Connection to jabber lost";			
			this.dispatchEvent(je);		
			
			if (this._reconnect && !this._connectionTimer.running){
				this._connectionTimer.start();
			}
		}	
		private function onPresence(evt:PresenceEvent):void{
			//trace("[JabberGateway onPresence]");
		}
						
		private function onError(e:XIFFErrorEvent):void
		{
			trace("[JabberGateway onError]", e.errorCode, e.errorMessage);
			
			var je:JabberEvent = new JabberEvent(MESSAGE_RECEIVED);
			je.errorMsg = "Jabber error ["+e.errorCode+"] : " + e.errorMessage;
			this.dispatchEvent(je);
		
		}
		
		///*****
		private function onConnectionTimer(evt:TimerEvent):void{
			trace("[JabberGateway onConnectionTimer]", this._connection.isLoggedIn())
			if (!this._connection.isLoggedIn()){				
				this._connection.connect();
			}else{
				this._connectionTimer.stop();
			}
		}
		
		
		
		
	}
}