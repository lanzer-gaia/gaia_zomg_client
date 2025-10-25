package com.gaiaonline.battle.ui
{
	import com.gaiaonline.battle.GlobalColors;
	import com.gaiaonline.battle.emotes.EmoteManagerOld;
	import com.gaiaonline.battle.emotes.EmoteOld;
	import com.gaiaonline.battle.gateway.BattleGateway;
	import com.gaiaonline.battle.newactors.ActorManager;
	import com.gaiaonline.battle.ui.ChatUi.ChatMiniMessage;
	import com.gaiaonline.battle.userinput.ChatManager;
	import com.gaiaonline.flexModulesAPIs.FlexMenuItem;
	import com.gaiaonline.flexModulesAPIs.chat.IChat;
	import com.gaiaonline.flexModulesAPIs.chat.IChatEventHandler;
	import com.gaiaonline.flexModulesAPIs.globalevent.GlobalEvent;
	import com.gaiaonline.flexModulesAPIs.managers.chat.DeSlasher;
	
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.events.TimerEvent;
	import flash.net.URLRequest;
	import flash.net.navigateToURL;
	import flash.utils.Dictionary;
	import flash.utils.Timer;
	
	import mx.collections.ArrayCollection;

	public class ChatController implements IChatEventHandler
	{
		private static const ABUSE_HISTORY_LENGTH:uint = 50;
		private static const MAX_MSG_LEN:uint = 250;		
		private static const PROMPT_TEXT:String = "Hit [ENTER] to chat";
		private static const PROMPT_FORMAT:String = "<font color='#999999' face='Arial' size='12'>[prompt]</font>";
		
		
		// Singleton ******************************
		private static var _instance:ChatController;
		public static function getInstance(flexUiManagerImpl:IFlexUiManager=null, gateway:BattleGateway=null, emoteManager:EmoteManagerOld=null, emoteHandler:IEmoteEventHandler=null, registerHandler:IRegisterHandler=null):ChatController{
			if (_instance == null){
				if (flexUiManagerImpl == null) {
					throw(new Error("Haven't initialized ChatController"));
				}				
				_instance = new ChatController(new SingletonEnforcer(), flexUiManagerImpl, gateway, emoteManager, emoteHandler, registerHandler);
			}
			return _instance;
		}
		
		
		
		//***********************************************************************
		//***********************************************************************
		//***********************************************************************
		
		private var _sendChannel:String = "room";
		
		private var _view:IChat = null;
		
		private var _emoteManager:EmoteManagerOld;
		private var _emoteHandler:IEmoteEventHandler;
		private var _emoteEnabled:Boolean = false;
		
		private var s_channelPrettyNames:Array = new Array();
		private var s_channelPrettyNameToCodeName:Dictionary = new Dictionary(true);
		
		private var _viewFiltersData:ArrayCollection = new ArrayCollection();
		private var _viewChannelData:ArrayCollection = new ArrayCollection();
		private var _channelFilters:Array = new Array();
				
		private var _miniMessages:Array = new Array();
		private var _isMinimized:Boolean = false;
		
		private var chat_notify:UiChatNotification;
		public var chat_notify_interval:Timer;
		
		private var _chatReportLog:Array = new Array();
		
		
		public function ChatController(S:SingletonEnforcer, flexUiManagerImpl:IFlexUiManager, gateway:BattleGateway, emoteManager:EmoteManagerOld, emoteHandler:IEmoteEventHandler, registerHandler:IRegisterHandler):void{
			
			this._emoteManager = emoteManager;
			this._emoteHandler = emoteHandler;
			
			
			GlobalEvent.eventDispatcher.addEventListener(GlobalEvent.USER_LEVEL_SET, onUserLevelSet, false, 0, true);		
			GlobalEvent.eventDispatcher.addEventListener(GlobalEvent.WHISPER_AUTOFILL, onWhisperAutofill, false, 0, true);
			GlobalEvent.eventDispatcher.addEventListener(GlobalEvent.CHAT_MINI_MESSAGE_END, onChatMiniMessageEnd, false, 0, true);
			GlobalEvent.eventDispatcher.addEventListener(GlobalEvent.CHAT_MESSAGE_READY, onChatMessageReady, false, 0, true);
			//GlobalEvent.eventDispatcher.addEventListener(GlobalEvent.IN_CREW_STATE_UPDATE, onInCrewStateUpdate, false, 0, true);
			//GlobalEvent.eventDispatcher.addEventListener(GlobalEvent.CLAN_MEMBERSHIP_UPDATE, onClanMembershipUpdate, false, 0, true);
			//GlobalEvent.eventDispatcher.addEventListener(GlobalEvent.PLAYER_CREATED, onPlayerCreated, false, 0, true);			
			
			
			this._startDate = new Date();
			
			this.chat_notify = new UiChatNotification();
			this.chat_notify_interval = new Timer(5000, 1);
			this.chat_notify_interval.addEventListener(TimerEvent.TIMER_COMPLETE, removeChatNotification, false, 0, true);
			
		}
		
			
		public function addView(view:IChat):void {
			this._view = view;
			this._view.setMaxInputChars(MAX_MSG_LEN);			
			this._view.setPrompt(PROMPT_TEXT, PROMPT_FORMAT);
			this._view.setEventHandler(this);
			
			this._view.setViewFilters(this._viewFiltersData);
			this._view.setChannels(this._viewChannelData, 0);
			
			this.loadEmotes();
			GlobalEvent.eventDispatcher.addEventListener(GlobalEvent.EMOTES_LOADED, onEmotesLoaded, false, 0, true);
									
			
		}
				
		
		//******** Add Channel ********************** 
		public function addChanel(channelPrettyName:String, chanelCodeName:String):void{
			this.s_channelPrettyNames.push(channelPrettyName);
			this.s_channelPrettyNameToCodeName[channelPrettyName] = chanelCodeName;
							
			addViewFilter(channelPrettyName);	
						
		}
		private function addViewFilter(name:String):void {
			var flexMenuItem:FlexMenuItem = new FlexMenuItem(name, "gamecheck");
			flexMenuItem.toggled = true;			 
			this._viewFiltersData.addItem(flexMenuItem);
			this._viewFiltersData.addItem(new FlexMenuItem("none", "separator"));
			
			var menuItem:FlexMenuItem = new FlexMenuItem(name);
			menuItem.color = ChatManager.s_colorLookup[String(s_channelPrettyNameToCodeName[name]).toLowerCase()];
			this._viewChannelData.addItem(menuItem);
			menuItem = new FlexMenuItem("none", "separator");
			this._viewChannelData.addItem(menuItem);
									
		}
				
		
		
		//********* Add new Text **************
		public function addText(type:String, actorId:String, name:String, msg:String, received:Boolean = true, fromSystem:Boolean = false, fromServer:Boolean = false, slashMe:Boolean = false, color:Number = NaN, timestamp:Number = NaN, errorMessage:String = null):void{
			
			if (this._view == null){
				return;
			}
			
			if (msg){
				msg = msg.split("<").join("&lt;").split(">").join("&gt;");
			}
			var obj:ChatText = new ChatText(type, name, msg, received, fromSystem, fromServer, slashMe, color, timestamp, errorMessage);
			var htmlText:String = htmlizeChatText(obj);
			this._view.addHtmlText(htmlText, type.toLowerCase());
			
			if ((actorId != "" && actorId == ActorManager.getInstance().myActor.actorId) || type == "dialog") {
				this._view.scrollToBottom();
			}
			
			
			if (this._channelFilters.indexOf(type.toLowerCase()) < 0){
				if (this._isMinimized && this._isOpen){
					this._miniMessages.push(new ChatMiniMessage(htmlText,DisplayObject(this._view).width-10));
					GlobalEvent.eventDispatcher.dispatchEvent(new GlobalEvent(GlobalEvent.CHAT_MINI_MESSAGE_CREATED, {messages:this._miniMessages}));
				}
				if (!this._isOpen) {
					this.chat_notify.showNotification(htmlText);
					this.chat_notify_interval.start();
				}
			}
			
			//**** add to chatReportLog
			this._chatReportLog.push(obj.name + ": " + obj.msg);
			if (this._chatReportLog.length > ABUSE_HISTORY_LENGTH){
				this._chatReportLog.shift();
			}
			
			//***** get last wisper name
			if (type.toLowerCase() == "whisper" && actorId != ActorManager.getInstance().myActor.actorId){
				this._lastWisperName = obj.name;
			}
			
		}
						
		private function removeChatNotification(e:TimerEvent):void{
			this.chat_notify.removeNotification();
		}
		
		public function getAbuseLog():String {
			var chatLog:String = this._chatReportLog.join(String.fromCharCode(13));
			return chatLog;	
		}
		
		private var _lastWisperName:String;
		public function getReplyToRecipientName():String{			
			return this._lastWisperName;
		}
					
		
		public function setFocus():void{
			if (this._view) {
				this._view.setFocus();
			}
		} 
		
		
		
		private var _isVisible:Boolean = true;
		public function setIsVisible(visible:Boolean):void{
			this._isVisible = visible;
		}		
		private function getIsVisible():Boolean {
			return this._isVisible;		
		}	
		
			
		public function set inputText(text:String):void {
			if (this._view) {
				this._view.setInputText(text);
				this.autoColorTextInput();
			}
		}
		private function autoColorTextInput():void {
			if (this._view) {
				var text:String = this._view.getInputText();
				var color:Number = this.getTextAutoColor(text);
				this._view.setInputTextColor(color);
			}
		}
						
		private function prepareToWhisperTo(userName:String = null):void {
			if(ActorManager.getInstance().myActor.isGuestUser())
			{
				GlobalEvent.eventDispatcher.dispatchEvent(new GlobalEvent(GlobalEvent.INVALID_GUEST_OPERATION, {}));
				return;	
			}
			
			if (userName == null) {
				userName = this.getReplyToRecipientName();
			}		
			
			if (userName == null) {
				return;
			}				
			
			this.setSendChannel("whisper");
			
			userName = canonicalizeName(userName);
			this._view.setInputText(DeSlasher.WHISPER_PREFIX  + " " + userName + " ");
			
		}
		private function canonicalizeName(userName:String):String {
			// We can't allow spaces when whispering to a target user, since then we can't parse the username
			// from the message.  Fortunately, our back-end code treats a name with underscores replacing spaces
			// as the same name as with the spaces.  
			return userName.split(" ").join("_");				
		}
		private function setSendChannel(channel:String):void{	
								
			this._sendChannel = channel;
			this.autoColorTextInput();
			
			toggleFilterOn(channel);
			
		}	
		
		
		private function toggleFilterOn(name:String):void{
						
			var index:int = this._channelFilters.indexOf(name);
			if (index >= 0){
				this._channelFilters.splice(index, 1);
			}				
			this._view.setChannelFilter(name, false);
			
			for each (var menuItem:FlexMenuItem in this._viewFiltersData){
				if (this.s_channelPrettyNameToCodeName[menuItem.label] == name){
					menuItem.toggled = true;
					this._viewFiltersData.itemUpdated(menuItem, false, true); 
				}
			}
		}
		
						
		// *************************************************
		//***** Global Event listener
		//**************************************************
		private function onUserLevelSet(e:GlobalEvent):void {
			var isGuest:Boolean = e.data.isGuest;		
			this.showRegisterPrompt(isGuest);
			this.setEmoteEnabled(!isGuest);
			
		}
		private function showRegisterPrompt(visible:Boolean):void {
			if (this._view) {
				this._view.showInput(!visible);
				this._view.showGuestReg(visible);
			}
		}
		
		private function onWhisperAutofill(e:GlobalEvent):void{
			var data:Object = e.data;
			var actorName:String = data.actorName;
			this.prepareToWhisperTo(actorName);
		}
		
			
		private function onChatMiniMessageEnd(e:GlobalEvent):void{
			this._miniMessages.shift();
		}
		
		
		private function onChatMessageReady(e:GlobalEvent):void {
			var data:Object = e.data;
			this.addText(data.channel, data.actorId, data.actorName, data.message, data.received, data.fromSystem, data.fromServer, data.slashMe, data.color, data.timestamp, data.errorMessage);
		}
			
		
		//**************************************************
		// ***********  Load Emotes
		//**************************************************
		private function loadEmotes():void {
			var emotes:Array = [];
			var e:EmoteOld;
			for each (e in this._emoteManager.emotes) {
				if(e.order > -1)
				{
					emotes.push(e);
				}
			}
			emotes = emotes.sortOn("order", Array.NUMERIC);
			
			var emoteIcons:Array = [];
			for each (e in emotes) {
				var icon:Sprite = e.getEmoteIcon();
				icon.name = e.id;
				emoteIcons.push(icon);
			}			
			
			this._view.setEmotes(emoteIcons);	
			this._view.enableEmotes(true);
		}		
		private function onEmotesLoaded(e:GlobalEvent):void {
			this.loadEmotes();
			GlobalEvent.eventDispatcher.removeEventListener(GlobalEvent.EMOTES_LOADED, onEmotesLoaded);
		}
		
		private function setEmoteEnabled(enabled:Boolean):void{
			if (enabled == this._emoteEnabled) {
				// short circuit if we don't need to do any work
				return;
			}
			this._emoteEnabled = enabled;
			if (this._view) {
				this._view.enableEmotes(enabled);
			}
		}	
		
		//**************************************************
		// ***********  IChatEventHandler implements
		//**************************************************
		
		public function onTextLinkClicked(text:String):void{
			if(ActorManager.getInstance().myActor.isGuestUser()) {
				GlobalEvent.eventDispatcher.dispatchEvent(new GlobalEvent(GlobalEvent.INVALID_GUEST_OPERATION, {}));
				return;
			}
			const httpPrefix:String = "http://";
			var txtPrefix:String = text.substring(0, httpPrefix.length);
			if (txtPrefix == httpPrefix) {
				var urlRequest:URLRequest = new URLRequest(text);
				navigateToURL(urlRequest, "_blank");							
			}			
		}
						
		public function getTextAutoColor(text:String):Number{
			// deslash the text, see if it's a command, and change our color accordingly.
			var deslasher:DeSlasher = new DeSlasher(text);
			const charsInTheCommand:int = deslasher.rawText.length - deslasher.deSlashedText.length;
			var currentChannel:String;
			if (charsInTheCommand)
			{
				currentChannel = ChatManager.mapSlashToChannel(deslasher.channel);
				if (currentChannel == "none") {
					currentChannel = this._sendChannel;
				}
			}
			else
			{
				currentChannel = this._sendChannel;
			}
			return typeColor(currentChannel, false, false, false, NaN);
		}
		
		public function sendChat(text:String):void{
			if (ActorManager.getInstance().myActor.isGuestUser()) {
				return;		// no can do, just to be sure
			}
			
			var msg:String = "";			
			var m:Array  = text.split(  String.fromCharCode(13) );
			for (var i:int = 0; i < m.length; i++){
				msg += m[i];
			}
			
			if (this._view) {
				this._view.setInputText("");
			}
						
			GlobalEvent.eventDispatcher.dispatchEvent(new GlobalEvent(GlobalEvent.CHAT_SEND, {channel:this._sendChannel, msg:msg } ));
									
			toggleFilterOn(this._sendChannel);
		}
		
		public function onSendChannelChanged(channelPrettyName:String):void{
			
			this.setSendChannel(this.s_channelPrettyNameToCodeName[channelPrettyName]);
			
			this._view.showWhisperPrompt(this._sendChannel == "whisper");
		}
				
		public function onViewFilterChanged(name:String, toggled:Boolean):void{
			var codeName:String = this.s_channelPrettyNameToCodeName[name];
			
			var index:int = this._channelFilters.indexOf(codeName);
			if (toggled && index < 0){
				this._channelFilters.push(codeName);			
			}else if (!toggled && index >= 0){
				this._channelFilters.splice(index, 1);
			}
			
			this._view.setChannelFilter(codeName, toggled);			
			
		}
		
		public function onMinimizedStateChanged(minimized:Boolean):void{
			this._isMinimized = minimized;
			if (this._view) {
				this._view.setHistoryVisible(!minimized);			
				this._view.setViewFiltersVisible(!minimized);
			}
		}
		
		public function onEmote(emoticonID:String):void {
			if (_emoteHandler) {
				_emoteHandler.onEmoteActivated(emoticonID);
			}
		}
		
		public function onEmotePopupChange(opening:Boolean):void {
			if (_emoteHandler) {
				_emoteHandler.onEmotePopupChange(opening);
			}
		}
		
		public function onRegister():void{
			//[Fred]  not needed 
			// this._registerHandler.onRegisteredThroughChat();
		}
				
		//**************************************************
		// ***********  helper functions
		//**************************************************				
		static private function typeColor(type:String, received:Boolean, fromSystem:Boolean, fromServer:Boolean, setColor:Number):int {
			//trace(type, received, fromSystem, fromServer, setColor);			
			if (!isNaN(setColor)) {
				return setColor;
			}
			if (fromSystem || fromServer)
			{
				return GlobalColors.RED;				
			}
			
			if (type == "whisper")
			{
				return received ? (GlobalColors.DARK_PURPLE) : GlobalColors.LIGHT_PURPLE;
			}
			
			if (type != null) {
				var color:Object = ChatManager.s_colorLookup[type.toLowerCase()];
				if (color != null) {
					return int(color);
				}
			}
			// by default, return white
			return GlobalColors.WHITE; 
		}
		
		private static var _sPattern:RegExp = new RegExp(":[0-5][0-9]\\s");
		private static function htmlizeChatText(chat:ChatText):String
		{
			var color:int = typeColor(chat.type, chat.received, chat.fromSystem, chat.fromServer, chat.color);				
			var message:String = chat.msg;
			var isError:Boolean = false;
			if (!chat.fromSystem && !chat.slashMe && chat.name != null && chat.name != "") {
				// FS#19959: So there's a weird Flash HTML rendering bug.  The problem only shows up 
				// if we bold the name, and if the name is longish--in that case, Flash seems to lose 
				// about a half a character width, making a single space between the colon
				// and the message seem to disappear.  So I've added two spaces after the colon.  
				// For cases where there is no bug, it doesn't look odd, and for places where the bug 
				// shows up, the space and a half is hardly noticeable as slightly smaller, 
				// and we have a gap between the colon and the message.
				// -- Mark Rubin
				var toString:String = (!chat.received && chat.type == "whisper") ? "to " : ""; 
				if (chat.received && !isNaN(chat.timestamp) && chat.timestamp < _instance.startTime) {	// offline message
					var time:Date = new Date(chat.timestamp*1000);
					// messages older than a year get punted
					// time in UTC
					var localTime:String = null;
					if (time.getDate() == _instance.startDate.getDate() && time.getMonth() == _instance.startDate.getMonth()) {
						localTime = time.toLocaleTimeString();
					} else {
						localTime = time.toLocaleString();
					}
					
					localTime = localTime.replace(_sPattern, " ");
					message = "<I>" +  toString + chat.name + " ("+localTime+"): " + message + "</I>";
				} else {
					message = "<B>" +  toString + chat.name + ":</B>  " + message;
				}
			} else if (chat.type == "whisper" && (chat.errorMessage && chat.errorMessage.length)) {	// whispered to an unknown recipient
				color = 0xFF0000;
				isError = true;
				message = chat.errorMessage;	
			}
			
			/*making lite green color for current user*/
			if((chat.type == "dialog") && (chat.name == ActorManager.getInstance().myActor.actorName)){
				color = 0x90EE90;
			}
			
			if (chat.fromSystem || chat.slashMe || isError)
			{
				// bold it
				message = "<B>" + message + "</B>";
			}
			
			//return "<TEXTFORMAT LEADING='2'><P ALIGN='LEFT'><FONT FACE='Arial' SIZE='11' COLOR='#" + color.toString(16) + "' LETTERSPACING='0' KERNING='0'>" +  message + "</FONT></P></TEXTFORMAT><TEXTFORMAT LEADING='-7'><P></P></TEXTFORMAT>";
			return "<FONT FACE='Arial' SIZE='11' COLOR='#" + color.toString(16) + "' LETTERSPACING='0' KERNING='0'>" +  message + "</FONT>";
		}
		
		
		
		//**************************************************
		// ***********  Public properties
		//**************************************************		
		private var _isOpen:Boolean = false;
		public function set isOpen(v:Boolean):void{
			this._isOpen = v;
		}		
		public function get isOpen():Boolean{
			return this._isOpen;
		}
		
		
		private var _startDate:Date = null;
		public function get startDate():Date {
			return this._startDate;
		}		
		public function get startTime():Number {
			return this._startDate.time*.001;
		}
		
	}
}



import flash.utils.getTimer;

final class ChatText
{
	public var type:String;
	public var name:String;
	public var msg:String;
	public var received:Boolean;
	public var fromSystem:Boolean;
	public var fromServer:Boolean;
	public var slashMe:Boolean;
	public var color:Number; 
	public var time:int;
	public var timestamp:Number;	// when the message was originally sent - whisper
	public var errorMessage:String;
	public function ChatText(type:String, name:String, msg:String, received:Boolean, fromSystem:Boolean, fromServer:Boolean, slashMe:Boolean, color:Number, timestamp:Number, errorMessage:String)
	{
		this.type = type;
		this.name = name;
		this.msg = msg;
		this.received = received;
		this.fromSystem = fromSystem;
		this.fromServer = fromServer;
		this.slashMe = slashMe;
		this.color = color;
		this.time = getTimer();
		this.timestamp = timestamp;	// sent over in seconds
		this.errorMessage = errorMessage;
	}
}

class SingletonEnforcer { }