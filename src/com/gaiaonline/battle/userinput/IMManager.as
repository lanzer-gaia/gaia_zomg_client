package com.gaiaonline.battle.userinput
{
	import com.gaiaonline.aimAPI.AimAPI;
	import com.gaiaonline.aimAPI.GaiaUser;
	import com.gaiaonline.aimAPI.globalEvent.GlobalBuddyListEvent;
	import com.gaiaonline.aimAPI.globalEvent.GlobalIMEvent;
	import com.gaiaonline.aimAPI.globalEvent.GlobalInstantMessageEvent;
	import com.gaiaonline.aimAPI.globalEvent.GlobalLoginEvent;
	import com.gaiaonline.aimAPI.globalEvent.GlobalLoginRequestResult;
	import com.gaiaonline.aimAPI.globalEvent.GlobalNameResolveError;
	import com.gaiaonline.aimAPI.globalEvent.GlobalSessionEvent;
	import com.gaiaonline.battle.gateway.BattleGateway;
	import com.gaiaonline.battle.newactors.ActorManager;
	import com.gaiaonline.flexModulesAPIs.globalevent.GlobalEvent;
	
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	import flash.events.TimerEvent;
	import flash.external.ExternalInterface;
	import flash.utils.Timer;
	
	public class IMManager extends EventDispatcher {
		private var _aimAPI:AimAPI = null;
		private var _loggingIn:Boolean = false;
		private var _loginAttempts:uint = 0;

		private var _notRegMessageShown:Boolean = false;
		private var _userActive:Boolean = false;
		private var _userEmailAddress:String = null;				
		
		private var _enableGIM:Boolean = false;
		private var _allowGIM:Boolean = false;
		
		private var _successfulLoginTimer:Timer = new Timer(3000);						
		private var _recentlyDisconnected:Boolean = false;
		
		private var _gateway:BattleGateway = null;		

		private const BROADCAST_SLASH_COMMAND:String = "/zOMGBroadcast";
				
		private const MAX_LOGIN_ATTEMPT_INTERVAL:uint = 300000; // 5 minutes == 300 seconds == 300000 milliseconds; IF YOU CHANGE THIS, CHANGE MAX_LOGIN_ATTEMPTS below
		private var MAX_LOGIN_ATTEMPTS:uint = 9; // 2^9 seconds == 512 seconds == 512000 milliseconds, first power of 2 that exceeds our limit for MAX_LOGIN_ATTEMPT_INTERVAL
	
		
		public function IMManager(gateway:BattleGateway, enableGIM:Boolean, target:IEventDispatcher=null) {
			super(target);
			
			this._gateway = gateway;
			this._enableGIM = enableGIM;
			
			// Player info
			GlobalEvent.eventDispatcher.addEventListener(GlobalEvent.PLAYER_CREATED, onPlayerInfo, false, 0, true);
											
			IMProxyEvent.proxy.addEventListener(IMProxyEvent.INIT, onInit);
			
			var evt:BattleIMEvent = new BattleIMEvent(BattleIMEvent.NOT_LOGGED_IN);
			var imProxyEvent:IMProxyEvent = new IMProxyEvent(IMProxyEvent.NOT_LOGGED_IN);
			imProxyEvent.battleIMEvent = evt;
			IMProxyEvent.proxy.dispatchEvent(imProxyEvent);						
		}

		private function onInit(e:IMProxyEvent):void {
			init();
		}
		
		public function init():void {
			if (!_aimAPI) {
				var gaiaName:String = ActorManager.getInstance().myActor.actorName;
				var gaiaId:String = ActorManager.getInstance().myActor.actorId;
				_aimAPI = new AimAPI(gaiaId, gaiaName, null, null);
				_aimAPI.gsiSubDomain = this._gateway.gsiSubdomain;
				_aimAPI.broadcastSlashCommand = BROADCAST_SLASH_COMMAND;
				_aimAPI.preventSelfSend();
	
				IMProxyEvent.proxy.addEventListener(IMProxyEvent.SIGN_OFF, onSignOffRequest)
				

				// connection issues
				GlobalIMEvent.global.addEventListener(GlobalSessionEvent.DISCONNECTED, onIMDisconnected);
				GlobalIMEvent.global.addEventListener(GlobalSessionEvent.RECONNECTING, onIMReconnecting);
				GlobalIMEvent.global.addEventListener(GlobalSessionEvent.ACTION_REQUESTED_WITH_NO_SESSION, onNoIMSession);
				
				GlobalIMEvent.global.addEventListener(GlobalSessionEvent.LOGGED_OUT, onIMLoggedOut);
				
				// login issues
				GlobalIMEvent.global.addEventListener(GlobalLoginRequestResult.IO_ERROR, onIMLoginError);
				GlobalIMEvent.global.addEventListener(GlobalLoginRequestResult.SECURITY_ERROR, onIMLoginError);
				GlobalIMEvent.global.addEventListener(GlobalLoginRequestResult.GENERAL_ERROR, onIMLoginError);
				
				// aim id issues				
				GlobalIMEvent.global.addEventListener(GlobalLoginRequestResult.USER_HAS_NON_COMPLIANT_AIMID, onUserHasNonCompliantAimId);
				GlobalIMEvent.global.addEventListener(GlobalNameResolveError.NO_AIMID, onNoAimIdForRecipient);
				
				// gaia id/name issues
				GlobalIMEvent.global.addEventListener(GlobalNameResolveError.INVALID_GAIANAME, onInvalidRecipientName);
				GlobalIMEvent.global.addEventListener(GlobalNameResolveError.INVALID_GAIAID, onInvalidRecipientId);
				GlobalIMEvent.global.addEventListener(GlobalNameResolveError.SELF_SEND, onSelfSend);				
				GlobalIMEvent.global.addEventListener(GlobalNameResolveError.GENERIC_ERROR, onGenericRecipientError);				
				
				// messaging issues
				GlobalIMEvent.global.addEventListener(GlobalInstantMessageEvent.RECEIVED_INVALID_GUILD_BROADCAST, onInvalidGuildBroadcastReceived);
								
				// successes
				GlobalIMEvent.global.addEventListener(GlobalSessionEvent.ONLINE, onIMLoginSuccess);												
				GlobalIMEvent.global.addEventListener(GlobalInstantMessageEvent.IM_RECEIVED, onIMReceived); 
				GlobalIMEvent.global.addEventListener(GlobalInstantMessageEvent.GUILD_BROADCAST_RECEIVED, onGuildBroadcastReceived);
				GlobalIMEvent.global.addEventListener(GlobalInstantMessageEvent.IM_SEND_RESULT, onIMSendResult);				
				GlobalIMEvent.global.addEventListener(GlobalBuddyListEvent.BUDDYLIST_REFRESH, onBuddyListRefresh);
	
				IMProxyEvent.proxy.addEventListener(IMProxyEvent.SEND_IM_TO_GUILD, onSendIMToGuild);
				IMProxyEvent.proxy.addEventListener(IMProxyEvent.SEND_IM_WITH_GAIA_ID, onSendIMWithGaiaId);
				IMProxyEvent.proxy.addEventListener(IMProxyEvent.SEND_IM_WITH_GAIA_NAME, onSendIMWithGaiaName);
				 
				// These are javascript function callbacks we use to hear back from the GIM reg page (we have
				// to launch this page if the user has a Gaia name that doesn't map nicely to a compliant AIM id (e.g.
				// the Gaia name has spaces in it.
				if (flash.external.ExternalInterface.available) {
    				ExternalInterface.addCallback("onGIMRegCancelled", onGIMRegCancelled);
					ExternalInterface.addCallback("onGIMRegSuccessful", onGIMRegSuccessful);
				}		

				_allowGIM = this._enableGIM;
			}
			
			signOn();							

			//@@@ ON CLOSE BATTLE SHOULD FIRE AN EVENT FOR LOGGING OFF				
		}
		
		private function onPlayerInfo(evt:GlobalEvent):void{
			var responseObj:Object = evt.data.playerInfo;

			this._userActive = responseObj.userActive;
			if (responseObj.userEmailAddress != null) {
				this._userEmailAddress = responseObj.userEmailAddress;
			}
		}
		
		private function onGIMRegCancelled():void {
			// Nothing to do for now
			trace("GIM registration cancelled");
		
		}
		
		private function onGIMRegSuccessful():void {
			signOn();
		}
		
		public function signOn():void {
			if (!_allowGIM) {
				return;
			}
			if (!_loggingIn) {
				_loggingIn = true;
				_loginAttempts = Math.min(_loginAttempts + 1, MAX_LOGIN_ATTEMPTS)
				if (_loginAttempts == 1) {	
					onSignOnRequest(null);
				} else {		
					// we increase our delay by powers of two seconds each time we attempt after a failure, capping at every five minutes			
					var delay:int = Math.pow(2, _loginAttempts - 1) * 1000;
					var secondsDelay:int = Math.min(delay, MAX_LOGIN_ATTEMPT_INTERVAL);
					var timer:Timer = new Timer(secondsDelay, 1);
					timer.addEventListener(TimerEvent.TIMER, onSignOnRequest);
					timer.start();
				} 
			}			
		}
		
		private function onSignOnRequest(e:TimerEvent):void {
			if (e && e.target) {
				var timer:Timer = e.target as Timer;
				if (timer) {
					timer.removeEventListener(TimerEvent.TIMER, onSignOnRequest);
				}
			}
			// fire off an event to our AIM API log in
			var loginEvent:GlobalLoginEvent = new GlobalLoginEvent(GlobalLoginEvent.SESSION_LOGIN);
			GlobalIMEvent.global.dispatchEvent(loginEvent);			
		}
		
		public function signOff():void {
			// fire off an event to our AIM API to log off
			var loginEvent:GlobalLoginEvent = new GlobalLoginEvent(GlobalLoginEvent.LOGOFF);
			GlobalIMEvent.global.dispatchEvent(loginEvent);
			_loggingIn = false;
			_loginAttempts = 0;
		}

		private function onSignOffRequest(e:IMProxyEvent):void {
			signOff();
		}		

		private function onSendIMWithGaiaId(e:IMProxyEvent):void {
			sendIMWithGaiaId(e.message, e.gaiaId);
		}
		
		public function sendIMWithGaiaId(txt:String, userId:String):void {
			_aimAPI.sendIMwithGaiaId(userId, txt);
		}

		private function onSendIMWithGaiaName(e:IMProxyEvent):void {
			sendIMWithGaiaName(e.message, e.gaiaName);
		}
				
		public function sendIMWithGaiaName(txt:String, userName:String):void {
			_aimAPI.sendIMwithGaiaName(userName, txt);
		}

		private function onSendIMToGuild(e:IMProxyEvent):void {
			sendGuildBroadcast(e.message, e.guildId);
		}
				
		public function sendGuildBroadcast(txt:String, guildId:String):void {		
			_aimAPI.sendIMtoGuild(guildId, txt);
		}		

		private function onBuddyListRefresh(e:GlobalBuddyListEvent):void {
			// Nothing to do for now; we should create a visible buddy list later
		}

		//----- IM error handling
		private function onIMLoginError(e:GlobalLoginRequestResult):void {
			var evt:BattleIMEvent = null;
			var msg:String = "";
			var imProxyEvent:IMProxyEvent = null;
			if (e.errorCode == "502") {
				if (this._loginAttempts < 4) { 
					return;
				}	
			} 	
					
			if (e.errorCode == "607") {
				// then most likely the user has been rate limited
				// UGH--would be nice to know how long to wait, but I'm not sure we know that
				msg = "You have logged in to GIM too frequently from this account.  Please wait until later before logging in again.";
				evt = new BattleIMEvent(BattleIMEvent.LOGIN_ERROR, e.errorCode, msg);		
				imProxyEvent = new IMProxyEvent(IMProxyEvent.LOGIN_ERROR);
				imProxyEvent.errorCode = e.errorCode;
				imProxyEvent.battleIMEvent = evt;
				IMProxyEvent.proxy.dispatchEvent(imProxyEvent);						

				return;
			}

			if (e.errorCode == "505") {
				// The user hasn't verified his or her email address
				if (!this._notRegMessageShown) {
					// We may not have the email address yet because we may not have gotten the player info yet.  But since we keep trying to log into
					// GIM, pretty quickly we'll get this error again after we have the email address, so we'll let that dynamic just work itself out.
					// Also, we allow our mechanism to keep trying to log in to continue, in case the user verifies his or her email address while
					// still in an active session.  In that case, we'll try again, and all of a sudden, we're into GIM!					
					if (this._userEmailAddress != null) {  
						msg = "You cannot use GIM until you verify your email address.  Go to " + this._userEmailAddress + " and respond to the email we sent you.";
						evt = new BattleIMEvent(BattleIMEvent.LOGIN_ERROR, null, msg);		
						imProxyEvent = new IMProxyEvent(IMProxyEvent.LOGIN_ERROR);
						imProxyEvent.errorCode = e.errorCode;
						imProxyEvent.battleIMEvent = evt;
						IMProxyEvent.proxy.dispatchEvent(imProxyEvent);
						
						this._notRegMessageShown = true;
					} else {
						this.retryLogin();
					}						
				}
				return;
			}

			if (e.errorCode == "506") {
				// A TOS agreement failure
				msg = "You have not agreed to the GIM terms of service.";
				evt = new BattleIMEvent(BattleIMEvent.LOGIN_ERROR, e.errorCode, msg);		
				imProxyEvent = new IMProxyEvent(IMProxyEvent.LOGIN_ERROR);
				imProxyEvent.errorCode = e.errorCode;				
				imProxyEvent.battleIMEvent = evt;
				IMProxyEvent.proxy.dispatchEvent(imProxyEvent);						

				return;
			}
			
			var errorText:String = "Login to GIM failed: " + e.text + ". Trying to log in again...";			
			evt = new BattleIMEvent(BattleIMEvent.NOT_LOGGED_IN, e.errorCode, errorText);
			var imProxyEvent2:IMProxyEvent = new IMProxyEvent(IMProxyEvent.NOT_LOGGED_IN);
			imProxyEvent2.errorCode = e.errorCode;			
			imProxyEvent2.battleIMEvent = evt;
			IMProxyEvent.proxy.dispatchEvent(imProxyEvent2);						
	
			this.retryLogin();
		}

		private function retryLogin():void {
			_loggingIn = false;
			signOn();			
		}
		
		private function onUserHasNonCompliantAimId(e:GlobalLoginRequestResult):void {
			if (flash.external.ExternalInterface.available) {
				var url:String = e.text;
	  			ExternalInterface.call("requestGIMReg", url);
	  		} else {
				var msg:String = "Unable to log you into GIM because you need to register a GIM id.  Please navigate to " + url + "choose a GIM id.";
				var evt:BattleIMEvent = new BattleIMEvent(BattleIMEvent.LOGIN_ERROR, "", msg);
				var imProxyEvent:IMProxyEvent = new IMProxyEvent(IMProxyEvent.LOGIN_ERROR);
				imProxyEvent.battleIMEvent = evt;
				IMProxyEvent.proxy.dispatchEvent(imProxyEvent);						
	  		}
		}		
		
		private function onIMLoginSuccess(e:GlobalSessionEvent):void {
			if (this._recentlyDisconnected) {
				// wait some time before issuing that we were successfully logged back in, since sometimes AIM ping pongs us
				// back and forth between being logged in and out over and over
				this._successfulLoginTimer.addEventListener(TimerEvent.TIMER_COMPLETE, onSuccessfulLoginTimerComplete, false, 0, true);
				this._successfulLoginTimer.start();	
			} else {
				this.sendSuccessfulLoginMessage();
			}
		}
		
		private function onSuccessfulLoginTimerComplete(e:TimerEvent):void {
			this._successfulLoginTimer.removeEventListener(TimerEvent.TIMER_COMPLETE, onSuccessfulLoginTimerComplete);
			if (this._aimAPI.isOnline()) {
				// we've stayed logged in long enough that we're probably not going to ping-pong
				this._recentlyDisconnected = false;				
				this.sendSuccessfulLoginMessage();
			}
			// otherwise, the disconnect code will try to log us back in, but we don't want to tell the user about this over and over
		}
		
		private function sendSuccessfulLoginMessage():void {			
			var evt:BattleIMEvent = new BattleIMEvent(BattleIMEvent.LOGIN_SUCCESS,"","");
			var imProxyEvent:IMProxyEvent = new IMProxyEvent(IMProxyEvent.LOGIN_SUCCESS);
			imProxyEvent.battleIMEvent = evt;
			IMProxyEvent.proxy.dispatchEvent(imProxyEvent);						

			_loggingIn = false;
			_loginAttempts = 0;			
		}		
		
		private function onNoIMSession(e:GlobalSessionEvent):void {
			var msg:String = this._enableGIM ? "You are not currently logged into GIM.  Trying to log you in . . ." : "GIM is not currently enabled.";
			var evt:BattleIMEvent = new BattleIMEvent(BattleIMEvent.ACTION_REQUESTED_WITH_NO_SESSION, "", msg);
			var imProxyEvent:IMProxyEvent = new IMProxyEvent(IMProxyEvent.ACTION_REQUESTED_WITH_NO_SESSION);
			imProxyEvent.battleIMEvent = evt;

			IMProxyEvent.proxy.dispatchEvent(imProxyEvent);														
			signOn();			
		}
		
		private function onIMDisconnected(e:GlobalSessionEvent):void {
			if (!this._recentlyDisconnected) {  // _recentlyDisconnected may get reset to true if we've been logged in long enough						
			var msg:String = "You have been disconnected from GIM.  Trying to log you in again . . .";
			var evt:BattleIMEvent = new BattleIMEvent(BattleIMEvent.NOT_LOGGED_IN, "", msg);
			var imProxyEvent:IMProxyEvent = new IMProxyEvent(IMProxyEvent.NOT_LOGGED_IN);
			imProxyEvent.battleIMEvent = evt;
			IMProxyEvent.proxy.dispatchEvent(imProxyEvent);						
			}
			
			this._recentlyDisconnected = true;			
			
			this.retryLogin();
		}
		private function onIMLoggedOut(e:GlobalSessionEvent):void {
			// I'm pretty sure the text describes the only condition under which this can happen
			var msg:String = "You have logged out of GIM from another location.";
			var evt:BattleIMEvent = new BattleIMEvent(BattleIMEvent.NOT_LOGGED_IN, "", msg);
			var imProxyEvent:IMProxyEvent = new IMProxyEvent(IMProxyEvent.NOT_LOGGED_IN);
			imProxyEvent.battleIMEvent = evt;
			IMProxyEvent.proxy.dispatchEvent(imProxyEvent);						
		}
		private function onIMReconnecting(e:GlobalSessionEvent):void {
			// do nothing for now
		}		
		private function onInvalidRecipientName(e:GlobalNameResolveError):void {
			var msg:String = "Unable to send your message to " + e.gaiaName + ": no user by that name.";
			var evt:BattleIMEvent = new BattleIMEvent(BattleIMEvent.MESSAGE_DELIVERY_FAILURE, "", msg);
			var imProxyEvent:IMProxyEvent = new IMProxyEvent(IMProxyEvent.MESSAGE_DELIVERY_FAILURE);
			imProxyEvent.battleIMEvent = evt;
			IMProxyEvent.proxy.dispatchEvent(imProxyEvent);						
		}
		private function onSelfSend(e:GlobalNameResolveError):void {
			var msg:String = "That's what she said.";
			var evt:BattleIMEvent = new BattleIMEvent(BattleIMEvent.MESSAGE_DELIVERY_FAILURE, "", msg);
			var imProxyEvent:IMProxyEvent = new IMProxyEvent(IMProxyEvent.MESSAGE_DELIVERY_FAILURE);
			imProxyEvent.battleIMEvent = evt;
			IMProxyEvent.proxy.dispatchEvent(imProxyEvent);						
		}				
		private function onInvalidRecipientId(e:GlobalNameResolveError):void {
			var msg:String = "Unable to send your message to user with ID " + e.gaiaNumericId + ": no user with that ID.";
			var evt:BattleIMEvent = new BattleIMEvent(BattleIMEvent.MESSAGE_DELIVERY_FAILURE, "", msg);
			var imProxyEvent:IMProxyEvent = new IMProxyEvent(IMProxyEvent.MESSAGE_DELIVERY_FAILURE);
			imProxyEvent.battleIMEvent = evt;
			IMProxyEvent.proxy.dispatchEvent(imProxyEvent);						
		}
		private function onNoAimIdForRecipient(e:GlobalNameResolveError):void {
			var msg:String = "Unable to send your message to " + e.gaiaName + ": " + "This user does not have a GIM ID.";
			var evt:BattleIMEvent = new BattleIMEvent(BattleIMEvent.MESSAGE_DELIVERY_FAILURE, "", msg);
			var imProxyEvent:IMProxyEvent = new IMProxyEvent(IMProxyEvent.MESSAGE_DELIVERY_FAILURE);
			imProxyEvent.battleIMEvent = evt;
			IMProxyEvent.proxy.dispatchEvent(imProxyEvent);						
		}
		private function onGenericRecipientError(e:GlobalNameResolveError):void {
			// This error only fires if we've had a pretty bad failure (e.g. we couldn't contact GSI to resolve a name or GSI is down, etc.).
			var msg:String = "Unable to send your message";
			if (e.gaiaName.length > 0) {
				msg += " to " + e.gaiaName + ": unable to find the GIM ID."
			} else if (e.gaiaNumericId.length > 0) {
				msg += " to ID " + e.gaiaNumericId + ": unable to find the GIM ID.";
			} else {
				msg += ".  Unable to find GIM IDs right now.";
			}
			var evt:BattleIMEvent = new BattleIMEvent(BattleIMEvent.MESSAGE_DELIVERY_FAILURE, "", msg);
			var imProxyEvent:IMProxyEvent = new IMProxyEvent(IMProxyEvent.MESSAGE_DELIVERY_FAILURE);
			imProxyEvent.battleIMEvent = evt;
			IMProxyEvent.proxy.dispatchEvent(imProxyEvent);									
		}
		private function onInvalidGuildBroadcastReceived(e:GlobalInstantMessageEvent):void {
			// This only fires if we couldn't parse the guild broadcast; no need to tell the client UI, I suppose	
		}
		private function onGuildBroadcastReceived(evt:GlobalInstantMessageEvent):void {
			handleReceivedIM(evt, "guild");
		}		
		private function onIMReceived(evt:GlobalInstantMessageEvent):void {
			handleReceivedIM(evt, "whisper");
		}
		private function handleReceivedIM(evt:GlobalInstantMessageEvent, channel:String):void {
			var msg:String = evt.gaiaIM.aimIM.message;
			var gaiaSender:GaiaUser = evt.gaiaIM.gaiaSender;
			var actorId:String = evt.gaiaIM.gaiaSender.gaiaId;
			var senderName:String =	evt.gaiaIM.gaiaSender.label; // Could be the aim id, if from someone not on GIM
			var imReceivedEvent:IMReceivedEvent = new IMReceivedEvent(IMReceivedEvent.IM_RECEIVED, msg, actorId, channel, senderName);
			imReceivedEvent.guildId = evt.gaiaIM.guildId;
			imReceivedEvent.guildName = evt.gaiaIM.guildName;
			var imProxyEvent:IMProxyEvent = new IMProxyEvent(IMProxyEvent.IM_RECEIVED);
			imProxyEvent.imReceivedEvent = imReceivedEvent;
			IMProxyEvent.proxy.dispatchEvent(imProxyEvent);			
		}
		private function onIMSendResult(e:GlobalInstantMessageEvent):void {
			var channel:String = e.sentToGuild ? "clan" : "whisper";
			var gaiaName:String = "";
			var msg:String = "";
			var evt:BattleIMEvent = null;
			var imProxyEvent:IMProxyEvent = null;
			if (e.statusCode == "200") { // success
 				channel = e.sentToGuild ? "clan" : "whisper";
				var successEvt:IMReceivedEvent = new IMReceivedEvent(IMReceivedEvent.IM_RECEIVED, e.gaiaIM.aimIM.message, e.gaiaIM.aimIM.sender.aimId, channel, e.gaiaIM.gaiaSender.gaiaName);
				var successIMProxyEvent:IMProxyEvent = new IMProxyEvent(IMProxyEvent.MESSAGE_DELIVERY_SUCCESS);
				successIMProxyEvent.imReceivedEvent = successEvt;
				IMProxyEvent.proxy.dispatchEvent(successIMProxyEvent);
			} else {
				if (e.sentToGuild) {
					msg = "We are currently unable to send messages to your clan (error " + e.statusCode + ")";
					evt = new BattleIMEvent(BattleIMEvent.MESSAGE_DELIVERY_FAILURE, statusCode, msg);
					imProxyEvent = new IMProxyEvent(IMProxyEvent.MESSAGE_DELIVERY_FAILURE);
					imProxyEvent.battleIMEvent = evt;
					IMProxyEvent.proxy.dispatchEvent(imProxyEvent);															
				} else switch (e.statusCode) {
					case "602":	// offline message rejected
						channel = "whisper";
						if (e.gaiaIM && e.gaiaIM.gaiaRecipient) {
							gaiaName = e.gaiaIM.gaiaRecipient.gaiaName;
						}
	 
						msg = "We were unable to send your message: " + gaiaName + " is offline."
						evt = new BattleIMEvent(BattleIMEvent.MESSAGE_DELIVERY_FAILURE, statusCode, msg);
						imProxyEvent = new IMProxyEvent(IMProxyEvent.MESSAGE_DELIVERY_FAILURE);
						imProxyEvent.battleIMEvent = evt;
						IMProxyEvent.proxy.dispatchEvent(imProxyEvent);					
						break;
					default: // general error		
						var statusCode:String = e.statusCode;
						var statusText:String = e.statusText;
						if (e.gaiaIM && e.gaiaIM.gaiaRecipient) {
							gaiaName = e.gaiaIM.gaiaRecipient.gaiaName;
						}
						msg = "Unable to send message to " + gaiaName + ".  If you're trying to send a message to a user name with a space in it, replace the space with an underscore (_): " + statusText;
						
						evt = new BattleIMEvent(BattleIMEvent.MESSAGE_DELIVERY_FAILURE, statusCode, msg);
						imProxyEvent = new IMProxyEvent(IMProxyEvent.MESSAGE_DELIVERY_FAILURE);
						imProxyEvent.battleIMEvent = evt;
						IMProxyEvent.proxy.dispatchEvent(imProxyEvent);
						break;
				}
			}		
		}
	}
}
