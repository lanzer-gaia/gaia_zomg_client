function convertLinkReport()
{
	fl.outputPanel.clear();

	var dom = fl.getDocumentDOM();

	var topLevelClassesFile = "file:////Users/bhalsted/src/other/gaia\trunk/mmo/Battle/fla/battleClientSharedBuild/TopLevelClasses";
	var linkReportFileName = "file:////Users/bhalsted/src/other/gaia\trunk/mmo/Battle/fla/battleClientSharedBuild/linkReport.xml";
	var manifestFileToWrite = "file:////Users/bhalsted/src/other/gaia\trunk/src/manifest.xml";
	var format = "spaces";

	var linkReport = FLfile.read(linkReportFileName);
	var topLevelClasses = FLfile.read(topLevelClassesFile);
	if (format == "xml") {
		var topLevelClassesArr = topLevelClasses.split("\n");
	} else {
		var topLevelClassesArr = topLevelClasses.split(" ");
	}

	FLfile.remove(manifestFileToWrite);	
	FLfile.write(manifestFileToWrite, "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<componentPackage>\n", "append");
	
	var links = linkReport.split("\n");

	var excludesArray = ["PreloaderProgress_PreloaderCLS", "mx.", "_arial", "ResourceBundle", "com.aol", "en_US", "NumericRasterTextField_Glyphs", "uiactionbar_fla", "WordBubble", "Lappet", "NameLabel", "wordbubble_fla", "com.gaiaonline.battle.ui.uiactionbar", "RingIconFactory_embeddedClass", "GameWindowAssets"]

	for(i=0;i<links.length;++i)
	{
		var link = links[i];
		if (link.indexOf("<def ") > -1) {
			var foundExclude = false;
			for each (var excludeEntry in excludesArray) {
				if (link.indexOf('Fl"') > -1 || link.indexOf(excludeEntry) > -1) {
					foundExclude = true;
					continue;
				}
			}
			
			if (foundExclude) {
				continue;
			}

			link = link.replace("<def id=\"","");
			link = link.replace("\" />","");
			link = link.replace(":",".");
			link = link.replace(" ","");
			link = link.split(" ").join("");
			var possibleMatch = link;

			if (format == "xml") {
				possibleMatch =  "\t<classEntry path=\"" + link + "\"/>";
			}
			var foundIndex = topLevelClassesArr.indexOf(possibleMatch)
			if (foundIndex == -1) {
				FLfile.write(manifestFileToWrite, "\t<component class=\"" + link + "\"/>\n", "append");
			}

		}		
	}
		
	FLfile.write(manifestFileToWrite, "</componentPackage>", "append");

}

convertLinkReport();
fl.quit(false);