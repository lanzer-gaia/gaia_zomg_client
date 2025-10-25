var flpFile = "%FLPPATH%";
var logFile = "%LOGPATH%";
var classPaths = "%AS3CLASSPATH%";
var quit = %QUIT%;
var profileNameOrig = "%CURR_PROFILE_NAME%";
var profileNameTweaked = "%NEW_PROFILE_NAME%";
var filename = "%FILENAME%";
var checkForGraphics = %CHECKFORGRAPHICS%;
var checkForBadAs = %CHECKFORBADAS%;
var processEveryFrameScript = "%PROCESSEVERYFRAMESCRIPT%";
var buildType = "%BUILDTYPE%"
var debugBuild = %DEBUG_BUILD%;
var forceOptimizeAs3 = true;

// String we create to read XML back into publish profile,
// plus supporting index values
// (we cannot use xml output by E4X due to limitations
// of publish properties xml parsing)
var newXMLContent;
var startIndex;
var nextIndex;

fl.outputPanel.clear();
fl.as3PackagePaths = classPaths;
fl.openProject(flpFile);
var project = fl.getProject();

// load up the document
var docURI = project.items[0].itemURI;
var doc = fl.openDocument(docURI);
 
// [bgh] run other scripts on the document:
//if(checkForGraphics || checkForBadAs) {
//	fl.runScript(processEveryFrameScript);
//}

// export its publish profile
FLfile.remove(profileNameOrig);
doc.exportPublishProfile(profileNameOrig);

// read the profile back in so we can parse it as xml
var xmlContent = FLfile.read(profileNameOrig);	

// Make the profile actually parseable by e4x by eliminating
// the bom + <?xml...> prefix.
var profileXML = new XML(xmlContent.substr(xmlContent.indexOf('>') + 1));

// make sure we have a PublishFlashProperties tag which is enabled
var flashPropsXML = profileXML.PublishFlashProperties;
if (flashPropsXML.length() == 0 || flashPropsXML.@enabled == "false") {
	alert("You must have Flash checked in the Formats tab of the Publish Settings dialog to run this command.");
}

// prepare string used to write xml content
newXMLContent = "";
startIndex = 0;

// note that these have to be in the order in which they appear in the xml
omitTrace = debugBuild ? 0 : 1;
debugPermitted = debugBuild ? 1 : 0;
protect = debugBuild ? 0: 1;
buildSwc = (buildType == "swc") ? 1 : 0;

fixNextValue("Protect", protect);
fixNextValue("OmitTraceActions", omitTrace);
fixNextValue("DebuggingPermitted", debugPermitted);
fixNextValue("ExportSwc", buildSwc);

if (forceOptimizeAs3) {
	fixNextValue("AS3Optimize", 1);
}

// output rest of the file
newXMLContent += xmlContent.substr(startIndex);

// write out new file and read it in
FLfile.write(profileNameTweaked, newXMLContent);
doc.importPublishProfile(profileNameTweaked);	

fl.getProject().publishProject();
fl.getDocumentDOM().close(false);
fl.closeProject();

fl.outputPanel.save(logFile, true);
fl.compilerErrors.save(logFile, true);
fl.resetAS3PackagePaths();
if (quit) {
	fl.quit(false);
}

function fixNextValue(tagName, targetValue) {
	// grab current value from document to see if we need to change
	var mustChange = false;

	// find tag value
	var searchToken = ("<" + tagName + ">");

	nextIndex = xmlContent.indexOf(searchToken, startIndex);

	if (nextIndex < 0) return false;

	nextIndex += searchToken.length;
	var endIndex = xmlContent.indexOf("<", nextIndex);
	var currentValue = xmlContent.slice(nextIndex, endIndex);

	// check tag value
	if (isNaN(currentValue) || currentValue != targetValue) {
		mustChange = true;
	}

	// output proper xml
	newXMLContent += xmlContent.slice(startIndex, nextIndex);
	newXMLContent += (mustChange) ? targetValue : currentValue;
	startIndex = endIndex;

	return mustChange;
}
