/* 
    * Copyright (c) 2009 by Vivox Inc.
    *
    * Permission to use, copy, distribute this software for any purpose is allowed
    * only in conjunction with the use of Vivox Services and in all cases must
    * include this notice.
    *
    * THE SOFTWARE IS PROVIDED "AS IS" AND VIVOX DISCLAIMS
    * ALL WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED
    * WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL VIVOX
    * BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL
    * DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR
    * PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS
    * ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS
    * SOFTWARE.
  */
/**
 * @author Christopher P. Pinto
 * @version 1.0.8
 * @copyright 2009 Vivox Inc. All Rights Reserved.
 * @projectDescription This file (vivoxVoice.class.js) contains a class that wraps the vivoxVoice plug in.
 * 
 */

/**
 * 
 * @param {Object} objectId
 * @param {Object} url_to_backend
 */
function vivoxVoice(objectId, url_to_backend){
    var host = this.getArg(arguments,2);
    var port = this.getArg(arguments,3);

    if (port === null || port === "" )  { port="44126"; }
    if (host === null || host === "" )  { host="127.0.0.1"; }
	return this.init(objectId, url_to_backend, host, port);
}
// Constants
var removedReason_left                             = 0;
var removedReason_timeout                          = 1;
var removedReason_kicked                           = 2;
var removedReason_banned                           = 3;
 
var session_media_none                             = 0;
var session_media_disconnected                     = 1;
var session_media_connected                        = 2;
var session_media_ringing                          = 3;
var session_media_refer                            = 4;
var session_media_connecting                       = 5;
var session_media_disconnecting                    = 6;

var participant_user                               = 0;
var participant_moderator                          = 1;
var participant_owner                              = 2;


var AudioStateDisconnected							= 0;
var AudioStateConnecting							= 1;
var AudioStateConnected								= 2;
var AudioStateAuthChallenged						= 3;
var AudioStateIncoming								= 4;


