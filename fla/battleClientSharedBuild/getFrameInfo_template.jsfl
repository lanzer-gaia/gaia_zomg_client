function getFrameInfo()
{
	for each (doc in fl.documents) {
		doc.close(true)
	}
	fl.openDocument("%FLAPATH%");
	var dom = fl.getDocumentDOM();
	var items = dom.library.items;
	var outputFile = "file:///c:/temp/frameInfo.txt";

	fl.outputPanel.clear();

	for(i=0;i<items.length;i++)
	{
		item = items[i];
		var type = item.itemType; // "movie clip"
		var isMovieClipType = (item.itemType.toLowerCase() == "movie clip");
		if (isMovieClipType) {
				var timeline = item.timeline;
				var as = timeline.getFrameProperty("actionScript", 0, 0);
				if (as.length > 0) {
					if (as.indexOf("goto") > -1 || as.indexOf("play")) {
						FLfile.write(outputFile, dom.name + ": " + item.name, true);
						FLfile.write(outputFile,"/n",true);
						fl.outputPanel.trace("*****************************************************************");
//						fl.outputPanel.trace(item.name + "   " + as);
//						var frameCount = timeline.frameCount;
//						timeline.insertFrames(1, false, frameCount);
//						timeline.setFrameProperty("name", "StopLabel", frameCount);
					}
				}
		}
	}
	fl.outputPanel.trace("QUITTING");
	fl.quit(false);
}

getFrameInfo();
