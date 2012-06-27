<cfscript>
	testSuite = createObject("component","mxunit.runner.DirectoryTestSuite");
	results = testSuite.run(
	 	  directory     = GetDirectoryFromPath( GetCurrentTemplatePath() ) & 'integration'
	 	, componentPath = "tests.integration"
	);

	writeOutput( results.getHtmlResults() );
</cfscript>