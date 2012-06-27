<cfcomponent>

	<cfset variables.requestScopeDebuggingEnabled = false />


  <cffunction name="setDataProviderHandler">
    <cfargument name="dph" />
    <cfset variables.dataProviderHandler = arguments.dph />
  </cffunction>


  <cffunction name="setMockingFramework">
     <cfargument name="mf" />
     <cfset variables.mockingFramework = arguments.mf />
  </cffunction>

	<cffunction name="enableRequestScopeDebugging">
		<!--- TODO: Add a test for request scope debugging or get rid of it. --->
		<cfset variables.requestScopeDebuggingEnabled = true />
	</cffunction>

	<cffunction name="run" returntype="any" access="public" output="true" hint="Primary method for running TestSuites and individual tests.">
		<cfargument name="allSuites" hint="a structure corresponding to the key/componentName"/>
		<cfargument name="results" hint="The TestResult collecting parameter." required="no" type="TestResult" default="#createObject("component","TestResult").TestResult()#" />
		<cfargument name="testMethod" hint="A single test method to run." type="string" required="no" default="">

		<cfset var testCase = "">
		<cfset var methodIndex = 1>
		<cfset var currentTestSuiteName = "" />
		<cfset var currentSuite = "" />
		<cfset var iterator = arguments.allSuites.keySet().iterator() />
	
		<cfloop condition="#iterator.hasNext()# eq true">
			<cfset currentTestSuiteName = iterator.next() />
			<cfset currentSuite = allSuites.get(currentTestSuiteName) />
			
			
			<cfset testCase = createTestCaseFromComponentOrComponentName(currentSuite.ComponentObject) />
			
			<!--- set the MockingFramework if one has been set for the TestSuite --->
			<cfif len(variables.MockingFramework)>
				<cfset testCase.setMockingFramework(variables.MockingFramework) />
			</cfif>
			
			<!--- Invoke prior to tests. Class-level setUp --->
			<cfset testCase.beforeTests() />
			
			<cfif len(arguments.testMethod)>
				<cfset runTestMethod(testCase, testMethod, results, currentTestSuiteName) />
			<cfelse>
				<cfloop from="1" to="#arrayLen(currentSuite.methods)#" index="methodIndex">
					<cfset runTestMethod(testCase, currentSuite.methods[methodIndex], results, currentTestSuiteName) />
				</cfloop>
			</cfif>
			
			<!--- Invoke after tests. Class-level tearDown --->
			<cfset testCase.afterTests()>
		</cfloop>

		<cfset results.closeResults() /><!--- Get correct time run for suite --->

		<cfreturn results />
	</cffunction>

	<cffunction name="createTestCaseFromComponentOrComponentName">
		<cfargument name="componentObject"/>
		<cfif isSimpleValue(componentObject)>
			<cfreturn createObject("component", currentTestSuiteName).TestCase(componentObject) />
		<cfelse>
			<cfreturn componentObject.TestCase(componentObject) />
		</cfif>
	</cffunction>

	<cffunction name="runTestMethod" access="private">
		<cfargument name="testCase" />
		<cfargument name="methodName" />
		<cfargument name="results" />
		<cfargument name="currentTestSuiteName"/>

		<cfset var tickCountAtStart = getTickCount() />
		<cfset var outputOfTest = "" />

		<cfset testCase.setExpectedExceptionType( testCase.getAnnotation(methodName,"expectedException") ) />
		<cfset testCase.setExpectedExceptionMessage('') />

		<cftry>

			<cfset results.startTest(methodName,currentTestSuiteName) />

			<cfset testCase.clearClassVariables() />
			<cfset testCase.initDebug() />

			<cfif requestScopeDebuggingEnabled>
				<cfset testCase.createRequestScopeDebug() />
			</cfif>

			<cfset testCase.setUp()/>

			<cfset outputOfTest = testCase.invokeTestMethod(methodName)>

			<cfset assertExpectedExceptionTypeWasThrown( testCase.getExpectedExceptionType(), testCase.getExpectedExceptionMessage() ) />

			<cfset results.addSuccess('Passed') />

			<!--- Add the trace message from the TestCase instance --->
			<cfset results.addContent(outputOfTest) />

			<cfcatch type="mxunit.exception.AssertionFailedError">
				<cfset addFailureToResults(results=results, expected=testCase.getExpected(), actual=testCase.getActual(), exception=cfcatch, content=outputOfTest)>
			</cfcatch>

			<cfcatch type="any">
				<!---<cflog text="inside cfcatch. #cfcatch.message# #cfcatch.detail#   #testCase.getExpectedExceptionType()#, #testCase.getexpectedExceptionMessage()# ">--->
				<cfset handleCaughtException(rootOfException(cfcatch), testCase.getExpectedExceptionType(), testCase.getExpectedExceptionMessage(), results, outputOfTest, testCase, cfcatch)>
			</cfcatch>
		</cftry>

		<cftry>
			<cfset testCase.tearDown() />

			<cfcatch type="any">
				<cfset results.addError(cfcatch)>
			</cfcatch>
		</cftry>

		<!--- add the debug array to the test result item --->
		<cfset results.setDebug( testCase.getDebug() ) />

		<!---  make sure the debug buffer is reset for the next text method  --->
		<cfset testCase.clearDebug()  />

		<!--- reset the trace message.Bill 6.10.07 --->
		<cfset testCase.traceMessage="" />
		<cfset results.addProcessingTime(getTickCount()-tickCountAtStart) />

		<cfset results.endTest(methodName) />
	</cffunction>

	<cffunction name="assertExpectedExceptionTypeWasThrown">
		<cfargument name="expectedExceptionType"/>
		<cfif expectedExceptionType NEQ "">
			<cfthrow type="mxunit.exception.AssertionFailedError" message="Exception: #expectedExceptionType# expected but no exception was thrown" />
		</cfif>
	</cffunction>

	<cffunction name="rootOfException" access="private">
		<cfargument name="caughtException"/>
		<cfif structKeyExists(caughtException,"rootcause")>
			<cfreturn caughtException.rootcause />
		</cfif>
		<cfreturn caughtException />
	</cffunction>

	<cffunction name="addFailureToResults" access="private">
		<cfargument name="results" required="true" hint="the results object">
		<cfargument name="expected" required="true">
		<cfargument name="actual" required="true">
		<cfargument name="exception" required="true" hint="the cfcatch struct">
		<cfargument name="content" required="true">

		<cfset results.addFailure(exception) />
		<cfset results.addExpected(expected)>
		<cfset results.addActual(actual)>
		<cfset results.addContent(content) />

		<cflog file="mxunit" type="error" application="false" text="#exception.message#::#exception.detail#">
	</cffunction>

	<cffunction name="_$snif" access="private" hint="Door into another component's variables scope">
		<cfreturn variables />
	</cffunction>



	<cffunction name="handleCaughtException" access="private">
		<cfargument name="caughtException" type="any"/>
		<cfargument name="expectedExceptionType" type="string" required="true" />
		<cfargument name="expectedExceptionMessage" type="string" required="true" />
		<cfargument name="results" />
		<cfargument name="outputOfTest" />
		<cfargument name="testCase" />

		<cfif arguments.expectedExceptionMessage eq ''>
			<cfset arguments.expectedExceptionMessage = 'Exception: #expectedExceptionType# expected but #arguments.caughtException.type# was thrown' />
		</cfif>

		<cfif exceptionMatchesType(arguments.caughtException, expectedExceptionType)>
			<cfset results.addSuccess('Passed') />
			<cfset results.addContent(outputOfTest) />
			<cfset arguments.testCase.debug(caughtException) />
		<cfelseif expectedExceptionType NEQ "">
			<cfset arguments.testCase.debug(caughtException) />
			<cftry>
				<cfthrow type="#arguments.expectedExceptionType#" message="#arguments.expectedExceptionMessage#">
				<cfcatch type="any">
					<cfset addFailureToResults(results=arguments.results, expected=arguments.expectedExceptionType, actual=arguments.caughtException.type, exception=arguments.caughtException, content=arguments.outputOfTest)>
				</cfcatch>
			</cftry>
		<cfelse>
			<cfset testCase.debug(caughtException) />
			<cfset results.addError(caughtException) />
			<cfset results.addContent(outputOfTest) />

			<cflog file="mxunit" type="error" application="false" text="#arguments.caughtException.message#::#arguments.caughtException.detail#" />
		</cfif>
	</cffunction>


	<cffunction name="exceptionMatchesType" access="private">
		<cfargument name="actualException" type="any" required="true" />
		<cfargument name="expectedExceptionType" type="string" required="true" />

		<cfif expectedExceptionType eq "">
			<cfreturn false/>
		</cfif>

		<cfreturn arguments.expectedExceptionType eq 'any' or listFindNoCase(expectedExceptionType, actualException.type) or listFindNoCase(expectedExceptionType, getMetaData(actualException).getName())>
	</cffunction>
</cfcomponent>