vivoxVoice.prototype = {

consoleLog:	function(msg){
  	this.consoleService.logStringMessage(msg);
},

/**
 * 
 * @param {Object} participant
 * @param {Object} session
 */
processDumpParticipant: function(participant, session){
		error_log('Participant '+participant.Uri+' found during dump');
		var wrappedParticipant = new Object();
		wrappedParticipant.IParticipant = participant;
		wrappedParticipant.IParticipant.IsLocalAudioMuted = wrappedParticipant.IParticipant.IsAudioMutedForMe;
		wrappedParticipant.IParticipant.IsModeratorAudioMuted = wrappedParticipant.IParticipant.IsAudioModeratorMuted;
		wrappedParticipant.IParticipant.IsGuest = wrappedParticipant.IParticipant.IsAnonymousLogin;
		
		error_log('onParticipantAdded '+serialize(wrappedParticipant));
		this.onParticipantAdded(this.m_AccountHandle, session.Uri, wrappedParticipant);
},
/**
 * 
 * @param {Object} session
 */
processDumpSession: function(session){
    var mySes = new Object();
    mySes.ISession = new Object();
    mySes.ISession.Uri              = session.Uri;
    mySes.ISession.Name             = session.Name;
    mySes.ISession.SessionHandle    = session.SessionHandle;
	mySes.ISession.VoiceFont	 	= session.SessionFontId;
    mySes.ISession.HasAudio         = session.HasAudio;
    mySes.ISession.HasText          = session.HasText;
    mySes.ISession.IsFocused        = session.IsFocused;
    mySes.ISession.IsTransmitEnabled = session.IsTransmitEnabled;
    mySes.ISession.IsIncoming        = session.IsIncoming;
    mySes.ISession.IsPositional      = session.IsPositional;
    mySes.ISession.IsConnected       = session.IsConnected;
    mySes.ISession.IsAudioMutedForMe = session.IsAudioMutedForMe;
    mySes.ISession.IsTextMutedForMe  = session.IsTextMutedForMe;
    mySes.ISession.SessionFontId     = session.SessionFontId;
    mySes.ISession.Volume            = session.Volume;
    mySes.ISession.DisplayName       = session.DisplayName ;
    mySes.ISession.HasAudio          = session.HasAudio;
    mySes.ISession.HasText           = session.HasText;
    mySes.ISession.IsAudioModeratorMuted = session.IsAudioModeratorMuted;
    mySes.ISession.IsTextModeratorMuted = session.IsTextModeratorMuted;
    mySes.ISession.IsAudioMuted      = session.IsAudioMutedForMe;
    mySes.ISession.IsAudioMutedForMe = session.IsAudioMutedForMe;
    mySes.ISession.IsHandRaised      = session.IsHandRaised;
    mySes.ISession.IsTyping          = session.IsTyping;
    mySes.ISession.IsSpeaking        = session.IsSpeaking;
    mySes.ISession.Type              = session.Type;
    mySes.ISession.Volume            = session.Volume;
    mySes.ISession.Energy            = session.Energy;
    this.setSessionState(this.m_AccountHandle, session.Uri, mySes);
    if ( this.m_cbAudioStateChanged !== null ){
		try {
			this.m_cbAudioStateChanged(this.m_AccountHandle, session.Uri, 'AudioStateConnected', 200);
		} catch (e) {
			error_log('Exception in processDumpSession calling client callback AudioStateChanged '+e);
		}
    }
	if ( session.Participants && session.Participants.Participant ){
		error_log('Dump ok with a Session and Participants present.');
		var participantsList = session.Participants.Participant;
		if (participantsList.length > 0) {
			error_log('found multiple participants');
			for (var i = 0; i < participantsList.length; i++) {
				var participant = participantsList[i];
				this.processDumpParticipant(participant, session);
			}
		} else {
			error_log('found a single participant');
			this.processDumpParticipant(participantsList, session);
		}
	}
},
/**
 * 
 * @param {Object} sessionGroup
 */
processDumpSessionGroup: function (sessionGroup){
	if ( sessionGroup.Sessions && sessionGroup.Sessions.Session){
		var session = sessionGroup.Sessions.Session;
		error_log('session '+serialize(session));
		if ( session.length ){
			error_log('Dump ok with a multiple Session(s) present.');
			for (var i = 0; i < session.length; i++) {
				var aSession = session[i];
				this.processDumpSession(aSession);
			}
		} else {
			error_log('Dump ok with a Session present.');
			error_log('Found a single session');
			this.processDumpSession(session);
		}
	}
},	
/**
 * 
 * @param {Object} userUri
 */
getUserName: function (userUri){
	var userParts = userUri.split(':');
	var userNameValue = userParts[1].split('@');
	return userNameValue[0];
},
/**
 * 
 * @param {Object} requestId
 * @param {Object} responseAction
 * @param {Object} responseObj
 * @param {Object} returnCode
 */
processDump: function (requestId, responseAction, responseObj, returnCode){
    if ( returnCode === "0" ){
        var results = responseObj.Response.Results;
		if ( results.Connectors && results.Connectors.Connector)
		{
			this.m_ConnectorHandle = results.Connectors.Connector.ConnectorHandle;
			var micMute = (results.Connectors.Connector.MicMute == "1")? "true" : "false";
			var speakerMute = (results.Connectors.Connector.SpeakerMute == "1")? "true" : "false";
			this.onLocalMicMute(this.m_ConnectorHandle, micMute);
			this.onLocalSpeakerMute(this.m_ConnectorHandle, speakerMute);
			if ( results.Connectors.Connector.Accounts ){
				this.m_AccountHandle = results.Connectors.Connector.Accounts.Account.AccountHandle;
				this.m_AccountUri = results.Connectors.Connector.Accounts.Account.AccountUri;
				this.m_userName = this.getUserName(this.m_AccountUri);
				
				this.m_Domain = this.getDomain(this.m_AccountUri);
				error_log("domain from accountUri is "+this.m_Domain+" "+this.m_AccountUri)
				var accounts = results.Connectors.Connector.Accounts.Account;
				var len = this.m_userName.length;
				if ( this.m_userName.substr(0,1) == '.' && this.m_userName.substr(len-1,1) == "." ){
					this.m_AnonymousLogin = true;						
				} else {
					this.m_AnonymousLogin = false;						
				}
				if (this.m_cbAccountLoginStateChange) {
					try {
						this.m_cbAccountLoginStateChange(this.m_AccountHandle, 200, 'OK', 1);
					} catch (e) { 
						error_log('Exception in processDump calling client callback AccountLoginStatChange '+e);
					}
				}
				error_log('Dump ok with an AccountHandle present.');
				error_log('sessionGroups '+serialize(accounts.SessionGroups));
				if ( accounts.SessionGroups && accounts.SessionGroups.SessionGroup){
					var sessionGroup = accounts.SessionGroups.SessionGroup;
					if ( sessionGroup.length ){
						error_log('found multiple sessionGroups');
						for (var i = 0; i < sessionGroup.length; i++) {
							var aSessionGroup = sessionGroup[i];
							error_log('sessionGroup '+serialize(sessionGroup));
							this.processDumpSessionGroup(aSessionGroup);
						}
					} else {
						error_log('found a single sessionGroup');
						error_log('sessionGroup '+serialize(sessionGroup));
						this.processDumpSessionGroup(sessionGroup);
					}
					
				} else {
					error_log('Dump ok with no Sessions Present');
				}
			} else {
				error_log('Dump ok with no Accounts');
				var foo = 'bar';
			}
		}
    } else {
        this.m_ConnectorHandle = null;
    }
},
/**
 * 
 * @param {Object} responseAction
 * @param {Object} responseObj
 * @param {Object} returnCode
 */
processConnectorMutes: function (responseAction, responseObj, returnCode){
    if ( returnCode === "0" ){
		
        var value = responseObj.Response.InputXml.Request.Value;
		var valBool = (value == "true") ? true : false;
		switch(responseAction) {
			case 'Connector.MuteLocalSpeaker.1':
				this.onLocalSpeakerMute(this.m_ConnectorHandle, value);
			break;
			case 'Connector.MuteLocalMic.1':
				this.onLocalMicMute(this.m_ConnectorHandle, value);
			break;
			
		}
    } 
},
/**
 * 
 * @param {Object} uri
 */
getDomain: function (uri){
	var parts = uri.split('@');
	var index = parts.length-1;
	return parts[index];
},
/**
 * 
 * @param {String} requestId
 * @param {String} responseAction
 * @param {Object} responseObj
 * @param {Number} returnCode
 */
handleStateChanges: function(requestId, responseAction, responseObj, returnCode){
    error_log('state change for '+ responseAction + 'returnCode '+ returnCode);
    switch(responseAction){
        case 'Connector.Create.1':
            if ( returnCode === "0" ){
                this.m_ConnectorHandle = responseObj.Response.Results.ConnectorHandle;
            } else {
                this.m_ConnectorHandle = null;
            }
        break;
        case 'Account.Login.1':
		case 'Account.AnonymousLogin.1':
            if ( returnCode === "0" ){
                this.m_AccountHandle = responseObj.Response.Results.AccountHandle;
				this.m_AccountUri = responseObj.Response.Results.Uri;
				this.m_userName = this.getUserName(this.m_AccountUri);
				this.m_Domain = this.getDomain(this.m_AccountUri);
				error_log('Saving AccountHandle, Uri & domain '+this.m_AccountHandle+' '+this.m_AccountUri+' '+this.m_Domain);
				this.m_AnonymousLogin = (responseAction == 'Account.AnonymousLogin.1') ? true : false;
            } else {
                this.m_AccountHandle = null;
				this.m_AccountUri = null;
				this.m_userName = null;
				this.m_Domain = null;
				this.m_AnonymousLogin = null;
            }
        break;
        
        case 'Aux.DiagnosticStateDump.1':
			this.processDump(requestId, responseAction, responseObj, returnCode);
        break;
	
	case 'Connector.MuteLocalSpeaker.1':
	case 'Connector.MuteLocalMic.1':
		this.processConnectorMutes(responseAction, responseObj, returnCode);
		break;
	
	default:
		break;
	
    }
	// console.timeEnd('handleStateChanges');
},
/**
 * 
 * @param {String} xml
 */
messageHandler: function(xml){
	var dtFinish = new Date();
	var dtValue = dtFinish.valueOf();
	
	if ( getSelf() === undefined){
		return;
	}
	var self        	= getSelf();
    var responseObj     = self.toObject(xml);
    if ( responseObj.Response ){
        var requestId       = responseObj.Response['@requestId'];
        var responseType    = responseObj.Response['@action'];
        var returnCode      = responseObj.Response.ReturnCode;
        self.handleStateChanges(requestId, responseType, responseObj, returnCode);

    var closure = hashCache.data(requestId);
	// free the memory
	if (closure) {
		hashCache.removeData(requestId, null);
	    if ( closure.onCompletion) {
        closure.onCompletion(closure, responseObj);
        }
	}
	var time = 'unknown time'
	if (closure && closure.requestTime) {
		time = dtValue - closure.requestTime;
		error_log('Round Trip ' + time + 'ms Response  ' + xml);
	} else {
		error_log('Response  ' + xml);
	}
		// console.timeEnd('messageHandler');
		if (self.m_clientMessageHandler !== null){
		    self.m_clientMessageHandler(responseObj);
		}
        return;
    }
    if ( responseObj.Event ){
		var type = responseObj.Event['@type'];
	var action = responseObj.Event['@action'];
	if ( type == 'MediaCompletionEvent'){
		if ( self.m_cbMediaCompletion ){
			self.m_cbMediaCompletion(responseObj.Event.MediaCompletionType);
		}
	}
	if ( type == 'AccountLoginStateChangeEvent'){
		var AccountHandle 	= responseObj.Event.AccountHandle;
		var StatusCode 		= responseObj.Event.StatusCode;
		var StatusString	= responseObj.Event.StatusString;
		var State 		= responseObj.Event.State;
		if (StatusCode == 200 && StatusString == "OK" && State == 1) {
			self.m_AccountHandle = AccountHandle;
		}
		if ( self.m_cbAccountLoginStateChange ){
			self.m_cbAccountLoginStateChange(AccountHandle, StatusCode, StatusString, State);
		}
        } else if ( type == 'AuxAudioPropertiesEvent'){
            error_log('received AuxAudioPropertiesEvent'+xml);
        } else if ( type == 'VoiceServiceConnectionStateChangedEvent') {
            error_log('received VoiceServiceConnectionStateChangedEvent '+xml);
            // force a new login
            if (self.m_ConnectorHandle != null) {
                self.handleStateChanges(requestId, 'Connector.Create.1', responseObj, -1);
                self.handleStateChanges(requestId, 'Account.Login.1', responseObj, -1);
                self.m_cbAccountLoginStateChange(AccountHandle, StatusCode, 'VVM restarted', 4);
                if ( self.m_Host ){  // had been started at one point
                    //error_log ('Host is set to '+ self.m_Host);
                    if ( self.m_cbServiceAvailablityStateChanged ){
                        self.m_cbServiceAvailablityStateChanged(1);
                    }
                }
            }
            return;
        } else {
            // unhandled event, log it
            // error_log('received unhandled responseObj.Event '+xml);
	}
	if ( action == 'OWI.Authorize'){
		error_log('received OWI.Authorize action');
		if ( self.m_cbAuthorize ){
			self.m_cbAuthorize(responseObj.Event);
		}
		
	}
	if ( action == 'OWI.AcceptanceListAllow'){
		error_log('received OWI.AcceptanceListAllow');
		if ( self.m_cbAcceptanceListAllow ){
			self.m_cbAcceptanceListAllow(responseObj.Event);
		}
	}
		if (self.m_clientMessageHandler !== null){
		    self.m_clientMessageHandler(responseObj);
		}
    }
	if (action == 'AccountLogin.1') {
		error_log('received AccountLogin.1');
	}
	
	// console.timeEnd('messageHandler');
	
},
/**
 * 
 * @param {Object} callbacks
 */
setCallbacks: function( callbacks ){
    for (var prop in callbacks){
        switch (prop){
            case "onParticipantUpdated":
                this.m_cbParticipantUpdated = callbacks[prop];
            break;
            case "onParticipantAdded":
                this.m_cbParticipantAdded = callbacks[prop];
            break;
            case "onParticipantRemoved":
                this.m_cbParticipantRemoved = callbacks[prop];
            break;
            case "onTextStateChanged":
                this.m_cbTextStateChanged = callbacks[prop];
            break;
            case "onAudioStateChanged":
                this.m_cbAudioStateChanged = callbacks[prop];
            break;
            case "onSessionUpdated":
                this.m_cbSessionUpdated = callbacks[prop];
            break;
            case "onMessageReceived":
                this.m_cbMessageReceived = callbacks[prop];
            break;
            case "onSendMsgCompleted":
                this.m_cbSendMsgCompleted = callbacks[prop];
            break;
            case "onSetVoiceFontCompleted":
                this.m_cbSetVoiceFontCompleted = callbacks[prop];
            break;
            case "onRecordingFramesCaptured":
                this.m_cbRecordingFramesCaptured = callbacks[prop];
            break;
            case "onFramePlayed":
                this.m_cbFramePlayed = callbacks[prop];
            break;
            case "onAudioInjectionCompleted":
                this.m_cbAudioInjectionCompleted = callbacks[prop];
            break;
            case "onAccountLoginStateChange":
                this.m_cbAccountLoginStateChange = callbacks[prop];
            break;
	        case "onAuthorize":
	            this.m_cbAuthorize = callbacks[prop];
	        break;
	        case "onAcceptanceListAllow":
	            this.m_cbAcceptanceListAllow = callbacks[prop];
	        break;
			case "onChannelError":
	            this.m_cbChannelError = callbacks[prop];
			break;
			case "onParticipantError":
	            this.m_cbParticipantError = callbacks[prop];
			break;
			case "onUnhandledError":
	            this.m_cbUnhandledError = callbacks[prop];
			break;
			case "onLocalSpeakerMute":
	            this.m_cbLocalSpeakerMute = callbacks[prop];
			break;
			case "onLocalMicMute":
	            this.m_cbLocalMicMute = callbacks[prop];
			break;
	        case "onServiceAvailablityStateChanged":
	            this.m_cbServiceAvailablityStateChanged = callbacks[prop];
			break;
	        case "onMediaCompletion":
	            this.m_cbMediaCompletion = callbacks[prop];
			break;
	        case "onRecordingStarted":
	            this.m_cbRecordingStarted = callbacks[prop];
			break;
	        case "onRecordingStopped":
	            this.m_cbRecordingStopped = callbacks[prop];
			break;
	        case "onRecordingSaveProgress":
	            this.m_cbRecordingSaveProgress = callbacks[prop];
			break;
			case "onWavDestination":
				this.m_cbWavDestination = callbacks[prop];
			break;
	        default: 
				error_log('unknown callback type'+prop)
	        break;
        }
    }
},
/**
 * 
 */
unsetCallbacks: function(){
    this.m_cbParticipantUpdated 						= null;
    this.m_cbParticipantAdded 							= null;
    this.m_cbParticipantRemoved 						= null;
    this.m_cbTextStateChanged 							= null;
    this.m_cbAudioStateChanged 							= null;
    this.m_cbSessionUpdated 							= null;
    this.m_cbMessageReceived 							= null;
    this.m_cbSendMessageCompleted 						= null;
    this.m_cbAudioStateChanged 							= null;
    this.m_cbSetVoiceFontCompleted 						= null;
    this.m_cbFramePlayed 								= null;
    this.m_cbAudioInjectionCompleted 					= null;
    this.m_cbAccountLoginStateChange 					= null;
    this.m_cbAuthorize 									= null;
    this.m_cbAcceptanceListAllow 						= null;
    this.m_cbChannelError 								= null;
    this.m_cbParticipantError 							= null;
    this.m_cbUnhandledError 							= null;
    this.m_cbLocalSpeakerMute 							= null;
    this.m_cbLocalMicMute 								= null;
    this.m_cbServiceAvailablityStateChanged 			= null;
    this.m_cbMediaCompletion 							= null;
    this.m_cbRecordingStarted 							= null;
    this.m_cbRecordingStopped 							= null;
    this.m_cbRecordingSaveProgress 						= null;
    this.m_scriptObject.vx_get_message              	= null;
    this.m_scriptObject.onTextStateChanged          	= null;
    this.m_scriptObject.onAudioStateChanged         	= null;
    this.m_scriptObject.onParticipantAdded          	= null;
    this.m_scriptObject.onParticipantRemoved        	= null;
    this.m_scriptObject.onParticipantUpdated        	= null;
    this.m_scriptObject.onParticipantRemoved        	= null;
    this.m_scriptObject.onSessionUpdated            	= null;
    this.m_scriptObject.onMessageReceived          		= null;
    this.m_scriptObject.onSendMsgCompleted          	= null;
    this.m_scriptObject.onSetVoiceFontCompleted     	= null;
    this.m_scriptObject.onRecordingFramesCaptured   	= null;
    this.m_scriptObject.onFramePlayed               	= null;
    this.m_scriptObject.onAudioInjectionCompleted   	= null;
	this.m_scriptObject.onChannelError              	= null;
  	this.m_scriptObject.onParticipantError          	= null;
  	this.m_scriptObject.onUnhandledError           		= null;
	this.m_scriptObject.onRecordingStarted				= null;
	this.m_scriptObject.onRecordingStopped				= null;
	this.m_scriptObject.onRecordingSaveProgress			= null;
	this.m_scriptObject.onWavDestination				= null;
    this.m_scriptObject.onServiceAvailablityStateChanged= null;
	
},
/**
 * 
 * @param {Object} args
 * @param {Number} minArgs
 */
getArg: function(args, minArgs){
    if ( args.length > minArgs){
        return args[minArgs];
    } else {
        return null;
    }
},
/**
 * 
 * @param {String} xml
 */
parseXml: function(xml) {
   var dom = null;
   if (window.DOMParser) {
      try { 
         dom = (new DOMParser()).parseFromString(xml, "text/xml"); 
      } 
      catch (e) { dom = null; }
   }
   else if (window.ActiveXObject) {
      try {
         dom = new ActiveXObject('Microsoft.XMLDOM');
         dom.async = false;
         if (!dom.loadXML(xml)) // parse error ..
            window.alert(dom.parseError.reason + dom.parseError.srcText);
      } 
      catch (e) { dom = null; }
   }
   else
      alert("oops");
   return dom;
},
/**
 * 
 * @param {String} xml
 */
toObject: function(xml){
    var jsonString = xml2json(this.parseXml(xml), "  ");
    var jsonObject = eval('json='+jsonString);
    return jsonObject;
},
/**
 * 
 * @param {String} xml
 */
makeXml: function(xml){
    var dom = null;
    if (window.DOMParser) {
        try {
            dom = (new DOMParser()).parseFromString(xml, "text/xml");
        } 
        catch (e) {
            dom = null;
        }
} else if (window.ActiveXObject) {
            try {
                dom = new ActiveXObject('Microsoft.XMLDOM');
                dom.async = false;
                if (!dom.loadXML(xml)) // parse error ..
                    window.alert(dom.parseError.reason + dom.parseError.srcText);
            } 
            catch (e) {
                dom = null;
            }
} else alert("oops");

    return dom;
},
/**
 * 
 * @param {String} xml
 */
makeObject: function(xml){
    var jsonString = xml2json(this.makeXml(xml), "  ");
    var jsonObject = eval('json=' + jsonString);
    return jsonObject;
},
/**
 * 
 * @param {String} name
 */
createRequestObject: function(name){
	// console.time('createRequestObject');
    if ( this.m_scriptObject ){
		try {
	        var requestXml = this.m_scriptObject.vx_req_create(name);
		} catch(e){
			this.handleException(e);
		}
		if ( !requestXml ){
			error_log('failed creating request for '+name);
		}
        var requestObject = this.toObject(requestXml);
        this.m_RequestId++;
        requestObject.Request['@requestId'] = "Req-"+this.hashCachePrefix+this.m_RequestId;
		// console.timeEnd('createRequestObject');
        return requestObject;
    } else {
        if ( this.m_scriptObject ){
            error_log('scriptObject.vx_req_create is undefined');
        } else {
            error_log('scriptObject is undefined');
        }
		// console.timeEnd('createRequestObject');
        return null;
    }
},
/**
 * 
 * @param {Object} requestObj
 * @param {Object} callback
 */
issueRequestObject: function (requestObj, callback){
	var dt = new Date();
    if ( callback !== null ){
		callback.requestTime = dt.valueOf();
	} else {
		callback = {requestTime: dt.valueOf()};
    }
	var cacheId = requestObj.Request['@requestId'];
	hashCache.data(cacheId, callback);
	var conCreateReqXml = json2xml(requestObj);
	error_log('issueRequestObject '+conCreateReqXml);
	try {
        this.m_scriptObject.vx_issue_request(conCreateReqXml);
    } catch(e) {
		this.handleException(e);
    }
},
/**
 * 
 * @param {Object} e
 */
handleException: function(e){
	if (e.number === undefined) {
		error_log(e);
	}
	else {
		var number = e.number;
		if (number < 0) {
			number = 0xFFFFFFFF + number + 1;
		}
		error_log("Error calling vx_issue_request: '" + e.message + "', 0x" + number.toString(16));
	}
},
/**
 * 
 * @param {String} accountHandle
 * @param {String} focusUri
 * @param {Object} session
 */
setSessionState: function (accountHandle, focusUri, session){
    if (!this.m_ActiveAccounts[accountHandle]){
        this.m_ActiveAccounts[accountHandle] = new Object();
    }
    if ( !this.m_ActiveAccounts[accountHandle][focusUri]){
        this.m_ActiveAccounts[accountHandle][focusUri] = new Object();
    }
    this.m_ActiveAccounts[accountHandle][focusUri].Session = session;
},
/**
 * 
 * @param {String} accountHandle
 * @param {String} focusUri
 */
getSessionState: function (accountHandle, focusUri){
    if ( !this.m_ActiveAccounts[accountHandle] ){
		error_log('getSessionState accountHandle not found');
        return null;
	}
    if (!this.m_ActiveAccounts[accountHandle][focusUri]) {
		error_log('getSessionState focusUri not found');
		return null;
	}
    if (!this.m_ActiveAccounts[accountHandle][focusUri].Session) {
		error_log('getSessionState session not found');
		return null;
	}
    return this.m_ActiveAccounts[accountHandle][focusUri].Session;            
},
/**
 * 
 * @param {String} accountHandle
 * @param {String} focusUri
 * @param {Object} participant
 */
setParticipantState: function (accountHandle, focusUri, participant){
    if (!this.m_ActiveAccounts[accountHandle]){
        this.m_ActiveAccounts[accountHandle] = new Object();
    }
    if ( !this.m_ActiveAccounts[accountHandle][focusUri] ){
        this.m_ActiveAccounts[accountHandle][focusUri] = new Object();
    }
    this.m_ActiveAccounts[accountHandle][focusUri][participant.IParticipant.Uri] = participant;
},
/**
 * 
 * @param {String} accountHandle
 * @param {String} focusUri
 * @param {Object} participantUri
 */
getParticipantState: function (accountHandle, focusUri, participantUri){
    if ( !this.m_ActiveAccounts[accountHandle] ){
		error_log('getParticipantState accountHandle not found');
        return null;
	}
    if (!this.m_ActiveAccounts[accountHandle][focusUri]) {
		error_log('getParticipantState focusUri not found');
		return null;
	}
    if (!this.m_ActiveAccounts[accountHandle][focusUri][participantUri]) {
		return null;
	}
    return this.m_ActiveAccounts[accountHandle][focusUri][participantUri];            
},

//
//	S D K  C A L L S
//    
/**
 * 
 * @param {String} url
 * @param {String} web_domain
 */
Vvx: function(url, web_domain) { 
    var callback = this.getArg(arguments,2);
    var vvxReq = this.createRequestObject("vvx_req");
    if ( vvxReq ){     
        vvxReq.Request.Content = url;
		vvxReq.Request.Url	   = web_domain;
        this.issueRequestObject(vvxReq, callback);
        return false;
    } else {
        error_log('failed creating vvx object');
        return this.m_reqObjCreateError;
    }
    
},
/**
 * 
 * @param {String} accountname
 * @param {String} accountpassword
 */
Login: function(accountname, accountpassword) { 
    var callback = this.getArg(arguments,2);
	
    var loginReq = this.createRequestObject("vx_req_account_login");
    if ( loginReq ){        
        loginReq.Request.ConnectorHandle = this.m_ConnectorHandle;
		loginReq.Request.EnableText = "TextModeEnabled";
        loginReq.Request.AccountName = accountname;
        loginReq.Request.AccountPassword = accountpassword;
        loginReq.Request.ParticipantPropertyFrequency = 100;
        loginReq.Request.AccountManagementServer = this.m_ManagementServer;
		loginReq.Request.EnableBuddiesAndPresence = "true";
		
        this.issueRequestObject(loginReq, callback);
        return false;
    } else {
        error_log('failed creating connector login object');
        return this.m_reqObjCreateError;
    }
    
},
/**
 * 
 * @param {String} Url
 * @param {Object} Parameters
 */
WebCall: function(Url, Parameters) { 
    var callback = this.getArg(arguments,2);
	
    var webReq = this.createRequestObject("vx_req_account_web_call");
	var ParameterArray = new Array();
	var i = 0;
    for (var paramName in Parameters) {
		
		ParameterArray[i] = {
								Name: paramName,
								Value: Parameters[paramName]
							};
		i++;
	}
    if ( webReq ){        
		webReq.Request.AccountHandle = this.m_AccountHandle;		
		webReq.Request.RelativePath = Url;
		webReq.Request.Parameters = new Object();
		webReq.Request.Parameters.Parameter = ParameterArray;
        this.issueRequestObject(webReq, callback);
        return false;
    } else {
        error_log('failed creating connector web call  object');
        return this.m_reqObjCreateError;
    }
    
},
/**
 * 
 * @param {String} displayname
 */
AnonymousLogin: function(displayname) { 
    var callback = this.getArg(arguments,1);
	
    var loginReq = this.createRequestObject("vx_req_account_anonymous_login");
    if ( loginReq ){        
        loginReq.Request.ConnectorHandle = this.m_ConnectorHandle;
		loginReq.Request.EnableText = "TextModeEnabled";
        loginReq.Request.DisplayName = displayname;
        loginReq.Request.ParticipantPropertyFrequency = 100;
        loginReq.Request.AccountManagementServer = this.m_ManagementServer;
        this.issueRequestObject(loginReq, callback);
        return false;
    } else {
        error_log('failed creating connector login object');
        return this.m_reqObjCreateError;
    }
    
},
/**
 * 
 * @param {String} accountHandle
 */
Logout: function(accountHandle) { 
    var callback = this.getArg(arguments,1);
    var logoutReq = this.createRequestObject("vx_req_account_logout");
    if ( logoutReq ){        
        logoutReq.Request.AccountHandle = accountHandle;
        this.issueRequestObject(logoutReq, callback);
        return false;
    } else {
        error_log('failed creating connector logout object');
        return this.m_reqObjCreateError;
    }
    
},
/**
 * 
 * @param {String} accountHandle
 * @param {String} focusUri
 * @param {String} participantUri
 */
Kick: function(accountHandle, focusUri, participantUri){
    var callback = this.getArg(arguments,3);
            
    var kickReq = this.createRequestObject("vx_req_channel_kick_user");
    if ( kickReq ){        
        kickReq.Request.AccountHandle = accountHandle;
        kickReq.Request.ChannelURI = focusUri;
        kickReq.Request.ParticipantURI = participantUri;
        this.issueRequestObject(kickReq, callback);
        return false;
    } else {
        error_log('failed creating kick request object');
        return this.m_reqObjCreateError;
    }
},
/**
 * 
 * @param {String} accountHandle
 * @param {String} focusUri
 * @param {String} participantUri
 */
Ban: function(accountHandle, focusUri, participantUri){
    var callback = this.getArg(arguments,3);
    
    var banReq = this.createRequestObject("vx_req_channel_ban_user");
    if ( banReq ){
        banReq.Request.AccountHandle = accountHandle;
        banReq.Request.ChannelURI = focusUri;
        banReq.Request.ParticipantURI = participantUri;
        this.issueRequestObject(banReq, callback);
        return false;
    } else {
        error_log('failed creating ban request object');
        return this.m_reqObjCreateError;
    }
},
/**
 * 
 * @param {String} accountHandle
 * @param {String} focusUri
 */
MuteAll: function(accountHandle, focusUri){
    var callback = this.getArg(arguments,2);
    var muteallReq = this.createRequestObject("vx_req_channel_mute_all_users");
    
    if ( muteallReq ){        
        muteallReq.Request.AccountHandle = accountHandle;
        muteallReq.Request.ChannelURI = focusUri;
        this.issueRequestObject(muteallReq, callback);
        return false;
    } else {
        error_log('failed creating mute all object');
        return this.m_reqObjCreateError;
    }        
},
/**
 * 
 * @param {String} accountHandle
 * @param {String} focusUri
 */
UnMuteAll: function(accountHandle, focusUri){
    var callback = this.getArg(arguments,2);
    var muteallReq = this.createRequestObject("vx_req_channel_unmute_all_users");
    
    if ( muteallReq ){        
        muteallReq.Request.AccountHandle = accountHandle;
        muteallReq.Request.ChannelURI = focusUri;
        this.issueRequestObject(muteallReq, callback);
        return false;
    } else {
        error_log('failed creating mute all object');
        return this.m_reqObjCreateError;
    }        
},
/**
 * 
 * @param {String} accountHandle
 * @param {String} focusUri
 * @param {String} participantUri
 */
Mute: function (accountHandle, focusUri, participantUri){
    var callback = this.getArg(arguments,3);
    var muteallReq = this.createRequestObject("vx_req_channel_mute_user");
    
    if ( muteallReq ){        
        muteallReq.Request.AccountHandle = accountHandle;
        muteallReq.Request.ChannelURI = focusUri;
		muteallReq.Request.ParticipantURI = participantUri;
        this.issueRequestObject(muteallReq, callback);
        return false;
    } else {
        error_log('failed creating mute all object');
        return this.m_reqObjCreateError;
    }        
},
/**
 * 
 * @param {String} accountHandle
 * @param {String} focusUri
 * @param {String} participantUri
 */
Unmute: function(accountHandle, focusUri, participantUri){
    var callback = this.getArg(arguments,3);
    var muteallReq = this.createRequestObject("vx_req_channel_unmute_user");
    
    if ( muteallReq ){        
        muteallReq.Request.AccountHandle = accountHandle;
        muteallReq.Request.ChannelURI = focusUri;
		muteallReq.Request.ParticipantURI = participantUri;
        this.issueRequestObject(muteallReq, callback);
        return false;
    } else {
        error_log('failed creating mute all object');
        return this.m_reqObjCreateError;
    }        
},
/**
 * 
 */
ConnectorCreate: function(){
    
    var callback = this.getArg(arguments,0);

	var conCreateReq = this.createRequestObject("vx_req_connector_create");
    if ( conCreateReq){
        conCreateReq.Request.AccountManagementServer = this.m_ManagementServer;
        conCreateReq.Request.Mode = 'Normal';
        conCreateReq.Request.MinimumPort =  9000;
        conCreateReq.Request.MaximumPort = 19000;
        
        this.issueRequestObject(conCreateReq, callback);
        return false;
    } else {
        error_log('failed creating connector request object');
        return this.m_reqObjCreateError;
    }
},
/**
 * 
 */
Dump: function(){
    var callback = this.getArg(arguments,0);
    var dumpReq = this.createRequestObject("vx_req_aux_diagnostic_state_dump");
    
    if ( dumpReq ){        
        this.issueRequestObject(dumpReq, callback);
        return false;
    } else {
        error_log('failed creating dump object');
        return this.m_reqObjCreateError;
    }        
    
},
/**
 * 
 */
GetChannelFavorites: function(){
    var callback = this.getArg(arguments,0);
    var favsReq = this.createRequestObject("vx_req_account_channel_favorites_get_list");

    if ( favsReq ){        
		favsReq.Request.AccountHandle = this.m_AccountHandle;
        this.issueRequestObject(favsReq, callback);
        return false;
    } else {
        error_log('failed creating get channel favs object');
        return this.m_reqObjCreateError;
    }        
},
/**
 * 
 * @param {String} connectorHandle
 * @param {Boolean} value
 */
MuteLocalMic: function (connectorHandle, value){
    var callback = this.getArg(arguments,2);
    var muteReq = this.createRequestObject("vx_req_connector_mute_local_mic");

    if ( muteReq ){  
		muteReq.Request.ConnectorHandle = connectorHandle;
		muteReq.Request.Value = (value)? "true": "false";
        this.issueRequestObject(muteReq, callback);
        return false;
    } else {
        error_log('failed creating mute local mic object');
        return this.m_reqObjCreateError;
    }        
},
/**
 * 
 * @param {String} connectorHandle
 * @param {Boolean} value
 */
MuteLocalSpeaker: function (connectorHandle, value){
    var callback = this.getArg(arguments,2);
    var muteReq = this.createRequestObject("vx_req_connector_mute_local_speaker");

    if ( muteReq ){        
		muteReq.Request.ConnectorHandle = connectorHandle;
		muteReq.Request.Value = (value)? "true": "false";
        this.issueRequestObject(muteReq, callback);
        return false;
    } else {
        error_log('failed creating mute local speaker object');
        return this.m_reqObjCreateError;
    }        
},
/**
 * 
 */
AudioCaptureStart: function (){
    var callback = this.getArg(arguments,0);
    var captureReq = this.createRequestObject("vx_req_aux_start_buffer_capture");

    if ( captureReq ){        
        this.issueRequestObject(captureReq, callback);
        return false;
    } else {
        error_log('failed creating mute local speaker object');
        return this.m_reqObjCreateError;
    }        
},
/**
 * 
 */
AudioCaptureStop: function (){
    var callback = this.getArg(arguments,0);
    var captureReq = this.createRequestObject("vx_req_aux_capture_audio_stop");

    if ( captureReq ){        
        this.issueRequestObject(captureReq, callback);
        return false;
    } else {
        error_log('failed creating mute local speaker object');
        return this.m_reqObjCreateError;
    }        
},
/**
 * 
 * @param {String} accountHandle
 * @param {Number} fontId
 */
AudioPlaybackStart: function (accountHandle, fontId){
    var callback = this.getArg(arguments,0);
    var captureReq = this.createRequestObject("vx_req_aux_play_audio_buffer");

    if ( captureReq ){        
		captureReq.Request.AccountHandle = accountHandle;
		captureReq.Request.TemplateFontID = fontId;
        this.issueRequestObject(captureReq, callback);
        return false;
    } else {
        error_log('failed creating mute local speaker object');
        return this.m_reqObjCreateError;
    }        
},
/**
 * 
 */
AudioPlaybackStop: function (){
    var callback = this.getArg(arguments,0);
    var captureReq = this.createRequestObject("vx_req_aux_render_audio_stop");

    if ( captureReq ){        
        this.issueRequestObject(captureReq, callback);
        return false;
    } else {
        error_log('failed creating mute local speaker object');
        return this.m_reqObjCreateError;
    }        
},
//
// SDK Channel functions
//	
/**
 * 
 * @param {String} accountHandle
 * @param {Object} properties
 */
ChannelCreate: function(accountHandle, properties) { 
/* request factory returns this:
 * 
 * Request @requestId=Req999 @action=Account.ChannelCreate.1
 * AccountHandle			null
 * Capacity					"0"
 * ChannelDescription		null
 * ChannelMode				"normal"
 * ChannelName				null
 * ChannelType				"channel"
 * ClampingDist				"-1"
 * DistModel				"-1"
 * EncryptAudio				"0"
 * MaxGain					"-1"
 * MaxNumberOfParticipants	"0"
 * MaxRange					"-1"
 * Persistent				"false"
 * Protected				"false"
 * ProtectedPassword		null
 * RollOff					"-1"
 * 
 */
    var callback = this.getArg(arguments,2);
	
    var chanReq = this.createRequestObject("vx_req_account_channel_create");
    if ( chanReq ){        
        chanReq.Request.AccountHandle = accountHandle;
        for (var prop in properties) {
			switch (prop) {
				case "ChannelName":
					chanReq.Request.ChannelName = properties[prop];
				break;
				case "Capacity":
					chanReq.Request.Capacity = properties[prop];
				break;
				case "ChannelDescription":
					chanReq.Request.ChannelDescription = properties[prop];
				break;
				case "ChannelMode":
					chanReq.Request.ChannelMode = properties[prop];
				break;
				case "ChannelName":
					chanReq.Request.ChannelName = properties[prop];
				break;
				case "ChannelType":
					chanReq.Request.ChannelType = properties[prop];
				break;
			 	case "ClampingDist":
					chanReq.Request.ClampingDist = 	 properties[prop];
				break;
			 	case "DistModel":
					chanReq.Request.DistModel = 	 properties[prop];
				break;
				case "EncryptAudio":
					chanReq.Request.EncryptAudio = 	 properties[prop];
				break;
			 	case "MaxGain":
					chanReq.Request.MaxGain = 	 properties[prop];
				break;
			 	case "MaxNumberOfParticipants":
					chanReq.Request.MaxNumberOfParticipants = 	 properties[prop];
				break;
			 	case "MaxRange":
					chanReq.Request.MaxRange = 	 properties[prop];
				break;
			 	case "Persistent":
					chanReq.Request.Persistent = 	 properties[prop];
				break;
			 	case "Protected":
					chanReq.Request.Protected = 	 properties[prop];
				break;
			 	case "ProtectedPassword":
					chanReq.Request.ProtectedPassword = 	 properties[prop];
				break;
			 	case "RollOff":
					chanReq.Request.RollOff = 	 properties[prop];
				break;
				default:
					error_log('unknown channel property' + prop)
				break;
			}
		}
        this.issueRequestObject(chanReq, callback);
        return false;
    } else {
        error_log('failed creating channel create object');
        return this.m_reqObjCreateError;
    }
    
},
/**
 * 
 * @param {String} accountHandle
 * @param {Object} properties
 */
ChannelUpdate: function(accountHandle, properties) { 

/* request factory method returns this:
 * 
 * Request @requestId=Req999 @action=Account.ChannelUpdate.1
 * AccountHandle			null
 * Capacity					"-1"
 * ChannelDescription		null
 * ChannelMode				"none"
 * ChannelURI				null
 * ClampingDist				"-1"
 * DistModel				"-1"
 * EncryptAudio				"-1"
 * MaxGain					"-1"
 * MaxNumberOfParticipants	"-1"
 * MaxRange					"-1"
 * Persistent				"-1"
 * Protected				"-1"
 * ProtectedPassword		null
 * RollOff					"-1"
 * 
 */

/*
 * Response @requestId=Req12 @action=Account.ChannelUpdate.1
 * ReturnCode						"0"
 * Results
 *   StatusCode						"0"
 *   StatusString					null
 * InputXml
 * 	Request @requestId=Req12 @action=Account.ChannelUpdate.1
 * 		AccountHandle				"2a13075c-62ef-4c0a-9dde-0dda85975bdb"
 * 		ChannelURI					"sip:confctl-1012@vxp.vivox.com"
 * 		ChannelDescription 			null
 * 		Persistent					"-1"
 * 		Protected					"-1"
 * 		ProtectedPassword 			null
 * 		Capacity					"-1"
 * 		MaxNumberOfParticipants		"-1"
 * 		ChannelMode					"lecture"
 * 		MaxRange					"-1"
 * 		ClampingDist				"-1"
 * 		RollOff						"-1"
 * 		MaxGain						"-1"
 * 		DistModel					"-1"
 * 		EncryptAudio				"-1"
 */
    var callback = this.getArg(arguments,2);
	
    var chanReq = this.createRequestObject("vx_req_account_channel_update");
    if ( chanReq ){        
        chanReq.Request.AccountHandle = accountHandle;
        for (var prop in properties) {
			switch (prop) {
				case "Capacity":
					chanReq.Request.Capacity = properties[prop];
				break;
				case "ChannelDescription":
					chanReq.Request.ChannelDescription = properties[prop];
				break;
				case "ChannelMode":
					chanReq.Request.ChannelMode = properties[prop];
				break;
				case "ChannelURI":
					chanReq.Request.ChannelURI = properties[prop];
				break;
			 	case "ClampingDist":
					chanReq.Request.ClampingDist = 	 properties[prop];
				break;
			 	case "DistModel":
					chanReq.Request.DistModel = 	 properties[prop];
				break;
				case "EncryptAudio":
					chanReq.Request.EncryptAudio = 	 properties[prop];
				break;
			 	case "MaxGain":
					chanReq.Request.MaxGain = 	 properties[prop];
				break;
			 	case "MaxNumberOfParticipants":
					chanReq.Request.MaxNumberOfParticipants = 	 properties[prop];
				break;
			 	case "MaxRange":
					chanReq.Request.MaxRange = 	 properties[prop];
				break;
			 	case "Persistent":
					chanReq.Request.Persistent = 	 properties[prop];
				break;
			 	case "Protected":
					chanReq.Request.Protected = 	 properties[prop];
				break;
			 	case "ProtectedPassword":
					chanReq.Request.ProtectedPassword = 	 properties[prop];
				break;
			 	case "RollOff":
					chanReq.Request.RollOff = 	 properties[prop];
				break;
				default:
					error_log('unknown channel property' + prop)
				break;
			}
		}
        this.issueRequestObject(chanReq, callback);
        return false;
    } else {
        error_log('failed creating channel update object');
        return this.m_reqObjCreateError;
    }
},
/**
 * 
 * @param {Object} accountHandle
 * @param {Object} channelUri
 */
ChannelDelete: function(accountHandle, channelUri) { 
	var callback = this.getArg(arguments,2);
	
	var chanReq = this.createRequestObject("vx_req_account_channel_delete");
	if ( chanReq ){        
	    chanReq.Request.AccountHandle = accountHandle;
	    chanReq.Request.ChannelURI = channelUri;
	    this.issueRequestObject(chanReq, callback);
	    return false;
	} else {
	    error_log('failed creating channel delete object');
	    return this.m_reqObjCreateError;
	}

},
/**
 * 
 * @param {String} accountHandle
 * @param {String} channelUri
 */
ChannelGetInfo: function(accountHandle, channelUri) { 
	var callback = this.getArg(arguments,2);
	
	var chanReq = this.createRequestObject("vx_req_account_channel_get_info");
	if ( chanReq ){        
	    chanReq.Request.AccountHandle = accountHandle;
		chanReq.Request.URI = channelUri;
	    this.issueRequestObject(chanReq, callback);
	    return false;
	} else {
	    error_log('failed creating channel get info object');
	    return this.m_reqObjCreateError;
	}

},
/**
 * 
 * @param {String} accountHandle
 */
ChannelFavoritesGetList: function(accountHandle){
	var callback = this.getArg(arguments,1);
	var favsReq = this.createRequestObject("vx_req_account_channel_favorites_get_list");
	
	if ( favsReq ){        
		favsReq.Request.AccountHandle = accountHandle;
	    this.issueRequestObject(favsReq, callback);
	    return false;
	} else {
	    error_log('failed creating channel favorites get list object');
	    return this.m_reqObjCreateError;
	}        
},
/**
 * 
 * @param {String} accountHandle
 * @param {Object} properties
 */
ChannelFavoriteSet: function(accountHandle, properties){
	
	var callback = this.getArg(arguments,2);
	var favsReq = this.createRequestObject("vx_req_account_channel_favorite_set");
	
	if ( favsReq ){        
		favsReq.Request.AccountHandle = accountHandle;
	    for (var prop in properties) {
			switch (prop) {
				case "Data":
					favsReq.Request.Data = properties[prop];
				break;
				case "GroupID":
					favsReq.Request.GroupID = properties[prop];
				break;
				case "ID":
					favsReq.Request.ID = properties[prop];
				break;
				case "Label":
					favsReq.Request.Label = properties[prop];
				break;
				case "URI":
					favsReq.Request.URI = properties[prop];
				break;
				default:
					error_log('unknown channel favorite property' + prop)
				break;
			}
		}
		
	    this.issueRequestObject(favsReq, callback);
	    return false;
	} else {
	    error_log('failed creating channel favorite set object');
	    return this.m_reqObjCreateError;
	}        
},
/**
 * 
 * @param {String} accountHandle
 * @param {Number} favoriteId
 */
ChannelFavoriteDelete: function(accountHandle, favoriteId){
	
	var callback = this.getArg(arguments,2);
	var favsReq = this.createRequestObject("vx_req_account_channel_favorite_delete");
	
	if ( favsReq ){        
		favsReq.Request.AccountHandle = accountHandle;
		favsReq.Request.ID = favoriteId;
	    this.issueRequestObject(favsReq, callback);
	    return false;
	} else {
	    error_log('failed creating channel favorite delete object');
	    return this.m_reqObjCreateError;
	}        
	
},
/**
 * 
 * @param {String} accountHandle
 * @param {Object} properties
 */
ChannelFavoriteGroupSet: function(accountHandle, properties){
	var callback = this.getArg(arguments,2);
	var favsReq = this.createRequestObject("vx_req_account_channel_favorite_group_set");
	
	if ( favsReq ){        
		favsReq.Request.AccountHandle = accountHandle;
	    for (var prop in properties) {
			switch (prop) {
				case "Data":
					favsReq.Request.Data = properties[prop];
				break;
				case "GroupID":
					favsReq.Request.GroupID = properties[prop];
				break;
				case "Name":
					favsReq.Request.Name = properties[prop];
				break;
				default:
					error_log('unknown channel favorite property' + prop)
				break;
			}
		}
		
	    this.issueRequestObject(favsReq, callback);
	    return false;
	} else {
	    error_log('failed creating channel favorite set');
	    return this.m_reqObjCreateError;
	}        
	
},
/**
 * 
 * @param {Object} accountHandle
 * @param {Object} groupId
 */
ChannelFavoriteGroupDelete: function(accountHandle, groupId){
	var callback = this.getArg(arguments,2);
	var favsReq = this.createRequestObject("vx_req_account_channel_favorite_group_delete");
	
	if ( favsReq ){        
		favsReq.Request.AccountHandle = accountHandle;
		favsReq.Request.GroupID = groupId;
	    this.issueRequestObject(favsReq, callback);
	    return false;
	} else {
	    error_log('failed creating channel favorite set');
	    return this.m_reqObjCreateError;
	}        
	
},
/**
 * 
 * @param {String} accountHandle
 * @param {Object} properties
 */
ChannelSearch: function (accountHandle, properties){
	var callback = this.getArg(arguments,2);
	var favsReq = this.createRequestObject("vx_req_account_channel_search");
	
	if ( favsReq ){        
		favsReq.Request.AccountHandle = accountHandle;
	    for (var prop in properties) {
			switch (prop) {
				case "PageNumber":
					favsReq.Request.PageNumber = properties[prop];
				break;
				case "PageSize":
					favsReq.Request.PageSize = properties[prop];
				break;
				case "Active":
					favsReq.Request.Active = properties[prop];
				break;
				case "Name":
					favsReq.Request.Name = properties[prop];
				break;
				case "Description":
					favsReq.Request.Description = properties[prop];
				break;
				case "Type":
					favsReq.Request.Type = properties[prop];
				break;
				case "ModerationType":
					favsReq.Request.ModerationType = properties[prop];
				break;
				default:
					error_log('unknown channel search property' + prop)
				break;
			}
		}
	    this.issueRequestObject(favsReq, callback);
	    return false;
	} else {
	    error_log('failed creating channel search object');
	    return this.m_reqObjCreateError;
	}        
	
},
/**
 * 
 * @param {String} accountHandle
 */
SessionFontsGet: function (accountHandle){
    var callback = this.getArg(arguments,1);
	var fontsReq = this.createRequestObject("vx_req_account_get_session_fonts");
	if ( fontsReq){
		fontsReq.Request.AccountHandle = accountHandle;
	    this.issueRequestObject(fontsReq, callback);
		return false;		
	} else {
	    error_log('failed creating channel favorite set');
	    return this.m_reqObjCreateError;
	}
},
/**
 * 
 * @param {String} accountHandle
 */
TemplateFontsGet: function (accountHandle){
    var callback = this.getArg(arguments,1);
	var fontsReq = this.createRequestObject("vx_req_account_get_template_fonts");
	if ( fontsReq){
		fontsReq.Request.AccountHandle = accountHandle;
	    this.issueRequestObject(fontsReq, callback);
		return false;		
	} else {
	    error_log('failed creating template fonts get');
	    return this.m_reqObjCreateError;
	}
},


//
//	S S I   C A L L B A C K S
//
/**
 * 
 * @param {String} accountHandle
 * @param {String} focusUri
 * @param {String} ISession
 */    
onSessionUpdated: function(accountHandle, focusUri, ISession){
	error_log('onSessionUpdated('+accountHandle+', '+focusUri+', '+ISession+')');
	var self        = getSelf();
    var session     = self.makeObject(ISession);
    
    // Cache the session info so we can do lookups locally
    self.setSessionState(accountHandle, focusUri, session);
    
    if ( self.m_cbSessionUpdated !== null ){
		try {
			self.m_cbSessionUpdated(accountHandle, focusUri, session);
		} catch (e){
			error_log('Execption calling client callback onSessionUpdated '+e);
		}
    }
},
/**
 * 
 * @param {String} accountHandle
 * @param {String} focusUri
 * @param {String} userUri
 * @param {String} messageBody
 * @param {String} messageHeader
 */
onMessageReceived: function(accountHandle, focusUri, userUri, messageBody, messageHeader){
	error_log('onMessageReceived('+accountHandle+', '+focusUri+', '+userUri+', '+messageBody+', '+messageHeader+')');
	var self        = getSelf();
    if ( self.m_cbMessageReceived !== null){
		try {
	        self.m_cbMessageReceived(accountHandle, focusUri, userUri, messageBody, messageHeader);
		} catch (e){
			error_log('Execption calling client callback onMessageReceived '+e);
		}
    }
},
/**
 * 
 * @param {String} accountHandle
 * @param {String} cookie
 * @param {String} errorCode
 */
onSendMsgCompleted: function(accountHandle, cookie, errorCode){
	var self        = getSelf();
    if (self.m_cbSendMsgCompleted !== null ){
		try {
	        self.m_cbSendMsgCompleted(accountHandle, cookie, errorCode);
		} catch (e){
			error_log('Execption calling client callback onSendMsgCompleted '+e);
		}
    }
},
/**
 * 
 * @param {String} accountHandle
 * @param {String} cookie
 * @param {String} errorCode
 */
onSetVoiceFontCompleted: function(accountHandle, cookie, errorCode){
	var self        = getSelf();
    if (self.m_cbSetVoiceFontCompleted !== null){
		try {
	        self.m_cbSetVoiceFontCompleted(accountHandle, cookie, errorCode);
		} catch (e){
			error_log('Execption calling client callback  onSetVoiceFontCompleted '+e);
		}
			
    }
},
onRecordingFramesCaptured: function(accountHandle, recordingHandle, totalFrames, frameCount, firstLoopFrame, totalLoopFrames){
	var self        = getSelf();
    if (self.m_cbRecordingFramesCaptured !== null){
		try {
	        self.m_cbRecordingFramesCaptured(accountHandle, recordingHandle, totalFrames, frameCount, firstLoopFrame, totalLoopFrames);
		} catch (e){
			error_log('Execption calling client callback  onRecordingFramesCaptured '+e);
		}
    }
},
onFramePlayed: function(accountHandle, playbackHandle, currentFrame, lastFrame){
	var self        = getSelf();
    if (self.m_cbFramePlayed !== null){
		try {
	        self.m_cbFramePlayed(accountHandle, playbackHandle, currentFrame, lastFrame);
		} catch (e){
			error_log('Execption calling client callback  onFramePlayed '+e);
		}
    }
},
onAudioInjectionCompleted: function(accountHandle, injectionHandle){
	var self        = getSelf();
    if (self.m_cbAudioInjectionCompleted){
		try {
	        self.m_cbAudioInjectionCompleted(accountHandle, injectionHandle);
		} catch (e){
			error_log('Execption calling client callback  onAudioInjectionCompleted '+e);
		}
    }
},
/**
 * 
 * @param {String} accountHandle
 * @param {String} errorCode
 * @param {String} focusUri
 */
onChannelError: function(accountHandle, errorCode, focusUri){
	var self        = getSelf();
	error_log('onChannelError('+accountHandle+', '+errorCode+', '+focusUri+')');
    if (self.m_cbChannelError !== null){
		try {
	        self.m_cbChannelError(accountHandle, errorCode, focusUri);
		} catch (e){
			error_log('Execption calling client callback  onChannelError '+e);
		}
    }
},
/**
 * 
 * @param {String} accountHandle
 * @param {String} errorCode
 * @param {String} focusUri
 * @param {String} userUri
 */
onParticipantError: function(accountHandle, errorCode, focusUri, userUri){
	var self        = getSelf();
	error_log('onParticipantError('+accountHandle+', '+errorCode+', '+focusUri+', '+userUri+')');
    if (self.m_cbParticipantError){
		try {
			self.m_cbParticipantError(accountHandle, errorCode, focusUri, userUri);
		} catch (e){
			error_log('Execption calling client callback  onParticipantError '+e);
		}

    }
},
/**
 * 
 * @param {Object} state
 */
onServiceAvailablityStateChanged: function(state){
  var self = getSelf();
  if(self.m_cbServiceAvailablityStateChanged !== null){
    self.m_cbServiceAvailablityStateChanged(state);
  }
},
/**
 * 
 * @param {String} accountHandle
 * @param {String} errorCode
 * @param {String} diagnosticCode
 * @param {String} diagnosticString
 * @param {String} diagnosticMessageType
 */
onUnhandledError: function(accountHandle, errorCode, diagnosticCode, diagnosticString, diagnosticMessageType){
	var self        = getSelf();
	error_log('onUnhandledError('+accountHandle+', '+errorCode+', '+diagnosticCode+', '+diagnosticString+', '+diagnosticMessageType+')');
    if (self.m_cbUnhandledError !== null){
		try {
	        self.m_cbUnhandledError(accountHandle, errorCode, diagnosticCode, diagnosticString, diagnosticMessageType);
		} catch (e){
			error_log('Execption calling client callback  onUnhandledError '+e);
		}
    }
},
/**
 * 
 * @param {String} accountHandle
 * @param {String} focusUri
 * @param {String} audioState
 * @param {String} statusCode
 */
onAudioStateChanged: function(accountHandle, focusUri, audioState, statusCode){
    error_log('in onAudioStateChanged('+accountHandle+', '+focusUri+', '+audioState+', '+statusCode+')');        
	var self        = getSelf();
    if ( self.m_cbAudioStateChanged !== null ){
		try {
	        self.m_cbAudioStateChanged(accountHandle, focusUri, audioState, statusCode);
		} catch (e){
			error_log('Execption calling client callback  onAudioStateChanged '+e);
		}
    }
	// free the audio state information, if present
	if ( audioState == 0 && self.m_ActiveAccounts[accountHandle] && 
	     self.m_ActiveAccounts[accountHandle][focusUri]){
		self.m_ActiveAccounts[accountHandle][focusUri] = null;
	}
},
/**
 * 
 * @param {String} accountHandle
 * @param {String} focusUri
 * @param {String} textState
 * @param {String} statusCode
 */
onTextStateChanged: function (accountHandle, focusUri, textState, statusCode){
    error_log('in onTextStateChanged('+accountHandle+', '+focusUri+', '+textState+', '+statusCode+')');        
	var self        = getSelf();
    if ( self.m_cbTextStateChanged !== null ){
		try {
	    	self.m_cbTextStateChanged(accountHandle, focusUri, textState, statusCode);
		} catch (e){
			error_log('Execption calling client callback  onTextStateChanged '+e);
		}
    }
},
/**
 * 
 * @param {String} accountHandle
 * @param {String} focusUri
 * @param {String} IParticipant
 */
onParticipantUpdated: function (accountHandle, focusUri, IParticipant){
	// console.time('onParticipantUpdated');
	var self        = getSelf();
    var participant = eval('json='+IParticipant);
    self.setParticipantState(accountHandle,focusUri,participant);
    if ( self.m_cbParticipantUpdated !== null ){
		try {
	    	self.m_cbParticipantUpdated(accountHandle, focusUri, participant);
		} catch (e){
			error_log('Execption calling client callback  onParticipantUpdated '+e);
		}
    }
	// console.timeEnd('onParticipantUpdated');
},
/**
 * 
 * @param {String} accountHandle
 * @param {String} focusUri
 * @param {Object} IParticipant
 */
onParticipantAdded:    function (accountHandle, focusUri, IParticipant){
    error_log('in onParticipantAdded('+accountHandle+', '+focusUri+', '+IParticipant+')');        
	var self        = getSelf();
    var participant = (typeof(IParticipant)=='string')? self.makeObject(IParticipant) : IParticipant;;
    
    if ( participant.IParticipant.IsMe == 'true' && participant.IParticipant.Type != 'participant_user'){
        self.m_Moderators[focusUri] = true;
		error_log('Can moderate the joined channel.')
    } else if ( participant.IParticipant.IsMe == 'true' && participant.IParticipant.Type == 'participant_user'){
        self.m_Moderators[focusUri] = false;
		error_log('Can NOT moderate the joined channel.')
    }
    if ( self.m_cbParticipantAdded!= null ){
		try {
	    	self.m_cbParticipantAdded(accountHandle, focusUri, participant);
		} catch (e){
			error_log('Execption calling client callback  onParticipantAdded '+e);
		}
    }
    self.setParticipantState(accountHandle,focusUri,participant);
	return;        
},
/**
 * 
 * @param {String} accountHandle
 * @param {String} focusUri
 * @param {String} userUri
 * @param {String} removedReason
 * @param {String} IParticipant
 */
onParticipantRemoved:	function (accountHandle, focusUri, userUri, removedReason, IParticipant){
    error_log('in onParticipantRemoved('+accountHandle+', '+focusUri+', '+userUri+', '+removedReason+')');        
	var self        = getSelf();
    var participant = (typeof(IParticipant)=='string')? self.makeObject(IParticipant) : IParticipant;;

    if ( self.m_cbParticipantRemoved !== null ){
		try {
	    	self.m_cbParticipantRemoved(accountHandle, focusUri, userUri, removedReason, participant);
		} catch (e){
			error_log('Execption calling client callback  onParticipantRemoved '+e);
		}
    }
	return;        
},
/**
 * 
 * @param {String} connectorHandle
 * @param {String} value
 */
onLocalSpeakerMute:	function (connectorHandle, value){
    error_log('in onLocalSpeakerMute('+connectorHandle+', '+value+')');        
	var self        = getSelf();

    if ( self.m_cbLocalSpeakerMute !== null ){
		try {
	    	self.m_cbLocalSpeakerMute(connectorHandle, value);
		} catch (e){
			error_log('Execption calling client callback  onLocalSpeakerMute '+e);
		}
    }
	return;        
},
/**
 * 
 * @param {String} connectorHandle
 * @param {String} value
 */
onLocalMicMute:	function (connectorHandle, value){
    error_log('in onLocalMicMute('+connectorHandle+', '+value+')');        
	var self        = getSelf();
	self.m_LocalMicMuteState = value;
    if ( self.m_cbLocalMicMute !== null ){
		try {
	    	self.m_cbLocalMicMute(connectorHandle, value);
		} catch (e){
			error_log('Execption calling client callback  onLocalMicMute '+e);
		}
    }
	return;        
},
/**
 * 
 * @param {String} accountHandle
 * @param {String} focusUri
 */
onRecordingStarted:	function (accountHandle, focusUri){
    error_log('in onRecordingStarted('+accountHandle+', '+focusUri+')');        
	var self        = getSelf();
    if ( self.m_cbRecordingStarted !== null ){
		try {
	    	self.m_cbRecordingStarted(accountHandle, focusUri);
		} catch (e){
			error_log('Execption calling client callback  onRecordingStarted '+e);
		}
    }
	return;        
},
/**
 * 
 * @param {String} accountHandle
 * @param {String} focusUri
 */
onRecordingStopped:	function (accountHandle, focusUri, frames){
    error_log('in onRecordingStopped('+accountHandle+', '+focusUri+', '+frames+')');        
	var self        = getSelf();
    if ( self.m_cbRecordingStopped !== null ){
		try {
	    	self.m_cbRecordingStopped(accountHandle, focusUri, frames);
		} catch (e){
			error_log('Execption calling client callback  onRecordingStopped '+e);
		}
    }
	return;        
},
/**
 * 
 * @param {String} accountHandle
 * @param {String} focusUri
 * @param {Number} progressValue
 * @param {Number} progressMax
 */
onRecordingSaveProgress:	function (accountHandle, focusUri, progressValue, progressMax){
    error_log('in onRecordingSaveProgress('+accountHandle+', '+focusUri+', '+progressValue+', '+progressMax+')');        
	var self        = getSelf();
    if ( self.m_cbRecordingStarted !== null ){
		try {
	    	self.m_cbRecordingSaveProgress(accountHandle, focusUri,progressValue, progressMax);
		} catch (e){
			error_log('Execption calling client callback  onRecordingSaveProgress '+e);
		}
    }
	return;        
},
onWavDestination:	function (accountHandle, path){
    error_log('in onWavDestination('+accountHandle+', '+path+')');        
	var self        = getSelf();
    if ( self.m_cbWavDestination !== null ){
		try {
	    	self.m_cbWavDestination(accountHandle, path);
		} catch (e){
			error_log('Execption calling client callback  onWavDestination '+e);
		}
    }
	return;        
},

    //
    // S S I   C A L L S
    //
/**
 * 
 */	
GetSessionCount: function (){
	if (this.m_scriptObject){
		try {
			return this.m_scriptObject.GetSessionCount();
		} catch(e){
			this.handleException(e);
		}
	} else {
		return null;
	}
},
/**
 * 
 * @param {Numnber} index
 */
GetSessionAt: function (index){
	if (this.m_scriptObject){
		try {
			var xmlReturn = this.m_scriptObject.GetSessionAt(index);
			return this.makeObject(xmlReturn);
		} catch(e){
			this.handleException(e);
		}
	} else {
		return null;
	}
},
/**
 * 
 * @param {String} accountHandle
 * @param {String} focusUri
 */
GetSession:	function (accountHandle, focusUri){
	if (this.m_scriptObject){
		try {
			var xmlReturn = this.m_scriptObject.GetSession(accountHandle, focusUri);
			return this.makeObject(xmlReturn);
		} catch(e) {
			this.handleException(e);
		}
	} else {
		return null;
	}
},
/**
 * 
 * @param {String} accountHandle
 * @param {String} focusUri
 * @param {String} userUri
 */
GetParticipant:	function (accountHandle, focusUri, userUri){
	if (this.m_scriptObject){
		try {
			var xmlReturn = this.m_scriptObject.GetParticipant(accountHandle, focusUri, userUri);
			return this.makeObject(xmlReturn);
		} catch(e){
			this.handleException(e);
		}
		
	} else {
		return null;
	}
},
/**
 * 
 * @param {String} accountHandle
 * @param {String} focusUri
 * @param {Number} value
 * @param {String} password
 */
SetTextState: function (accountHandle, focusUri, value, password){
	if (this.m_scriptObject){
		try {
		    //Ie does not belive in optional params
			error_log('SetTextState('+accountHandle+', '+focusUri+', '+value+', '+password+', "")');
			return this.m_scriptObject.SetTextState(accountHandle, focusUri, value, password,"");
		} catch(e){
			this.handleException(e);
		}
	} else {
		return null;
	}
},
/**
 * 
 * @param {String} accountHandle
 * @param {String} focusUri
 * @param {Number} value
 */
CanSetTextState: function (accountHandle, focusUri, value){
	if (this.m_scriptObject){
		try {
			return this.m_scriptObject.CanSetTextState(accountHandle, focusUri, value);
		} catch(e){
			this.handleException(e);
		}
	} else {
		return null;
	}
},
/**
 * 
 * @param {String} accountHandle
 * @param {String} focusUri
 */
StartRecording: function (accountHandle, focusUri){
	if (this.m_scriptObject){
		try {
			error_log('StartRecording('+accountHandle+', '+focusUri+')');
			return this.m_scriptObject.StartRecording(accountHandle, focusUri);
		} catch(e) {
			this.handleException(e);
		}
	} else {
		return null;
	}
},
/**
 * 
 * @param {String} accountHandle
 * @param {String} focusUri
 */
StopRecording: function (accountHandle, focusUri){
	if (this.m_scriptObject){
		try {
			error_log('StopRecording('+accountHandle+', '+focusUri+')');
			return this.m_scriptObject.StopRecording(accountHandle, focusUri);
		} catch(e) {
			this.handleException(e);
		}
	} else {
		return null;
	}
},
/**
 * 
 * @param {String} accountHandle
 * @param {String} focusUri
 * @param {String} filepath
 * @param {Number} flag
 */
SaveRecording: function (accountHandle, focusUri, filepath, flag){
	if (this.m_scriptObject){
		try {
			error_log('SaveRecording('+accountHandle+', '+focusUri+', '+filepath+', '+flag+')');
			return this.m_scriptObject.SaveRecording(accountHandle, focusUri,filepath,flag);
		} catch(e) {
			this.handleException(e);
		}
	} else {
		return null;
	}
},
/**
 * 
 * @param {String} accountHandle
 * @param {String} focusUri
 * @param {Number} value
 * @param {Number} font_id
 * @param {String} password
 * @param {String} channel_name
 */
SetAudioState: function (accountHandle, focusUri, value, font_id, password, channel_name){
	if (this.m_scriptObject){
		try {
			error_log('SetAudioState('+accountHandle+', '+focusUri+', '+value+', '+font_id+', '+password+', '+channel_name+')');
			return this.m_scriptObject.SetAudioState(accountHandle, focusUri, value, font_id, password, channel_name);
		} catch(e) {
			this.handleException(e);
		}
	} else {
		return null;
	}
},
CanSetAudioState: function (accountHandle, focusUri, value){
	if (this.m_scriptObject){
		try {
			return this.m_scriptObject.CanSetAudioState(accountHandle, focusUri, value);
		} catch(e){
			this.handleException(e);
		}
	} else {
		return null;
	}
},
SendMsg: function (accountHandle, focusUri, contentType, content, cookie){
	if (this.m_scriptObject){
		try {
			return this.m_scriptObject.SendMsg(accountHandle, focusUri, contentType, content, cookie);
		} catch(e){
			this.handleException(e);
		}
	} else {
		return null;
	}
},
CanSendMsg:	function (accountHandle, focusUri){
	if (this.m_scriptObject){
		try {
			return this.m_scriptObject.CanSendMsg(accountHandle, focusUri);
		} catch(e){
			this.handleException(e);
		}
	} else {
		return null;
	}
},
SetTyping: function (accountHandle, focusUri, value){
	if (this.m_scriptObject){
		try {
			return this.m_scriptObject.SetTyping(accountHandle, focusUri, value);
		} catch(e){
			this.handleException(e);
		}
	} else {
		return null;
	}
},
CanSetTyping: function (accountHandle, focusUri){
	if (this.m_scriptObject){
		try {
			return this.m_scriptObject.CanSetTyping(accountHandle, focusUri);
		} catch(e){
			this.handleException(e);
		}
	} else {
		return null;
	}
},
SetHandRaised: function (accountHandle, focusUri, value){
	if (this.m_scriptObject){
		try {
			return this.m_scriptObject.SetHandRaised(accountHandle, focusUri, value);
		} catch(e){
			this.handleException(e);
		}
	} else {
		return null;
	}
},
CanSetHandRaised: function (accountHandle, focusUri){
	if (this.m_scriptObject){
		try {
			return this.m_scriptObject.CanSetHandRaised(accountHandle, focusUri);
		} catch(e){
			this.handleException(e);
		}
	} else {
		return null;
	}
},
MuteRender:	function (accountHandle, focusUri, value){
	if (this.m_scriptObject){
		try {
			return this.m_scriptObject.MuteRender(accountHandle, focusUri, value);
		} catch(e){
			this.handleException(e);
		}
	} else {
		return null;
	}
},
CanMuteRender: function (accountHandle, focusUri){
	if (this.m_scriptObject){
		try {
			return this.m_scriptObject.CanMuteRender(accountHandle, focusUri);
		} catch(e){
			this.handleException(e);
		}
	} else {
		return null;
	}
},
MuteText: function (accountHandle, focusUri, value){
	if (this.m_scriptObject){
		try {
			return this.m_scriptObject.MuteText(accountHandle, focusUri, value);
		} catch(e){
			this.handleException(e);
		}
	} else {
		return null;
	}
},
CanMuteText: function (accountHandle, focusUri){
	if (this.m_scriptObject){
		try {
			return this.m_scriptObject.CanMuteText(accountHandle, focusUri);
		} catch(e){
			this.handleException(e);
		}
	} else {
		return null;
	}
},
SetRenderVolume: function (accountHandle, focusUri, value){
	if (this.m_scriptObject){
		try {
			return this.m_scriptObject.SetRenderVolume(accountHandle, focusUri, value);
		} catch(e){
			this.handleException(e);
		}
	} else {
		return null;
	}
},
CanSetRenderVolume:	function (accountHandle, focusUri){
	if (this.m_scriptObject){
		try {
			return this.m_scriptObject.CanSetRenderVolume(accountHandle, focusUri);
		} catch(e){
			this.handleException(e);
		}
	} else {
		return null;
	}
},
SetVoiceFont: function (accountHandle, focusUri, font_id){
	if (this.m_scriptObject){
		try {
			return this.m_scriptObject.SetVoiceFont(accountHandle, focusUri, font_id);
		} catch(e){
			this.handleException(e);
		}
	} else {
		return null;
	}
},
CanSetVoiceFont: function (accountHandle, focusUri){
	if (this.m_scriptObject){
		try {
			return this.m_scriptObject.CanSetVoiceFont(accountHandle, focusUri);
		} catch(e){
			this.handleException(e);
		}
	} else {
		return null;
	}
},
SetTransmitToOneChannel: function (accountHandle, focusUri){
	if (this.m_scriptObject){
		try {
			return this.m_scriptObject.SetTransmitToOneChannel(accountHandle, focusUri);
		} catch(e){
			this.handleException(e);
		}
	} else {
		return null;
	}
},
CanSetTransmitToOneChannel:	function (accountHandle, focusUri){
	if (this.m_scriptObject){
		try {
			return this.m_scriptObject.CanSetTransmitToOneChannel(accountHandle, focusUri);
		} catch(e){
			this.handleException(e);
		}
	} else {
		return null;
	}
},
SetTransmitAllChannels:	function (accountHandle){
	if (this.m_scriptObject){
		try {
			return this.m_scriptObject.SetTransmitAllChannels(accountHandle);
		} catch(e){
			this.handleException(e);
		}
	} else {
		return null;
	}
},
CanSetTransmitAllChannels: function (accountHandle){
	if (this.m_scriptObject){
		try {
			return this.m_scriptObject.CanSetTransmitAllChannels(accountHandle);
		} catch(e){
			this.handleException(e);
		}
	} else {
		return null;
	}
},
SetTransmitNoChannels: function (accountHandle){
	if (this.m_scriptObject){
		try {
			return this.m_scriptObject.SetTransmitNoChannels(accountHandle);
		} catch(e){
			this.handleException(e);
		}
	} else {
		return null;
	}
},
CanSetTransmitNoChannels: function (accountHandle){
	if (this.m_scriptObject){
		try {
			return this.m_scriptObject.CanSetTransmitNoChannels(accountHandle);
		} catch(e){
			this.handleException(e);
		}
	} else {
		return null;
	}
},
SetFocusOneChannel:	function (accountHandle, focusUri, value){
	if (this.m_scriptObject){
		try {
			return this.m_scriptObject.SetFocusOneChannel(accountHandle, focusUri, value);
		} catch(e){
			this.handleException(e);
		}
	} else {
		return null;
	}
},
CanSetFocusOnechannel: function (accountHandle, focusUri){
	if (this.m_scriptObject){
		try {
			return this.m_scriptObject.CanSetFocusOnechannel(accountHandle, focusUri);
		} catch(e){
			this.handleException(e);
		}
	} else {
		return null;
	}
},
ClearAllFocusedChannels: function (accountHandle){
	if (this.m_scriptObject){
		try {
			return this.m_scriptObject.ClearAllFocusedChannels(accountHandle);
		} catch(e){
			this.handleException(e);
		}
	} else {
		return null;
	}
},
CanClearAllFocusedChannels:	function (accountHandle){
	if (this.m_scriptObject){
		try {
			return this.m_scriptObject.CanClearAllFocusedChannels(accountHandle);
		} catch(e){
			this.handleException(e);
		}
	} else {
		return null;
	}
},
SetParticipantVolume: function (accountHandle, focusUri, userUri, volume){
	if (this.m_scriptObject){
		try {
			return this.m_scriptObject.SetParticipantVolume(accountHandle, focusUri, userUri, volume);
		} catch(e){
			this.handleException(e);
		}
	} else {
		return null;
	}
},
CanSetParticipantVolume: function (accountHandle, focusUri, userUri){
	if (this.m_scriptObject){
		try {
			return this.m_scriptObject.CanSetParticipantVolume(accountHandle, focusUri, userUri);
		} catch(e){
			this.handleException(e);
		}
	} else {
		return null;
	}
},
SetParticipantAudioMuted: function (accountHandle, focusUri, userUri, muted){
	if (this.m_scriptObject){
		try {
			return this.m_scriptObject.SetParticipantAudioMuted(accountHandle, focusUri, userUri, muted);
		} catch(e){
			this.handleException(e);
		}
	} else {
		return null;
	}
},
CanSetParticipantAudioMuted: function (accountHandle, focusUri, userUri){
	if (this.m_scriptObject){
		try{
			return this.m_scriptObject.CanSetParticipantAudioMuted(accountHandle, focusUri, userUri);
		} catch(e){
			this.handleException(e);
		}
	} else {
		return null;
	}
},
SetMy3dPosition: function (accountHandle, focusUri, listenerPosition, listenerAtOrientation, listenerUpOrientation, speakerPosition){
	if (this.m_scriptObject){
		try {
			return this.m_scriptObject.SetMy3dPosition(accountHandle, focusUri, listenerPosition, listenerAtOrientation, listenerUpOrientation, speakerPosition);
		} catch(e){
			this.handleException(e);
		}
	} else {
		return null;
	}
},
CanSetMy3dPosition:	function (accountHandle, focusUri){
	if (this.m_scriptObject){
		try {		
			return this.m_scriptObject.CanSetMy3dPosition(accountHandle, focusUri);
		} catch(e){
			this.handleException(e);
		}
	} else {
		return null;
	}
},
SetSessionPosition:	function (accountHandle, focusUri,speakerPosition){
	if (this.m_scriptObject){
		try {
			return this.m_scriptObject.SetSessionPosition(accountHandle, focusUri,speakerPosition);
		} catch(e){
			this.handleException(e);
		}
	} else {
		return null;
	}
},
CanSetSessionPosition: function (accountHandle, focusUri){
	if (this.m_scriptObject){
		try {	
			return this.m_scriptObject.CanSetSessionPosition(accountHandle, focusUri);
		} catch(e){
			this.handleException(e);
		}
	} else {
		return null;
	}
},
StartAudioInjection: function (accountHandle, filename){
	if (this.m_scriptObject){
		try {
			return this.m_scriptObject.StartAudioInjection(accountHandle, filename);
		} catch(e){
			this.handleException(e);
		}
	} else {
		return null;
	}
},
StopAudioInjection:	function (accountHandle){
	if (this.m_scriptObject){
		try {
			return this.m_scriptObject.StopAudioInjection(accountHandle);
		} catch(e){
			this.handleException(e);
		}
	} else {
		return null;
	}
},
RestartAudioInjection: function (accountHandle, filename){
	if (this.m_scriptObject){
		try {
			return this.m_scriptObject.RestartAudioInjection(accountHandle, filename);
		} catch(e){
			this.handleException(e);
		}
	} else {
		return null;
	}
},
CanModerateChannel:	function (focusUri){
    var canModerate = (this.m_Moderators[focusUri]) ? this.m_Moderators[focusUri] : false;
    return canModerate;
},
GetWavDestination:	function (accountHandle){
	if (this.m_scriptObject){
		try {
			return this.m_scriptObject.GetWavDestination(accountHandle);
		} catch(e){
			this.handleException(e);
		}
	} else {
		return null;
	}
},
Start: function() {
	try {
		error_log('Starting plugin on '+this.m_Host+' port '+this.m_Port);
	    this.m_scriptObject.Start(this.m_Host, this.m_Port);
	} catch(e){
		this.handleException(e);
	}
		
},
	
    // Owi Wrappers,
OwiAbout: function (){
    var owiReq = this.createRequestObject("owi_req_about_dialog");
    
    if ( owiReq ){        
        this.issueRequestObject(owiReq, null);
        return false;
    } else {
        error_log('failed creating About Dialog object');
        return this.m_reqObjCreateError;
    }        
    
},
OwiAuth: function (url){
    var callback = this.getArg(arguments,1);
    var owiReq = this.createRequestObject("owi_req_auth");
    
    if ( owiReq ){
		owiReq.Request.Url = url;
        this.issueRequestObject(owiReq, callback);
        return false;
    } else {
        error_log('failed creating owi auth object');
        return this.m_reqObjCreateError;
    }        
    
},
OwiAuthListAllow: function (url){
    var owiReq = this.createRequestObject("owi_req_acceptance_list_allow_dialog");
    
    if ( owiReq ){
		owiReq.Request.Url = url;
        this.issueRequestObject(owiReq, null);
        return false;
    } else {
        error_log('failed creating owi acceptance list allow dialog object');
        return this.m_reqObjCreateError;
    }        
    
},
OwiManage: function (){
    var owiReq = this.createRequestObject("owi_req_acceptance_list_manage_dialog");
    
    if ( owiReq ){
        this.issueRequestObject(owiReq, null);
        return false;
    } else {
        error_log('failed creating owi acceptance list allow dialog object');
        return this.m_reqObjCreateError;
    }        
    
},
OwiLogin: function (x,y){
    var owiReq = this.createRequestObject("owi_req_login_dialog");
    
    if ( owiReq ){        
		owiReq.Request.xpos = x;
		owiReq.Request.ypos = y;
        this.issueRequestObject(owiReq, null);
        return false;
    } else {
        error_log('failed creating Login Dialog object');
        return this.m_reqObjCreateError;
    }        
    
},
OwiAudioSettings: function (){
    var owiReq = this.createRequestObject("owi_req_audio_settings_dialog");
    
    if ( owiReq ){        
        this.issueRequestObject(owiReq, null);
        return false;
    } else {
        error_log('failed creating AudioSettings Dialog object');
        return this.m_reqObjCreateError;
    }        
    
},
OwiRoster: function (){
    var owiReq = this.createRequestObject("owi_req_roster_list_edit_dialog");
    
    if ( owiReq ){        
        this.issueRequestObject(owiReq, null);
        return false;
    } else {
        error_log('failed creating RosterList Dialog object');
        return this.m_reqObjCreateError;
    }        
    
},
OwiPushToTalk: function (){
    var owiReq = this.createRequestObject("owi_req_ptt_dialog");
    
    if ( owiReq ){        
        this.issueRequestObject(owiReq, null);
        return false;
    } else {
        error_log('failed creating Push To Talk Dialog object');
        return this.m_reqObjCreateError;
    }        
    
},
OwiVolume: function (x,y){
    var owiReq = this.createRequestObject("owi_req_volum_dialog");
    
    if ( owiReq ){        
		owiReq.Request.xpos = x;
		owiReq.Request.ypos = y;
        this.issueRequestObject(owiReq, null);
        return false;
    } else {
        error_log('failed creating volume Dialog object');
        return this.m_reqObjCreateError;
    }        
    
},

init: function(objectId, url_to_backend, host, port){    
    // 
    // Was a client message handler provided?
    // 
    var clientMessageHandler = this.getArg(arguments,4);
    
    //    
    // Set member variables.
    //
	this.hashCachePrefix								= generateShortGuid();
    this.m_Debug                                        = true;
    this.m_ManagementServer                             = url_to_backend;
    this.m_Host                                         = host;
    this.m_Port                                         = port;
    this.m_RequestId                                    = 0;
    this.m_scriptObject                                 = document.getElementById(objectId);
    this.m_AccountHandle                                = null;
    this.m_ConnectorHandle                              = null;
    this.m_ActiveAccounts                               = new Object();
    this.m_Moderators                                   = new Object();
	
	this.consoleService 								= null;

	this.m_cbAccountLoginStateChange					= null;
	this.m_cbAuthorize									= null;
	this.m_cbAcceptanceListAllow						= null;
	this.m_cbAudioStateChanged                          = null;
    this.m_cbTextStateChanged                           = null;
    this.m_cbParticipantAdded                           = null;
    this.m_cbParticipantRemoved                         = null;
    this.m_cbParticipantUpdated                         = null;
    this.m_cbSessionUpdated                             = null;
    this.m_cbMessageRecieved                            = null;
    this.m_cbSendMsgCompleted                           = null;
    this.m_cbSetVoiceFontCompleted                      = null;
    this.m_cbRecordingFramesCaptured                    = null;
    this.m_cbFramePlayed                                = null;
    this.m_cbAudioInjectionCompleted                    = null;
	this.m_cbChannelError								= null;
	this.m_cbUserError									= null;
	this.m_cbUnhandledError								= null;
	this.m_cbLocalSpeakerMute							= null;
	this.m_cbLocalMicMute								= null;
    this.m_cbServiceAvailablityStateChanged     		= null;
	
    this.m_clientMessageHandler                         = clientMessageHandler;
	this.m_reqObjCreateError 	                        = {StatusCode: -1, StatusString: 'Failed creating request Object', '@typeof': 'Error'};
    this.m_pluginObjCreateError                         = {StatusCode: -2, StatusString: 'Failed creating plugin Object', '@typeof': 'Error'};
    this.m_notLoggedInError                             = {StatusCode: -3, StatusString: 'Login before calling.', '@typeof': 'Error'};
    this.m_wrongPluginError                             = {StatusCode: -4, StatusString: 'An upgraged plugin is required to run latest Voice Widgets.', '@typeof': 'Error'};
	
    this.removedReason_left                             = 0;
    this.removedReason_timeout                          = 1;
    this.removedReason_kicked                           = 2;
    this.removedReason_banned                           = 3;
    this.session_media_none                             = 0;
    this.session_media_disconnected                     = 1;
    this.session_media_connected                        = 2;
    this.session_media_ringing                          = 3;
    this.session_media_refer                            = 4;
    this.session_media_connecting                       = 5;
    this.session_media_disconnecting                    = 6;
    this.participant_user                               = 0;
    this.participant_moderator                          = 1;
    this.participant_owner                              = 2;

    if ( this.m_scriptObject ){
		setSelf(this);
        this.m_scriptObject.vx_get_message              = this.messageHandler;
        this.m_scriptObject.onTextStateChanged          = this.onTextStateChanged;
        this.m_scriptObject.onAudioStateChanged         = this.onAudioStateChanged;
        this.m_scriptObject.onParticipantAdded          = this.onParticipantAdded;
        this.m_scriptObject.onParticipantRemoved        = this.onParticipantRemoved;
        this.m_scriptObject.onParticipantUpdated        = this.onParticipantUpdated;
        this.m_scriptObject.onParticipantRemoved        = this.onParticipantRemoved;
        this.m_scriptObject.onSessionUpdated            = this.onSessionUpdated;
        this.m_scriptObject.onMessageReceived           = this.onMessageReceived;
        this.m_scriptObject.onSendMsgCompleted          = this.onSendMsgCompleted;
        this.m_scriptObject.onSetVoiceFontCompleted     = this.onSetVoiceFontCompleted;
        this.m_scriptObject.onRecordingFramesCaptured   = this.onRecordingFramesCaptured;
        this.m_scriptObject.onFramePlayed               = this.onFramePlayed;
        this.m_scriptObject.onAudioInjectionCompleted   = this.onAudioInjectionCompleted;
		this.m_scriptObject.onChannelError              = this.onChannelError;
      	this.m_scriptObject.onParticipantError          = this.onParticipantError;
      	this.m_scriptObject.onUnhandledError           	= this.onUnhandledError;
      	this.m_scriptObject.onRecordingStarted         	= this.onRecordingStarted;
      	this.m_scriptObject.onRecordingStopped        	= this.onRecordingStopped;
      	this.m_scriptObject.onRecordingSaveProgress    	= this.onRecordingSaveProgress;
      	this.m_scriptObject.onWavDestination    		= this.onWavDestination;
        this.m_scriptObject.onServiceAvailablityStateChanged = this.onServiceAvailablityStateChanged;
        
		this.iniFile									= null;
		this.iniLines									= null;
		this.iniValues									= null;
		this['@typeof']									= 'vivoxVoice';
        return this;
    } else {
		error_log(this.m_pluginObjCreateError.StatusCode+' '+this.m_pluginObjCreateError.StatusString);
        return this.m_pluginObjCreateError;
    }
} };
function printStackTrace() {
  var callstack = [];
  var isCallstackPopulated = false;
  try {
    i.dont.exist+=0; //doesn't exist- that's the point
  } catch(e) {
    if (e.stack) { //Firefox
      var lines = e.stack.split("\n");
      for (var i=0, len=lines.length; i<len; i++) {
        if (lines[i].match(/^\s*[A-Za-z0-9\-_\$]+\(/)) {
          callstack.push(lines[i]);
        }
      }
      //Remove call to printStackTrace()
      callstack.shift();
      isCallstackPopulated = true;
    }
    else if (window.opera && e.message) { //Opera
      var lines = e.message.split("\n");
      for (var i=0, len=lines.length; i<len; i++) {
        if (lines[i].match(/^\s*[A-Za-z0-9\-_\$]+\(/)) {
          var entry = lines[i];
          //Append next line also since it has the file info
          if (lines[i+1]) {
            entry += " at " + lines[i+1];
            i++;
          }
          callstack.push(entry);
        }
      }
      //Remove call to printStackTrace()
      callstack.shift();
      isCallstackPopulated = true;
    }
  }
  if (!isCallstackPopulated) { //IE and Safari
    var currentFunction = arguments.callee.caller;
    while (currentFunction) {
      var fn = currentFunction.toString();
      var fname = fn.substring(fn.indexOf("function") + 8, fn.indexOf("(")) || "anonymous";
      callstack.push(fname);
      currentFunction = currentFunction.caller;
    }
  }
  output(callstack);
}

function output(arr) {
  //Optput however you want
  alert(arr.join("nn"));
}
var vvxSelf = null;
function setSelf(obj){
	vvxSelf = obj;
}
function getSelf(){
	return vvxSelf;
}


// end of our class (the library)

/*	This work is licensed under Creative Commons GNU LGPL License.
	License: http://creativecommons.org/licenses/LGPL/2.1/
   Version: 0.9
	Author:  Stefan Goessner/2006
	Web:     http://goessner.net/ 
*/

function json2xml(o, tab) {
   var toXml = function(v, name, ind) {
      var xml = "";
      if (v instanceof Array) {
         for (var i=0, n=v.length; i<n; i++)
            xml += ind + toXml(v[i], name, ind+"\t") + "\n";
      }
      else if (typeof(v) == "object") {
         var hasChild = false;
         xml += ind + "<" + name;
         for (var m in v) {
            if (m.charAt(0) == "@")
               xml += " " + m.substr(1) + "=\"" + v[m].toString() + "\"";
            else
               hasChild = true;
         }
         xml += hasChild ? ">" : "/>";
         if (hasChild) {
            for (var m in v) {
               if (m == "#text")
                  xml += v[m];
               else if (m == "#cdata")
                  xml += "<![CDATA[" + v[m] + "]]>";
               else if (m.charAt(0) != "@")
                  xml += toXml(v[m], m, ind+"\t");
            }
            xml += (xml.charAt(xml.length-1)=="\n"?ind:"") + "</" + name + ">";
         }
      }
      else {
         xml += ind + "<" + name + ">" + v.toString() +  "</" + name + ">";
      }
      return xml;
   }, xml="";
   for (var m in o)
      xml += toXml(o[m], m, "");
   return tab ? xml.replace(/\t/g, tab) : xml.replace(/\t|\n/g, "");
}

/*	This work is licensed under Creative Commons GNU LGPL License.
	License: http://creativecommons.org/licenses/LGPL/2.1/
   Version: 0.9
	Author:  Stefan Goessner/2006
	Web:     http://goessner.net/ 
*/
function xml2json(xml, tab) {
   var X = {
      toObj: function(xml) {
         var o = {};
         if (xml.nodeType==1) {   // element node ..
            if (xml.attributes.length)   // element with attributes  ..
               for (var i=0; i<xml.attributes.length; i++)
                  o["@"+xml.attributes[i].nodeName] = (xml.attributes[i].nodeValue||"").toString();
            if (xml.firstChild) { // element has child nodes ..
               var textChild=0, cdataChild=0, hasElementChild=false;
               for (var n=xml.firstChild; n; n=n.nextSibling) {
                  if (n.nodeType==1) hasElementChild = true;
                  else if (n.nodeType==3 && n.nodeValue.match(/[^ \f\n\r\t\v]/)) textChild++; // non-whitespace text
                  else if (n.nodeType==4) cdataChild++; // cdata section node
               }
               if (hasElementChild) {
                  if (textChild < 2 && cdataChild < 2) { // structured element with evtl. a single text or/and cdata node ..
                     X.removeWhite(xml);
                     for (var n=xml.firstChild; n; n=n.nextSibling) {
                        if (n.nodeType == 3)  // text node
                           o["#text"] = X.escape(n.nodeValue);
                        else if (n.nodeType == 4)  // cdata node
                           o["#cdata"] = X.escape(n.nodeValue);
                        else if (o[n.nodeName]) {  // multiple occurence of element ..
                           if (o[n.nodeName] instanceof Array)
                              o[n.nodeName][o[n.nodeName].length] = X.toObj(n);
                           else
                              o[n.nodeName] = [o[n.nodeName], X.toObj(n)];
                        }
                        else  // first occurence of element..
                           o[n.nodeName] = X.toObj(n);
                     }
                  }
                  else { // mixed content
                     if (!xml.attributes.length)
                        o = X.escape(X.innerXml(xml));
                     else
                        o["#text"] = X.escape(X.innerXml(xml));
                  }
               }
               else if (textChild) { // pure text
                  if (!xml.attributes.length)
                     o = X.escape(X.innerXml(xml));
                  else
                     o["#text"] = X.escape(X.innerXml(xml));
               }
               else if (cdataChild) { // cdata
                  if (cdataChild > 1)
                     o = X.escape(X.innerXml(xml));
                  else
                     for (var n=xml.firstChild; n; n=n.nextSibling)
                        o["#cdata"] = X.escape(n.nodeValue);
               }
            }
            if (!xml.attributes.length && !xml.firstChild) o = null;
         }
         else if (xml.nodeType==9) { // document.node
            o = X.toObj(xml.documentElement);
         }
         else
            alert("unhandled node type: " + xml.nodeType);
         return o;
      },
      toJson: function(o, name, ind) {
         var json = name ? ("\""+name+"\"") : "";
         if (o instanceof Array) {
            for (var i=0,n=o.length; i<n; i++)
               o[i] = X.toJson(o[i], "", ind+"\t");
            json += (name?":[":"[") + (o.length > 1 ? ("\n"+ind+"\t"+o.join(",\n"+ind+"\t")+"\n"+ind) : o.join("")) + "]";
         }
         else if (o === null)
            json += (name&&":") + "null";
         else if (typeof(o) == "object") {
            var arr = [];
            for (var m in o)
               arr[arr.length] = X.toJson(o[m], m, ind+"\t");
            json += (name?":{":"{") + (arr.length > 1 ? ("\n"+ind+"\t"+arr.join(",\n"+ind+"\t")+"\n"+ind) : arr.join("")) + "}";
         }
         else if (typeof(o) == "string")
            json += (name&&":") + "\"" + o.toString() + "\"";
         else
            json += (name&&":") + o.toString();
         return json;
      },
      innerXml: function(node) {
         var s = ""
         if ("innerHTML" in node)
            s = node.innerHTML;
         else {
            var asXml = function(n) {
               var s = "";
               if (n.nodeType == 1) {
                  s += "<" + n.nodeName;
                  for (var i=0; i<n.attributes.length;i++)
                     s += " " + n.attributes[i].nodeName + "=\"" + (n.attributes[i].nodeValue||"").toString() + "\"";
                  if (n.firstChild) {
                     s += ">";
                     for (var c=n.firstChild; c; c=c.nextSibling)
                        s += asXml(c);
                     s += "</"+n.nodeName+">";
                  }
                  else
                     s += "/>";
               }
               else if (n.nodeType == 3)
                  s += n.nodeValue;
               else if (n.nodeType == 4)
                  s += "<![CDATA[" + n.nodeValue + "]]>";
               return s;
            };
            for (var c=node.firstChild; c; c=c.nextSibling)
               s += asXml(c);
         }
         return s;
      },
      escape: function(txt) {
         return txt.replace(/[\\]/g, "\\\\")
                   .replace(/[\"]/g, '\\"')
                   .replace(/[\n]/g, '\\n')
                   .replace(/[\r]/g, '\\r');
      },
      removeWhite: function(e) {
         e.normalize();
         for (var n = e.firstChild; n; ) {
            if (n.nodeType == 3) {  // text node
               if (!n.nodeValue.match(/[^ \f\n\r\t\v]/)) { // pure whitespace text node
                  var nxt = n.nextSibling;
                  e.removeChild(n);
                  n = nxt;
               }
               else
                  n = n.nextSibling;
            }
            else if (n.nodeType == 1) {  // element node
               X.removeWhite(n);
               n = n.nextSibling;
            }
            else                      // any other node
               n = n.nextSibling;
         }
         return e;
      }
   };
   if (xml.nodeType == 9) // document node
      xml = xml.documentElement;
   var json = X.toJson(X.toObj(X.removeWhite(xml)), xml.nodeName, "\t");
   return "{\n" + tab + (tab ? json.replace(/\t/g, tab) : json.replace(/\t|\n/g, "")) + "\n}";
}


function dataCache(){
	this.cache = new Object();
}
dataCache.prototype = {
	data: function(name, data){
		if ( data === undefined ){
			if (name && this.cache[[name]]) {
				return this.cache[name];
			} else {
				return null;
			}
		} else {
			this.cache[name] = data;
		}
		
	},
	removeData: function(name){
		if (name && this.cache[name]){
			delete this.cache[name];
		}
	}
}
var hashCache = new dataCache();


// {{{ serialize
function serialize( mixed_value ) {
    // Generates a storable representation of a value
    // 
    // +    discuss at: http://kevin.vanzonneveld.net/techblog/article/javascript_equivalent_for_phps_serialize/
    // +       version: 812.3015
    // +   original by: Arpad Ray (mailto:arpad@php.net)
    // +   improved by: Dino
    // +   bugfixed by: Andrej Pavlovic
    // +   bugfixed by: Garagoth
    // %          note: We feel the main purpose of this function should be to ease the transport of data between php & js
    // %          note: Aiming for PHP-compatibility, we have to translate objects to arrays
    // *     example 1: serialize(['Kevin', 'van', 'Zonneveld']);
    // *     returns 1: 'a:3:{i:0;s:5:"Kevin";i:1;s:3:"van";i:2;s:9:"Zonneveld";}'
    // *     example 2: serialize({firstName: 'Kevin', midName: 'van', surName: 'Zonneveld'});
    // *     returns 2: 'a:3:{s:9:"firstName";s:5:"Kevin";s:7:"midName";s:3:"van";s:7:"surName";s:9:"Zonneveld";}'

    var _getType = function( inp ) {
        var type = typeof inp, match;
        var key;
        if (type == 'object' && !inp) {
            return 'null';
        }
        if (type == "object") {
            if (!inp.constructor) {
                return 'object';
            }
            var cons = inp.constructor.toString();
            if (match = cons.match(/(\w+)\(/)) {
                cons = match[1].toLowerCase();
            }
            var types = ["boolean", "number", "string", "array"];
            for (key in types) {
                if (cons == types[key]) {
                    type = types[key];
                    break;
                }
            }
        }
        return type;
    };
    var type = _getType(mixed_value);
    var val, ktype = '';
    
    switch (type) {
        case "function": 
            val = ""; 
            break;
        case "undefined":
            val = "N";
            break;
        case "boolean":
            val = "b:" + (mixed_value ? "1" : "0");
            break;
        case "number":
            val = (Math.round(mixed_value) == mixed_value ? "i" : "d") + ":" + mixed_value;
            break;
        case "string":
            val = "s:" + mixed_value.length + ":\"" + mixed_value + "\"";
            break;
        case "array":
        case "object":
            val = "a";
            /*
            if (type == "object") {
                var objname = mixed_value.constructor.toString().match(/(\w+)\(\)/);
                if (objname === undefined) {
                    return;
                }
                objname[1] = serialize(objname[1]);
                val = "O" + objname[1].substring(1, objname[1].length - 1);
            }
            */
            var count = 0;
            var vals = "";
            var okey;
            var key;
            for (key in mixed_value) {
                ktype = _getType(mixed_value[key]);
                if (ktype == "function") { 
                    continue; 
                }
                
                okey = (key.match(/^[0-9]+$/) ? parseInt(key) : key);
                vals += serialize(okey) +
                        serialize(mixed_value[key]);
                count++;
            }
            val += ":" + count + ":{" + vals + "}";
            break;
    }
    if (type != "object" && type != "array") val += ";";
    return val;
}// }}}

function generateGuid()
{
    var result, i, j;
    result = '';
    for(j=0; j<32; j++)
    {
        if( j == 8 || j == 12|| j == 16|| j == 20)
        result = result + '-';
        i = Math.floor(Math.random()*16).toString(16).toLowerCase();
        result = result + i;
	}
    return result
}
function generateShortGuid()
{
    var result, i, j;
    result = '';
    for(j=0; j<16; j++)
    {
        if( j == 8 || j == 12|| j == 16|| j == 20)
        result = result + '-';
        i = Math.floor(Math.random()*16).toString(16).toLowerCase();
        result = result + i;
	}
    return result+'_';
}

