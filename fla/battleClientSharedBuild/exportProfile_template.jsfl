var sourceFile = "%FLAPATH%";
var profileFile= "%PROFILEPATH%";

var doc = fl.openDocument(sourceFile);
fl.getDocumentDOM().exportPublishProfile(profileFile);
fl.closeDocument(doc, false);