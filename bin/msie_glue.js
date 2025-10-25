
function document.vivoxPluginObject::onvx_get_message(msg){
	if (msg=='Test String')
		return;
	var vvxHandle = getSelf();
	vvxHandle.messageHandler(msg);
	
}
function document.vivoxPluginObject::onTextStateChanged(accountHandle, focusUri, textState, statusCode){
	var vvxHandle = getSelf();
	vvxHandle.onTextStateChanged(accountHandle, focusUri, textState, statusCode)
}
function document.vivoxPluginObject::onAudioStateChanged(accountHandle, focusUri, audioState, statusCode){
	var vvxHandle = getSelf();
	vvxHandle.onAudioStateChanged(accountHandle, focusUri, audioState, statusCode);
}
function document.vivoxPluginObject::onParticipantAdded(accountHandle, focusUri, jsonParticipant){
	var vvxHandle = getSelf();
	vvxHandle.onParticipantAdded(accountHandle, focusUri, jsonParticipant);
	
}
function document.vivoxPluginObject::onParticipantRemoved(accountHandle, focusUri, userUri, removedReason, jsonParticipant){
	var vvxHandle = getSelf();
	vvxHandle.onParticipantRemoved(accountHandle, focusUri, userUri, removedReason, jsonParticipant);
}

function document.vivoxPluginObject::onParticipantUpdated(accountHandle, focusUri, jsonParticipant){
	var vvxHandle = getSelf();
	vvxHandle.onParticipantUpdated(accountHandle, focusUri, jsonParticipant);
}

function document.vivoxPluginObject::onMessageReceived(accountHandle, focusUri, userUri, messageBody, messageHeader){
	var vvxHandle = getSelf();
	vvxHandle.onMessageReceived(accountHandle, focusUri, userUri, messageBody, messageHeader);
}

function document.vivoxPluginObject::onSendMsgCompleted(accountHandle, cookie, errorCode){
        var vvxHandle = getSelf();
	vvxHandle.onSendMsgCompleted(accountHandle, cookie, errorCode);
}

function document.vivoxPluginObject::onSessionUpdated(accountHandle, focusUri,jsonSession){
	var vvxHandle = getSelf();
	vvxHandle.onSessionUpdated(accountHandle, focusUri,jsonSession);
}

function document.vivoxPluginObject::onChannelError(accountHandle, errorCode, focusUri){
	
	var vvxHandle = getSelf();
	vvxHandle.onChannelError(accountHandle, errorCode, focusUri);
}
function document.vivoxPluginObject::onParticipantError(accountHandle, errorCode, focusUri, userUri){
	var vvxHandle = getSelf();
	vvxHandle.onParticipantError(accountHandle, errorCode, focusUri, userUri);
}
function document.vivoxPluginObject::onUnhandledError(accountHandle, errorCode, diagnosticCode, diagnosticString, diagnosticMessageType){
	var vvxHandle = getSelf();
	vvxHandle.onUnhandledError(accountHandle, errorCode, diagnosticCode, diagnosticString, diagnosticMessageType);
}

