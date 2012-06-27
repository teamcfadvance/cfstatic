<cfcomponent name="HtmlRunner" hint="Responsible for determining what is to be run and outputting results" output="true">
	<cffunction name="HtmlRunner" returntype="HtmlRunner" hint="Constructor">
		<cfreturn this />
	</cffunction>
	
	<cffunction name="run" access="remote" output="true">
		<cfargument name="test" type="string" required="true" hint="TestCase,TestSuite, or Dircetory to run" />
		<cfargument name="componentPath" type="string" required="false" default="" hint="A dotted prefix mapping for the directory; e.g., com.foo.bar" />
		
		<cfscript>
			var dirrunner = "";
			var results = "";
			
			if (refind("[\\/]+", arguments.test)) {
				if( arguments.componentPath is ""){
					writeoutput("WARNING: Please supply componentPath when running a directory of tests");
					return;
				}
				
				dirrunner = createObject("component","DirectoryTestSuite");
				
				results = dirrunner.run(test,componentPath,false);
				
				writeoutput(results.getResultsOutput("rawhtml"));
			} else {
				localTest = createObject("component", arguments.test);
				
				localTest.runTestRemote(output="rawhtml");
			}
		</cfscript>
	</cffunction>
</cfcomponent>
