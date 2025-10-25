function createFlexLibProperties()
{
	for each (doc in fl.documents) {
		doc.close(true)
	}
	fl.openDocument("%FLAPATH%");
	var dom = fl.getDocumentDOM();
	var items = dom.library.items;
	var outputFile = "%OUTPUTFILE%";
	var manifestFileToWrite = "%MANIFESTLOC%";
	var format= "%FORMAT%";

	fl.outputPanel.clear();

	FLfile.remove(outputFile);	
	FLfile.remove(manifestFileToWrite);	

	if (format == "xml") {
		FLfile.write(outputFile, "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<flexLibProperties version=\"1\">\n<includeClasses>\n", "append");	
	}
	FLfile.write(manifestFileToWrite, "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<componentPackage>\n", "append");


	for(i=0;i<items.length;i++) //alter library items that have exclude classes in first frame
	{
		item = items[i];
		if(item.linkageExportForAS && item.linkageClassName.indexOf("com.") == 0) {		
			if (format == "xml") {
				FLfile.write(outputFile, "\t<classEntry path=\"" + item.linkageClassName + "\"/>\n", "append");
			}	else {
				FLfile.write(outputFile, item.linkageClassName + " ", "append");
			}

			FLfile.write(manifestFileToWrite, "\t<component class=\"" + item.linkageClassName + "\"/>\n", "append");
		}
	}
	if (format == "xml") {
		FLfile.write(outputFile, "</includeClasses>\n<includeResources/>\n<namespaceManifests/>\n</flexLibProperties>", "append");
	}
	FLfile.write(manifestFileToWrite, "</componentPackage>", "append");
}

createFlexLibProperties();
fl.quit(false);