package com.gaiaonline.battle.utils
{
	import flash.system.Security;
	
	public class LoadPolicyFileManager
	{
		
		private static var policyDomain:Object = new Object()
		
		public function LoadPolicyFileManager()
		{
		}
		
		public static function LoadPolicyFile(url:String):void{
			if (url == null || url.length == 0){
				return;
			}
			
			var domain:String = getDomain(url);
			if (!domain) {
				throw new Error("Requesting a polcy file from a null domain for url " + url);
				return;
			}

			//---- check if we alrady have it
			//---- if not Load the policy file
			if (policyDomain[domain] == null){		
				if (domain.indexOf("javascript:") == -1) {  		
					Security.loadPolicyFile( domain + "/crossdomain.xml?refresh=" + Math.random() );
					policyDomain[domain] = domain;
				}
			}		
		}
		
		
		public static function getDomain(url:String):String{
			//---- clean up the domain			
			url = decodeURIComponent(url).toLowerCase();
			
			// try to find the http:// prefix
			var urlPrefix:String = "http://";
			var start:int = 0;
			if (url.substr(0, urlPrefix.length) == urlPrefix) {
				start = urlPrefix.length;
			} else {
				url = urlPrefix + url;
				start += urlPrefix.length;
			}			
			
			var slashIndex:int = url.indexOf("/", start);
			if (slashIndex == -1) {
				slashIndex = url.length + 1;
			}
			
			var domain:String = url.substr(0, slashIndex);
			return domain;	
		}

	}
}