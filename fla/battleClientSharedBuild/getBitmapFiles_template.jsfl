function getBitmaps()
{
	for each (doc in fl.documents) {
		doc.close(true)
	}
	fl.openDocument("%FLAPATH%");
	var dom = fl.getDocumentDOM();
	var items = dom.library.items;
	var outputFile = "file:///c:/temp/bitmaplist";

	fl.outputPanel.clear();

	for(i=0;i<items.length;i++)
	{
		item = items[i];
		var type = item.itemType;
		var linkageBaseClass = item.linkageBaseClass;
		var linkageClassName = item.linkageClassName;
		if ( type == "bitmap" && (item.linkageExportInFirstFrame || item.linkageExportForAS || (linkageBaseClass && linkageBaseClass) != "" || (linkageClassName && linkageClassName != "")) ) {
				if (linkageBaseClass != undefined || linkageClassName != undefined) {
					FLfile.write(outputFile, dom.name + ": " + item.name + "   " + item.linkageBaseClass + "  " + item.linkageClassName  + "\n", true);
				}
		}
	}
}

getBitmaps();
//fl.quit(false);