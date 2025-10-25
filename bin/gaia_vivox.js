
var userAgent=navigator.userAgent.toLowerCase();
check=function(r){return r.test(userAgent);}
var isOpera=check(/opera/);
varisIE=!isOpera&&check(/msie/);
var isWebKit=check(/webkit/);
var isGecko=!isWebKit&&check(/gecko/);

var debugOn = false;
var log;

if(debugOn)
{
	log = log4javascript.getLogger("main");
	var appender = new log4javascript.PopUpAppender();
	log.addAppender(appender);
}


var info = function(msg){
    if (debugOn == false) {return;}
	if ( log ){log.info(msg); return;}
    if (window.console) {
        if (window.console.log) {
            window.console.log(msg);
        }
    }
};
var debug = function(msg){
    if (debugOn == false) {return;}
	if ( log ){log.info(msg); return;}
    if (window.console) {
        if (window.console.log) {
            window.console.log(msg);
        }
    }
};
var error_log = function(msg){
    if (debugOn == false) {return;}
	if ( log ){log.debug(msg);}
    if (window.console) {
        if (window.console.log) {
            window.console.log(msg);
        }
    }
};

function VivoxWrapper() {
	
	var flash = null;
	var me = this;
	
	var vvxHandle = null;
	
	var flashReady = false;
	var vivoxReady = false;
	
	var callWhenFlashIsReady = new Array();
	var host = "www.gaiaonline.com";
	
	/*
	 * Closure function for vvxHandle.ConnectorCreate().
	 * When successful, show the login div.
	 */
	function completedConnector(requestId, responseObj){
	    info('completedConnector Response.ReturnCode = ' + responseObj.Response.ReturnCode);
	    if (responseObj.Response.ReturnCode != "0" ) {
	        if (responseObj.Response.Results.StatusCode == 1002) {
	            info('Connector already exists, calling Dump from completedConnector');
	            vvxHandle.Dump({onCompletion: completedDump});
	            return;
	        }
	        else {
	            info('CreateConnector failed ' + responseObj.Response.Results.StatusString + ' (' + responseObj.Response.Results.StatusCode+')')
	            ExtAlert('CreateConnector failed ' + responseObj.Response.Results.StatusString + ' (' + responseObj.Response.Results.StatusCode+')')
	        }
	    } else {
			info('completedConnector() -> showing trying vivoxIsReady()');
			vivoxIsReady();
	    }
	}
	
	/*
	 * Closure function used when calling vvxHandle.Dump()
	 * We call dump first and if there is no connector available then call 
	 * vvxHandle.ConnectorCreate.
	 * 
	 * When dump is called the user could already be logged in. 
	 * This closure function handles the state transition for this web application by showing 
	 * and hiding the appproiate login/logout divs.
	 * 
	 */
	function completedDump(requestId, responseObj){
	    info('completedDump() -> Response.ReturnCode ' + responseObj.Response.ReturnCode);
	    if (responseObj.Response.ReturnCode != "0") {
			info('completedDump() -> Response.Results ' + serialize(responseObj.Response.Results));
			return;
		} else if (!responseObj.Response.Results.Connectors) {
				info("compltedDump() -> Contacting Vivox Network...");
				vvxHandle.ConnectorCreate({onCompletion: completedConnector});
		} else {
	        if (isUserLoggedIn()) {
	            info('completedDump() -> User is already logged in');
	            info('completedDump() -> '+JSON.stringify(responseObj));
	        } else {
				info('completedDump() -> User is not logged in');
	        }
		vivoxIsReady();
	    }
	}
	
	function vivoxIsReady()
	{
		info('vivoxIsReady()');
   		vivoxReady = true;
        	checkIfFlashAndVivoxIsReady();	
	}
	
	function isUserLoggedIn()
	{
		return vvxHandle.m_AccountHandle ? true : false;
	}
	
	function clientMessageHandler(xml){
	    info('clientMessageHandler() -> xml ' + xml);
	}
	
	
	
	function is_plugin_installed(){
		var return_val = false;
		if ( isIE ){
			if (window.ActiveXObject) {
				var control = null;
				try {
					control = new ActiveXObject('atlvivoxvoiceplugin.atlvivoxvoiceplugin');
				} 
				catch (e) {
					return false;
				}
				return true; 
			}
		} else {
			var i;
			for (i=0; i<navigator.plugins.length; i++){
				if ( (navigator.plugins[i].name == 'Vivox Voice Plugin' &&
					 navigator.plugins[i].filename == 'npvivoxvoiceplugin.dll') ||
					 navigator.plugins[i].filename == 'vivoxvoice.plugin' ){
					return true;
				}
			}
			return false;
		}
	}

	function check_for_and_run_plugin(){
    
        /*	-- Vivox voice plugin 
         *  -- The id is passed into the call to new vivoxVoice()
         *  -- Must be set to "vivoxPluginObject"
         */
        var win = (navigator.platform.indexOf("Win") != -1);
        var mac = (navigator.platform.indexOf("Mac") != -1);
        
        if (isIE) {
            var installed = is_plugin_installed();
            
            if (installed) {
				document.write('<div id="vvxUpgrade"><p>Checking for upgrades</p></div>');
                info('Vivox Voice Plugin IS installed');
                document.write('<OBJECT ID="vivoxPluginObject" ');
                document.write(' CLASSID="CLSID:17E9F5FA-FBFA-4F83-9445-63C86BF29E7D"');
                document.write(' DATA="DATA:application/x-oleobject;BASE64,+vXpF/r7g0+URWPIa/KefQAIAADYEwAA2BMAAA==" ');
                document.write(' codebase="http://vivoxtest.s3.amazonaws.com/VivoxToolbarDownloader-1.0.6-vxp-current.exe" ');
                document.write(' type="voice/x-vivox" HEIGHT=1 WIDTH=1></OBJECT>');
                document.write('<scr');
                document.write('ipt src="msie_glue.js" language="JScript"></scr');
                document.write('ipt>');
			} else {
                //			info('Vivox Voice Plugin IS NOT installed');
            }
        }
        else if (isGecko) {
            var installed = is_plugin_installed();
            if (installed) {
                info('Vivox Voice Plugin IS installed');
                document.write('<OBJECT ID="vivoxPluginObject" ');
                if (win) {
                    document.write('codebase="http://s3.amazonaws.com/vivox/vivoxvoicetoolbar-1.0.0.latest-win32.xpi" ');
                }
                else 
                    if (mac) {
                        document.write('codebase="http://s3.amazonaws.com/vivox/vivoxvoicetoolbar-1.0.0.latest-Darwin.xpi" ');
                    }
                document.write(' type="voice/x-vivox"></OBJECT>');
			} else {
          	  //			info('Vivox Voice plugin IS NOT installed');
            }
        }
        else {
            // ExtAlert('Internet Explorer and Firefox are the only supported browsers at this time.')
        }
    }


	function parseUri (str) {
		var	o   = {
				strictMode: false,
				key: ["source","protocol","authority","userInfo","user","password","host","port","relative","path","directory","file","query","anchor"],
				q:   {
					name:   "queryKey",
					parser: /(?:^|&)([^&=]*)=?([^&]*)/g
				},
				parser: {
					strict: /^(?:([^:\/?#]+):)?(?:\/\/((?:(([^:@]*):?([^:@]*))?@)?([^:\/?#]*)(?::(\d*))?))?((((?:[^?#\/]*\/)*)([^?#]*))(?:\?([^#]*))?(?:#(.*))?)/,
					loose:  /^(?:(?![^:@]+:[^:@\/]*@)([^:\/?#.]+):)?(?:\/\/)?((?:(([^:@]*):?([^:@]*))?@)?([^:\/?#]*)(?::(\d*))?)(((\/(?:[^?#](?![^?#\/]*\.[^?#\/.]+(?:[?#]|$)))*\/?)?([^?#\/]*))(?:\?([^#]*))?(?:#(.*))?)/
				}
			},
			m   = o.parser[o.strictMode ? "strict" : "loose"].exec(str),
			uri = {},
			i   = 14;
	
		while (i--) uri[o.key[i]] = m[i] || "";
	
		uri[o.q.name] = {};
		uri[o.key[12]].replace(o.q.parser, function ($0, $1, $2) {
			if ($1) uri[o.q.name][$1] = $2;
		});
	
		return uri;
	};
	
	 /*
	 * Closure function used when calling vvxHandle.Login()
	 */
	function cbCompletedLogin(requestId, responseObj){
	    info('completedLogin() -> Response.ReturnCode ' + responseObj.Response.ReturnCode);
	    
	    var loginSuccess = responseObj.Response.ReturnCode == 0;
	    
	    if (!loginSuccess) {
	        info('completedLogin() -> Response.Results '+serialize(responseObj.Response.Results) );
	    } else {
	        info('completedLogin() -> Successfull login!');
	    }
	    
		if(flash) {    
		    flash.loginCallback(loginSuccess, JSON.stringify(responseObj.Response.Results));
		}
	}
	function cbParticipantAdded(accountHandle, uri, participant) {
		if(flash) {
			info("cbParticipantAdded(" + accountHandle + ", " + uri + ", " + participant + ")");
			flash.participantAdded(accountHandle, uri, JSON.stringify(participant));
		}
	}
	function cbParticipantUpdated(accountHandle, uri, participant) {
		if(flash) {
			info("cbParticipantUpdated(" + accountHandle + ", " + uri + ", " + participant + ")");
			flash.participantUpdated(accountHandle, uri, JSON.stringify(participant));
		}
	}
	function cbParticipantRemoved(accountHandle, uri, userUri, removedReason, participant) {
		if(flash) {
			info("cbParticipantRemoved(" + accountHandle + ", " + userUri + ", " + userUri + ", " + removedReason + ", " + participant + ")");
			flash.participantRemoved(accountHandle, uri, userUri, removedReason, JSON.stringify(participant));
		}
	}
	function cbAudioStateChanged(accountHandle, uri, audioState, statusCode) {
		info('cbAudioStateChanged('+accountHandle+', '+uri+', '+audioState+', '+statusCode +')');
		if(flash) {
			flash.audioStateChanged(accountHandle, uri, audioState, statusCode);
		}
	}
	function cbSessionUpdated(accountHandle, focusUri, jsonSession) {
		info('cbSessionUpdated('+accountHandle+', '+focusUri+', '+jsonSession+')');
	}
	function cbAcceptanceListAllow(event){
		info('cbAcceptanceListAllow() -> event '+serialize(event));
	}
	function cbAccountLoginStateChange(AccountHandle, StatusCode, StatusString, State) { 
		info("cbAccountLoginStateChange() -> " + AccountHandle + " " + StatusCode + " " + StatusString + " " + State);
		var cb = function() {
			flash.accountLoginStateChanged(AccountHandle, StatusCode, StatusString, State);
		};
		callIfAndWhenFlashIsReady(cb);
	}
	function cbChannelError(accountHandle, errorCode, focusUri) {
		info('cbChannelError('+accountHandle+', '+errorCode+', '+focusUri+')');
	}
	function cbParticipantError(accountHandle, errorCode, focusUri, userUri) {
		info('cbParticipantError('+accountHandle+', '+errorCode+', '+focusUri+', '+userUri+')');
	}
	function cbUnhandledError(accountHandle, errorCode, diagnosticCode, diagnosticString, diagnosticMessageType) {
		info('cbUnhandledError('+accountHandle+', '+errorCode+', '+diagnosticCode+', '+diagnosticString+', '+diagnosticMessageType+')');
	}
	function cbServiceAvailabilityStateChanged(state) {
		info('cbServiceAvailabilityStateChanged('+state+')');
		if(1 == state)
		{
			if ( vvxHandle.m_scriptObject ){
				info('Auth for host '+host);
				vvxHandle.OwiAuth(host, {onCompletion: cbAuthComplete, hostname: host});
			} else {
				info('cannot create scriptable object.');
			}
		}
	}
	
	function callIfAndWhenFlashIsReady(cb) {
		if(flash) {
			cb();
		}
		else {
			callWhenFlashIsReady.push(cb);
		}
	}
	
	function cbLocalMicMute(connectorHandle, value) {
		info("cbLocalMicMute() -> " + connectorHandle + " " + value);
		var cb = function() {
			flash.localMicMute(connectorHandle, value);
		};
		callIfAndWhenFlashIsReady(cb);
	}
	
	function cbLocalSpeakerMute(connectorHandle, value) {
		var cb = function() {
			flash.localSpeakerMute(connectorHandle, value);		
		};
		info("cbLocalSpeakerMute() -> " + connectorHandle + " " + value);
		callIfAndWhenFlashIsReady(cb);
	}
	function cbMessageReceived(accountHandle, focusUri, userUri, messageBody, messageHeader) {
		info('cbUnhandledError('+accountHandle+', '+focusUri+', '+userUri+', '+messageBody+', '+messageHeader+')');	
	}
	function cbMessageCompleted(accountHandle, cookie, errorCode) {
		info('cbMessageCompleted('+accountHandle+', '+cookie+', '+errorCode+')');
	}
	function cbPlaybackCompleted(type){
		info('cbPlaybackCompleted('+type+')');
	}
	function cbAuthComplete(reqId, responseObj){
	 	info('authComplete() -> closureObj '+serialize(reqId)+' responseObj '+serialize(responseObj));
	 	if ( responseObj.Response.Allow == 1){
	 		info('authComplete() -> Connecting to Vivox...');
			var status = vvxHandle.Dump({onCompletion: completedDump});
	 	} else {
	 		info("authComplete() -> Authorization failed...");
	 		info('authComplete() -> Requesting authorization');
			vvxHandle.OwiAuthListAllow(reqId.hostname);
		}
	}
	
	this.startVivox = function(location) {
		check_for_and_run_plugin();
	
	    vvxHandle = new vivoxVoice('vivoxPluginObject', 'http://www.zomgd.vivox.com/api2/', clientMessageHandler);
		vvxHandleTypeof = typeof vvxHandle;
		vvxHandleObjectType = vvxHandle['@typeof'] ? vvxHandle['@typeof'] : '';
		if (!vvxHandle || vvxHandleTypeof != 'object' ||  vvxHandleObjectType != "vivoxVoice"){
			alert('Error '+vvxHandle.StatusString+' ('+vvxHandle.StatusCode+')');
			return;
		}

		var uri = location;
		if (uri.indexOf("?") > 0){
			uri = uri.substring(0, uri.indexOf("?"));
		}
	
		host = parseUri(uri).host;

		
		vvxHandle.setCallbacks({
			onParticipantAdded			: cbParticipantAdded,
			onParticipantUpdated			: cbParticipantUpdated,
			onParticipantRemoved			: cbParticipantRemoved,
			onAudioStateChanged			: cbAudioStateChanged,
			onSessionUpdated			: cbSessionUpdated,
			onAcceptanceListAllow			: cbAcceptanceListAllow,
			onAccountLoginStateChange		: cbAccountLoginStateChange,
			onChannelError				: cbChannelError,
			onParticipantError			: cbParticipantError,
			onUnhandledError			: cbUnhandledError,
			onServiceAvailablityStateChanged	: cbServiceAvailabilityStateChanged,
			onLocalMicMute				: cbLocalMicMute,
			onLocalSpeakerMute			: cbLocalSpeakerMute,
			onMessageReceived			: cbMessageReceived,
			onSendMsgCompleted			: cbMessageCompleted,
			onMediaCompletion			: cbPlaybackCompleted
		});

		try {
	         	vvxHandle.m_scriptObject.Start();
		} catch (e) {
			info('Exception occured starting Vivox voice plugin');
			info('Error starting plugin ' + e);
			//alert(e);
		}
	
	}; 
	
	this.flashIsReady = function(flashClient)
	{
		flash = flashClient;
		
		info('flashIsReady');
		flashReady = true;
		checkIfFlashAndVivoxIsReady()
	}
	
	function checkIfFlashAndVivoxIsReady()
	{
		var isReady = flashReady && vivoxReady;
		
		info('checkIfFlashAndVivoxIsReady() -> ' + flashReady + '&' + vivoxReady + '=' + isReady);
		
		if(flash && isReady)
		{
			flash.vivoxIsReady();
			
			// [bgh] now, call all of the flash functions that have been stacking up
			for(var index = 0; index < callWhenFlashIsReady.length; index++)
			{
				var cb = callWhenFlashIsReady[index];
				cb();
			}
		}
	}
	
	function completedFavorites(requestId, responseObj){
		
		var returnCode = responseObj.Response.ReturnCode;
		var favsList = [];
		info('completedFavorites() -> Response.ReturnCode ' + returnCode);
		
		if (responseObj.Response.ReturnCode != 0) {
			info('completedFavorites() -> Response.Results ' + serialize(responseObj.Response.Results));
			return;
	    } else {
			var favorites = responseObj.Response.Results.Favorites;
			if (favorites == null) {
				return;
			}
			favsList = favorites.Favorite;
		}

		var account_handle = responseObj.Response.InputXml.Request.AccountHandle;	
		if(flash) {
			flash.setChannelFavorites(account_handle, JSON.stringify(favsList), returnCode);
		} 			
	}
	
	
	function createChannelCompleted(closure, responseObj){
		info('createChannelCompleted '+closure);
		info('createChannelCompleted '+serialize(responseObj));
		if ( responseObj.Response.ReturnCode == "0"){
			var uri = responseObj.Response.Results.ChannelURI;
			var label = responseObj.Response.InputXml.Request.ChannelName;
			var properties = {Label: label,	URI: uri};
			
		} else {
			var results = responseObj.Response.Results;
		}
		if(flash) {
			flash.channelCreated(JSON.stringify(responseObj));
		}
	}
	
	function getSessionFontsCompleted( requestObj, responseObj){
		info('getSessionFontsCompleted() -> REQUEST: ' + JSON.stringify(requestObj) + " RESPONSE " + JSON.stringify(responseObj));
		if(flash) {
			flash.setSessionFonts(JSON.stringify(requestObj), JSON.stringify(responseObj));
		}
	}
	
	this.addFlashHooks = function(scope)
	{
		scope.gaiavivox_login = function(username, password)
		{
			info('gaiavivox_login() -> vvxHandle.Login('+username+',********)');
			vvxHandle.Login(username, password,{onCompletion: cbCompletedLogin});
		};
		
		scope.gaiavivox_logout = function logout()
		{
			info('gaiavivox_logout() ');
			vvxHandle.Logout(vvxHandle.m_AccountHandle);
		};
		
		scope.gaiavivox_muteLocalMic = function(mute)
		{
			info('gaiavivox_muteLocalMic() -> ' + mute);
			vvxHandle.MuteLocalMic(vvxHandle.m_ConnectorHandle, mute);
		};

		scope.gaiavivox_muteLocalSpeaker = function(mute)
		{
			info('gaiavivox_muteLocalSpeaker() -> ' + mute);
			vvxHandle.MuteLocalSpeaker(vvxHandle.m_ConnectorHandle, mute);
		};
		
		scope.gaiavivox_getChannelFavorites = function()
		{
			info('gaiavivox_getChannelFavorites()');
			var chnfavRet = vvxHandle.GetChannelFavorites({onCompletion: completedFavorites});
			info('gaiavivox_getChannelFavorites() -> '+chnfavRet);
		};
		
		scope.gaiavivox_setAudioState = function(handle, uri, value, fontId, password, channelName)
		{
			info('gaiavivox_setAudioState('+handle+', '+uri+', '+value+', '+fontId+', '+password+', '+channelName+')');
			vvxHandle.SetAudioState(handle, uri, value, parseInt(fontId), password, channelName);
		};
		
		scope.gaiavivox_createChannel = function(handle, channelName, channelDesc, password)
		{
			var properties = {ChannelName: channelName, ChannelDescription: channelDesc};
			if ( password.length > 0){
				properties.Protected = "true";
				properties.ProtectedPassword = password.toString();
			}
			vvxHandle.ChannelCreate(handle, properties, {onCompletion: createChannelCompleted});
		};
		
		scope.gaiavivox_setParticipanAudioMuted = function(handle, channelUri, participantUri, mute)
		{
			info('gaiavivox_setParticipanAudioMuted('+handle+','+channelUri+','+participantUri+','+mute+')');
			vvxHandle.SetParticipantAudioMuted(handle, channelUri, participantUri, mute);
		};
		
		scope.gaiavivox_getSessionFonts = function(handle)
		{
			vvxHandle.SessionFontsGet(handle, {onCompletion: getSessionFontsCompleted});
		};
		
		scope.gaiavivox_setVoiceFont = function(handle, channel, fontId)
		{
			vvxHandle.SetVoiceFont(handle, channel, fontId);
		};
		
		scope.gaiavivox_previewRecordStart = function()
		{
			vvxHandle.AudioCaptureStart();
		};	
		scope.gaiavivox_previewRecordStop = function()
		{
			vvxHandle.AudioCaptureStop();
		};	
		scope.gaiavivox_previewPlay = function(handle, fontId)
		{
			info('gaiavivox_previewPlay('+handle+','+fontId+')');
			vvxHandle.AudioPlaybackStart(handle, fontId);
		};	
		scope.gaiavivox_doUnload = function()
		{
			info('Unloaded()');
			if ( vvxHandle && vvxHandle.unsetCallbacks ){
				vvxHandle.unsetCallbacks();
			}
		};

		// [bgh] add a hook to remove hooks to the vivox plug-in
		if (scope.window.body) {
			window.body.onunload = scope.gaiavivox_doUnload; // IE
		} else {
			window.onunload = scope.gaiavivox_doUnload; // FX
		}

	}
}

