<!---
	The implements attribute is essentially ignored by CFMX 7 and 8, but
	this class does implement run(), the main contract in Test.cfc.
--->
<cfcomponent displayname="TestCase" extends="Assert" hint="Composite parent of all TestCases. Extend this class to build and run tests within the MXUnit framework.">
	<!---
		Invoked prior to any test methods and run once per TestCase.

		Override in your testcase.
	--->
	<cffunction name="beforeTests" returntype="void" access="public">
	</cffunction>

	<!---
		Invoked after all test methods and run once per TestCase.

		Override in your testcase.
	--->
	<cffunction name="afterTests" returntype="void" access="public">
	</cffunction>

	<!---
		Invoked by MXUnit prior to any test method.

		Override in your testcase.
	--->
	<cffunction name="setUp" returntype="void" access="public" hint="">
	</cffunction>

	<!---
		Invoked by MXUnit after to any test method.

		Override in your testcase.
	--->
	<cffunction name="tearDown" returntype="void" access="public">
	</cffunction>

	<!--- constructor --->
	<cfset initProperties() />

	<!--- initialization --->
	<cffunction name="initProperties" access="private" output="false">
		<!--- How can we enforce creating a name? --->
		<cfparam name="this.name" type="string" default="" />
		<cfparam name="this.traceMessage" type="string" default="" />
		<cfparam name="this.result" type="any" default="#createObject("component", "TestResult")#" />
		<cfparam name="this.metadata" type="struct" default="#getMetaData(this)#" />
		<cfparam name="this.package" type="string" default="" />

		<cfset setMockingFramework("") />
		<cfset initDebug() />
	</cffunction>

	<cffunction name="initDebug" access="public" output="false">
		<cfparam name="debugArrayWrapper" type="struct" default="#StructNew()#" />
		<cfparam name="debugArray" type="array" default="#arrayNew(1)#" />

		<cfset variables.debugArrayWrapper.debugArray = debugArray />

		<cfreturn debugArrayWrapper />
	</cffunction>

	<cffunction name="createRequestScopeDebug" access="public" output="false">
		<cfset request.debug = debug><!--- mixin the function --->
		<cfset request.debugArrayWrapper = StructNew()>
		<cfset request.debugArrayWrapper.debugArray = arrayNew(1)>
	</cffunction>

	<cffunction name="stopRequestScopeDebug" access="public" output="false">
		<cfset structDelete(request,"debug")>
		<cfset structDelete(request,"debugArrayWrapper")>
	</cffunction>

	<!--- get on with the show --->
	<cffunction name="TestCase" returntype="any" access="remote">
		<cfargument name="aTestCase" type="TestCase" required="no" default="#this#" />

		<cfscript>
			super.init();
			this.metadata = getMetaData(aTestCase);
			this.installRoot = componentUtils.getComponentRoot();
			return applyDecorators(aTestCase);
		</cfscript>

	</cffunction>

	<cffunction name="toStringValue" access="public" returntype="string" hint="Returns the name of this TestCase">
		<cfreturn this.name />
	</cffunction>

	<cffunction name="createResult" access="private" returntype="TestResult">
		<cfscript>
			this.result = createObject("component","TestResult").TestResult();
			return this.result;
		</cfscript>
	</cffunction>

	<cffunction name="run" returntype="any" access="remote" hint="Main run method used by the Eclipse Plugin">">
		<cfargument name="testResult" type="any" required="no" default="#createObject("component","TestResult")#" />

		<cfscript>
			TestCase(this);
			testResult.startTest(this);
		</cfscript>
	</cffunction>

	<cffunction name="invokeTestMethod" hint="invoke the test method on this case, returns any output. Generally useful for decorators to intercept"
		access="public" returntype="string" output="false" >
		<cfargument name="methodName" hint="the name of the method to invoke" type="string" required="Yes">
		<cfargument name="args" hint="Optional set of arguments" type="struct" required="No" default="#StructNew()#">
		<cfset var output = 0>
		<cfsavecontent variable="output" >
			<cfinvoke component="#this#" method="#arguments.methodName#" argumentcollection="#arguments.args#">
		</cfsavecontent>
		<cfreturn output />
	</cffunction>

	<!---
		Note: This will fail if test suite is built using the add() method instead
		of the addAll() method. If add() is used, override this method.
	--->
	<cffunction name="runTest" returntype="TestResult" access="remote" output="true">
		<cfargument name="suite" type="any" required="no" default="#createObject("component","TestSuite").addAll(this.metadata.name)#" />

		<cfif structKeyExists(url, 'testMethod')>
			<cfset this.result = suite.run(this.result, url.testMethod)/>
		<cfelse>
			<cfset this.result = suite.run()/>
		</cfif>

		<cfreturn this.result />
	</cffunction>

	<cffunction name="runBare" returntype="void" access="public" hint="Not really used">
		<cfscript>
			TestCase(this);

			setUp();

			try {
				runTest();
			} catch (exception e){
				/*do nothing*/
			}

			tearDown();
		</cfscript>
	</cffunction>

	<!--- Wrapper to add tracing --->
	<cffunction name="addTrace" returntype="void" access="public" hint="Deprecated. Use debug() instead.">
		<cfargument name="message" type="string" required="false" default="" />

		<cfscript>
			debug(arguments.message);
		</cfscript>
	</cffunction>

	<!---
		Convenience method for running tests via URL/Web service invocation
		One less step a developer has to implement
	--->
	<cffunction name="runTestRemote" access="remote" returntype="void" hint="Remote method for running tests quickly via Http.">
		<cfargument name="testMethod" type="string" required="no" default="" hint="A single test to run. If not specified, all tests are run." />
		<cfargument name="debug" type="boolean" required="false" default="false" hint="Flag to indicate whether or not to dump the test results to the screen.">
		<cfargument name="output" type="string" required="false" default="jqGrid" hint="Output format: html,xml,junitxml,jqGrid "><!--- html,xml,junitxml,jqGrid --->

		<cfscript>
			TestCase(this); //don't remove this. its breaks things (no I don't know why)

			this.result = runTest();

			switch(arguments.output){
			case 'rawhtml':
					writeoutput(this.result.getRawHtmlresults());
				break;

			case 'xml':
					writeoutput(this.result.getXmlresults());
				break;

			case 'junitxml':
					writeoutput(this.result.getJUnitXmlresults());
				break;

			case 'json':
					writeoutput(this.result.getJSONResults());
				break;

			case 'query':
					dump(this.result.getQueryresults());
				break;

			case 'text':
					writeoutput( trim(this.result.getTextresults(this.name)));
				break;

			default:
					writeoutput(this.result.getHtmlresults());
				break;
			}
		</cfscript>

		<cfif arguments.debug>
			<p>&nbsp;</p>
			<cfdump var="#this.result.getResults()#" label="Raw Results Dump" />
		</cfif>
	</cffunction>

	<cffunction name="getRunnableMethods" hint="Gets an array of all runnable test methods for this test case. This includes anything in its inheritance hierarchy" access="public" returntype="array" output="false">
		<cfset var a_methods = arrayNew(1) />
		<cfset var a_parentMethods = arrayNew(1) />
		<cfset var thisComponentMetadata = getMetadata(this) />
		<cfset var i = "" />
		<cfset var tmpParentObj = "" />

		<!--- now get the public methods from the actual component --->
		<cfif StructKeyExists(thisComponentMetadata, "Functions")>
			<cfloop from="1" to="#arrayLen(thisComponentMetadata.Functions)#" index="i">
				<cfparam name="thisComponentMetadata.Functions[#i#].access" default="public">
				<cfif accept(thisComponentMetadata.Functions[i])>
					<cfset arrayAppend(a_methods, thisComponentMetadata.Functions[i].name)>
				</cfif>
			</cfloop>
		</cfif>

		<!--- climb the parent tree until we hit a framework template (i.e. TestCase) --->
		<cfif NOT componentUtils.isFrameworkTemplate(thisComponentMetadata.Extends.Path)>
			<cfset tmpParentObj = createObject("component", thisComponentMetadata.Extends.Name) />
			<cfset a_parentMethods = tmpParentObj.getRunnableMethods() />

			<cfloop from="1" to="#arrayLen(a_parentMethods)#" index="i">
				<!--- append this method from the parent only if the child didn't already add it --->
				<cfif NOT listFindNoCase(arrayToList(a_methods), a_parentMethods[i])>
					<cfset arrayAppend(a_methods, a_parentMethods[i]) />
				</cfif>
			</cfloop>

			<cfset tmpParentObj = "" />
			<cfset a_parentMethods = arrayNew(1) />
		</cfif>

		<cfreturn a_methods />
	</cffunction>

	<cffunction name="accept" access="package" hint="contains the logic for whether a test is a valid runnable method" returntype="boolean">
		<cfargument name="testStruct" type="struct" required="true" hint="Structure for a function coming from getmetadata"/>
		<cfset var isAcceptable = true>

		<cfif listFindNoCase("package,private", testStruct.access)
			 OR listFindNoCase("setUp,tearDown,beforeTests,afterTests", testStruct.name)
			 OR reFindNoCase("_cffunccfthread", testStruct.Name)
			 OR ( (structKeyExists(testStruct, "test") AND isBoolean(testStruct.test) AND NOT testStruct.test))>

			<cfset isAcceptable = false>
		</cfif>

		<cfreturn isAcceptable />
	</cffunction>

	<cffunction name="makePublic" access="package" hint="makes a testable version of a private method for a given object. This is a convenience pass-through to PublicProxyMaker.makePublic. See documentation on 'testing private methods' at mxunit.org/doc. Or open mxunit/tests/framework/PublicProxyMakerTest.cfc for examples of how to use" returntype="any">
		<cfargument name="ObjectUnderTest" required="true" type="any" hint="an instance of the object with a private method to be proxied">
		<cfargument name="privateMethodName" required="true" type="string" hint="name of the private method to be proxied">
		<cfargument name="proxyMethodName" required="false" type="string" default="" hint="name of the proxy method name to be used; if not passed, defaults to the name of the private method prefixed with an underscore">

		<cfset var obj = "" />

		<cfinvoke component="PublicProxyMaker" method="makePublic" ObjectUnderTest="#ObjectUnderTest#" privateMethodName="#privateMethodName#" proxyMethodName="#proxyMethodName#" returnvariable="obj">

		<cfreturn obj />
	</cffunction>

	<cffunction name="injectMethod" output="false" access="public" returntype="void" hint="injects the method from giver into receiver. This is helpful for quick and dirty mocking">
		<cfargument name="receiver" type="any" required="true" hint="the object receiving the method"/>
		<cfargument name="giver" type="any" required="true" hint="the object giving the method"/>
		<cfargument name="functionName" type="string" required="true" hint="the function to be injected from the giver into the receiver"/>
		<cfargument name="functionNameInReceiver" type="string" required="false" default="#arguments.functionName#" hint="the function name that you will call. this is useful when you want to inject giver.someFunctionXXX but have it be called as someFunction in your receiver object">

		<cfset var blender = createObject("component","ComponentBlender")>

		<cfset blender._mixinAll(receiver, blender, "_mixin,_copyToNewName")>
		<cfset blender._mixinAll(giver, blender, "_getComponentVariable")>

		<cfset receiver._copyToNewName(functionNameInReceiver, functionNameInReceiver & "__orig__", true)>
		<cfset receiver._mixin( propertyName = functionNameInReceiver,
								property = Giver._getComponentVariable(functionName),
								ignoreIfExisting = false )>
	</cffunction>

	<cffunction name="restoreMethod" output="false" access="public" returntype="void" hint="restores a previously overwritten method (via injectMethod) to its original state">
    	<cfargument name="receiver" type="any" required="true"/>
		<cfargument name="functionName" type="string" required="true"/>
		<cfset var blender = createObject("component","ComponentBlender")>
		<cfset blender._mixinAll(receiver, blender, "_copyToNewName")>
		<cfset receiver._copyToNewName(functionName & "__orig__", functionName,false)>
	</cffunction>


	<cffunction name="injectProperty" output="false" access="public" returntype="void" hint="injects properties into the receiving object">
		<cfargument name="receiver" type="any" required="true" hint="the object receiving the method"/>
		<cfargument name="propertyName" type="string" required="true" hint="the property to be overwritten"/>
		<cfargument name="propertyValue" type="any" required="true" hint="the property value to be used">
		<cfargument name="scope" type="string" required="false" default="" hint="the scope in which to set the property. Defaults to variables and this.">

		<cfset var blender = createObject("component","ComponentBlender")>

		<cfset blender._mixinAll(receiver, blender, "_mixin,_mixinProperty")>
		<cfset receiver._mixinProperty(propertyName = arguments.propertyName,
								property = arguments.propertyValue,
								scope = arguments.scope)>
	</cffunction>

	<cffunction name="dump" access="public">
		<cfargument name="obj" required="true" type="any">
		<cfargument name="label" required="false" default="MXUNIT Dump" />
		<cfdump var="#arguments.obj#" label="#arguments.label#">
	</cffunction>

	<cffunction name="debug" access="public" returntype="void" hint="Use in your tests to add simple or complex debug data to test results. Used by Eclpise plugin heavily. Beware: adding lots of data, particularly object instances, will probably cause this to hang!">
		<cfargument name="var" type="any" required="true" />

		<cfif isDefined("request.debugArrayWrapper")>
			<cfset variables.debugArrayWrapper = request.debugArrayWrapper>
		</cfif>

		<cfset arrayAppend(variables.debugArrayWrapper.debugArray, arguments) />
	</cffunction>

	<cffunction name="clearDebug" access="public" returntype="void" hint="Clears the debug array">
		<cfset arrayClear(debugArrayWrapper.debugArray) />
	</cffunction>

	<cffunction name="getDebug" access="public" returntype="array" hint="Returns the debug array">
		<cfif isDefined("request.debugArrayWrapper")>
			<cfset variables.debugArrayWrapper = request.debugArrayWrapper>
		</cfif>

		<cfreturn variables.debugArrayWrapper.debugArray />
	</cffunction>

	<cffunction name="getDebugWrapper" access="public" returntype="struct" hint="Returns the debug array">
		<cfreturn variables.debugArrayWrapper />
	</cffunction>

	<cffunction name="setDebugWrapper" access="public" returntype="void" hint="">
		<cfargument name="debugArrayWrapper" type="struct" required="true"/>

		<cfset variables.debugArrayWrapper = arguments.debugArrayWrapper />
	</cffunction>

	<cffunction name="print" hint="Wrapper for writeoutout().">
		<cfargument name="message" />

		<cfoutput>#arguments.message#</cfoutput>
	</cffunction>

	<cffunction name="println" hint="Wrapper for writeoutout().">
		<cfargument name="message" />

		<cfoutput>#arguments.message#<br /></cfoutput>
	</cffunction>

	<!--- Mocking stuff --->
	<cfset _mockFactory = createObject("component", "MockFactoryFactory") />

	<cffunction name="_setMockFactory" hint="Dependency injection window.">
		<cfargument name="mf" type="any" required="true" />

		<cfset _mockFactory = arguments.mf />
	</cffunction>

	<cffunction name="_getMockFactory" hint="Returns the current MockFactory object.">
		<cfreturn _mockFactory />
	</cffunction>

	<cffunction name="setMockingFramework" hint="Allows a developer to set the default Mocking Framework for this test case.">
		<cfargument name="name" type="Any" required="true" hint="The name of the mocking framework to use" />

		<cfset this.mockingFramework = arguments.name />
	</cffunction>

	<cffunction name="getMockFactory" hint="Returns the actual Mock factory of the framework">
		<cfargument name="fw" type="Any" required="false" default="" hint="The name of the mocking framework to use" />

		<cfif not len(arguments.fw)>
			<cfset arguments.fw = this.mockingFramework />
		</cfif>

		<cfreturn  _mockFactory.MockFactoryFactory(arguments.fw).getFactory() />
	</cffunction>

	<cffunction name="mock" output="false" access="public" returntype="any" hint="Returns a mock object via the configured Mock Factory">
		<cfargument name="mocked" type="any" required="false" default="" hint="Component name or an actual component" />
		<cfargument name="mockType" type="string" required="false" hint="Type of mock to create (fast,typeSafe,...)" />
		<cfargument name="fw" type="string" required="false" default="MightyMock" hint="The name of the mocking framework to use" />

		<cfset var theMock = 0 />
		<cfset var mff = 0 />
		<cfset var mf = 0 />

		<cfif not len(arguments.fw)>
			<cfset arguments.fw = this.mockingFramework />
		</cfif>

		<cfset mff = _mockFactory.MockFactoryFactory(arguments.fw) />
		<cfset mf = mff.getFactory() />

		<cfif not IsObject(arguments.mocked)>
			<cfset arguments[mff.getConfig("CreateMockStringArgumentName")] = arguments.mocked />
		<cfelse>
			<cfset arguments[mff.getConfig("CreateMockObjectArgumentName")] = arguments.mocked />
		</cfif>

		<cfinvoke component="#mf#" method="#mff.getConfig('CreateMockMethodName')#" argumentcollection="#arguments#" returnvariable="theMock" />

		<cfreturn theMock />
	</cffunction>

	<!--- annotation stuff --->
	<cffunction name="getAnnotation" access="public" returntype="Any" hint="Returns the value for an annotation, allowing for an mxunit namespace or not">
		<cfargument name="methodName" type="Any" required="false" hint="The name of the test method. An empty string means a testCase annotation" default="" />
		<cfargument name="annotationName" type="Any" required="true" hint="The name of the annotation" />
		<cfargument name="defaultValue" type="Any" required="false" default="" hint="The value to return if no annotation is found" />

		<cfset var returnVal = arguments.defaultValue />
		<cfset var metadataTarget = this />
		<cfset var metadata = "" />
		<cfif len(arguments.methodName) gt 0>
			<cfif not structKeyExists(this,arguments.methodName)>
				<cfthrow type="mxunit.exception.methodNotFound"
					message="An annotation of #arguments.annotationName# was requested for the #arguments.methodName# method, which does not exist."
					detail="Check the name of the method." />
			<cfelse>
				<cfset metadataTarget = this[arguments.methodName] />
			</cfif>
		</cfif>

		<cfset metadata = getMetadata(metadataTarget) />

		<!--- go lookup up inheritence tree, and move the metadata if neccessary --->
		<cfscript>
			if(NOT Len(arguments.methodName))
			{
				while(StructKeyExists(metadata, "extends"))
				{
					if(StructKeyExists(metadata,"mxunit:" & arguments.annotationName) OR
						StructKeyExists(metadata,arguments.annotationName)
						)
					{
						break;
					}

					metadata = metadata.extends;
				}
			}
        </cfscript>

		<cfif StructKeyExists(metadata,"mxunit:" & arguments.annotationName)>
			<cfset returnVal = metadata["mxunit:" & arguments.annotationName] />
		<cfelseif StructKeyExists(metadata,arguments.annotationName)>
			<cfset returnVal = metadata[arguments.annotationName] />
		</cfif>

		<cfreturn returnVal />
	</cffunction>

	<cffunction name="expectException">
		<cfargument name="expectedExceptionType" />
		<cfargument name="expectedExceptionMessage" default="" />
		<cfset structAppend( variables, arguments ) />
	</cffunction>

	 <cffunction name="orderedExpectation" access="public" hint="Method for mocking. Creates an OrderedExpectation object used for verify the order in which mocks have been called">
		<cfargument name="mocks" required="true" type="any" hint="One or more mocks in which to verify order" />
		<cfscript>
		return createObject("component","mightymock.OrderedExpectation").init(mocks);
		</cfscript>
	</cffunction>

	<cffunction name="getBaseTarget" hint="In case of decorators - return myself" access="public" returntype="any" output="false">
		<cfreturn this/>
	</cffunction>

	<cffunction name="applyDecorators" hint="applies the chain of decorators, if it exists" access="public" returntype="any" output="false">
		<cfargument name="object" hint="the object to check to see if it needs some decorators applied" type="any" required="Yes">
		<cfscript>
			var meta = getMetadata(object);
			var decorator = 0;
			var decoratorPath = 0;
			var decoratorNames = 0;

			//if already a decorator, kick out.
			if(componentUtils.objectIsTypeOf(arguments.object, "mxunit.framework.TestDecorator"))
			{
				return arguments.object;
			}
        </cfscript>

        <cfset decoratorNames = arguments.object.getAnnotation(annotationName="decorators") />
		<cfset decoratorNames = listPrepend( decoratorNames, getRequiredDecoratorPaths() ) />

		<cfloop list="#decoratorNames#" index="decoratorPath">
			<cfset decorator = createObject("component", decoratorPath)/>
			<cfset decorator.setTarget(object)/>
			<cfset decorator.metadata = meta />
			<cfset arguments.object = decorator/> <!--- flip it and reverse it. --->
		</cfloop>

		<cfreturn arguments.object>
	</cffunction>

	<cffunction name="getRequiredDecoratorPaths" output="false" access="public" returntype="any" hint="Returns a list of fully-qualified paths to framework-required decorators">
    	<cfreturn "mxunit.framework.decorators.DataProviderDecorator">
    </cffunction>

    <cffunction name="setExpectedExceptionType" access="public">
		<cfargument name="expectedExceptionType" type="string" required="true"/>
		<cfset variables.expectedExceptionType = arguments.expectedExceptionType />
	</cffunction>

    <cffunction name="setExpectedExceptionMessage" access="public">
		<cfargument name="expectedExceptionMessage" type="string" required="true"/>
		<cfset variables.expectedExceptionMessage = arguments.expectedExceptionMessage />
	</cffunction>

    <cffunction name="getExpectedExceptionType" access="public">
		<cfreturn variables.expectedExceptionType />
	</cffunction>

	<cffunction name="getExpectedExceptionMessage" access="public">
		<cfreturn variables.expectedExceptionMessage />
	</cffunction>

	<cffunction name="getVariablesScope" access="public" hint="Front door into the Test's variables scope">
		<cfreturn variables>
	</cffunction>
</cfcomponent>
