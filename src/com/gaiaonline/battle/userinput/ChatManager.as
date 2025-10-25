package com.gaiaonline.battle.userinput
{
	import com.adobe.utils.StringUtil;
	import com.gaiaonline.battle.ApplicationInterfaces.ILinkManager;
	import com.gaiaonline.battle.ApplicationInterfaces.IUIFramework;
	import com.gaiaonline.battle.GlobalColors;
	import com.gaiaonline.battle.GlobalTexts;
	import com.gaiaonline.battle.gateway.BattleEvent;
	import com.gaiaonline.battle.gateway.BattleGateway;
	import com.gaiaonline.battle.gateway.BattleMessage;
	import com.gaiaonline.battle.jabberchat.JabberEvent;
	import com.gaiaonline.battle.jabberchat.JabberGateway;
	import com.gaiaonline.battle.jabberchat.JabberMessage;
	import com.gaiaonline.battle.newactors.ActorManager;
	import com.gaiaonline.battle.newactors.BaseActor;
	import com.gaiaonline.battle.newactors.BaseActorEvent;
	import com.gaiaonline.battle.ui.AlertTypes;
	import com.gaiaonline.battle.ui.ChatController;
	import com.gaiaonline.battle.ui.DialogWindow;
	import com.gaiaonline.battle.ui.DialogWindowFactory;
	import com.gaiaonline.battle.ui.DialogWindowTypes;
	import com.gaiaonline.battle.userServerSettings.IGameSettings;
	import com.gaiaonline.battle.utils.BattleUtils;
	import com.gaiaonline.display.wordbubble.BubbleEvent;
	import com.gaiaonline.flexModulesAPIs.actorInfo.ActorTypes;
	import com.gaiaonline.flexModulesAPIs.globalevent.GlobalEvent;
	import com.gaiaonline.flexModulesAPIs.managers.chat.DeSlasher;
	import com.gaiaonline.gsi.GSIEvent;
	import com.gaiaonline.utils.DisplayObjectUtils;
	import com.gaiaonline.utils.FrameTimer;
	import com.gaiaonline.utils.wordfilter.WordFilter;
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.utils.Timer;

	
	public class ChatManager extends EventDispatcher
	{	
		public static const REPORT_ABUSE_CALL_ID:int = 1001;
		private static const GAIA_NAME_TO_GAIAID:int = 9006;
		private static const MAX_GAIA_NAME_LEN:uint = 26;
		
		private var scriptDialogs:Array = new Array();
		private var isScripDialogOpen:Boolean = false;
		
		private var _wordFilter:WordFilter = null;
		private var _wordFilterReady:Boolean = false;
		private var _cachedChats:Array = new Array(); // We cache chats until the word filter is ready
		
		private var _inited:Boolean = false;	
		
		private var _gimEnabled:Boolean = false;
		private var _gimLoginErrorShown:Boolean = false;

		private var _gaiaNamesToLookup:Object = new Object();
		
		// used to help us de-dupe conversation dialogs; it's a hash by npc, which maps to a hash by conversation id, which maps to dialg ids
		private var _conversationHash:Object = new Object();
		
		private var _gateway:BattleGateway = null;
		private var _uiFramework:IUIFramework = null;
		private var _linkManager:ILinkManager = null;
		
		private var _receivedIMCounter:uint = 0;
		private const REPLY_MESSAGE_MAX:uint = 5;
		
		private var _disableDialog:Boolean = false;
		private var _dialogOpen:Boolean = false;		 
		
		private var _frameTimer:FrameTimer = new FrameTimer(onFrameTimer);
		
		private var _ignoreList:Array = [];
		
		private var _autoMoveInRange:Boolean = true;
		
		private var _jabberGateway:JabberGateway;

		static public const s_colorLookup:Object = 
		{
			"area": GlobalColors.AREA_CHANNEL,			
			"room": GlobalColors.ROOM_CHANNEL,
			"team": GlobalColors.TEAM_CHANNEL,
			"clan": GlobalColors.CLAN_CHANNEL,
			"dialog": GlobalColors.DIALOG,
			"whisper": GlobalColors.WHISPER_CHANNEL,
			"server": GlobalColors.SERVER_CHANNEL
		};


		public function ChatManager(gateway:BattleGateway, uiFramework:IUIFramework, linkManager:ILinkManager):void{		
			DisplayObjectUtils.addWeakListener(GlobalEvent.eventDispatcher, GlobalEvent.USER_LEVEL_SET, onUserLevelSet);
			DisplayObjectUtils.addWeakListener(GlobalEvent.eventDispatcher, GlobalEvent.CONVERSATION_END, onConversationEnd);
			DisplayObjectUtils.addWeakListener(GlobalEvent.eventDispatcher, GlobalEvent.CHATTABLE_MSG, onChattableMessage);
			DisplayObjectUtils.addWeakListener(GlobalEvent.eventDispatcher, GlobalEvent.DIALOG_OPEN_STATUS_CHANGED, onDialogOpenStatusChanged);
			DisplayObjectUtils.addWeakListener(GlobalEvent.eventDispatcher, GlobalEvent.DISABLE_DIALOG, onDisableDialog);						
			DisplayObjectUtils.addWeakListener(GlobalEvent.eventDispatcher, GlobalEvent.WORD_FILTER_READY, onWordFilterReady);									
			DisplayObjectUtils.addWeakListener(GlobalEvent.eventDispatcher, GlobalEvent.INVITE_FAILED, onInviteFailed);		
			
			GlobalEvent.eventDispatcher.addEventListener(GlobalEvent.USER_SETTINGS_LOADED, onGraphicsOptionChanged, false, 0, true);
			GlobalEvent.eventDispatcher.addEventListener(GlobalEvent.GRAPHIC_OPTIONS_CHANGED, onGraphicsOptionChanged, false, 0, true);										

			this._gateway = gateway;
			this._uiFramework = uiFramework;
			this._linkManager = linkManager;		
			this._frameTimer.startPerFrame();	
			
			// ** chat
			this._gateway.addEventListener(BattleEvent.USER_LOOKUP, onUserLookup, false, 0, true); // from server	
			this._gateway.addEventListener(BattleEvent.CHAT, onServerChat, false, 0, true); // from server	
			DisplayObjectUtils.addWeakListener(GlobalEvent.eventDispatcher, GlobalEvent.CHAT_SEND, onChatSend); // from user
			
			//** Dialog						
			DisplayObjectUtils.addWeakListener(GlobalEvent.eventDispatcher, GlobalEvent.CMD_DIALOG, onDialog);
			DisplayObjectUtils.addWeakListener(GlobalEvent.eventDispatcher, BubbleEvent.BTN_CLICK, onDialogBtnClick);
			
			//*** Jabber
			this._jabberGateway = JabberGateway.getInstance(this._gateway);
			this._jabberGateway.addEventListener(JabberGateway.MESSAGE_RECEIVED, onJabberMessageReceived);
			
			
			
			// ** IM
			// We'll set these up whether or not we've init'd the IM components; as the user changes level (e.g. from guest user to 
			// regular user), we'll toggle off whether we sign in or off, etc., but we can keep the listeners in any of the cases--they 
			// just won't fire if IM isn't logged in.	
			IMProxyEvent.proxy.addEventListener(IMProxyEvent.IM_RECEIVED, onIMReceived, false, 0, true);
			IMProxyEvent.proxy.addEventListener(IMProxyEvent.MESSAGE_DELIVERY_SUCCESS, onIMSuccess, false, 0, true);
			// and let's make sure we indicate that GIM is not enabled
			setGimEnabled(false);
			
			// These two are really used to toggle the UI to show whether we're connected or not
			IMProxyEvent.proxy.addEventListener(IMProxyEvent.LOGIN_SUCCESS, onLoginSuccess, false, 0, true);
			IMProxyEvent.proxy.addEventListener(IMProxyEvent.NOT_LOGGED_IN, onNotLoggedIn, false, 0, true);				

			// These are a few different types of errors; right now they're lumped into one handler.
			IMProxyEvent.proxy.addEventListener(IMProxyEvent.ACTION_REQUESTED_WITH_NO_SESSION, onIMError, false, 0, true);								
			IMProxyEvent.proxy.addEventListener(IMProxyEvent.LOGIN_ERROR, onIMError, false, 0, true);								
			IMProxyEvent.proxy.addEventListener(IMProxyEvent.MESSAGE_DELIVERY_FAILURE, onIMError, false, 0, true);	
			
			this._gateway.addEventListener(GSIEvent.LOADED, onGsiLoaded, false, 0, true);
			this._gateway.addEventListener(GSIEvent.ERROR, onGsiError, false, 0, true);			
			
			// ** Deal with IM logging in at the end here
			// We have to deal with a possible timing mismatch between when we're init'd
			// and when we first here if the user is a guest user.  We need to make sure we're init'd
			// to listen to IM login and other events, but we don't want to log in until we know if 
			// the user is a guest or not.
			_inited = true;
		}
		
		private function onDialogOpenStatusChanged(e:GlobalEvent):void {
			var data:Object = e.data;
			this._dialogOpen = e.data.open;
		}	

		private function onDisableDialog(e:GlobalEvent):void {
			var data:Object = e.data;
			this._disableDialog = e.data.disable;
		}	

		private function onUserLevelSet(e:GlobalEvent):void {
			var isGuest:Boolean = e.data.isGuest;
			tryToLogInToIM(isGuest);		
		}
		
		private function tryToLogInToIM(isGuest:Boolean):void {
			if (!_inited) {
				return;
			}
			
			if (!isGuest) {
				// See the comment in IMProxyEvent for why we're using it.
				
				// Note that INIT will log you in, if necessary, and will init only if it wasn't
				// init'd before, so INIT is a safe event here to fire.
				IMProxyEvent.proxy.dispatchEvent(new IMProxyEvent(IMProxyEvent.INIT));	
			} else {
				IMProxyEvent.proxy.dispatchEvent(new IMProxyEvent(IMProxyEvent.SIGN_OFF));					
			}
		}
		
		private function onGraphicsOptionChanged(evt:GlobalEvent):void{			
			var data2:IGameSettings = evt.data as IGameSettings;
			if (data2){
				this._autoMoveInRange = data2.getAutoMoveInRange()
			}
			
		}
		
		//----- Chat  Send
		private var messageTimesQueue:Array = new Array();
		private var penaltyTimer:Timer = new Timer(MESSAGE_PENALTY_BOX_DURATION, 1);
		private const MESSAGE_TIME_QUEUE_MAX_LEN:int = 3;
		private const MESSAGE_TIME_WINDOW:int = 5 * 1000; // 5 seconds
		private const MESSAGE_PENALTY_BOX_DURATION:Number = 5 * 1000; // 5 seconds
		private function floodControlMessage():Boolean {
			var now:Date = new Date();
			// see if the user is already in the penalty box			
			if (penaltyTimer.running) { 
				return true;
			}

			// they are not already in the penalty box; let's see if they are committing a violation with this message
			// that lands them in the penalty box
			
			if (messageTimesQueue.length < MESSAGE_TIME_QUEUE_MAX_LEN) { // if they haven't even sent enough messages, they're okay
				messageTimesQueue.push(now);
			} else {
				var duration:Number = now.getTime() - (messageTimesQueue[0] as Date).getTime();
				if (now.getTime() - (messageTimesQueue[0] as Date).getTime() > MESSAGE_TIME_WINDOW) {
					// no violation, so shift the queue to hold only the most recent 3 times
					messageTimesQueue.shift();
					messageTimesQueue.push(now);
				} else {
					// violation--throw them in the penalty box
					penaltyTimer.start();
					// reset; we won't keep penalizing them for messages they attempt to send during this
					// penalty period.
					messageTimesQueue.length = 0;
					return true;
				}
			}
			return false;
		}
		
		private static var s_mapSlashToChannel:Object = null;
		public static function mapSlashToChannel(slashCommand:String):String
		{
			if (!s_mapSlashToChannel)
			{
				s_mapSlashToChannel = {};
				s_mapSlashToChannel[DeSlasher.WHISPER] = "whisper";
				s_mapSlashToChannel[DeSlasher.LOCAL] = "room";
				s_mapSlashToChannel[DeSlasher.BROADCAST] = "area";
				s_mapSlashToChannel[DeSlasher.CREW] = "team";
				s_mapSlashToChannel[DeSlasher.GUILD] = "clan";
				s_mapSlashToChannel[DeSlasher.SERVER] = "server";
				s_mapSlashToChannel[DeSlasher.STUCK] = "server";
				s_mapSlashToChannel[DeSlasher.INVITE] = "server";
				s_mapSlashToChannel[DeSlasher.SLASH_ME] = "none";				
				s_mapSlashToChannel[DeSlasher.SLASH_ADMIN] = "none";				
			}
			return s_mapSlashToChannel[slashCommand];
		}

		public function sendChat(txt:String, channel:String = "room", userId:String = null):void {
			if (floodControlMessage()) {
				// swallow the message
				return;
			}
			
			// If user's send a slash command, we'll parse it out here and possibly override other features of the chat (e.g. channel)
			var deSlasher:DeSlasher = new DeSlasher(txt);
			const mappedChannel:String = mapSlashToChannel(deSlasher.channel);		
					
		
			switch (deSlasher.channel) {
				case DeSlasher.WHISPER:
					txt = deSlasher.deSlashedText;					
					var userName:String = deSlasher.recipient;
					if (deSlasher.reply) {
						userName = ChatController.getInstance().getReplyToRecipientName();
					}
					if (userName == null) {
						this.displaySystemMessage("There is no one to reply to.");
						return;
					}
					if (txt == null || txt == "") {
						/* if (this._gimEnabled) { // otherwise, let our GIM code issue an error that we're not logged in
							this.displaySystemMessage("What do you want to whisper to " + userName +"?");
							return;
						} */						
					} else {
						channel = mappedChannel;
						// Note that /w commands include the user *name* not id						
						
						var jbMsg:JabberMessage = new JabberMessage(userName, txt);
						jbMsg.addEventListener(JabberMessage.MESSAGE_READY, onJabberMessageReady, false, 0, true);
						this._jabberGateway.sendMsg(jbMsg);
						//showChat(txt, ActorManager.getInstance().myActor.actorId, "whisper", userName, false);
						
						//sendWhisperWithGaiaName(txt, userName);
					}			
					return;					
				case DeSlasher.LOCAL:
				case DeSlasher.BROADCAST:
				case DeSlasher.CREW:
				case DeSlasher.GUILD:
				case DeSlasher.SERVER:
					txt = deSlasher.deSlashedText;
					channel = mappedChannel;
					break;
				case DeSlasher.STUCK:
					channel = mappedChannel;
					var msg:BattleMessage = new BattleMessage(BattleEvent.STUCK, null);
					this._gateway.sendMsg(msg);			
					return;
				case DeSlasher.INVITE:				
					channel = mappedChannel;					
					if (!ActorManager.getInstance().myActor.isTeamLeader) {
						this.displaySystemMessage("You cannot invite users to a crew unless you are the leader.");
						return;
					}											
					var gaiaName:String = deSlasher.deSlashedText;
					if (gaiaName == null) {
						this.displaySystemMessage("Who do you want to invite?");
						return;
					}

					if (gaiaName.length > MAX_GAIA_NAME_LEN) {
						this.showInviteNameError(gaiaName);						
						return;
					}
					
					var userId:String = this._gaiaNamesToLookup[gaiaName]; 

					if (userId == null || userId == "") {
						this._gaiaNamesToLookup[gaiaName] = "";
						
						var obj:Object = new Object();
						obj.lookup = gaiaName;
						var lookupMessage:BattleMessage = new BattleMessage(BattleEvent.USER_LOOKUP, obj);
						this._gateway.sendMsg(lookupMessage);			
						
//						this._gateway.addEventListener(GSIEvent.LOADED, onGsiLoaded, false, 0, true);					
//						this._gateway.addEventListener(GSIEvent.ERROR, onGsiError, false, 0, true);											
//						this._gateway.gsiInvoke(GAIA_NAME_TO_GAIAID, gaiaName);
					} else {
						if (userId == ActorManager.getInstance().myActor.actorId) {
							onSelfInvite();
							return;
						}
						this.inviteUser(this._gaiaNamesToLookup[gaiaName], gaiaName);														
					}
					return;
				case DeSlasher.SLASH_ME:
					if (channel == "area") {
						this.displaySystemMessage("/me is not allowed on this channel.");
						return;						
					}
					break;
				case DeSlasher.SLASH_ADMIN:
				{
					if( ActorManager.getInstance().myActor.isDev() )
					{
						if( deSlasher.deSlashedText == " panel" )
						{
							GlobalEvent.eventDispatcher.dispatchEvent( new GlobalEvent( GlobalEvent.OPEN_ADMIN_PANEL, null ) );
						}
						else
						{
							this.displaySystemMessage( "unsupported /admin command '" + deSlasher.deSlashedText + "'" );
						}
					}
					return;
				}
					break;
				case DeSlasher.NONE:
					// fall through
				default:
					break;
			}
			
			
			//******* first chek if message should be send using jabber room:
			if (this._jabberGateway.containChannel(channel) ){
						
				//var jbMsg2:JabberMessage = new JabberMessage(userName, txt);
				var jbMsg2:JabberMessage = new JabberMessage(ActorManager.getInstance().myActor.actorName, txt);
				jbMsg2.addEventListener(JabberMessage.MESSAGE_READY, onJabberMessageReady, false, 0, true);
				jbMsg2.channel = channel;
				this._jabberGateway.sendMsg(jbMsg2);
				
			}else if (txt.length > 0){
				
				switch (channel) {
					case "whisper": 
						sendWhisperWithGaiaId(txt, userId);
						if (txt == null || txt == "") {
							/* if (this._gimEnabled) { // otherwise, let our GIM code issue an error that we're not logged in
								this.displaySystemMessage("What do you want to whisper?");
								return;							
							}	 */					
						}						
						break;
					case "clan":
						
						var clanId:int = parseInt(ActorManager.getInstance().myActor.clanId); 
						if ( clanId <= -1){
							this.displaySystemMessage("You are not a member of a clan.");
							return;
						}
						
						/* [FRED] clan is now hadle by jabber 
						
						if (txt == null || txt == "") {
							// if (this._gimEnabled) { // otherwise, let our GIM code issue an error that we're not logged in
							//	this.displaySystemMessage("What do you want to say to your clan?");
							//	return;
							//}						
						} else {						
							var clanId:int = parseInt(ActorManager.getInstance().myActor.clanId); 
							if (clanId > -1) {			
								sendGuildBroadcast(txt, String(clanId));
							} else {
								this.displaySystemMessage("You are not a member of a clan.");
								return;
							}
						} 
						*/
						break; 

					case "team":
						if (ActorManager.getInstance().myActor.inCrewState != BaseActor.CREW_STATE_IN) {
							this.displaySystemMessage("You are not a member of a crew.");
							return;
						}
						sendChatThroughBattle(txt, channel, userId);
						break;
					default: 
						sendChatThroughBattle(txt, channel, userId);
						break;
				}
			}		
		}
		
		private function onJabberMessageReady(evt:Event):void{
			var msg:JabberMessage = evt.target as JabberMessage;
			if (msg){
				msg.removeEventListener(JabberMessage.MESSAGE_READY, onJabberMessageReady);
				if (!msg.isError){
					var channel:String = "whisper";
					if (msg.channel != null){
						channel = msg.channel;
					}
					showChat(msg.txt, ActorManager.getInstance().myActor.actorId, channel, msg.displayName, false);
				}else{
					this.displaySystemMessage(msg.txt);
				}
			}
		}
		
		private function displaySystemMessage(message:String):void {
			var received:Boolean = false;
			var fromSystem:Boolean = true;
			this.showChat(message, "", "whisper", "",received, fromSystem);
		}
		
		private function sendWhisperWithGaiaId(txt:String, userId:String):void {
			var received:Boolean = false;
			showChat(txt, ActorManager.getInstance().myActor.actorId, "whisper", ActorManager.getInstance().myActor.actorName, received);
			
			var imProxyEvent:IMProxyEvent = new IMProxyEvent(IMProxyEvent.SEND_IM_WITH_GAIA_ID);
			imProxyEvent.message = txt;
			imProxyEvent.gaiaId = userId;
		 	IMProxyEvent.proxy.dispatchEvent(imProxyEvent);
		}
		
		private function sendWhisperWithGaiaName(txt:String, userName:String):void {
			var received:Boolean = false;
			showChat(txt, ActorManager.getInstance().myActor.actorId, "whisper", userName, received);
			
			var imProxyEvent:IMProxyEvent = new IMProxyEvent(IMProxyEvent.SEND_IM_WITH_GAIA_NAME);
			imProxyEvent.message = txt;
			imProxyEvent.gaiaName = userName;
		 	IMProxyEvent.proxy.dispatchEvent(imProxyEvent);			
		}
		
		private function sendGuildBroadcast(txt:String, guildId:String):void {		
			var imProxyEvent:IMProxyEvent = new IMProxyEvent(IMProxyEvent.SEND_IM_TO_GUILD);
			imProxyEvent.message = txt;
			imProxyEvent.guildId = guildId;
		 	IMProxyEvent.proxy.dispatchEvent(imProxyEvent);			
		}
		
		private function sendChatThroughBattle(txt:String, channel:String, userId:String):void {
			var obj:Object = new Object();
			obj.chatMessage = txt;
			obj.chatChannel = channel;				
			if (userId != null){					
				obj.targetID = userId
			}				
				
			var msg:BattleMessage = new BattleMessage("chat",obj);
			msg.addEventListener(BattleEvent.CALL_BACK, onChatSentCallBack)
			this._gateway.sendMsg(msg);
		}
	
		private function onChatSentCallBack(evt:BattleEvent):void{
			////trace("SEND CHAT CALL BACK"); 
			BattleMessage(evt.target).removeEventListener(BattleEvent.CALL_BACK, onChatSentCallBack);
		}

		private function onInviteSentCallBack(evt:BattleEvent):void{
			////trace("SEND CHAT CALL BACK"); 
			BattleMessage(evt.target).removeEventListener(BattleEvent.CALL_BACK, onInviteSentCallBack);
		}
		
		
		private var _pendingServerChatEvents:Array = [];
		 //-------- Chat Recieved
		private function onServerChat(evt:BattleEvent):void{
			this._pendingServerChatEvents.push(evt);
		}
		
		private function onFrameTimer():void {
			for each (var evt:BattleEvent in this._pendingServerChatEvents) {
				for (var i:int = 0; i < evt.battleMessage.responseObj.length; i++){
					var msg:String = evt.battleMessage.responseObj[i].chatMessage;
					var actorId:String = evt.battleMessage.responseObj[i].senderID
					var channel:String = evt.battleMessage.responseObj[i].chatChannel;
					var actorName:String = evt.battleMessage.responseObj[i].name;
					var timestamp:Number = evt.battleMessage.responseObj[i].timestamp;	// format offline comments differently
					var errorMessage:String = evt.battleMessage.responseObj[i].errorMessage;
					var fromSystem:Boolean = false;
					var actor:BaseActor = ActorManager.actorIdToActor(actorId);
					fromSystem = actor && !ActorTypes.isActor(actor.actorType);
					
					var received:Boolean = true;
					if (channel == "whisper" && actorId == ActorManager.getInstance().myActor.actorId && evt.battleMessage.responseObj[i].recipient){
						actorName = evt.battleMessage.responseObj[i].recipient;
						received = false;
					}					
					
					showChat( msg, actorId, channel, actorName, received,fromSystem,ChatManager.s_colorLookup[channel.toLocaleLowerCase()], timestamp, errorMessage);
				}
			}
			this._pendingServerChatEvents.length = 0;
		}

		
		private function onJabberMessageReceived(evt:JabberEvent):void{
			
			if (evt.fromUserName && evt.msg){
				var timeStamp:Number = NaN;
				if (evt.timeStamp){
					timeStamp = evt.timeStamp.time/1000;				
				}
				var channel:String = "whisper";
				if (evt.channel != null){
					channel = evt.channel;
				}
				showChat(evt.msg, evt.fromUserId, channel, evt.fromUserName, true, false, NaN, timeStamp);
			}

			if (evt.errorMsg){
				this.displaySystemMessage(evt.errorMsg);
			}
			
		}	
		
		private function onIMReceived(evt:IMProxyEvent):void {
			var e:IMReceivedEvent = evt.imReceivedEvent;
			var received:Boolean = true;
			var channel:String = e.channel;
			if (e.channel == "guild") {
				if (e.guildId == ActorManager.getInstance().myActor.clanId) {
					e.channel = "clan";
				} else {
					// Just drop guild broadcasts that aren't to your clan for now
					return;
					//e.message = "(to " + e.guildName + ") " + e.message;				
				}
			} else {
				if (++this._receivedIMCounter <= this.REPLY_MESSAGE_MAX) {
					var received2:Boolean = false;
					var fromSystem:Boolean = true;
					this.displaySystemMessage("Hit the Backspace key to reply to " + e.senderName);
				}					 
			}
			showChat(e.message, e.senderId, e.channel, e.senderName, received);
		}
		
		private function onIMSuccess(evt:IMProxyEvent):void {
		}

		private function onChattableMessage(e:GlobalEvent):void {
			var data:Object = e.data;
			var type:String = data.type || "";
			var actorId:String = data.actorId || "";
			var name:String = data.name || "";
			var msg:String = data.msg || "";
			var received:Boolean = (data.received !== undefined) ? data.received : false;
			var fromSystem:Boolean = (data.fromSystem !== undefined) ? data.fromSystem : false;
			var color:Number = (data.color !== undefined) ? data.color : NaN; 		
				
			this.showChat(msg, actorId, type, name, received, fromSystem, color); 
		}


		public function showChat( msg:String, actorId:String, channel:String, actorName:String, received:Boolean = true, fromSystem:Boolean = false, color:Number = NaN, timestamp:Number = NaN, errorMessage:String=null):void {
			if (!_wordFilterReady) {
				// Really we shouldn't drop messages if the word filter isn't ready, but we'll take the easy way out
				// for now, since it's unlikely that it will take a long time to get the dictionary back for the filter
				// and that the user will have goten messages by then.  But to be safe in not offending anyone, we'll drop
				// the messages rather than showing them.					
				_cachedChats.push(new Chat(msg, actorId, channel, actorName));
				return;
			} 

			if(_ignoreList && _ignoreList.indexOf(actorId) > -1)
			{
				return;
			}

			var actor:BaseActor = ActorManager.actorIdToActor(actorId);
			var doFilter:Boolean = !fromSystem && ( (actor == null)  || (actor.actorType == ActorTypes.PLAYER)); 
			if (doFilter) {
				msg = WordFilter.clean(msg, ActorManager.getInstance().myActor.wordFilterLevel);
			}
			
			var fromServer:Boolean = false;
			var slashMe:Boolean = false;
			
			// we should prevent /me on area, because folks are using it to impersonate others
			if (channel != "whisper" && channel != "area") {			
				var leftTrimmed:String = StringUtil.ltrim(msg);
				var prefix:String = leftTrimmed.substr(0, DeSlasher.SLASH_ME.length);
				slashMe = (prefix == DeSlasher.SLASH_ME || prefix == DeSlasher.SLASH_ME.toUpperCase());
				if (slashMe) {
					msg = actorName + msg.substr(DeSlasher.SLASH_ME.length);
				}
			}
			
			if (channel == "whisper") {
				GlobalEvent.eventDispatcher.dispatchEvent(new GlobalEvent(GlobalEvent.ALERT, {type:AlertTypes.MESSAGE_RECIEVED_OR_SENT}));
			}																																											
						
			if (!slashMe && showMessageInBubble(channel)) {
				if (actorId != null && actor != null){
					if (actor.roomId == ActorManager.getInstance().myActor.roomId) {
						actorName = actor.actorName;
						GlobalEvent.eventDispatcher.dispatchEvent(new GlobalEvent(GlobalEvent.MAP_ADD_TEXT, {actor:actor, actorName:actor.actorName, actorBounds:actor.getActorBound(), message:msg, channel:channel}));
					}	
				}	
			}
			
			var chatData:Object = {
									channel:channel,
									actorId:actorId,
									actorName:actorName,
									message:msg,
									received:received,
									fromSystem:fromSystem,
									fromServer:fromServer,
									slashMe:slashMe,
									color:color,
									timestamp:timestamp,
									errorMessage: errorMessage
								  }
			GlobalEvent.eventDispatcher.dispatchEvent(new GlobalEvent(GlobalEvent.CHAT_MESSAGE_READY, chatData));
		}
			
		private function showMessageInBubble(channel:String):Boolean {
			var show:Boolean = false;
			
			switch (channel) {
				case "area": // drop through
				case "room":
					show = true;
					break;
				default:
					show = false;
					break;
			}
			
			return show;
		}
		
		//---- IM login success and errors
		private function onLoginSuccess(evt:IMProxyEvent):void {
			var e:BattleIMEvent = evt.battleIMEvent;
			if (this._gimLoginErrorShown) {
				this.displaySystemMessage("You are logged into GIM!");
			}
			setGimEnabled(true);				 
			this._gimLoginErrorShown = false;			
			BattleUtils.cleanObject(this.errorMap);
		}

		private var errorMap:Object = new Object();
		private function shownThisError(errorCode:String):Boolean {
			return errorMap[errorCode] != null;
		}
		
		private function onNotLoggedIn(evt:IMProxyEvent):void {
			var e:BattleIMEvent = evt.battleIMEvent;
			setGimEnabled(false);
			this._gimLoginErrorShown = true;
			var errorCode:String = evt.errorCode;														
			if (!shownThisError(errorCode)) {	
				errorMap[errorCode] = true;
				if (e.errorMessage.length > 0) {						
					this.displaySystemMessage(e.errorMessage);
				}
			}						
		}		

		private function setGimEnabled(enabled:Boolean):void {				
			this._gimEnabled = enabled;
			GlobalEvent.eventDispatcher.dispatchEvent(new GlobalEvent(GlobalEvent.GIM_ENABLED_CHANGE, {enabled:this._gimEnabled}));
		}	
			
		private function onIMError(evt:IMProxyEvent):void {
			var e:BattleIMEvent = evt.battleIMEvent;			
			var errorMessage:String = e.errorMessage;
			if (e.errorCode && e.errorCode.length > 0) {
				errorMessage += " (" + e.errorCode + ")";
			}			
			
			this.displaySystemMessage(errorMessage);
		}		
		
		//----- Dialog 
		private function onDialog(evt:GlobalEvent):void {
			var r:Object = evt.data;
			if (r.isInfo == "1"){ 
				if (r.npcText != null && r.npcText != undefined){
					if (handleDuplicateDialogs(r)) { // note that we check this before we push the script dialog or set it to "DONE"
						return;	
					}
					const okSuffix:String = "<p align='right'><a href ='event:close'>OK</a></p>"; 											
					var txt:String = r.npcText + okSuffix; 					
					var xmlized:XML = null;				
					try {
						xmlized= new XML(r.npcText);
					} catch (e:Error) {
						trace(e);
					}	
					if (xmlized != null && xmlized.name() == "zOMG") {
						var zOMG:XML = xmlized[0];
						var textList:XMLList = zOMG.text();
						var textXML:XML = textList[0];
						if (textList.length() > 0) {
							txt = textXML.toString();
							delete xmlized.children()[textXML.childIndex()];
							XML(xmlized).appendChild(new XML("<![CDATA[" + txt + okSuffix + "]]>"));
							txt = xmlized.toXMLString();							
						}
						
						if(r.con){
							GlobalEvent.eventDispatcher.dispatchEvent(new GlobalEvent(GlobalEvent.TRACKING_EVENT, "tutorial_" + r.con));
						}
					} 

							
					this.scriptDialogs.push({txt:txt, con:r.con, dlg:r.dlg, npc:r.npc, isTutorial:(r.isInfo == "1")});
					this.processNextScriptDialog();
					// Uuuuugly hack.  We force the tutorial dialog to act as a "DONE" event, so that we close the 
					// tutorial dialog.  But we use the closing of the dialog box (normal dialog or tutorial box) to 
					// trigger clearing our cache.  But we don't want to clear our cache if we're faking the done
					// because of the tutorial, which *might* actually be a real "DONE" if the server tells us so.
					r.isNaturalDone = (r.dlg == "DONE");

					r.dlg = "DONE";	
					this.processDialog(r);				
				}					
			}else{			
				if (handleDuplicateDialogs(r)) {
					return;
				}
				this.processDialog(r);
			}
		}
		
		private function tryToHideDialogButton():void {
			var isDialogOpen:Boolean = this._dialogOpen && !this._disableDialog;			
			if (!isDialogOpen) {
				GlobalEvent.eventDispatcher.dispatchEvent(new GlobalEvent(GlobalEvent.MAP_SET_DIALOG_BUTTON_VISIBLE, {visible:true}));
			}
		}
		
		// Returns true if the dialog was a duplicate, false otherwise
		private function handleDuplicateDialogs(r:Object):Boolean {
			var con:String = r.con;
			var npc:String = r.npc;
			var dlg:String = r.dlg;
			if (con != null && npc != null && dlg != null) {
				// If we haven't hashed for this npc, then start one.
				if (_conversationHash[npc] == null) {
					_conversationHash[npc] = new Object();
				}
				// Now let's see if we've started a conversation hash for this npc.
				// We only want to hash one conversation per npc, so if the conversation
				// we're processing is a new one, we blow away our previous conversation
				// hash for this npc and replace it with a new hash; otherwise, we add
				// to the dialogs we're remembering for this conversation.
				if (_conversationHash[npc][con] == null) {
					_conversationHash[npc][con] = new Object();
				} 
				// Now let's see if our dialog is a dupe for this conversation.
				if (_conversationHash[npc][con][dlg] == null) {
					// mark it as a dialog we've seen for this conversation from this npc, so we know the next
					// time we see this dialog, it's a dupe.					
					_conversationHash[npc][con][dlg] = true;					
				} else {
					if (r.dupe != null && r.dupe == true) {
						// then it's already a dupe
						return true;
					}
				}
			}
			
			return false;
		}

		private function onConversationEnd(e:GlobalEvent):void {
			var convId:String = e.data.convId;
			if (convId != null) {
				for each (var npcHash:Object in _conversationHash) {
					delete npcHash[convId];
				}
			}
		}
				
		private function processDialog(r:Object):void{
			if (r.dlg == "DONE"){	
				// addDialog with the dlg = 'DONE' will end the conversation
				// and close the dialog box if no more conversation	
				GlobalEvent.eventDispatcher.dispatchEvent(new GlobalEvent(GlobalEvent.DIALOG_DATA_UPDATED, {data:r}));
				tryToHideDialogButton();
			}	
								
			//--
			var npc:String = r.npc;
			var actor:BaseActor = ActorManager.actorIdToActor(npc);
			if (r.state == 1 && actor != null){
				//--- set target type for mouse over icon
				actor.targetType = 4;
								
				//add the '...' button on the npc
				var priority:int = 0;
				if (r.priority != null){
					priority = r.priority;
				}					
							
				// Reset our conversation hash so we can repeat dialogs for this npc
				delete _conversationHash[npc];
				
				GlobalEvent.eventDispatcher.dispatchEvent(new GlobalEvent(GlobalEvent.MAP_ADD_DIALOG_BUTTON, {actor:actor, priority:priority}));

				actor.Dialogable = true;
				tryToHideDialogButton();
							
			}else if (r.state == 2){
				// -- Hide all the '...' button on npc			
				// this will pop up the dialog box if not alrady open
				GlobalEvent.eventDispatcher.dispatchEvent(new GlobalEvent(GlobalEvent.MAP_SET_DIALOG_BUTTON_VISIBLE, {visible:false}));
				GlobalEvent.eventDispatcher.dispatchEvent(new GlobalEvent(GlobalEvent.DIALOG_DATA_UPDATED, {data:r}));
				
				//--- reset all actors target type for mouse over icon
				ActorManager.resetAllTargetType();				
									
			}else if (r.state == 0){
				// remove the '...' form an NPC			
				if(npc) {	
					// Reset our conversation hash so we can repeat dialogs for this npc
					delete _conversationHash[npc];

					GlobalEvent.eventDispatcher.dispatchEvent(new GlobalEvent(GlobalEvent.MAP_REMOVE_DIALOG, {actor_id:npc}));
					if(actor) {
						if(actor) {
							actor.resetTargetType(); 					//--- set target type for mouse over icon
							actor.Dialogable = false;					
						}
					}
				}
				tryToHideDialogButton();
			}
		}
			
		private function onDialogBtnClick(evt:BubbleEvent):void{
			
			var ba:BaseActor = 	evt.myActor as BaseActor;			
			var range:Number = 250;	 
			if (ba.range > 0){
				range = ba.range;
			}
			var params1:Object = {npc:ba.actorId, opt:-1};
			
			if (this._autoMoveInRange ||  ActorManager.getInstance().myActor.checkRange(ba, range) ){
				var msg1:BattleMessage = new BattleMessage("dialogClick", params1);
				msg1.addEventListener(BattleEvent.CALL_BACK, onDialogCallBack);
				this._gateway.sendMsg(msg1);
			}else{
				this.showChat(GlobalTexts.getNpcOutOfRangeText(ba.actorName), ba.actorId, "room", ba.actorName);
			}
			
			// [Fred] Range Check now done on server
			/*
			//---- Check if in range
			var ba:BaseActor = 	evt.myActor as BaseActor;			
			var range:Number = 250;
			if (ba.range > 0){
				range = ba.range;
			}			
			if (ActorManager.getInstance().myActor.checkRange(ba, range) ){
				var params1:Object = {npc:ba.actorId, opt:-1};
				var msg1:BattleMessage = new BattleMessage("dialog", params1);
				this._gateway.sendMsg(msg1);
			}else{
				this.showChat(GlobalTexts.getNpcOutOfRangeText(ba.actorName), ba.actorId, "room", ba.actorName);
			}	
			*/
			
		}		
		private function onDialogCallBack(evt:BattleEvent):void{
			trace("[ChatManager onDialogCallBack]");
						
			BattleMessage(evt.target).removeEventListener(BattleEvent.CALL_BACK, onDialogCallBack);	
			var rObj:Object = evt.battleMessage.responseObj;
						 
			for each (var response:Object in rObj) {
				
				if (response.hasOwnProperty("error") && response.error != null) {
					var error:uint = response.error;
				}					
				if (error){
					var requestObj:Object = evt.battleMessage.requestObjUnsafeForModifying; 
					if (requestObj.npc){
						var actor:BaseActor = ActorManager.actorIdToActor(requestObj.npc);
						if (actor) {
							switch(error){
								case 201: //Out Of Range
									this.showChat(GlobalTexts.getNpcOutOfRangeText(actor.actorName), actor.actorId, "room", actor.actorName);
									break;								
							}
							
						}					
					}
			    }
			}		
		}
		public function getDialogBtnInfo():Object{
			return new Object();
		}
		
		
		//----- World NPC, Help Dialog		
		private function processNextScriptDialog():void{
			if (!this.isScripDialogOpen && this.scriptDialogs.length > 0){
				var obj:Object = this.scriptDialogs.shift();						
				var dw:DialogWindow = DialogWindowFactory.getInstance().getNewDialogWindow(this._uiFramework, this._linkManager, DialogWindowTypes.NORMAL, 200);				
				dw.autoCenterTop = true;
				dw.autoSize = true;
				//dw.setHeader("Tips");
				dw.setHtmlText(obj.txt);
				dw.params = obj;
				dw.addEventListener("CLOSE", onScriptDialogClose);				
				dw.supportHyperlinks = obj.isTutorial;			
				this.isScripDialogOpen = true;				
			}
		}		
		
		private function onScriptDialogClose(evt:Event):void{
			DialogWindow(evt.target).removeEventListener("CLOSE", onScriptDialogClose);
			var obj:Object = DialogWindow(evt.target).params;
			
			this.isScripDialogOpen = false;

			////trace(obj.dlg, obj.con, obj.npc);
			var params:Object = new Object();
			params.npc = obj.npc;
			params.con = obj.con;
			params.dlg = obj.dlg;
			params.opt = 0;			
			var msg:BattleMessage = new BattleMessage("dialogClick", params);
			this._gateway.sendMsg(msg);
			GlobalEvent.eventDispatcher.dispatchEvent(new GlobalEvent(GlobalEvent.TUTORIAL_CLOSED, {}));
			this.processNextScriptDialog();	
			
			DialogWindow(evt.target).removeEventListener("CLOSE", onScriptDialogClose);
		}	
						
		private function onWordFilterReady(e:Event):void {
		 	_wordFilterReady = true;
		 	for each (var chat:Chat in _cachedChats) {
		 		showChat(chat.msg, chat.actorId, chat.channel, chat.actorName);
		 	}
		 	
		 	_cachedChats = null;
		}
		
		private function onUserLookup(event:BattleEvent):void
		{
			var data:Object = event.battleMessage.responseObj[0];
			var lookup:String = data["lookup"];
			
			if(data.hasOwnProperty("error"))
			{
				this.showInviteNameError(lookup);
			}
			else
			{
				var name:String = data["name"];
				var id:String = data["id"];
				var currMapping:String = this._gaiaNamesToLookup[name];
				if (currMapping == "") {
					this._gaiaNamesToLookup[name] = id;
					if (id == ActorManager.getInstance().myActor.actorId) {
						onSelfInvite();
						return;
					} else {							
						this.inviteUser(id, name);
					}
				}
			}
		}
		
		private function onGsiLoaded(evt:GSIEvent):void {		
			switch (evt.gsiMethod) {
				case REPORT_ABUSE_CALL_ID:
					var reportId:int = parseInt(evt.gsiData as String);
					var data:Object = {reportId:reportId};
					GlobalEvent.eventDispatcher.dispatchEvent(new GlobalEvent(GlobalEvent.ABUSE_REPORTED, data));
					break;
				default:
					break;
			}
		}
		
		private function inviteUser(userId:String, userName:String):void {
			if (parseInt(userId) > 0) {		
				ActorManager.getInstance().myActor.inviteUser(userId, userName, onInviteSentCallBack);
			} else {
				this.displaySystemMessage("There is no user with the name " + userName);		
			}
		}

		private function onInviteFailed(e:GlobalEvent):void {
			this.displaySystemMessage("There is no user with that name.");		
		}	
			
		private function onSelfInvite():void {
			this.displaySystemMessage("Inviting yourself to your own crew--how polite!");
		}		
		
		private function onGsiError(evt:GSIEvent):void {
			switch (evt.gsiMethod) {
				case REPORT_ABUSE_CALL_ID:
					var err:Object = {error:evt.gsiData.error};
					GlobalEvent.eventDispatcher.dispatchEvent(new GlobalEvent(GlobalEvent.ABUSE_REPORT_FAILED, err));
					break;
				default:
					break;
			}
		}

		private function onChatSend(e:GlobalEvent):void{
			var data:Object = e.data;
			var msg:String = data.msg;
			var channel:String = data.channel;
			var color:Number = e.data.color ? e.data.color : NaN;
			this.sendChat(msg, channel, null);
		}
		
		//-----------
		private function log(...args):void{
			var s:String;			
			for (var p:String in args){				
				if (s == null){
					if (args[p] == null){
						s = "null";
					}else{
						s = args[p];
					}
				}else{
					if (args[p] == null){
						s = s = s + ", null";
					}else{
						s = s + "," + String(args[p]);
					}
				} 
			}									
			
		}	
		
		public function bindIgnoreList(actor:BaseActor):void
		{
			DisplayObjectUtils.addWeakListener(actor, BaseActorEvent.IGNORE_LIST_CHANGED, onIgnoreListUpdate);
		}	
		
		private function onIgnoreListUpdate(event:BaseActorEvent):void
		{
			_ignoreList = event.actor.ignoreList;
		}
		
		private function showInviteNameError(userName:String):void {
			this.displaySystemMessage("There is no user with the name " + userName + " to send an invitation to.");			
		}
	}
}
// Locally scoped class for when we have to cache messages before IM is ready
class Chat {
	private var _msg:String = null;
	private var _actorId:String = null;
	private var _channel:String = null;
	private var _actorName:String = null;

	public function Chat(msg:String, actorId:String, channel:String, actorName:String) {
		this._msg = msg;
		this._actorId = actorId;
		this._channel = channel;
		this._actorName = actorName;
	}
	
	public function get msg():String {
		return _msg;
	}
	
	public function get actorId():String {
		return _actorId;
	}
	
	public function get channel():String {
		return _channel;
	}
	
	public function get actorName():String {
		return _actorName;		
	}
	
}
