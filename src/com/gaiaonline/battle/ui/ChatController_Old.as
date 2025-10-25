package com.gaiaonline.battle.ui
{
	import com.gaiaonline.battle.GlobalColors;
	import com.gaiaonline.battle.emotes.EmoteManagerOld;
	import com.gaiaonline.battle.emotes.EmoteOld;
	import com.gaiaonline.battle.gateway.BattleGateway;
	import com.gaiaonline.battle.gateway.BattleMessage;
	import com.gaiaonline.battle.newactors.ActorManager;
	import com.gaiaonline.battle.newactors.BaseActor;
	import com.gaiaonline.battle.ui.ChatUi.ChatMiniMessage;
	import com.gaiaonline.battle.userinput.ChatManager;
	import com.gaiaonline.flexModulesAPIs.FlexMenuItem;
	import com.gaiaonline.flexModulesAPIs.chat.IChat;
	import com.gaiaonline.flexModulesAPIs.chat.IChatEventHandler;
	import com.gaiaonline.flexModulesAPIs.globalevent.GlobalEvent;
	import com.gaiaonline.flexModulesAPIs.managers.chat.DeSlasher;
	
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.TimerEvent;
	import flash.net.URLRequest;
	import flash.net.navigateToURL;
	import flash.utils.Timer;
	import flash.utils.getTimer;
	
	public class ChatController_Old implements IChatEventHandler
	{
		private static const ABUSE_HISTORY_LENGTH:uint = 50;
		private static const MAX_MSG_LEN:uint = 250; 		
		private static const PROMPT_TEXT:String = "Hit [ENTER] to chat";
		private static const PROMPT_FORMAT:String = "<font color='#999999' face='Arial' size='12'>[prompt]</font>";
		private static const MAX_MSG:uint = 100;		
		private var _view:IChat = null;

		private var _flexUiManagerImpl:IFlexUiManager;
		private var _gateway:BattleGateway;
		private var _emoteManager:EmoteManagerOld;
		private var _emoteHandler:IEmoteEventHandler;
		private var _registerHandler:IRegisterHandler;
		
		private var _sendChannel:String = null;
		private var _lastSendChannel:String = _sendChannel;		
		
		private var _filterArea:Boolean = false;
		private var _filterRoom:Boolean = false;
		private var _filterTeam:Boolean = false;
		private var _filterClan:Boolean = false;
		private var _filterWhisper:Boolean = false;
		private var _filterDialog:Boolean = false;
		private var _filterServer:Boolean = false;		
		
		private var _areaMsgs:Array = new Array();
		private var _roomMsgs:Array = new Array();
		private var _teamMsgs:Array = new Array();
		private var _clanMsgs:Array = new Array();				
		private var _whisperMsgs:Array = new Array();
		private var _dialogMsgs:Array = new Array();
		private var _serverMsgs:Array = new Array();
		
		private var _viewFilters:Array = [];		
		
		private var chat_notify:UiChatNotification;
		public var chat_notify_interval:Timer;
		
		private var _isOpen:Boolean = false;
		private var _isVisible:Boolean = true;		
		private var _isMinimized:Boolean = false;	
		
		private var miniMessages:Array = new Array();
		
		//private var _GIMEnabled:Boolean = false;
		private var _emoteEnabled:Boolean = false;					

		private var _channels:Object = null; // array collection for our channels menu
		private var _viewFiltersData:Object = null; // array collection for our view filters menu

		private var _textDirty:Boolean = false;

		private var _inCrew:Boolean = false;
		private var _inClan:Boolean = false;		
				
		private var _showingWhisperPrompt:Boolean = false;
		
		private var _me:BaseActor = null;
		
		private var _startDate:Date = null;
		
		// Singleton ******************************
		private static var _instance:ChatController_Old
		public static function getInstance(flexUiManagerImpl:IFlexUiManager=null, gateway:BattleGateway=null, emoteManager:EmoteManagerOld=null, emoteHandler:IEmoteEventHandler=null, registerHandler:IRegisterHandler=null):ChatController_Old{
			if (_instance == null){
				if (flexUiManagerImpl == null) {
					throw(new Error("Haven't initialized ChatController"));
				}				
				_instance = new ChatController_Old(new SingletonEnforcer(), flexUiManagerImpl, gateway, emoteManager, emoteHandler, registerHandler);
			}
			return _instance;
		}
		
		public function ChatController_Old(S:SingletonEnforcer, flexUiManagerImpl:IFlexUiManager, gateway:BattleGateway, emoteManager:EmoteManagerOld, emoteHandler:IEmoteEventHandler, registerHandler:IRegisterHandler):void {
			this._flexUiManagerImpl = flexUiManagerImpl;
			this._gateway = gateway;
			this._emoteManager = emoteManager;
			this._emoteHandler = emoteHandler;
			this._registerHandler = registerHandler;
			
			this._startDate = new Date();
			
			
			setup();
		}
		
		public function get startDate():Date {
			return this._startDate;
		}
		
		public function get startTime():Number {
			return this._startDate.time*.001;
		}
		
		private function setup():void {
			this._me = ActorManager.getInstance().myActor;
			this.recordChannelButtonsEnabledState();
						
			this.chat_notify = new UiChatNotification();
			this.chat_notify_interval = new Timer(5000, 1);
			this.chat_notify_interval.addEventListener(TimerEvent.TIMER_COMPLETE, removeChatNotification, false, 0, true);

			this.setRegisterPromptVisible(false);
			
			
			//GIM & EMOTE BUTTONS
			//this._GIMEnabled = true; // just so the shortcircuit in setGIMEnabled won't fire
			//this.setGIMEnabled(false);
			
			this._emoteEnabled = false;
			setEmoteEnabled(true);

			this.onSendChannelChanged("talk");
			
			this.setFilters(this._filterArea, this._filterRoom, this._filterTeam, this._filterClan, this._filterWhisper);

			GlobalEvent.eventDispatcher.addEventListener(GlobalEvent.USER_LEVEL_SET, onUserLevelSet, false, 0, true);
			//GlobalEvent.eventDispatcher.addEventListener(GlobalEvent.GIM_ENABLED_CHANGE, onGimEnabledChange, false, 0, true);			
			GlobalEvent.eventDispatcher.addEventListener(GlobalEvent.WHISPER_AUTOFILL, onWhisperAutofill, false, 0, true);
			GlobalEvent.eventDispatcher.addEventListener(GlobalEvent.CHAT_MINI_MESSAGE_END, onChatMiniMessageEnd, false, 0, true);
			GlobalEvent.eventDispatcher.addEventListener(GlobalEvent.CHAT_MESSAGE_READY, onChatMessageReady, false, 0, true);
			GlobalEvent.eventDispatcher.addEventListener(GlobalEvent.IN_CREW_STATE_UPDATE, onInCrewStateUpdate, false, 0, true);
			GlobalEvent.eventDispatcher.addEventListener(GlobalEvent.CLAN_MEMBERSHIP_UPDATE, onClanMembershipUpdate, false, 0, true);
			GlobalEvent.eventDispatcher.addEventListener(GlobalEvent.PLAYER_CREATED, onPlayerCreated, false, 0, true);																								
		}
		
		private function onPlayerCreated(e:GlobalEvent):void {
			this._me = ActorManager.getInstance().myActor;			
			this.recordChannelButtonsEnabledState();
		}
		
		private function recordChannelButtonsEnabledState():void {
			if (this._me) {
				this._inCrew = (this._me.inCrewState == BaseActor.CREW_STATE_IN);
				this._inClan = (this._me.clanId != null || this._me.clanName != null);
			}
		}

		
		private function onInCrewStateUpdate(e:GlobalEvent):void {
			if (ActorManager.getInstance().isMyActor(e.data._actorId)) { 			
				this._inCrew = (e.data.inCrewState == BaseActor.CREW_STATE_IN);
//				this.toggleChannelEntryEnable("crew", this._inCrew);
			}			 
		}
		
		private function onClanMembershipUpdate(e:GlobalEvent):void {			
			this._inClan = (e.data.clanID != null || e.data.clanName != null);
//			this.toggleChannelEntryEnable("clan", this._inClan);
		}
		
		private function toggleChannelEntryEnable(channelName:String, enabled:Boolean):void {
			var len:uint = this._channels.length;

			for (var i:uint = 0; i < len; ++i) {			
				var flexMenuItem:FlexMenuItem = this._channels.getItemAt(i);
				if (flexMenuItem.label.toLowerCase() == channelName.toLowerCase()) {
					if (flexMenuItem.enabled != enabled) {
						flexMenuItem.enabled = enabled;
						this._channels.itemUpdated(flexMenuItem, !enabled, enabled);
					}
				}								
			}
		}
		
		public function addView(view:IChat):void {
			this._view = view;
			this._view.setMaxInputChars(MAX_MSG_LEN);			
			this._view.setPrompt(PROMPT_TEXT, PROMPT_FORMAT);
			this._view.setEventHandler(this);
			//this._view.setGIMEnabled(this._GIMEnabled);
			
			this._channels = this._flexUiManagerImpl.getArrayCollection();
			var numChannels:uint = s_channelPrettyNames.length;
			for (var i:uint = 0; i < numChannels; ++i) {
				var key:String = s_channelPrettyNames[i];
				var menuItem:FlexMenuItem = new FlexMenuItem(key);
				menuItem.color = ChatManager.s_colorLookup[String(s_channelPrettyNameToCodeName[key]).toLowerCase()];
				this._channels.addItem(menuItem);
				menuItem = new FlexMenuItem("none", "separator");
				this._channels.addItem(menuItem);
			}
			
//			this.toggleChannelEntryEnable("crew", this._inCrew);			
//			this.toggleChannelEntryEnable("clan", this._inClan);						

			// remove the last (extra) separator
			if (this._channels.length > 0){
				this._channels.removeItemAt(this._channels.length -1);
			}

			this._view.setChannels(this._channels, 0); // set "TALK" to be the default selection (we have to skin an index for our separator)
			this._sendChannel = "room";
			
			/*  [Fred ] this has moved to addChanel			
			this._viewFiltersData = this._flexUiManagerImpl.getArrayCollection();				
			addViewFilter("Talk");
			addViewFilter("Shout");			
			addViewFilter("Crew");
			addViewFilter("Clan");
			addViewFilter("Whisper");									
			addViewFilter("Dialog");			
			*/
			
			this._viewFiltersData.removeItemAt(this._viewFiltersData.length - 1);

			this.tryToApplyChatFiltersData();			
			
			this._view.setViewFilters(this._viewFiltersData);
			
			
			this.loadEmotes();
			GlobalEvent.eventDispatcher.addEventListener(GlobalEvent.EMOTES_LOADED, onEmotesLoaded, false, 0, true);
		}

		private function onEmotesLoaded(e:GlobalEvent):void {
			this.loadEmotes();
			GlobalEvent.eventDispatcher.removeEventListener(GlobalEvent.EMOTES_LOADED, onEmotesLoaded);
		}
		
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
		
		private function addViewFilter(name:String):void {
			var flexMenuItem:FlexMenuItem = new FlexMenuItem(name, "gamecheck");
			flexMenuItem.toggled = true;			 
			this._viewFiltersData.addItem(flexMenuItem);
			this._viewFiltersData.addItem(new FlexMenuItem("none", "separator"));
		}

		private var _pendingChatFiltersData:Object = null;
		public function setChatFilters(chatFilters:Object):void {
			this._pendingChatFiltersData = chatFilters;
			this.tryToApplyChatFiltersData();
		}				
		
		private function tryToApplyChatFiltersData():void {
			if (this._viewFiltersData) {
				var len:uint = this._viewFiltersData.length;
				for (var filterName:String in this._pendingChatFiltersData) {
					if (this._pendingChatFiltersData[filterName] == null || this._pendingChatFiltersData[filterName] == undefined) {
						continue;
					}					
					var filterValue:Boolean = this._pendingChatFiltersData[filterName];
					filterName = filterName.substr(0, filterName.length - 6); // they have a suffix of "Filter"
					for (var i:uint = 0; i < len; ++i) {
						// find the menu item in the array collection; the view will pick this up via the colleciton updating mechanism
						var flexMenuItem:FlexMenuItem = this._viewFiltersData.getItemAt(i);
						if (flexMenuItem.label.toLowerCase() == filterName.toLowerCase()) {
							if (filterValue == flexMenuItem.toggled) { // toggled means we should NOT filter the item						
								flexMenuItem.toggled = !filterValue;
								this._viewFiltersData.itemUpdated(flexMenuItem, filterValue, !filterValue);
								// update our filters
								this.handleFilterChange(filterName, filterValue, false);													
							}
						}					
					}
				}
				this._pendingChatFiltersData = null;				
			} 
		}	
			
		private function autoColorTextInput():void {
			if (this._view) {
				var text:String = this._view.getInputText();
				var color:Number = this.getTextAutoColor(text);
				this._view.setInputTextColor(color);
			}
		}
					
		public function getTextAutoColor(text:String):Number
		{
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

		public function onTextLinkClicked(text:String):void {
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
				
		private function setSendChannel(channel:String):void{
			if (channel == "whisper"){
				if (this._channelExplicitlySelectedByUser == "whisper") {
					this._lastSendChannel = "whisper";
				} else {
				this._lastSendChannel = this._sendChannel;
			}				
			}				
			this._sendChannel = channel;
			this.autoColorTextInput();
		}		
		
		private var s_channelPrettyNames:Array = new Array() ; //["Talk", "Shout", "Crew", "Clan", "Whisper"];
		private var s_channelPrettyNameToCodeName:Object = new Object();
		/*
		{
			"Talk" : "room",
			"Shout" : "area",
			"Crew" : "team",
			"Clan" : "clan",
			"Whisper" : "whisper"
		};
		*/
		
		public function addChanel(channelPrettyName:String, chanelCodeName:String):void{
			this.s_channelPrettyNames.push(channelPrettyName);
			this.s_channelPrettyNameToCodeName[channelPrettyName] = chanelCodeName;
			
			if (!this._viewFiltersData){
				this._viewFiltersData = this._flexUiManagerImpl.getArrayCollection();
			}			
			addViewFilter(channelPrettyName);								
			
		}
		
		private var _channelExplicitlySelectedByUser:String = null;
		public function onSendChannelChanged(channelPrettyName:String):void {
			var codeName:String = String(s_channelPrettyNameToCodeName[channelPrettyName]).toLowerCase();
			if (codeName) {
				this._channelExplicitlySelectedByUser = codeName;				
				this.setSendChannel(codeName);
				
				// update our view filters to make sure we show text on this channel
				if (this._viewFiltersData) {
				var len:uint = this._viewFiltersData.length;
				for (var i:uint = 0; i < len; ++i) {
					// find the menu item in the array collection; the view will pick this up via the colleciton updating mechanism
					var flexMenuItem:FlexMenuItem = this._viewFiltersData.getItemAt(i);
					if (flexMenuItem.label.toLowerCase() == channelPrettyName.toLowerCase()) {
						if (!flexMenuItem.toggled) {						
							flexMenuItem.toggled = true;
							this._viewFiltersData.itemUpdated(flexMenuItem, false, true);						
						}
					}					
				}
				// update our filters
				this.onViewFilterChanged(channelPrettyName, false);
			}			
				this.toggleWhisperPromptVisibility(codeName == "whisper");		
		}
		}

		public function onViewFilterChanged(name:String, filtered:Boolean):void {
			handleFilterChange(name, filtered);
		}
		
		private function handleFilterChange(name:String, filtered:Boolean, tellServer:Boolean = true):void {
			this._filterServer = false;
			
			var dirty:Boolean = false;
			switch (name.toLowerCase()){
				case "shout":
					if (this._filterArea != filtered) {					
						this._filterArea = filtered;
						dirty = true;
					}
					break;					
				case "crew":
					if (this._filterTeam != filtered) {
						this._filterTeam = filtered;
						dirty = true;
					}
					break;					
				case "talk":
					if (this._filterRoom != filtered) {
						this._filterRoom = filtered;
						this._filterDialog = filtered;
						dirty = true;
					}
					break;					
				case "clan":
					if (this._filterClan != filtered) {
						this._filterClan = filtered;
						dirty = true;
					}
					break;
					
				case "dialog":
					if (this._filterDialog != filtered) {
						this._filterDialog = filtered;
						dirty = true;
					}
					break;

				case "whisper":
					if (this._filterWhisper != filtered) {
						this._filterWhisper = filtered;
						dirty = true;
					}
					break;
					
				default: // do nothing
					break;
			}			
			
			if (dirty) {
				this._textDirty = true;
				this.setFilters(this._filterArea, this._filterRoom, this._filterTeam, this._filterClan, this._filterWhisper, this._filterServer, this._filterDialog);

				if (tellServer) {
					var viewFilterMap:Object = {"shoutFilter":this._filterArea, "crewFilter":this._filterTeam, "talkFilter":this._filterRoom, "clanFilter":this._filterClan};
					var msg:BattleMessage = new BattleMessage("putNkvp", viewFilterMap);
					this._gateway.sendMsg(msg);
				}
				if (filtered) {				
					this.updateDefaultChannel();
				}
			}						
		}
		
		private function updateDefaultChannel():void {
			var channel:String = null;				
			if (!this._filterRoom) {
				channel = "Talk";
			} else if (!this._filterArea) {
				channel = "Shout";
			} else if (!this._filterTeam) {
				channel = "Crew";
			} else if (!this._filterClan) {
				channel = "Clan";
			} else {
				channel = "Whisper";
			}
			
			if (channel) {
				// find the channel in our channels data provider and set it as the defalut
				var channelsLen:uint = this._channels.length;
				for (var i:uint = 0; i < channelsLen; ++i) {
					var flexMenuItem:FlexMenuItem = this._channels.getItemAt(i);
					if (flexMenuItem.label.toLowerCase() == channel.toLowerCase()) {
						if (this._view) {
							this._view.setToChannel(i);
						}
						break;
					}
				}
				this._sendChannel = String(s_channelPrettyNameToCodeName[channel]).toLowerCase();
				this.autoColorTextInput();
			}
		}							
			
		private function setFilters(area:Boolean, room:Boolean, team:Boolean, clan:Boolean, whisper:Boolean, server:Boolean = false, dialog:Boolean = false):void{
			this._filterArea = area;
			this._filterRoom = room;
			this._filterTeam = team;
			this._filterClan= clan;			
			this._filterWhisper = whisper;
			this._filterDialog = dialog;
			this._filterServer = server;			
			
			this.refreshHistory(true);
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
			
			return "<TEXTFORMAT LEADING='2'><P ALIGN='LEFT'><FONT FACE='Arial' SIZE='11' COLOR='#" + color.toString(16) + "' LETTERSPACING='0' KERNING='0'>" +  message + "</FONT></P></TEXTFORMAT><TEXTFORMAT LEADING='-7'><P></P></TEXTFORMAT>";
		}

		private function refreshHistory(forceScrollToBottom:Boolean = true):void{
			if (!this._textDirty) {
				return;
			}
			
			var filtered:Boolean = true;
			var chatHistory:Array = this.getHistory(filtered);
			var htmlText:String = "";

			/*normal chat*/				
			for (var i:int = 0; i < chatHistory.length ; i++){
				var chat:ChatText = chatHistory[i];
				htmlText += htmlizeChatText(chat);
			}
			
			if (this._view) {
				//this._view.setHistoryHTMLText(htmlText, forceScrollToBottom);
			}

			//create mini message
			if (this._isMinimized && this._isOpen) { 
				chatHistory.reverse();
				if (chatHistory.length > 0){
					var chatMinimized:ChatText = chatHistory[0];
					htmlText = htmlizeChatText(chatMinimized);
					this.miniMessages.push(new ChatMiniMessage(htmlText,DisplayObject(this._view).width-10));
					GlobalEvent.eventDispatcher.dispatchEvent(new GlobalEvent(GlobalEvent.CHAT_MINI_MESSAGE_CREATED, {messages:this.miniMessages}));				
				}
			}
			
			/*chat notification*/
			if(!this._isOpen){
				chatHistory.reverse();
				var txt:String = "";
				for (var t:int = 0; t< 3; t++){
					try{
						var chatClosed:ChatText = chatHistory[t];
						txt += htmlizeChatText(chatClosed);
					}catch(e:Error){
					}
				}
				if (this.getIsVisible()) {
					this.chat_notify.showNotification(txt);
					this.chat_notify_interval.start();
				}
			}
			this._textDirty = false;			
		}	

		private var _chatHistory:Array;
		private function getHistory(filtered:Boolean):Array {
			if (!_chatHistory) {
				this._chatHistory = new Array();
			} else {
				_chatHistory.length = 0;
			}

			if (!filtered || !this._filterArea) _chatHistory = _chatHistory.concat(this._areaMsgs);			
			if (!filtered || !this._filterRoom) _chatHistory = _chatHistory.concat(this._roomMsgs);						
			if (!filtered || !this._filterTeam) _chatHistory = _chatHistory.concat(this._teamMsgs);
			if (!filtered || !this._filterClan) _chatHistory = _chatHistory.concat(this._clanMsgs);			
			if (!filtered || !this._filterWhisper) _chatHistory = _chatHistory.concat(this._whisperMsgs);
			if (!filtered || !this._filterServer)  _chatHistory = _chatHistory.concat(this._serverMsgs);			
			if (!filtered || !this._filterDialog)_chatHistory = _chatHistory.concat(this._dialogMsgs);

			_chatHistory.sortOn("time", Array.NUMERIC);
			
			return _chatHistory;
		}
		
		public function set inputText(text:String):void {
			if (this._view) {
				this._view.setInputText(text);
				this.autoColorTextInput();
			}
		}
		
		public function setFocus():void{
			if (this._view) {
				this._view.setFocus();
			}
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
			
			if (this._sendChannel == "whisper"){
				this.setSendChannel(this._lastSendChannel);
			}			
		}
		
		
		/*
		public function onScrollPositionChange(scrollingUp:Boolean):void {
			if (!this._isMinimized && !scrollingUp) {
				// inject any messages we queued up while the user was scrolling up 
				this.refreshIfBottomScrolled();
			}
		}
		*/
		
		/*
		private function refreshIfBottomScrolled():void
		{
			// Refresh the chat pane if they've scrolled close to the bottom.

			if (this._view && this._view.getScrolledNearToBottom()) { 
				this.refreshHistory(false);
			}	
		}
		*/
		
		private function onChatMessageReady(e:GlobalEvent):void {
			var data:Object = e.data;
			this.addText(data.channel, data.actorId, data.actorName, data.message, data.received, data.fromSystem, data.fromServer, data.slashMe, data.color, data.timestamp, data.errorMessage);
		}
		
		// For most of the channels we send over, we wind up getting the message back, so this addText gets
		// called to show the message on receiving it.  But for whisper, we don't get the message back (unless
		// you whisper to yourself.  Setting the received value to false indicates that the text we're adding
		// is for a sent message.  This will allow us to treat them differently (e.g. adjust their color).
		//
		// Also, we distinguish messages that are from the system (fromSystem) and from the server (fromServer).  fromSystem is true
		// when showing such things as GIM error messages--they're system messages, but weren't sent via our servers.  fromServer is true
		// when showing things that are server-wide messages (e.g. an admin issues a /s command).
		public function addText(type:String, actorId:String, name:String, msg:String, received:Boolean = true, fromSystem:Boolean = false, fromServer:Boolean = false, slashMe:Boolean = false, color:Number = NaN, timestamp:Number = NaN, errorMessage:String = null):void{
			this._textDirty = true;
			
			//[ fred ] removed if clause, all message shoudl get clean .. 
 			//if (!(type == "whisper" && received)) { // if it's not a received whisper
				// then escape tags (so received whispers can accept html)
			
				if (msg){
					msg = msg.split("<").join("&lt;").split(">").join("&gt;");
				}
			//}
			
			var obj:ChatText = new ChatText(type, name, msg, received, fromSystem, fromServer, slashMe, color, timestamp, errorMessage);
			switch (type.toLowerCase()){
				
				case "area":					
					this._areaMsgs.push(obj);					
					if (this._areaMsgs.length > MAX_MSG){
						this._areaMsgs.shift();
					}
					break;
				case "room":
					this._roomMsgs.push(obj);					
					if (this._roomMsgs.length > MAX_MSG){						
						this._roomMsgs.shift();
					}
					break;					
				case "team":
					this._teamMsgs.push(obj);
					if (this._teamMsgs.length > MAX_MSG){
						this._teamMsgs.shift();
					}
					break;
				case "clan":
					this._clanMsgs.push(obj);
					if (this._clanMsgs.length > MAX_MSG){
						this._clanMsgs.shift();
					}
					break;					
				case "whisper":
					this._whisperMsgs.push(obj);
					if (this._whisperMsgs.length > MAX_MSG){
						this._whisperMsgs.shift();
					}
					break;				
				case "dialog":
					this._dialogMsgs.push(obj);
					if (this._dialogMsgs.length > MAX_MSG){
						this._dialogMsgs.shift();
					}
					break;
				case "server":
					this._serverMsgs.push(obj);
					if (this._serverMsgs.length > MAX_MSG){
						this._serverMsgs.shift();
					}					
					// no filtering on server right now					
					break;
					
			}			
			
			
			if ((actorId != "" && actorId == ActorManager.getInstance().myActor.actorId) || type == "dialog") {
				// then you sent it, so scroll
				this.refreshHistory(true);
			}else {
				// Only refresh if they've scrolled to bottom
				this.refreshHistory(false);
			}
		}

		/*
		private function onScroll(e:Event):void
		{
			if (!this._isMinimized) {
				// inject any messages we queued up while the user was scrolling up 
				refreshIfBottomScrolled();
			}
		}
		*/
		
		/*function for removing chat notification window*/
		private function removeChatNotification(e:TimerEvent):void{
			this.chat_notify.removeNotification();
		}
		//@@@ I DON'T REALLY LIKE THIS
		public function set isOpen(v:Boolean):void{
			this._isOpen = v;
		}
		
		public function get isOpen():Boolean{
			return this._isOpen;
		}
		
		public function setIsVisible(visible:Boolean):void {
			this._isVisible = visible;
		}
		
		private function getIsVisible():Boolean {
			return this._isVisible;		
		}		

		private function onUserLevelSet(e:GlobalEvent):void {
			var isGuest:Boolean = e.data.isGuest;	

			this.showRegisterPrompt(isGuest);
			this.setEmoteEnabled(!isGuest);
		}
		

		private function setRegisterPromptVisible(visible:Boolean):void {
			if (this._view) {
				this._view.showGuestReg(visible);
			}
		}

		private function showRegisterPrompt(visible:Boolean):void {
			if (this._view) {
				this._view.showInput(!visible);
				this._view.showGuestReg(visible);
			}
		}
		
		public function onRegister():void {
			this._registerHandler.onRegisteredThroughChat();
		}
		
		/*
		private function onGimEnabledChange(e:GlobalEvent):void {
			var enabled:Boolean = e.data.enabled;
			this.setGIMEnabled(enabled);
		}		
		
		private function setGIMEnabled(enabled:Boolean):void{			
			var myActor:BaseActor = ActorManager.getInstance().myActor;
			var isGuestUser:Boolean = (myActor && myActor.isGuestUser());			
			
			
			if (enabled == this._GIMEnabled) {
				// short circuit if we don't need to do any work
				return;
			}
			this._GIMEnabled = enabled;
			if (this._view) {
				this._view.setGIMEnabled(this._GIMEnabled);
			}	
			
		}	
		*/		
		
		public function onMinimizedStateChanged(minimized:Boolean):void {
			this._isMinimized = minimized;
			if (this._view) {
				this._view.setHistoryVisible(!minimized);			
				this._view.setViewFiltersVisible(!minimized);
			}
		}

		private var _chatLogArray:Array;
		public function getAbuseLog():String {
			var filtered:Boolean = false;
			var chatHistory:Array = getHistory(filtered);
			if (chatHistory.length > ABUSE_HISTORY_LENGTH) {
				chatHistory.splice(0, chatHistory.length - ABUSE_HISTORY_LENGTH);
			}
			
			if (!_chatLogArray) {
				_chatLogArray = new Array();
			} else {
				_chatLogArray.length = 0;
			}
			
			for each (var chat:Object in chatHistory) {
				_chatLogArray.push(chat.name + ": " + chat.msg);
			}
			
			var chatLog:String = _chatLogArray.join(String.fromCharCode(13));
			
			return chatLog;			
		}

		public function getReplyToRecipientName():String {
			var name:String = null;
			var len:int = this._whisperMsgs.length;
			var chat:Object = null;
			for (var i:int = this._whisperMsgs.length - 1; i >=0; --i) {
				if ((this._whisperMsgs[i].name as String) && this._whisperMsgs[i].name.length > 0 && this._whisperMsgs[i].name != ActorManager.getInstance().myActor.actorName) {
					chat = this._whisperMsgs[i];
					break;
				}
			}
			
			if (chat != null) {
				name = chat.name;
			} 
		
			return name;
		}

		private function onWhisperAutofill(e:GlobalEvent):void {
			var data:Object = e.data;
			var actorName:String = data.actorName;
			this.prepareToWhisperTo(actorName);
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

		private function onChatMiniMessageEnd(e:GlobalEvent):void{
			this.miniMessages.shift();
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
		
		public function toggleWhisperPromptVisibility(show:Boolean):void {
			if (show != this._showingWhisperPrompt) {
				this._showingWhisperPrompt = show;
				this._view.showWhisperPrompt(show);
	}
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