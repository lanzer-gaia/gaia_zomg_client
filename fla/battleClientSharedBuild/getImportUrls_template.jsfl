function createDependencyXML()
{
	var outputFile = "%OUTPUTFILE%";
	var flapath= "%FLAPATH%";
	var pubProfilePath = "%PROFILE_PATH%";

	fl.outputPanel.clear();

	var doc = fl.openDocument(flapath);

	// parse the publish profile to figure out the published swf name
	FLfile.remove(pubProfilePath);
	doc.exportPublishProfile(pubProfilePath);
	// read the profile back in so we can parse it as xml
	var profileString = FLfile.read(pubProfilePath);
	// Make the profile actually parseable by e4x by eliminating
	// the bom + <?xml...> prefix.
	var xmlPublishProfile = new XML(profileString.substr(profileString.indexOf('>') + 1));

	// get the output swf name from the exported profile
	var publishName = (xmlPublishProfile..flashFileName[0]).text().toString();

	// see if we have our xml file started yet
	if (!FLfile.exists(outputFile)) {
		FLfile.write(outputFile, "<MapDependencies></MapDependencies>");
	}

	// figure out dependencies to write to our xml file
	var output = new XML(FLfile.read(outputFile));

	var dom = fl.getDocumentDOM();
	var items = dom.library.items;
	for(i=0;i<items.length;i++) //alter library items that have exclude classes in first frame
	{
		item = items[i];
		if(item.linkageImportForRS) {		
			var linkageURL = item.linkageURL;
			var mapNodesWithMatch = output.Map.(@fileName == publishName);
			if (mapNodesWithMatch.length() > 0) {
				var dependencyNodesWithMatch = mapNodesWithMatch[0].Dependency.(@url == item.linkageURL);
				if (dependencyNodesWithMatch.length() == 0) {
					output.Map.(@fileName == publishName).Dependency += <Dependency url={linkageURL}/>;
				}
			} else {
				output.Map += <Map fileName={publishName}/>;
			}
		}
	}

	FLfile.write(outputFile,output.toXMLString());
	
//	fl.quit(false);	
}

createDependencyXML();