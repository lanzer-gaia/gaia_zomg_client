
var doc = null;

var graphicsFileList = [];
var badActionScriptList = [];

var checkForGraphics = %CHECKFORGRAPHICS%;
var checkForBadAS = %CHECKFORBADAS%;
var checkForFonts = false;

function processLayers(timeline, name)
{
	for each(var layer in timeline.layers)
	{
		for each(var frame in layer.frames)
		{
			if (checkForBadAS) {
				findBadActionScript(frame, timeline, layer, name);
			}
			if (checkForGraphics) {
				findGraphics(frame.elements, timeline, layer, name);
			}
			if (checkForFonts) {
				findFonts(frame.elements, timeline, layer, name);
			}
		}
	}
}

function findFonts(elements, timeline, layer, name) {
	for each(var element in elements)
	{
		var elementType = element.elementType;
		switch(elementType)
		{
			case "text":
				var identifier = doc.path + ": " + name + " TIMELINE: " + timeline.name + " LAYER: " + layer.name;
				var embeddedCharacters = element.embeddedCharacters;
				if (embeddedCharacters) {
					fl.trace(identifier + " FONTS: " + element.getTextAttr("face") + "   " + embeddedCharacters);
				}
				var embedRanges = element.embedRanges;
				if (embedRanges) {
					fl.trace(identifier + " FONTS: " + element.getTextAttr("face") + "   "  + embedRanges);
				}
				break;
		}
	}
}

function findBadActionScript(frame, timeline, layer, name)
{
	var as = frame.actionScript;
	if (as.length > 0 && 
		 as.indexOf("addEventListener") > -1 && 
		 as.indexOf("new ") > -1)  {
			var identifier = doc.path + ": " + name + " TIMELINE: " + timeline.name + " LAYER: " + layer.name + " FRAME: " + frame.startFrame + "\r\n";
			if (badActionScriptList.indexOf(identifier) == -1) {
				badActionScriptList.push(identifier);
			}
	}
}

function findGraphics(elements, timeline, layer, name)
{
	for each(var element in elements)
	{
		var symbolType = element.symbolType;
		switch(symbolType)
		{
		case "graphic":
			var identifier = doc.path;  // + ": " + name + " TIMELINE: " + timeline.name + " LAYER: " + layer.name + " FRAME: " + element.name + "\r\n";
			if (graphicsFileList.indexOf(identifier) == -1) {
				graphicsFileList.push(identifier);
				break;
			}
			break;
		default:
			break;
		}
	}
}

function iterateOverLibrary()
{
	var outputFile = "%OUTPUTFILE%";

	doc = fl.getDocumentDOM();

	var library = doc.library;

	for each(var item in library.items)
	{
		var type = item.itemType; // "movie clip"
		var isMovieClipType = (item.itemType.toLowerCase() == "movie clip");
		if (isMovieClipType) {
			library.editItem(item.name)
			var timeline = item.timeline;
			processLayers(timeline, item.name);
		}

	}

	var len = graphicsFileList.length;
	if(len > 0)
	{
		FLfile.write(outputFile, "FILE NEEDING GRAPHICS CONVERSION\r\n", "append");
		for (var i = 0; i < len; ++i) {
			FLfile.write(outputFile, graphicsFileList[i], "append");
		}
		FLfile.write(outputFile, "\r\n\r\n\r\n", "append");
		fl.trace("Graphics converted to movies: " + len);
	}

	len = badActionScriptList.length;
	if(len > 0)
	{
		FLfile.write(outputFile, "FILE WITH BAD ACTIONSCRIPT\r\n", "append");
		for (i = 0; i < len; ++i) {
			FLfile.write(outputFile, badActionScriptList[i], "append");
		}
		FLfile.write(outputFile, "\r\n\r\n\r\n", "append");
	}
}

fl.outputPanel.clear();
iterateOverLibrary();

