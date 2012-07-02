<cfcomponent displayname="TestSuite" extends="Test" hint="Responsible for creating and running groups of Tests.">
	<cfset cu = createObject("component","ComponentUtils") />
	

	<cfparam name="this.testSuites" default="#getMap()#" />
	<cfparam name="this.tests" default="#arrayNew(1)#" />

	<!--- Generated content from method --->
	<cfparam name="this.c" default="Error occurred. See stack trace." />
	<cfparam name="this.dataProviderHandler" default='#createObject("component","DataproviderHandler")#' />
	<cfparam name="this.MockingFramework" default="" />

	<cfparam name="variables.requestScopeDebuggingEnabled" type="boolean" default="false" />

	<cffunction name="TestSuite" access="public" returntype="TestSuite" hint="Constructor">
		<cfreturn this />
	</cffunction>

	<!---
		Should be of Type "Test". Since All TestCases and TestSuites
		are inherited from Test, we should be able to add them here

		Also, need to
	--->
	<cffunction name="addTest" access="remote" returntype="void" hint="Adds a single TestCase to the TestSuite.">
		<cfargument name="componentName" type="string" required="yes" />
		<cfargument name="method" type="string" required="yes" />
		<cfargument name="componentObject" type="Any" required="no" default="" />

		<cfscript>
			var newStruct = {};
			try{
				this.tempStruct = structNew();
				this.tempStruct.ComponentObject = arguments.ComponentObject;

				// If the test suite exists get the method array and
				// append the new method name ...
				// update an existing test suite
				if (this.testSuites.containsKey(arguments.componentName)) {
					this.tempStruct = this.testSuites.get(arguments.componentName);

					tempArray = structFind(this.tempStruct, "methods");
					arrayAppend(tempArray,arguments.method);

					structUpdate(this.tempStruct, "methods", tempArray);
					this.tesSuites.put(arguments.componentName, this.tempStruct);
				} else{
					//Begin a new test Suite
					this.testSuite.put(arguments.componentName, this.tempStruct);

					//Grab all the methods that begin with the string 'test' ...
					tests = listToArray(arguments.method);

					newStruct.methods = tests;

					this.testSuites.put(arguments.componentName,newStruct);
				}
			} catch (Exception e) {
				writeoutput(e.getMessage());
			}
		</cfscript>
	</cffunction>

	<!---
		Maybe should be named addList
		Adds a list of methods belonging to a component into a testSuite object
	--->
	<cffunction name="add" access="remote" returntype="void" hint="Adds a list of TestCases to the TestSuite">
		<cfargument name="componentName" type="Any" required="yes" />
		<cfargument name="methods" type="string" required="yes" />
		<cfargument name="componentObject" type="Any" required="no" default="" />

		<cfif isSimpleValue(arguments.ComponentObject)>
			<cfset ComponentObject = createObject("component",arguments.ComponentName) />
		</cfif>

		<cfscript>
			try{
				//If the component already has methods, just update the method array
				if ( this.testSuites.containsKey(arguments.componentName) ) {
					tests = testSuites.get(arguments.componentName);

					for( i = 1; i lte listLen(arguments.methods); i = i + 1 ) {
						arrayAppend(tests.methods, listGetAt(arguments.methods,i));
					}

					return;
				}

				//else convert the list of methods to an array and add it to the test suite
				this.tempStruct = structNew();
				this.tempStruct.ComponentObject = arguments.ComponentObject;
				this.tempStruct.methods = listToArray(arguments.methods);
				this.testSuites.put(arguments.componentName, this.tempStruct);
			} catch (any e) {
				writeoutput("Error Adding Tests : " & e.getType() & "  " &  e.getMessage() & " " & e.getDetail());
			}
		</cfscript>
	</cffunction>

	<cffunction name="addAll" access="remote" returntype="any" output="false" hint="Adds all runnable TestCases to the TestSuite">
		<cfargument name="ComponentName" type="any" required="yes" />
		<cfargument name="ComponentObject" type="any" required="false" default="" />

		<cfset var a_methods = "" />

		<cfif isSimpleValue(arguments.ComponentObject)>
			<cfset ComponentObject = createObject("component",arguments.ComponentName).TestCase() />
		</cfif>
 	
		<cfset a_methods = ComponentObject.getRunnableMethods() />

		<cfset add(arguments.ComponentName,ArrayToList(a_methods),ComponentObject) />

		<cfreturn this />
	</cffunction>

	<cffunction name="run" returntype="any" access="remote" output="true" hint="Primary method for running TestSuites and individual tests.">
		<cfargument name="results" hint="The TestResult collecting parameter." required="no" type="TestResult" default="#createObject("component","TestResult").TestResult()#" />
		<cfargument name="testMethod" hint="A single test method to run." type="string" required="no" default="">

		<cfset var testRunner = createObject("component", "TestSuiteRunner") />

		<cfset testRunner.setMockingFramework(this.mockingFramework) />
		<cfset testRunner.setDataProviderHandler(this.dataProviderHandler) />

		<cfif variables.requestScopeDebuggingEnabled OR structKeyExists(url,"requestdebugenable")>
			<cfset testRunner.enableRequestScopeDebugging() />
		</cfif>

		<cfreturn testRunner.run(this.suites(), results, testMethod)>
	</cffunction>

	<cffunction name="runTestRemote" access="remote" output="true">
		<cfargument name="output" type="string" required="false" default="jqgrid" hint="Output format: html,xml,junitxml,jqgrid ">
		<cfargument name="debug" type="boolean" required="false" default="false" hint="Flag to indicate whether or not to dump the test results to the screen.">

		<cfscript>
			var result = this.run();

			switch(arguments.output){
			case 'xml':
					writeoutput(result.getXmlresults());
				break;

			case 'junitxml':
					writeoutput(result.getJUnitXmlresults());
				break;

			case 'json':
					writeoutput(result.getJSONResults());
				break;

			case 'query':
					dump(result.getQueryresults());
				break;

			case 'text':
					writeoutput( trim(result.getTextresults(name)));
				break;

			case 'rawhtml':
					writeoutput(result.getRawHtmlresults());
				break;

			default:
					writeoutput(result.getHtmlresults());
				break;
			}
		</cfscript>

		<cfif arguments.debug>
			<p>&nbsp;</p>

			<cfdump var="#result.getResults()#" label="Raw Results Dump">
		</cfif>
	</cffunction>

	<cffunction name="suites" access="public" returntype="any">
		
		<cfreturn this.testSuites />
	</cffunction>

	<cffunction name="stringValue" access="remote" returntype="string">
		<cfreturn this.suites().toString() />
	</cffunction>

	<cffunction name="dump">
		<cfargument name="o">

		<cfdump var="#o#">
	</cffunction>

	<cffunction name="enableRequestScopeDebugging" access="public" output="false" hint="enables creation of the request.debug function">
		<cfset requestScopeDebuggingEnabled = true>
	</cffunction>

	<cffunction name="setMockingFramework" hint="Allows a developer to set the default Mocking Framework for this test suite.">
		<cfargument name="name" type="Any" required="true" hint="The name of the mocking framework to use" />

		<cfset this.MockingFramework = arguments.name />
	</cffunction>

	<cffunction name="getMap" returntype="Any" access="private" output="false" hint="I return an instance of a java sorted map" >
			<cfreturn createObject("Java","java.util.LinkedHashMap") />
	</cffunction>

	<cffunction name="setTestSuites" access="public" returntype="void" output="false" hint="Method used to set test suites for testing" >
		<cfargument name="testSuites" type="any" required="true" />
		<cfif arguments.testSuites.getClass().getName() eq "java.util.LinkedHashMap" >
			<cfset this.testSuites = arguments.testSuites />
		</cfif>
	</cffunction>
</cfcomponent>
