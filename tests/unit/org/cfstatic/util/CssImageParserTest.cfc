<cfcomponent extends="tests.BaseTestCase" output="false">

<!--- setup, teardown, etc --->
	<cffunction name="setup" access="public" returntype="void" output="false">
		<cfscript>
			cssImageParser = getTestTarget('org.cfstatic.util.CssImageParser');
		</cfscript>
	</cffunction>
	
	<cffunction name="teardown" access="public" returntype="void" output="false">
	
	</cffunction>

<!--- tests --->
	<cffunction name="t01_init_shouldPassBasePathAndUrlToSettersAndReturnSelf" returntype="void">
		<cfscript>
			// data, etc.
			var mockUrl  = "testing my url";
			var mockPath = "testing my path";
			var result   = "";
			
			// mock calls
			cssImageParser.$('_setBaseCssUrl');
			cssImageParser.$('_setBaseCssPath');
			cssImageParser.$('testImMe', true);
			
			// run the method
			result = cssImageParser.init( mockUrl, mockPath );
			
			// assert the result
			AssertEquals( result.testImMe(), cssImageParser.testImMe() );
			
			// check the call logs to setters
			Assert( cssImageParser.$once('_setBaseCssUrl') );
			Assert( cssImageParser.$once('_setBaseCssPath') );
			
			AssertEquals( mockUrl , cssImageParser.$callLog()._setBaseCssUrl [1][1] );
			AssertEquals( mockPath, cssImageParser.$callLog()._setBaseCssPath[1][1] );
		</cfscript>	
	</cffunction>

	<cffunction name="t02_parse_shouldReturnCssIntact_whenNoImageReferencesFound" returntype="void">
		<cfscript>
			// data, etc.
			var mockCss  = "this is just a test";
			var mockPath = "test lives here";

			// mocking
			cssImageParser.$('$reSearch', StructNew()); // the empty regex search results
			cssImageParser.$('_calculateFullUrl', '');  // this should never be called
			
			// run the method, asserting that the css does not change
			AssertEquals( mockCss, cssImageParser.parse(mockCss, mockPath));
			
			// assert the calls were made correctly
			Assert( cssImageParser.$never('_calculateFullUrl') );
			Assert( cssImageParser.$once('$reSearch') );
			
			AssertEquals( 'url\((.+?)\)', cssImageParser.$callLog().$reSearch[1][1] );
			AssertEquals( mockCss       , cssImageParser.$callLog().$reSearch[1][2] );
		</cfscript>			
	</cffunction>
	
	<cffunction name="t03_parse_shouldReplaceImageMatchesWithFullUrls" returntype="void">
		<cfscript>
			// data, etc.
			var mockCss            = "Once url(again), I'm url(just) testing url(this), which is nice";
			var mockPath           = "test path";
			var expectedResult     = "Once url(foo), I'm url(bar) testing url(test), which is nice";
			var mockSearchResult   = StructNew();
			mockSearchResult['$1'] = ListToArray('again,just,this');
			
			// mocking
			cssImageParser.$('$reSearch', mockSearchResult);
			cssImageParser.$('_calculateFullUrl').$args('again', mockPath).$results('foo' );
			cssImageParser.$('_calculateFullUrl').$args('just' , mockPath).$results('bar' );
			cssImageParser.$('_calculateFullUrl').$args('this' , mockPath).$results('test');
			
			// run the method, asserting the result is as expected
			AssertEquals( expectedResult, cssImageParser.parse( mockCss, mockPath ) );
			
			// assert against method calls
			Assert( cssImageParser.$once('$reSearch') );
			AssertEquals( 'url\((.+?)\)', cssImageParser.$callLog().$reSearch[1][1] );
			AssertEquals( mockCss       , cssImageParser.$callLog().$reSearch[1][2] );
			
			AssertEquals( 3, ArrayLen(cssImageParser.$callLog()._calculateFullUrl) );
		</cfscript>			
	</cffunction>
</cfcomponent>