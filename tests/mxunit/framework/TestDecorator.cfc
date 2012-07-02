<cfcomponent hint="Abstract decorator for extending when you want to have decorators for unit tests" output="false">

	<!------------------------------------------- PUBLIC ------------------------------------------->

	<!--- proxies --->

	<cffunction name="TestCase" returntype="any" access="remote">
		<cfargument name="aTestCase" type="any" required="yes" />
		<cfscript>
			//skip down to the end, since it may be a decorator
			getBaseTarget().TestCase(arguments.aTestCase.getBaseTarget());

			return this;
	    </cfscript>
	</cffunction>

	<cffunction name="beforeTests" returntype="void" access="public">
		<cfreturn getTarget().beforeTests()>
	</cffunction>

	<cffunction name="afterTests" returntype="void" access="public">
		<cfreturn getTarget().afterTests() />
	</cffunction>

	<cffunction name="setUp" returntype="void" access="public" hint="">
		<cfreturn getTarget().setUp() />
	</cffunction>

	<cffunction name="tearDown" returntype="void" access="public">
		<cfreturn getTarget().tearDown() />
	</cffunction>

	<cffunction name="createRequestScopeDebug" access="public" output="false">
		<cfreturn getTarget().createRequestScopeDebug() />
	</cffunction>

	<cffunction name="invokeTestMethod"	access="public" returntype="string" output="false" >
		<cfargument name="methodName" hint="the name of the method to invoke" type="string" required="Yes">
		<cfargument name="args" hint="Optional set of arguments" type="struct" required="No" >
		<cfreturn getTarget().invokeTestMethod(argumentCollection=arguments) />
	</cffunction>

	<cffunction name="getRunnableMethods" access="public" returntype="array" output="false">
		<cfreturn getTarget().getRunnableMethods() />
	</cffunction>

	<cffunction name="setMockingFramework" access="public" output="false">
		<cfargument name="name" type="Any" required="true" />
		<cfset getTarget().setMockingFramework(argumentCollection=arguments) />
	</cffunction>

	<cffunction name="initDebug" access="public" output="false">
		<cfreturn getTarget().initDebug() />
	</cffunction>

	<cffunction name="debug" access="public" returntype="void">
		<cfargument name="var" type="any" required="true" />
		<cfset getTarget().debug(arguments.var)>
	</cffunction>

	<cffunction name="getDebug" access="public" returntype="array">
		<cfreturn getTarget().getDebug()>
	</cffunction>

	<cffunction name="clearDebug" access="public" returntype="void">
		<cfset getTarget().clearDebug()>
	</cffunction>

	<cffunction name="getAnnotation" access="public" returntype="Any" >
		<cfargument name="methodName" type="Any" required="true" />
		<cfargument name="annotationName" type="Any" required="true" />
		<cfargument name="defaultValue" type="Any" required="false" />
		<cfreturn getTarget().getAnnotation(argumentCollection=arguments) />
	</cffunction>

	<cffunction name="clearClassVariables" access="public">
		<cfset getTarget().clearClassVariables()>
	</cffunction>

	<cffunction name="getExpected" access="public">
		<cfreturn getTarget().getExpected() />
	</cffunction>

	<cffunction name="getActual" access="public">
		<cfreturn getTarget().getActual() />
	</cffunction>

	<cffunction name="getExpectedExceptionType" access="public">
		<cfreturn getTarget().getExpectedExceptionType() />
	</cffunction>

	<cffunction name="getExpectedExceptionMessage" access="public">
		<cfreturn getTarget().getExpectedExceptionMessage() />
	</cffunction>

	<cffunction name="setExpectedExceptionType" access="public">
		<cfargument name="expectedExceptionType" type="string" required="true"/>
		<cfreturn getTarget().setExpectedExceptionType(arguments.expectedExceptionType) />
	</cffunction>

	<cffunction name="setExpectedExceptionMessage" access="public">
		<cfargument name="expectedExceptionMessage" type="string" required="true"/>
		<cfreturn getTarget().setExpectedExceptionMessage(arguments.expectedExceptionMessage) />
	</cffunction>

	<cffunction name="getTarget" hint="get the current Target. May actually be another decorator." access="public" returntype="any" output="false">
		<cfreturn variables.instance.target />
	</cffunction>

	<cffunction name="setTarget" access="public" returntype="void" output="false">
		<cfargument name="target" type="any" required="true">
		<cfset variables.instance.target = arguments.target />
	</cffunction>

	<cffunction name="getBaseTarget" hint="Get the absolute bottom target - the actual test case" access="public" returntype="any" output="false">
		<cfreturn getTarget().getBaseTarget()/>
	</cffunction>

	<cffunction name="getVariablesScope" access="public" hint="Door into another component's variables scope">
		<cfreturn getTarget().getBaseTarget().getVariablesScope() />
	</cffunction>

	<cffunction name="onMissingMethod" hint="Delegates any missing method calls down the decorator chain, ending at the base target. If a function is still not found, a method not found exception will result">
		<cfargument name="missingMethodName" type="string" required="true"/>
		<cfargument name="missingMethodArguments" type="any" required="false"/>
		<cfset var result = "">
		<cfinvoke component="#getTarget()#" method="#missingMethodName#" argumentcollection="#missingMethodArguments#" returnvariable="result">

		<cfif isDefined("result")>
			<cfreturn result>
		</cfif>
	</cffunction>

	<!------------------------------------------- PACKAGE ------------------------------------------->

	<!------------------------------------------- PRIVATE ------------------------------------------->

</cfcomponent>